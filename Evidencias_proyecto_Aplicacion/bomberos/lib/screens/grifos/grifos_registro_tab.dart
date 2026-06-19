import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../services/geocode_service.dart';
import '../../services/grifo_registro_service.dart';
import '../../services/mapa_grifo_service.dart';
import '../../utils/geo_utils.dart';
import '../../utils/grifo_estado_utils.dart';
import '../../widgets/custom_widgets.dart';

class GrifosRegistroTab extends StatefulWidget {
  const GrifosRegistroTab({super.key, this.perfil});

  final BomberoPerfil? perfil;

  @override
  State<GrifosRegistroTab> createState() => _GrifosRegistroTabState();
}

class _GrifosRegistroTabState extends State<GrifosRegistroTab> {
  static const _azul = Color(0xFF1565C0);
  static const _latSantiago = -33.4489;
  static const _lonSantiago = -70.6693;
  late final MapaGrifoService _mapaSvc;
  late final GrifoRegistroService _registroSvc;
  final GeocodeService _geocode = GeocodeService();
  final _busquedaMapaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _centroCamara = const LatLng(_latSantiago, _lonSantiago);
  LatLng? _puntoSeleccionado;
  double _zoomActual = 14;

  List<EstadoGrifoOpcion> _estados = [];
  int? _idEstadoSeleccionado;
  Set<Marker> _markersExistentes = {};
  Marker? _markerSeleccion;

