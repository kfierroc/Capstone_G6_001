import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/centro_distribucion.dart';
import '../models/grifo_mapa.dart';
import '../services/mapa_grifo_service.dart';
import '../services/places_distribucion_service.dart';
import '../utils/geo_utils.dart';
import '../utils/grifo_estado_utils.dart';
import '../widgets/custom_widgets.dart';

/// Vista estática del domicilio: carga grifos y centros una sola vez (radio 1 km).
/// El usuario puede mover el mapa, pero no se vuelve a consultar.
class MapaDetalleResidenciaScreen extends StatefulWidget {
  const MapaDetalleResidenciaScreen({
    super.key,
    required this.lat,
    required this.lon,
    required this.direccion,
    this.idRegistro,
  });

  final double lat;
  final double lon;
  final String direccion;
  final int? idRegistro;

  @override
  State<MapaDetalleResidenciaScreen> createState() => _MapaDetalleResidenciaScreenState();
}

class _MapaDetalleResidenciaScreenState extends State<MapaDetalleResidenciaScreen> {
  static const _rojo = Color(0xFFC62828);
  static const _azul = Color(0xFF1565C0);
  static const _naranja = Color(0xFFE65100);
  static const _radioMaxMetros = 1000;
  late final MapaGrifoService _grifoSvc;
  final PlacesDistribucionService _placesSvc = PlacesDistribucionService();

  GoogleMapController? _mapController;
  bool _mapaCreado = false;
  bool _datosCargados = false;
  bool _encuadreAplicado = false;

  List<GrifoMapaResultado> _grifos = [];
  List<CentroDistribucion> _centros = [];
  Set<Marker> _markers = {};
  bool _cargando = true;
  String? _errorGrifos;
  String? _errorCentros;

  LatLng get _posicionResidencia => LatLng(widget.lat, widget.lon);

  @override
  void initState() {
    super.initState();
    _grifoSvc = MapaGrifoService(Supabase.instance.client);
    _cargarDatos();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (_datosCargados) return;

    setState(() {
      _cargando = true;
      _errorGrifos = null;
      _errorCentros = null;
    });

    List<GrifoMapaResultado> grifos = [];
    List<CentroDistribucion> centros = [];
    String? errGrifos;
    String? errCentros;

    try {
      grifos = await _grifoSvc.grifosOperativosCercanos(
        lat: widget.lat,
        lon: widget.lon,
        radioMetros: _radioMaxMetros,
        limite: 3,
      );
    } on MapaGrifoException catch (e) {
      errGrifos = e.message;
    } catch (e) {
      errGrifos = '$e';
    }

    try {
      centros = await _placesSvc.buscarCercanos(
        lat: widget.lat,
        lon: widget.lon,
        radioMetros: _radioMaxMetros,
      );
    } on PlacesDistribucionException catch (e) {
      errCentros = e.message;
    } catch (e) {
      errCentros = '$e';
    }

    if (!mounted) return;
    setState(() {
      _grifos = grifos;
      _centros = centros;
      _errorGrifos = errGrifos;
      _errorCentros = errCentros;
      _markers = _construirMarcadores();
      _cargando = false;
      _datosCargados = true;
    });

    _intentarEncuadrarUnaVez();
  }

  void _intentarEncuadrarUnaVez() {
    if (!_mapaCreado || !_datosCargados || _encuadreAplicado) return;
    _encuadreAplicado = true;
    _encuadrarCamaraInicial();
  }

  Set<Marker> _construirMarcadores() {
    final s = <Marker>{
      Marker(
        markerId: const MarkerId('residencia'),
        position: _posicionResidencia,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Domicilio',
          snippet: widget.direccion,
        ),
        zIndexInt: 3,
      ),
    };

    for (final g in _grifos) {
      s.add(
        Marker(
          markerId: MarkerId('grifo_${g.idGrifo}'),
          position: LatLng(g.lat, g.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Grifo #${g.idGrifo}',
            snippet: '${g.estado} • ${GeoUtils.distanciaMetros(widget.lat, widget.lon, g.lat, g.lon).round()} m',
          ),
          zIndexInt: 2,
        ),
      );
    }

