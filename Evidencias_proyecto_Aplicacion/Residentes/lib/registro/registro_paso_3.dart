import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../widgets/custom_widgets.dart';
import 'registro_models.dart';

class RegistroPaso3 extends StatefulWidget {
  final RegistroResidenteBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso3({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<RegistroPaso3> createState() => _RegistroPaso3State();
}

class _RegistroPaso3State extends State<RegistroPaso3> {
  static const double _latIni = -33.4489;
  static const double _lonIni = -70.6693;

  final _calleController = TextEditingController();
  final _nroController = TextEditingController();
  final _unidadController = TextEditingController();
  final _latManualController = TextEditingController();
  final _lonManualController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _cameraTarget = const LatLng(_latIni, _lonIni);
  double? _pinLat;
  double? _pinLon;
  final Set<Marker> _markers = {};

  /// Con mapa: oculto por defecto. Sin mapa: abierto para poder ingresar coordenadas.
  bool _coordsManualAbiertas = false;

  bool _mapaGoogleDisponible() {
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
  void initState() {
    super.initState();
    final d = widget.draft;
    final lat0 = d.lat ?? _latIni;
    final lon0 = d.lon ?? _lonIni;
    _latManualController.text = lat0.toStringAsFixed(6);
    _lonManualController.text = lon0.toStringAsFixed(6);
    if (d.calle != null && d.calle!.trim().isNotEmpty) {
      _calleController.text = d.calle!.trim();
    }
    if (d.nroDireccion != null) _nroController.text = '${d.nroDireccion}';
    if (d.unidad != null && d.unidad!.trim().isNotEmpty) {
      _unidadController.text = d.unidad!.trim();
    }
    _cameraTarget = LatLng(lat0, lon0);
    _pinLat = lat0;
    _pinLon = lon0;

    if (_mapaGoogleDisponible()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _actualizarMarcador(lat0, lon0);
        });
      });
    } else {
      _coordsManualAbiertas = true;
    }
  }

  void _actualizarMarcador(double lat, double lon) {
    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('residencia'),
          position: LatLng(lat, lon),
          draggable: true,
          onDragEnd: (p) {
            setState(() {
              _pinLat = p.latitude;
              _pinLon = p.longitude;
              _latManualController.text = p.latitude.toStringAsFixed(6);
              _lonManualController.text = p.longitude.toStringAsFixed(6);
            });
          },
        ),
      );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _calleController.dispose();
    _nroController.dispose();
    _unidadController.dispose();
    _latManualController.dispose();
    _lonManualController.dispose();
    super.dispose();
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _onMapTap(LatLng p) {
    setState(() {
      _pinLat = p.latitude;
      _pinLon = p.longitude;
      _latManualController.text = p.latitude.toStringAsFixed(6);
      _lonManualController.text = p.longitude.toStringAsFixed(6);
      _actualizarMarcador(p.latitude, p.longitude);
    });
  }

  void _sincronizarManualALatLon() {
    final lat = double.tryParse(_latManualController.text.trim().replaceAll(',', '.'));
    final lon = double.tryParse(_lonManualController.text.trim().replaceAll(',', '.'));
    if (lat != null && lon != null && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180) {
      setState(() {
        _pinLat = lat;
        _pinLon = lon;
        _cameraTarget = LatLng(lat, lon);
        _actualizarMarcador(lat, lon);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), 16));
      });
    }
  }

  void _continuar() {
    final calle = _calleController.text.trim();
    if (calle.isEmpty) {
      _showSnack('Ingresa el nombre de la calle.');
      return;
    }
    final nro = int.tryParse(_nroController.text.trim());
    if (nro == null || nro <= 0) {
      _showSnack('Ingresa un número de dirección válido.');
      return;
    }

    double? lat = double.tryParse(_latManualController.text.trim().replaceAll(',', '.'));
    double? lon = double.tryParse(_lonManualController.text.trim().replaceAll(',', '.'));
    final camposValidos =
        lat != null &&
        lon != null &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
    if (!camposValidos) {
      lat = _pinLat;
      lon = _pinLon;
    }
    if (lat == null || lon == null) {
      _showSnack('Ingresa latitud y longitud válidas o marca un punto en el mapa.');
      return;
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      _showSnack('Coordenadas fuera de rango.');
      return;
    }

    final d = widget.draft;
    d.calle = calle;
    d.nroDireccion = nro;
    d.unidad = _unidadController.text.trim().isEmpty ? null : _unidadController.text.trim();
    d.lat = lat;
    d.lon = lon;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final azulMarco = Colors.blue.shade400;
    final botonCoordStyle = OutlinedButton.styleFrom(
      foregroundColor: azulMarco,
      side: BorderSide(color: azulMarco),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Ubicación de la Residencia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Proporciona los datos básicos de tu vivienda y contactos de emergencia",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final camposEnFila = c.maxWidth >= 400;
            final campoCalle = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InputLabel(label: "Calle", required: true),
                TextField(
                  controller: _calleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Ej: Av. Libertador Bernardo O'Higgins",
                  ),
                ),
              ],
            );
            final campoNumero = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InputLabel(label: "Número", required: true),
                TextField(
                  controller: _nroController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: "1234"),
                ),
              ],
            );
            if (camposEnFila) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: campoCalle),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: campoNumero),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                campoCalle,
                const SizedBox(height: 8),
                campoNumero,
              ],
            );
          },
        ),
        const InputLabel(label: "Casa interior (opcional)"),
        TextField(
          controller: _unidadController,
          decoration: const InputDecoration(hintText: "Depto, torre, etc. (opcional)"),
        ),
        const SizedBox(height: 16),
        const Text(
          "Ubicación en el mapa",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (_mapaGoogleDisponible())
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _cameraTarget, zoom: 15),
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                onMapCreated: (c) {
                  _mapController = c;
                },
                onTap: _onMapTap,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'En esta plataforma no hay mapa de Google integrado. Usa “Ingresar coordenadas manualmente” abajo.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.home_outlined, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _pinLat != null && _pinLon != null
                    ? 'Coordenadas: ${_pinLat!.toStringAsFixed(1)}°, ${_pinLon!.toStringAsFixed(1)}°'
                    : 'Coordenadas: —',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta vista previa ayuda a los bomberos a localizar rápidamente tu domicilio en caso de emergencia.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Si tienes problemas con ubicar tu residencia, tu mismo ingresa su coordenada',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: botonCoordStyle,
            onPressed: () => setState(() => _coordsManualAbiertas = !_coordsManualAbiertas),
            child: Text(_coordsManualAbiertas ? 'Ocultar coordenadas' : 'Ingresar coordenadas'),
          ),
        ),
        if (_coordsManualAbiertas) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresar coordenadas manualmente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                const InputLabel(label: "Latitud", required: true),
                TextField(
                  controller: _latManualController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _sincronizarManualALatLon(),
                  decoration: const InputDecoration(
                    hintText: 'Ejemplo: -33.4489 (coordenada Y)',
                  ),
                ),
                const SizedBox(height: 8),
                const InputLabel(label: "Longitud", required: true),
                TextField(
                  controller: _lonManualController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _sincronizarManualALatLon(),
                  decoration: const InputDecoration(
                    hintText: 'Ejemplo: -70.6693 (coordenada X)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Puedes obtener las coordenadas desde Google Maps: haz clic derecho en tu ubicación y selecciona las coordenadas que aparecen.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text("Anterior"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continuar,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
