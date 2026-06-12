import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/grifo_mapa.dart';
import '../utils/geo_utils.dart';

class MapaGrifosCache {
  final Map<String, List<GrifoMapaResultado>> _resultados = {};

  LatLng? ultimoCentroBuscado;
  int? ultimoRadioMetros;
  int? ultimoLimite;

  bool esBusquedaRedundante(LatLng centro, int radioMetros, int limite) {
    final prev = ultimoCentroBuscado;
    if (prev == null || ultimoRadioMetros != radioMetros || ultimoLimite != limite) {
      return false;
    }
    final dist = GeoUtils.distanciaMetros(prev.latitude, prev.longitude, centro.latitude, centro.longitude);
    return dist < 200;
  }

  List<GrifoMapaResultado>? obtener(String clave) => _resultados[clave];

  void guardar({
    required String clave,
    required List<GrifoMapaResultado> datos,
    required LatLng centro,
    required int radioMetros,
    required int limite,
  }) {
    _resultados[clave] = datos;
    ultimoCentroBuscado = centro;
    ultimoRadioMetros = radioMetros;
    ultimoLimite = limite;
  }
}
