import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mapa_busqueda_opciones.dart';
import '../models/residencia_mapa.dart';
import '../services/mapa_residencia_service.dart';
import '../services/mapa_residencias_cache.dart';
import '../utils/geo_utils.dart';
import '../models/bombero_perfil.dart';
import '../widgets/custom_widgets.dart';
import 'detalle_residencia_screen.dart';

/// Mapa con radio geográfico configurable y búsqueda manual por zona.
class MapaResidenciasScreen extends StatefulWidget {
  const MapaResidenciasScreen({super.key, this.perfil});

  final BomberoPerfil? perfil;

  @override
  State<MapaResidenciasScreen> createState() => _MapaResidenciasScreenState();
}

class _MapaResidenciasScreenState extends State<MapaResidenciasScreen> {
  static const _rojo = Color(0xFFC62828);
  static const _fondo = Color(0xFFF4F4F2);
  static const _latSantiago = -33.4489;
  static const _lonSantiago = -70.6693;
  static const _alturaMapa = 368.0;

  final MapaResidenciasCache _cache = MapaResidenciasCache();
  late final MapaResidenciaService _mapaSvc;

  GoogleMapController? _mapController;

  /// Centro de la cámara (y del círculo de búsqueda).
  LatLng _centroCamara = const LatLng(_latSantiago, _lonSantiago);
  double _zoomActual = 14;

  int _radioMetros = MapaBusquedaOpciones.radioPorDefectoMetros;
  int _limiteResultados = MapaBusquedaOpciones.limitePorDefecto;

  Set<Marker> _markers = {};
  List<ResidenciaMapaResultado> _resultados = [];

  bool _mapaListo = false;
  bool _ubicando = true;
  bool _buscando = false;
  bool _mostrarBotonBuscar = true;

  LatLng? _centroPendiente;