  bool _mapaListo = false;
  bool _ubicando = true;
  bool _buscandoDireccion = false;
  bool _guardando = false;
  bool _cargandoContexto = false;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _mapaSvc = MapaGrifoService(client);
    _registroSvc = GrifoRegistroService(client);
    _puntoSeleccionado = _centroCamara;
    _cargarEstados();
    _centrarEnUsuario();
  }

  @override
  void dispose() {
    _busquedaMapaCtrl.dispose();
    _notasCtrl.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _cargarEstados() async {
    try {
      final list = await _mapaSvc.listarEstados();
      if (!mounted) return;
      int? defecto;
      for (final e in list) {
        if (e.nombre.toLowerCase().contains('desconocido')) {
          defecto = e.id;
          break;
        }
      }
      setState(() {
        _estados = list;
        _idEstadoSeleccionado = defecto ?? (list.isNotEmpty ? list.first.id : null);
      });
    } catch (_) {}
  }

  Future<void> _centrarEnUsuario() async {
    if (mounted) setState(() => _ubicando = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        _fijarCentro(const LatLng(_latSantiago, _lonSantiago), 14);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _fijarCentro(latLng, 16);
      _seleccionarPunto(latLng);
    } catch (_) {
      _fijarCentro(const LatLng(_latSantiago, _lonSantiago), 14);
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  void _fijarCentro(LatLng target, double zoom) {
    _centroCamara = target;
    _zoomActual = zoom;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
    _cargarGrifosCercanos(target);
  }

  Future<void> _cargarGrifosCercanos(LatLng centro) async {
    if (mounted) setState(() => _cargandoContexto = true);
    try {
      final box = GeoUtils.boundingBox(centro.latitude, centro.longitude, 2500);
      final lista = await _mapaSvc.grifosEnBoundingBox(
        minLat: box.minLat,
        maxLat: box.maxLat,
        minLon: box.minLon,
        maxLon: box.maxLon,
      );
      if (!mounted) return;
      setState(() {
        _markersExistentes = lista
            .map(
              (g) => Marker(
                markerId: MarkerId('ctx_${g.idGrifo}'),
                position: LatLng(g.lat, g.lon),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  GrifoEstadoUtils.huePorEstado(g.estado),
                ),
              ),
            )
            .toSet();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoContexto = false);
    }
  }

  void _seleccionarPunto(LatLng p) {
    setState(() {
      _puntoSeleccionado = p;
      _markerSeleccion = Marker(
        markerId: const MarkerId('nuevo_grifo'),
        position: p,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  Set<Marker> get _todosLosMarkers {
    final s = Set<Marker>.from(_markersExistentes);
    if (_markerSeleccion != null) s.add(_markerSeleccion!);
    return s;
  }

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

  Future<void> _buscarEnMapa() async {
    final q = _busquedaMapaCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() => _buscandoDireccion = true);
    try {
      final latLng = await _geocode.buscarDireccion(q);
      if (!mounted) return;
      if (latLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró esa dirección.')),
        );
        return;
      }
      _centroCamara = latLng;
      _zoomActual = 17;
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
      _cargarGrifosCercanos(latLng);
    } on GeocodeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _buscandoDireccion = false);
    }
  }

  void _limpiarFormulario() {
    _notasCtrl.clear();
    _busquedaMapaCtrl.clear();
    final centro = const LatLng(_latSantiago, _lonSantiago);
    setState(() {
      _puntoSeleccionado = centro;
      _markerSeleccion = Marker(
        markerId: const MarkerId('nuevo_grifo'),
        position: centro,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(centro, 14));
  }

  Future<void> _registrar() async {
    final perfil = widget.perfil;
    if (perfil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para registrar un grifo.')),
      );
      return;
    }
    final punto = _puntoSeleccionado;
    final idEstado = _idEstadoSeleccionado;
    if (punto == null || idEstado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un punto en el mapa y un estado.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final id = await _registroSvc.registrar(
        lat: punto.latitude,
        lon: punto.longitude,
        idEstadoGr: idEstado,
        rutNumBombero: perfil.rutNum,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grifo #$id registrado correctamente.')),
      );
      _limpiarFormulario();
      _cargarGrifosCercanos(punto);
    } on GrifoRegistroException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String get _fechaHoy {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}-${n.month.toString().padLeft(2, '0')}-${n.year}';
  }

  String get _coordsTexto {
    final p = _puntoSeleccionado;
    if (p == null) return '—';
    return '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: AppWidthContainer(
        child: Container(
          padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: _azul, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Nuevo Grifo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Añade un nuevo punto de agua al sistema',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const InputLabel(label: 'Seleccionar ubicación en el mapa', required: true),
            _buildMapaRegistro(),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.red.shade700),
                const SizedBox(width: 4),
                Text(
                  'Seleccionado: $_coordsTexto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Haz clic en el mapa para fijar las coordenadas del grifo. '
              'La barra de búsqueda solo te ayuda a moverte por el mapa.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.35),
            ),
            const InputLabel(label: 'Estado actual', required: true),
            DropdownButtonFormField<int>(
              key: ValueKey(_idEstadoSeleccionado),
              initialValue: _idEstadoSeleccionado,
              isExpanded: true,
              decoration: _inputDeco(),
              items: _estados
                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _idEstadoSeleccionado = v),
            ),
            const InputLabel(label: 'Última inspección'),
            TextFormField(
              readOnly: true,
              initialValue: _fechaHoy,
              decoration: _inputDeco(fill: const Color(0xFFF1F4F8)),
            ),
            Text(
              'Automáticamente asignado a la fecha actual.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const InputLabel(label: 'Reportado por'),
            TextFormField(
              readOnly: true,
              initialValue: widget.perfil?.nombreCompleto ?? '—',
              decoration: _inputDeco(fill: const Color(0xFFF1F4F8)),
            ),
            Text(
              'Automáticamente asignado a tu usuario.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const InputLabel(label: 'Notas adicionales'),
            TextFormField(
              controller: _notasCtrl,
              maxLines: 4,
              decoration: _inputDeco().copyWith(
                hintText: 'Información relevante sobre el grifo, acceso, condiciones especiales, etc.',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _limpiarFormulario,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Limpiar Formulario'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _guardando ? null : _registrar,
                    style: FilledButton.styleFrom(
                      backgroundColor: _azul,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Registrar Grifo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({Color? fill}) {
    return InputDecoration(
      filled: true,
      fillColor: fill ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildMapaRegistro() {
    final alturaMapa = AppLayout.mapHeight(MediaQuery.sizeOf(context).width, scale: 0.92);

    if (!_mapaDisponible()) {
      return Container(
        height: alturaMapa,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Mapa disponible en Android, iOS y Web.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: alturaMapa,
        child: Stack(
          children: [
            GoogleMap(
              key: const ValueKey('mapa_grifo_registro'),
              initialCameraPosition: CameraPosition(target: _centroCamara, zoom: _zoomActual),
              markers: _todosLosMarkers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              onMapCreated: (c) {
                _mapController = c;
                _mapaListo = true;
                final p = _puntoSeleccionado;
                if (p != null) _seleccionarPunto(p);
              },
              onTap: _seleccionarPunto,
              onCameraIdle: () {
                if (_mapaListo) _cargarGrifosCercanos(_centroCamara);
              },
              onCameraMove: (pos) => _centroCamara = pos.target,
            ),
            if (_ubicando || _cargandoContexto)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black12,
                  child: Center(child: CircularProgressIndicator(color: _azul)),
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(Icons.place, color: _azul, size: 22),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _busquedaMapaCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Buscar dirección para mover el mapa…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscarEnMapa(),
                      ),
                    ),
                    IconButton(
                      icon: _buscandoDireccion
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _azul),
                            )
                          : const Icon(Icons.search, color: _azul),
                      onPressed: _buscandoDireccion ? null : _buscarEnMapa,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 58,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(_coordsTexto, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    _leyenda(GrifoEstadoUtils.verde, 'Operativo'),
                    _leyenda(GrifoEstadoUtils.rojo, 'Dañado'),
                    _leyenda(_azul, 'Nuevo grifo'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
