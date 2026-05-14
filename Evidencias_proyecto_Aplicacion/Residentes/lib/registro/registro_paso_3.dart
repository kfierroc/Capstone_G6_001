import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/google_places_models.dart';
import '../services/google_places_service.dart';
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

  final GooglePlacesService _places = GooglePlacesService();

  final _busquedaController = TextEditingController();
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

  Timer? _debounceBusqueda;
  List<PlaceAutocompletePrediction> _predicciones = [];
  bool _cargandoPredicciones = false;

  /// Si es false: solo búsqueda Google + calle/número de solo lectura (relleno desde Places).
  /// Si es true: campos calle/número editables sin autocompletado obligatorio.
  bool _direccionManual = false;

  /// En modo Google: true solo si Place Details devolvió `route` + número válidos.
  bool _googleFormatoValido = false;

  /// Sin mapa: coordenadas por texto. Con mapa: solo pin (no se muestra este bloque).
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

    final hayCalleNro = _calleController.text.isNotEmpty && _nroController.text.isNotEmpty;
    if (hayCalleNro) {
      _googleFormatoValido = true;
    }

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
              _syncCoordsControllersDesdePin();
            });
          },
        ),
      );
  }

  void _syncCoordsControllersDesdePin() {
    if (_pinLat != null && _pinLon != null) {
      _latManualController.text = _pinLat!.toStringAsFixed(6);
      _lonManualController.text = _pinLon!.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _debounceBusqueda?.cancel();
    _mapController?.dispose();
    _busquedaController.dispose();
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

  void _onBusquedaChanged(String value) {
    _debounceBusqueda?.cancel();
    if (_direccionManual) return;
    if (value.trim().length < 3) {
      setState(() => _predicciones = []);
      return;
    }
    _debounceBusqueda = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _cargandoPredicciones = true);
      try {
        final list = await _places.autocomplete(value.trim());
        if (!mounted) return;
        setState(() {
          _predicciones = list;
          _cargandoPredicciones = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _predicciones = [];
          _cargandoPredicciones = false;
        });
      }
    });
  }

  Future<void> _seleccionarPrediccion(PlaceAutocompletePrediction pred) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _predicciones = [];
      _cargandoPredicciones = true;
    });
    try {
      final det = await _places.placeDetails(pred.placeId);
      if (!mounted) return;
      setState(() {
        _busquedaController.text = pred.description;
        _pinLat = det.lat;
        _pinLon = det.lng;
        _cameraTarget = LatLng(det.lat, det.lng);
        _actualizarMarcador(det.lat, det.lng);
        _syncCoordsControllersDesdePin();

        if (det.tieneFormatoCalleNumero && det.calle != null && det.nroDireccion != null) {
          _calleController.text = det.calle!;
          _nroController.text = '${det.nroDireccion}';
          _googleFormatoValido = true;
        } else {
          _calleController.clear();
          _nroController.clear();
          _googleFormatoValido = false;
          _showSnack(
            'Google no devolvió calle y número en el formato requerido. '
            'Prueba otra sugerencia o marca “ingresar dirección manualmente”.',
          );
        }
        _cargandoPredicciones = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(det.lat, det.lng), 17),
      );
    } on GooglePlacesException catch (e) {
      if (!mounted) return;
      setState(() => _cargandoPredicciones = false);
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoPredicciones = false);
      _showSnack('No se pudo cargar el detalle del lugar.');
    }
  }

  void _onMapTap(LatLng p) {
    setState(() {
      _pinLat = p.latitude;
      _pinLon = p.longitude;
      _syncCoordsControllersDesdePin();
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

  bool _coordsPinValidas(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  void _continuar() {
    final calle = _calleController.text.trim();
    final nro = int.tryParse(_nroController.text.trim());

    if (!_direccionManual) {
      if (!_googleFormatoValido || calle.isEmpty || nro == null || nro <= 0) {
        _showSnack(
          'Selecciona una dirección en las sugerencias de Google que incluya calle y número. '
          'Si no aparece, usa la opción de ingreso manual.',
        );
        return;
      }
    } else {
      if (calle.isEmpty) {
        _showSnack('Ingresa el nombre de la calle.');
        return;
      }
      if (nro == null || nro <= 0) {
        _showSnack('Ingresa un número de dirección válido.');
        return;
      }
    }

    if (calle.length > 150) {
      _showSnack('La calle admite como máximo 150 caracteres.');
      return;
    }

    double? lat = _pinLat;
    double? lon = _pinLon;
    if (!_mapaGoogleDisponible()) {
      lat = double.tryParse(_latManualController.text.trim().replaceAll(',', '.'));
      lon = double.tryParse(_lonManualController.text.trim().replaceAll(',', '.'));
    }

    if (!_coordsPinValidas(lat, lon)) {
      _showSnack('Marca la ubicación real en el mapa (pin) o ingresa coordenadas válidas.');
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

  double _alturaMapa(BuildContext context, double anchoLayout) {
    final h = MediaQuery.sizeOf(context).height;
    if (!_mapaGoogleDisponible()) return 240;
    if (kIsWeb) {
      if (anchoLayout >= 920) return (h * 0.52).clamp(380.0, 720.0);
      if (anchoLayout >= 600) return (h * 0.40).clamp(280.0, 520.0);
      return (h * 0.34).clamp(240.0, 460.0);
    }
    if (anchoLayout >= 600) return 300;
    return 260;
  }

  Widget _buildBuscadorGoogle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InputLabel(label: 'Buscar dirección (Google Maps)', required: true),
        TextField(
          controller: _busquedaController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Escribe calle y ciudad…',
            suffixIcon: _cargandoPredicciones
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          onChanged: _onBusquedaChanged,
        ),
        if (_predicciones.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height >= 700 ? 260 : 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _predicciones.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, i) {
                final p = _predicciones[i];
                return ListTile(
                  dense: true,
                  title: Text(p.description, style: const TextStyle(fontSize: 14)),
                  onTap: () => _seleccionarPrediccion(p),
                );
              },
            ),
          ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildVistaPreviaSoloLectura() {
    final calle = _calleController.text.trim();
    final nro = _nroController.text.trim();
    final tiene = calle.isNotEmpty && nro.isNotEmpty;
    final subtle = TextStyle(color: Colors.grey.shade700, fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Vista previa de la dirección',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Solo lectura',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'No editable: se rellena únicamente al elegir una sugerencia del buscador.',
          style: subtle,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: tiene
              ? LayoutBuilder(
                  builder: (context, c) {
                    final fila = c.maxWidth >= 420;
                    final calleCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calle', style: subtle.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(calle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    );
                    final nroCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Número', style: subtle.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(nro, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    );
                    if (fila) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: calleCol),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: nroCol),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        calleCol,
                        const SizedBox(height: 14),
                        nroCol,
                      ],
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Selecciona una dirección en las sugerencias del buscador para ver aquí calle y número.',
                    style: subtle.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCamposManualDireccion() {
    return LayoutBuilder(
      builder: (context, c) {
        final camposEnFila = c.maxWidth >= 400;
        final campoCalle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InputLabel(label: 'Calle', required: true),
            TextField(
              controller: _calleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Ej: Pasaje Los Alerces',
              ),
            ),
          ],
        );
        final campoNumero = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InputLabel(label: 'Número', required: true),
            TextField(
              controller: _nroController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '1234'),
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
    );
  }

  Widget _buildColumnaMapaYExtras({
    required double alturaMapa,
    required ButtonStyle botonCoordStyle,
  }) {
    final tituloMapa = MediaQuery.sizeOf(context).width >= 900 ? 15.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación en el mapa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: tituloMapa),
        ),
        const SizedBox(height: 6),
        Text(
          'Las coordenadas guardadas son siempre las del pin. Puedes arrastrarlo o tocar el mapa para corregir la posición.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
        ),
        const SizedBox(height: 10),
        if (_mapaGoogleDisponible())
          SizedBox(
            height: alturaMapa,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
              'En esta plataforma no hay mapa integrado. Ingresa coordenadas abajo.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _pinLat != null && _pinLon != null
                    ? 'Coordenadas del pin: ${_pinLat!.toStringAsFixed(6)}, ${_pinLon!.toStringAsFixed(6)}'
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
                'Esta vista ayuda a los bomberos a localizar tu domicilio en caso de emergencia.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
        if (_mapaGoogleDisponible()) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: botonCoordStyle,
              onPressed: () => setState(() => _coordsManualAbiertas = !_coordsManualAbiertas),
              child: Text(_coordsManualAbiertas ? 'Ocultar coordenadas' : 'Editar latitud y longitud manualmente'),
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
                    'Coordenadas (opcional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por defecto el pin define la ubicación. Solo usa esto si necesitas copiar coordenadas desde otro mapa.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 12),
                  const InputLabel(label: 'Latitud', required: false),
                  TextField(
                    controller: _latManualController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (_) => _sincronizarManualALatLon(),
                    decoration: const InputDecoration(hintText: 'Ej: -33.448900'),
                  ),
                  const SizedBox(height: 8),
                  const InputLabel(label: 'Longitud', required: false),
                  TextField(
                    controller: _lonManualController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (_) => _sincronizarManualALatLon(),
                    decoration: const InputDecoration(hintText: 'Ej: -70.669300'),
                  ),
                ],
              ),
            ),
          ],
        ],
        if (!_mapaGoogleDisponible()) ...[
          const SizedBox(height: 16),
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
                  'Coordenadas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade800),
                ),
                const SizedBox(height: 12),
                const InputLabel(label: 'Latitud', required: true),
                TextField(
                  controller: _latManualController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _sincronizarManualALatLon(),
                  decoration: const InputDecoration(hintText: 'Ej: -33.448900'),
                ),
                const SizedBox(height: 8),
                const InputLabel(label: 'Longitud', required: true),
                TextField(
                  controller: _lonManualController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _sincronizarManualALatLon(),
                  decoration: const InputDecoration(hintText: 'Ej: -70.669300'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final azulMarco = Colors.blue.shade400;
    final botonCoordStyle = OutlinedButton.styleFrom(
      foregroundColor: azulMarco,
      side: BorderSide(color: azulMarco),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final mapaOk = _mapaGoogleDisponible();
        final dosColumnas = mapaOk && ancho >= 920;
        final alturaMapa = _alturaMapa(context, ancho);
        final textoAyuda = _direccionManual
            ? 'Completa calle y número y ajusta el pin en el mapa hasta tu ubicación real.'
            : 'Usa solo el buscador para la dirección; abajo verás una vista previa (no editable). Para escribir calle y número a mano, marca la opción de ingreso manual.';

        final columnaIzquierda = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home_outlined, size: ancho >= 900 ? 26 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ubicación de la Residencia',
                    style: TextStyle(
                      fontSize: ancho >= 900 ? 22 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              textoAyuda,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: ancho >= 900 ? 15 : 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tu dirección no está en Google Maps, ¿ingresarla manualmente?',
                style: TextStyle(fontSize: 14),
              ),
              value: _direccionManual,
              onChanged: (v) {
                setState(() {
                  _direccionManual = v ?? false;
                  _predicciones = [];
                  if (_direccionManual) {
                    _googleFormatoValido = false;
                    _busquedaController.clear();
                  } else {
                    _calleController.clear();
                    _nroController.clear();
                    _googleFormatoValido = false;
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            if (!_direccionManual) _buildBuscadorGoogle(),
            if (!_direccionManual) _buildVistaPreviaSoloLectura() else _buildCamposManualDireccion(),
            const InputLabel(label: 'Casa interior (opcional)'),
            TextField(
              controller: _unidadController,
              decoration: const InputDecoration(hintText: 'Depto, torre, etc. (opcional)'),
            ),
          ],
        );

        final columnaMapa = _buildColumnaMapaYExtras(
          alturaMapa: alturaMapa,
          botonCoordStyle: botonCoordStyle,
        );

        final botones = Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continuar,
                child: const Text('Continuar'),
              ),
            ),
          ],
        );

        if (dosColumnas) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: columnaIzquierda),
                  const SizedBox(width: 28),
                  Expanded(flex: 6, child: columnaMapa),
                ],
              ),
              const SizedBox(height: 28),
              botones,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            columnaIzquierda,
            const SizedBox(height: 18),
            columnaMapa,
            const SizedBox(height: 22),
            botones,
          ],
        );
      },
    );
  }
}
