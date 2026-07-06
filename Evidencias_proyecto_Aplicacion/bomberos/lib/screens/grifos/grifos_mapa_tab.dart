import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../models/mapa_busqueda_opciones.dart';
import '../../services/mapa_grifo_service.dart';
import '../../services/mapa_grifos_cache.dart';
import '../../utils/geo_utils.dart';
import '../../utils/grifo_estado_utils.dart';
import '../../utils/mapa_centro_inicial.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/mapa_seleccion_callout.dart';
import 'grifos_resultados_widgets.dart';

/// Vista de mapa guardada antes de entrar al modo enfoque de un grifo.
class _EstadoVistaMapa {
  const _EstadoVistaMapa({
    required this.centroCamara,
    required this.zoom,
    required this.mostrarBotonBuscar,
  });

  final LatLng centroCamara;
  final double zoom;
  final bool mostrarBotonBuscar;
}

/// Pestaña mapa: búsqueda por zona con radio configurable.
class GrifosMapaTab extends StatefulWidget {
  const GrifosMapaTab({
    super.key,
    required this.resultados,
    required this.onResultados,
    this.perfil,
    this.onEditar,
  });

  final List<GrifoMapaResultado> resultados;
  final ValueChanged<List<GrifoMapaResultado>> onResultados;
  final BomberoPerfil? perfil;
  final Future<void> Function(GrifoMapaResultado)? onEditar;

  @override
  State<GrifosMapaTab> createState() => _GrifosMapaTabState();
}

class _GrifosMapaTabState extends State<GrifosMapaTab> {
  static const _azul = Color(0xFF1565C0);
  final MapaGrifosCache _cache = MapaGrifosCache();
  late final MapaGrifoService _svc;

  GoogleMapController? _mapController;

  LatLng _centroCamara = MapaCentroInicial.santiago;
  double _zoomActual = 14;
  int _radioMetros = MapaBusquedaOpciones.radioPorDefectoMetros;
  int _limiteResultados = MapaBusquedaOpciones.limitePorDefecto;

  Set<Marker> _markers = {};
  GrifoFiltroEstado _filtroEstado = GrifoFiltroEstado.todos;
  int? _idGrifoDestacado;
  GrifoMapaResultado? _calloutGrifo;
  Offset? _calloutScreen;
  bool _modoEnfoque = false;
  _EstadoVistaMapa? _vistaAntesEnfoque;
  bool _restaurandoVista = false;

  final _mapaPanelKey = GlobalKey();

  bool _mapaListo = false;
  bool _ubicando = true;
  bool _buscando = false;
  bool _mostrarBotonBuscar = true;

  LatLng? _centroPendiente;

