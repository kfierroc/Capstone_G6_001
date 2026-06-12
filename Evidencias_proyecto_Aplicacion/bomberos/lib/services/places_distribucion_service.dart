import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/centro_distribucion.dart';
import '../utils/geo_utils.dart';

class PlacesDistribucionException implements Exception {
  PlacesDistribucionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Centros de distribución de gas, combustible y parafina (Google Places API).
class PlacesDistribucionService {
  static const radioMaximoMetros = 1000;

  String get _apiKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw PlacesDistribucionException('Falta GOOGLE_MAPS_API_KEY en .env');
    }
    return key;
  }

  /// Una sola consulta al abrir el mapa: lugares dentro de [radioMetros] (máx. 1 km).
  Future<List<CentroDistribucion>> buscarCercanos({
    required double lat,
    required double lon,
    int radioMetros = radioMaximoMetros,
  }) async {
    final acumulado = <String, CentroDistribucion>{};

    final consultas = <_ConsultaPlaces>[
      _ConsultaPlaces(type: 'gas_station', categoria: 'Combustible'),
      _ConsultaPlaces(keyword: 'distribuidora gas licuado', categoria: 'Gas'),
      _ConsultaPlaces(keyword: 'centro distribución gas', categoria: 'Gas'),
      _ConsultaPlaces(keyword: 'parafina combustible', categoria: 'Parafina'),
    ];

    for (final c in consultas) {
      try {
        final lugares = await _nearbySearch(
          lat: lat,
          lon: lon,
          radioMetros: radioMetros,
          type: c.type,
          keyword: c.keyword,
          categoria: c.categoria,
        );
        for (final lugar in lugares) {
          final prev = acumulado[lugar.placeId];
          if (prev == null) {
            acumulado[lugar.placeId] = lugar;
          } else {
            final cats = {...prev.categorias, ...lugar.categorias}.toList();
            acumulado[lugar.placeId] = CentroDistribucion(
              placeId: prev.placeId,
              nombre: prev.nombre,
              lat: prev.lat,
              lon: prev.lon,
              distanciaMetros: prev.distanciaMetros,
              categorias: cats,
              direccion: prev.direccion ?? lugar.direccion,
            );
          }
        }
      } on PlacesDistribucionException {
        // Si una consulta falla, seguimos con las demás.
      }
    }

    final lista = acumulado.values.toList()
      ..sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
    return lista;
  }

  Future<List<CentroDistribucion>> _nearbySearch({
    required double lat,
    required double lon,
    required int radioMetros,
    required String categoria,
    String? type,
    String? keyword,
  }) async {
    final params = <String, String>{
      'location': '$lat,$lon',
      'radius': '$radioMetros',
      'key': _apiKey,
      'language': 'es',
    };
    if (type != null) params['type'] = type;
    if (keyword != null) params['keyword'] = keyword;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', params);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw PlacesDistribucionException('Places API error (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      final err = data['error_message'] as String?;
      throw PlacesDistribucionException(err ?? 'Places: $status');
    }

    final results = data['results'] as List<dynamic>? ?? [];
    final lista = <CentroDistribucion>[];

    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final placeId = raw['place_id'] as String?;
      final nombre = raw['name'] as String?;
      final geom = raw['geometry']?['location'] as Map<String, dynamic>?;
      if (placeId == null || nombre == null || geom == null) continue;

      final pLat = (geom['lat'] as num?)?.toDouble();
      final pLon = (geom['lng'] as num?)?.toDouble();
      if (pLat == null || pLon == null) continue;

      final dist = GeoUtils.distanciaMetros(lat, lon, pLat, pLon);
      if (dist > radioMetros) continue;

      final cats = _categoriasDesdePlace(raw, categoria);
      lista.add(
        CentroDistribucion(
          placeId: placeId,
          nombre: nombre,
          lat: pLat,
          lon: pLon,
          distanciaMetros: dist,
          categorias: cats,
          direccion: raw['vicinity'] as String? ?? raw['formatted_address'] as String?,
        ),
      );
    }
    return lista;
  }

  List<String> _categoriasDesdePlace(Map<String, dynamic> raw, String categoriaBase) {
    final types = (raw['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final cats = <String>{categoriaBase};

    if (types.contains('gas_station')) cats.add('Combustible');
    final name = (raw['name'] as String? ?? '').toLowerCase();
    if (name.contains('gas') || name.contains('glp') || name.contains('licuado')) {
      cats.add('Gas');
    }
    if (name.contains('parafina') || name.contains('kerosene') || name.contains('queroseno')) {
      cats.add('Parafina');
    }
    if (name.contains('petroleo') || name.contains('combustible') || name.contains('bencina')) {
      cats.add('Combustible');
    }
    return cats.toList();
  }
}

class _ConsultaPlaces {
  _ConsultaPlaces({this.type, this.keyword, required this.categoria});

  final String? type;
  final String? keyword;
  final String categoria;
}