  @override
  void initState() {
    super.initState();
    _mapaSvc = MapaResidenciaService(Supabase.instance.client);
    _centrarEnUsuario();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  Set<Circle> get _circuloBusqueda => {
        Circle(
          circleId: const CircleId('radio_busqueda'),
          center: _centroCamara,
          radius: _radioMetros.toDouble(),
          fillColor: const Color(0x33C62828),
          strokeColor: _rojo,
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
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        _fijarCentro(const LatLng(_latSantiago, _lonSantiago), 13);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _fijarCentro(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {
      _fijarCentro(const LatLng(_latSantiago, _lonSantiago), 13);
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
    if (!mounted) return;
    final c = _mapController;
    if (c == null || !_mapaListo) return;
    try {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_centroCamara, zoom));
    } catch (e) {
      debugPrint('No se pudo mover la cámara: $e');
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
      debugPrint('No se pudo encuadrar el radio: $e');
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
  }

  void _onCameraIdle() {
    if (!_mapaListo || _buscando || !mounted) return;
    _requiereNuevaBusqueda();
  }

  void _onRadioSeleccionado(int metros) {
    if (_radioMetros == metros) return;
    setState(() => _radioMetros = metros);
    _requiereNuevaBusqueda();
    _encuadrarRadio();
  }

  void _onLimiteSeleccionado(int limite) {
    if (_limiteResultados == limite) return;
    setState(() => _limiteResultados = limite);
    _requiereNuevaBusqueda();
  }

  Future<void> _buscarEnZona() async {
    if (_mapController == null || !_mapaListo) return;

    setState(() => _buscando = true);
    try {
      final centro = _centroCamara;

      if (_cache.esBusquedaRedundante(centro, _radioMetros, _limiteResultados)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta zona ya fue consultada con el mismo radio y límite. '
                'Mueve el mapa al menos 200 m o cambia las opciones.',
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

      final lista = await _mapaSvc.buscarEnArea(
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
              'No hay residencias activas dentro de ${MapaBusquedaOpciones.etiquetaRadio(_radioMetros)}.',
            ),
          ),
        );
      }
    } on MapaResidenciaException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
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

  void _aplicarResultados(List<ResidenciaMapaResultado> lista) {
    if (!mounted) return;
    setState(() {
      _resultados = lista;
      _markers = lista
          .map(
            (r) => Marker(
              markerId: MarkerId('res_${r.idResidencia}'),
              position: LatLng(r.lat, r.lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: r.direccionCompleta,
                snippet: '${r.cantidadPersonas} personas • ${r.cantidadMascotas} mascotas',
              ),
            ),
          )
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Mapa de Residencias Registradas',
            subtitle: 'Radio fijo en metros • búsqueda manual',
            showBack: true,
            leadingIcon: Icons.location_on_outlined,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _panelMapaYOpciones(),
                ),
                Expanded(child: _listaResidencias()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelMapaYOpciones() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Área de búsqueda',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'El círculo rojo muestra el radio real en metros. Mueve el mapa y pulsa buscar.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropdown(
                  titulo: 'Radio de búsqueda',
                  valor: _radioMetros,
                  opciones: MapaBusquedaOpciones.radiosMetros,
                  etiqueta: MapaBusquedaOpciones.etiquetaRadio,
                  onChanged: _onRadioSeleccionado,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  titulo: 'Máx. resultados',
                  valor: _limiteResultados,
                  opciones: MapaBusquedaOpciones.limitesResultados,
                  etiqueta: (v) => '$v',
                  onChanged: _onLimiteSeleccionado,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMapa(),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String titulo,
    required int valor,
    required List<int> opciones,
    required String Function(int) etiqueta,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          key: ValueKey('$titulo-$valor'),
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F4F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: opciones
              .map((v) => DropdownMenuItem(value: v, child: Text(etiqueta(v), style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  void _abrirDetalle(int idRegistro) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetalleResidenciaScreen(idRegistro: idRegistro, perfil: widget.perfil),
      ),
    );
  }

  Widget _listaResidencias() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dentro del radio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_resultados.length} / $_limiteResultados',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buscando
                ? const Center(child: CircularProgressIndicator(color: _rojo))
                : _resultados.isEmpty
                    ? Center(
                        child: Text(
                          _mostrarBotonBuscar
                              ? 'Pulsa «Buscar en esta zona» para ver residencias dentro del círculo.'
                              : 'Sin residencias activas en este radio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (_, i) => _tarjetaResidencia(_resultados[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    if (!_mapaDisponible()) {
      return Container(
        height: _alturaMapa,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text('El mapa está disponible en Android, iOS y Web.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: _alturaMapa,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GoogleMap(
              key: const ValueKey('mapa_residencias_google'),
              initialCameraPosition: CameraPosition(target: _centroCamara, zoom: _zoomActual),
              circles: _circuloBusqueda,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
            ),
            if (_ubicando)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            IgnorePointer(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _rojo,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                  'Máx. $_limiteResultados • Encontradas: ${_resultados.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_mostrarBotonBuscar && !_ubicando)
              Positioned(
                top: 44,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(24),
                    color: _rojo,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResidencia(ResidenciaMapaResultado r) {
    final dist = GeoUtils.distanciaMetros(_centroCamara.latitude, _centroCamara.longitude, r.lat, r.lon);
    final distTexto = dist >= 1000 ? '${(dist / 1000).toStringAsFixed(1)} km' : '${dist.round()} m';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.direccionCompleta,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dentro del radio • $distTexto del centro',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _abrirDetalle(r.idRegistro),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Ver Detalles', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _chipInfo(Icons.people_outline, '${r.cantidadPersonas} personas'),
              _chipInfo(Icons.pets_outlined, '${r.cantidadMascotas} mascotas'),
              _chipInfo(Icons.home_outlined, r.tipoVivienda),
              if (r.cantidadMaterialesPeligrosos > 0)
                _chipInfo(
                  Icons.local_fire_department_outlined,
                  '${r.cantidadMaterialesPeligrosos} materiales peligrosos',
                  color: _rojo,
                ),
            ],
          ),
          if (r.alertasMedicas.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...r.alertasMedicas.take(3).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      a,
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _chipInfo(IconData icon, String texto, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade800)),
      ],
    );
  }
}