  @override
  void initState() {
    super.initState();
    _svc = MapaGrifoService(Supabase.instance.client);
    _centrarEnUsuario();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrifosMapaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resultados != widget.resultados && !_modoEnfoque) {
      setState(() {
        _idGrifoDestacado = null;
        _calloutGrifo = null;
        _calloutScreen = null;
        _markers = _crearMarcadores(widget.resultados);
      });
    }
  }

  MarkerId _markerId(GrifoMapaResultado g) => MarkerId('grifo_${g.idGrifo}');

  Marker _marcadorGrifo(GrifoMapaResultado g, {required bool destacado}) {
    return Marker(
      markerId: _markerId(g),
      position: LatLng(g.lat, g.lon),
      zIndexInt: destacado ? 2 : 1,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        destacado ? BitmapDescriptor.hueOrange : GrifoEstadoUtils.huePorEstado(g.estado),
      ),
      infoWindow: const InfoWindow(),
    );
  }

  Set<Marker> _crearMarcadores(List<GrifoMapaResultado> base) {
    if (_modoEnfoque && _calloutGrifo != null) {
      return {_marcadorGrifo(_calloutGrifo!, destacado: true)};
    }

    final lista = GrifoListaUtils.filtrar(base, _filtroEstado);
    return lista.map((g) => _marcadorGrifo(g, destacado: g.idGrifo == _idGrifoDestacado)).toSet();
  }

  Set<Circle> get _circulosEnMapa {
    final circles = <Circle>{};

    if (!_modoEnfoque) {
      circles.addAll(_circuloBusqueda);
    }

    final g = _calloutGrifo;
    if (g == null) return circles;

    circles.add(
      Circle(
        circleId: CircleId('resaltado_grifo_${g.idGrifo}'),
        center: LatLng(g.lat, g.lon),
        radius: 35,
        fillColor: const Color(0x44FF9800),
        strokeColor: const Color(0xFFE65100),
        strokeWidth: 3,
        zIndex: 1,
      ),
    );
    return circles;
  }

  Future<void> _salirModoEnfoque() async {
    final vista = _vistaAntesEnfoque;
    if (!_modoEnfoque && _calloutGrifo == null) return;

    setState(() {
      _modoEnfoque = false;
      _idGrifoDestacado = null;
      _calloutGrifo = null;
      _calloutScreen = null;
      _vistaAntesEnfoque = null;
      _markers = _crearMarcadores(widget.resultados);
      if (vista != null) {
        _centroCamara = vista.centroCamara;
        _zoomActual = vista.zoom;
        _mostrarBotonBuscar = vista.mostrarBotonBuscar;
      }
    });

    final c = _mapController;
    if (c == null || vista == null || !_mapaListo) return;

    _restaurandoVista = true;
    try {
      await c.animateCamera(CameraUpdate.newLatLngZoom(vista.centroCamara, vista.zoom));
    } catch (e) {
      debugPrint('Restaurar vista mapa grifos: $e');
    } finally {
      _restaurandoVista = false;
    }
  }

  Future<void> _actualizarPosicionCallout() async {
    final g = _calloutGrifo;
    final c = _mapController;
    if (g == null || c == null || !_mapaListo) return;
    try {
      final sc = await c.getScreenCoordinate(LatLng(g.lat, g.lon));
      if (!mounted) return;
      setState(() => _calloutScreen = Offset(sc.x.toDouble(), sc.y.toDouble()));
    } catch (e) {
      debugPrint('Posición callout grifo: $e');
    }
  }

  Future<void> _mostrarGrifoEnMapa(GrifoMapaResultado g) async {
    if (!_modoEnfoque) {
      _vistaAntesEnfoque = _EstadoVistaMapa(
        centroCamara: _centroCamara,
        zoom: _zoomActual,
        mostrarBotonBuscar: _mostrarBotonBuscar,
      );
    }

    setState(() {
      _modoEnfoque = true;
      _idGrifoDestacado = g.idGrifo;
      _calloutGrifo = g;
      _markers = _crearMarcadores(widget.resultados);
    });

    final panel = _mapaPanelKey.currentContext;
    if (panel != null && mounted) {
      await Scrollable.ensureVisible(
        panel,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }

    final c = _mapController;
    if (c == null || !_mapaListo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espera a que el mapa termine de cargar.')),
        );
      }
      return;
    }

    _restaurandoVista = true;
    try {
      const zoomEnfoque = 17.0;
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(g.lat, g.lon), zoomEnfoque),
      );
      if (mounted) {
        setState(() {
          _centroCamara = LatLng(g.lat, g.lon);
          _zoomActual = zoomEnfoque;
        });
      }
      await _actualizarPosicionCallout();
    } catch (e) {
      debugPrint('Enfocar grifo en mapa: $e');
    } finally {
      _restaurandoVista = false;
    }
  }

  void _onFiltroChanged(GrifoFiltroEstado f) {
    if (_modoEnfoque) {
      final visibles = GrifoListaUtils.filtrar(widget.resultados, f);
      final id = _idGrifoDestacado;
      if (id != null && !visibles.any((g) => g.idGrifo == id)) {
        _salirModoEnfoque();
      }
    }
    setState(() {
      _filtroEstado = f;
      if (!_modoEnfoque) {
        _markers = _crearMarcadores(widget.resultados);
      }
    });
    if (_modoEnfoque && _calloutGrifo != null) _actualizarPosicionCallout();
  }

  Set<Circle> get _circuloBusqueda => {
        Circle(
          circleId: const CircleId('radio_grifos'),
          center: _centroCamara,
          radius: _radioMetros.toDouble(),
          fillColor: const Color(0x331565C0),
          strokeColor: _azul,
          strokeWidth: 2,
        ),
      };

  bool _mapaDisponible() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  void _requiereNuevaBusqueda() {
    if (!_mostrarBotonBuscar && mounted) {
      setState(() => _mostrarBotonBuscar = true);
    }
  }

  Future<void> _centrarEnUsuario() async {
    if (mounted) setState(() => _ubicando = true);
    try {
      final res = await MapaCentroInicial.resolver(
        client: Supabase.instance.client,
        idCompania: widget.perfil?.idCompania,
      );
      _fijarCentro(res.centro, res.zoom);
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  void _fijarCentro(LatLng target, double zoom) {
    _centroCamara = target;
    _zoomActual = zoom;
    _centroPendiente = target;
    _aplicarCentroAlMapa(zoom);
  }

  Future<void> _aplicarCentroAlMapa(double zoom) async {
    final c = _mapController;
    if (c == null || !_mapaListo) return;
    try {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_centroCamara, zoom));
    } catch (e) {
      debugPrint('Cámara grifos: $e');
    }
  }

  Future<void> _encuadrarRadio() async {
    final c = _mapController;
    if (c == null || !mounted) return;
    final box = GeoUtils.boundingBox(
      _centroCamara.latitude,
      _centroCamara.longitude,
      _radioMetros.toDouble(),
    );
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(box.minLat, box.minLon),
            northeast: LatLng(box.maxLat, box.maxLon),
          ),
          56,
        ),
      );
    } catch (e) {
      debugPrint('Encuadre grifos: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapaListo = true;
    final pendiente = _centroPendiente;
    if (pendiente != null) {
      _centroCamara = pendiente;
      _aplicarCentroAlMapa(_zoomActual);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _centroCamara = position.target;
    _zoomActual = position.zoom;
    setState(() {});
    if (_modoEnfoque && _calloutGrifo != null) _actualizarPosicionCallout();
  }

  void _onCameraIdle() {
    if (!_mapaListo || _buscando || !mounted || _restaurandoVista) return;
    if (_modoEnfoque) {
      if (_calloutGrifo != null) _actualizarPosicionCallout();
      return;
    }
    _requiereNuevaBusqueda();
  }

  Future<void> _buscarEnZona() async {
    if (_mapController == null || !_mapaListo) return;

    if (_modoEnfoque) await _salirModoEnfoque();

    setState(() => _buscando = true);
    try {
      final centro = _centroCamara;

      if (_cache.esBusquedaRedundante(centro, _radioMetros, _limiteResultados)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta zona ya fue consultada. Mueve el mapa al menos 200 m o cambia radio/límite.',
              ),
            ),
          );
        }
        return;
      }

      final clave = GeoUtils.claveCache(
        centro.latitude,
        centro.longitude,
        _radioMetros,
        _limiteResultados,
      );
      final enCache = _cache.obtener(clave);
      if (enCache != null) {
        _aplicarResultados(enCache);
        _cache.guardar(
          clave: clave,
          datos: enCache,
          centro: centro,
          radioMetros: _radioMetros,
          limite: _limiteResultados,
        );
        return;
      }

      final lista = await _svc.buscarEnArea(
        latCentro: centro.latitude,
        lonCentro: centro.longitude,
        radioMetros: _radioMetros,
        limiteMaximo: _limiteResultados,
      );
      if (!mounted) return;

      _cache.guardar(
        clave: clave,
        datos: lista,
        centro: centro,
        radioMetros: _radioMetros,
        limite: _limiteResultados,
      );
      _aplicarResultados(lista);

      if (lista.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay grifos dentro de ${MapaBusquedaOpciones.etiquetaRadio(_radioMetros)}.',
            ),
          ),
        );
      }
    } on MapaGrifoException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
          _mostrarBotonBuscar = false;
        });
      }
    }
  }

  void _aplicarResultados(List<GrifoMapaResultado> lista) {
    if (!mounted) return;
    setState(() {
      _modoEnfoque = false;
      _vistaAntesEnfoque = null;
      _idGrifoDestacado = null;
      _calloutGrifo = null;
      _calloutScreen = null;
      _markers = _crearMarcadores(lista);
    });
    widget.onResultados(lista);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: AppWidthContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _seccionTitulo(
            icon: Icons.map_outlined,
            titulo: 'Búsqueda de Grifos en Mapa',
            subtitulo:
                'Usa el mapa interactivo para buscar y localizar grifos. Mueve el mapa y pulsa buscar.',
          ),
          KeyedSubtree(
            key: _mapaPanelKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _dropdownInt(
                        titulo: 'Radio de búsqueda',
                        valor: _radioMetros,
                        opciones: MapaBusquedaOpciones.radiosMetros,
                        etiqueta: MapaBusquedaOpciones.etiquetaRadio,
                        onChanged: (v) {
                          setState(() => _radioMetros = v);
                          _requiereNuevaBusqueda();
                          _encuadrarRadio();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdownInt(
                        titulo: 'Máx. grifos',
                        valor: _limiteResultados,
                        opciones: MapaBusquedaOpciones.limitesResultados,
                        etiqueta: (v) => '$v',
                        onChanged: (v) {
                          setState(() => _limiteResultados = v);
                          _requiereNuevaBusqueda();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMapa(),
                const SizedBox(height: 10),
                _leyendaMapa(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GrifosPanelResultados(
            resultados: widget.resultados,
            filtro: _filtroEstado,
            onFiltroChanged: _onFiltroChanged,
            idGrifoDestacado: _idGrifoDestacado,
            onVerEnMapa: _mostrarGrifoEnMapa,
            onEditar: widget.onEditar,
            mensajeVacio: 'Busca en esta zona para ver grifos en el mapa y la lista.',
          ),
        ],
        ),
      ),
    );
  }

  Widget _seccionTitulo({required IconData icon, required String titulo, String? subtitulo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _azul, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3)),
        ],
      ],
    );
  }

  Widget _leyendaMapa() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        _puntoLeyenda(GrifoEstadoUtils.verde, 'Operativo'),
        _puntoLeyenda(GrifoEstadoUtils.rojo, 'Dañado'),
        _puntoLeyenda(GrifoEstadoUtils.amarillo, 'Mantenimiento'),
        _puntoLeyenda(GrifoEstadoUtils.gris, 'Sin verificar'),
      ],
    );
  }

  Widget _puntoLeyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _dropdownInt({
    required String titulo,
    required int valor,
    required List<int> opciones,
    required String Function(int) etiqueta,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          key: ValueKey('$titulo-$valor'),
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: opciones
              .map((v) => DropdownMenuItem(value: v, child: Text(etiqueta(v), style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _buildMapa() {
    final alturaMapa = AppLayout.mapHeight(MediaQuery.sizeOf(context).width);

    if (!_mapaDisponible()) {
      return Container(
        height: alturaMapa,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('Mapa disponible en Android, iOS y Web.'),
      );
    }

    final callout = _calloutGrifo;
    final calloutPos = _calloutScreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: alturaMapa,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapW = constraints.maxWidth;
            final mapH = constraints.maxHeight;

            double? calloutLeft;
            double? calloutTop;
            if (callout != null && calloutPos != null) {
              const calloutW = 260.0;
              const calloutH = 72.0;
              calloutLeft = (calloutPos.dx - calloutW / 2).clamp(8.0, mapW - calloutW - 8);
              calloutTop = (calloutPos.dy - calloutH - 18).clamp(44.0, mapH - calloutH - 8);
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
              key: const ValueKey('mapa_grifos_busqueda'),
              initialCameraPosition: CameraPosition(target: _centroCamara, zoom: _zoomActual),
              circles: _circulosEnMapa,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
                ),
                if (callout != null && calloutLeft != null && calloutTop != null)
                  Positioned(
                    left: calloutLeft,
                    top: calloutTop,
                    child: MapaSeleccionCallout(
                      titulo: 'Grifo #${callout.idGrifo}',
                      subtitulo: 'Seleccionado en la lista',
                      accentColor: _azul,
                      onCerrar: _salirModoEnfoque,
                    ),
                  ),
                if (_ubicando)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            if (!_modoEnfoque)
              IgnorePointer(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _azul,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Radio: ${MapaBusquedaOpciones.etiquetaRadio(_radioMetros)} • '
                  'Máx. $_limiteResultados • Encontrados: ${widget.resultados.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_mostrarBotonBuscar && !_ubicando && !_modoEnfoque)
              Positioned(
                top: 44,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  color: _azul,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _buscando ? null : _buscarEnZona,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_buscando)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Icon(Icons.search, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _buscando ? 'Buscando…' : 'Buscar en esta zona',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ],
            );
          },
        ),
      ),
    );
  }
}
