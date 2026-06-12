import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/residencia_mapa.dart';
import '../utils/geo_utils.dart';

/// Caché en memoria y control de búsquedas duplicadas en el mapa.
class MapaResidenciasCache {
  final Map<String, List<ResidenciaMapaResultado>> _resultados = {};

  LatLng? ultimoCentroBuscado;
  int? ultimoRadioMetros;
  int? ultimoLimite;

  /// No rebuscar si el centro se movió menos de 200 m con mismo radio y límite.
  bool esBusquedaRedundante(LatLng centro, int radioMetros, int limite) {
    final prev = ultimoCentroBuscado;
    if (prev == null || ultimoRadioMetros != radioMetros || ultimoLimite != limite) {
      return false;
    }

    final dist = GeoUtils.distanciaMetros(prev.latitude, prev.longitude, centro.latitude, centro.longitude);
    return dist < 200;
  }

  List<ResidenciaMapaResultado>? obtener(String clave) => _resultados[clave];

  void guardar({
    required String clave,
    required List<ResidenciaMapaResultado> datos,
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