    for (final c in _centros) {
      s.add(
        Marker(
          markerId: MarkerId('centro_${c.placeId}'),
          position: LatLng(c.lat, c.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: c.nombre,
            snippet: '${c.categoriasTexto} • ${c.distanciaTexto}',
          ),
          zIndexInt: 1,
        ),
      );
    }
    return s;
  }

  Set<Circle> get _circuloCercania => {
        Circle(
          circleId: const CircleId('radio_1km'),
          center: _posicionResidencia,
          radius: _radioMaxMetros.toDouble(),
          fillColor: const Color(0x221565C0),
          strokeColor: _azul,
          strokeWidth: 2,
        ),
      };

  /// Centra la cámara en el domicilio mostrando el radio de 1 km (solo al cargar).
  Future<void> _encuadrarCamaraInicial() async {
    final c = _mapController;
    if (c == null || !mounted) return;
    try {
      final box = GeoUtils.boundingBox(widget.lat, widget.lon, _radioMaxMetros.toDouble());
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(box.minLat, box.minLon),
            northeast: LatLng(box.maxLat, box.maxLon),
          ),
          48,
        ),
      );
    } catch (_) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(_posicionResidencia, 15));
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F2),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Mapa del Domicilio',
            subtitle: widget.direccion,
            leadingIcon: Icons.home_outlined,
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _rojo))
                : AppWidthContainer(
                    includeVerticalPadding: true,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _avisoDatosEstaticos(),
                          const SizedBox(height: 10),
                          _buildMapa(),
                          const SizedBox(height: 12),
                          _leyenda(),
                          const SizedBox(height: 16),
                          _seccionGrifos(),
                          const SizedBox(height: 16),
                          _seccionCentros(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
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
        ),
        child: const Text('Mapa disponible en Android, iOS y Web.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: alturaMapa,
        child: GoogleMap(
          key: ValueKey('mapa_detalle_${widget.idRegistro ?? widget.lat}'),
          initialCameraPosition: CameraPosition(target: _posicionResidencia, zoom: 17),
          markers: _markers,
          circles: _circuloCercania,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          onMapCreated: (controller) {
            _mapController = controller;
            _mapaCreado = true;
            _intentarEncuadrarUnaVez();
          },
        ),
      ),
    );
  }

  Widget _avisoDatosEstaticos() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Puntos cercanos al domicilio (radio máximo 1 km). '
              'Los datos se cargan una sola vez; puedes mover el mapa libremente.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyenda() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _itemLeyenda(_rojo, 'Domicilio'),
        _itemLeyenda(GrifoEstadoUtils.verde, 'Grifo operativo'),
        _itemLeyenda(_naranja, 'Centro distribución'),
        _itemLeyenda(_azul, 'Radio 1 km'),
      ],
    );
  }

  Widget _itemLeyenda(Color color, String texto) {
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

  Widget _seccionGrifos() {
    return _tarjetaSeccion(
      icon: Icons.water_drop_outlined,
      color: _azul,
      titulo: 'Grifos operativos cercanos',
      subtitulo: 'Hasta 3 más próximos · radio 1 km',
      child: _errorGrifos != null
          ? Text(_errorGrifos!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))
          : _grifos.isEmpty
              ? Text(
                  'No hay grifos operativos cercanos dentro de 1 km.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                )
              : Column(
                  children: _grifos.map(_filaGrifo).toList(),
                ),
    );
  }

  Widget _seccionCentros() {
    return _tarjetaSeccion(
      icon: Icons.local_gas_station_outlined,
      color: _naranja,
      titulo: 'Centros de distribución',
      subtitulo: 'Gas, combustible y parafina · radio 1 km',
      child: _errorCentros != null
          ? Text(_errorCentros!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))
          : _centros.isEmpty
              ? Text(
                  'No hay centros de distribución de gas, combustible o parafina cercanos dentro de 1 km.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
                )
              : Column(
                  children: _centros.map(_filaCentro).toList(),
                ),
    );
  }

  Widget _tarjetaSeccion({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(subtitulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _filaGrifo(GrifoMapaResultado g) {
    final dist = GeoUtils.distanciaMetros(widget.lat, widget.lon, g.lat, g.lon);
    final distTxt = dist >= 1000 ? '${(dist / 1000).toStringAsFixed(1)} km' : '${dist.round()} m';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrifoEstadoUtils.verde.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GrifoEstadoUtils.verde.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: GrifoEstadoUtils.verde, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grifo #${g.idGrifo}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Operativo • $distTxt', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                if (g.notas != null && g.notas!.isNotEmpty)
                  Text(g.notas!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaCentro(CentroDistribucion c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _naranja.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _naranja.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_gas_station, color: _naranja, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${c.categoriasTexto} • ${c.distanciaTexto}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (c.direccion != null) ...[
                  const SizedBox(height: 4),
                  Text(c.direccion!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
