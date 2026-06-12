import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodeException implements Exception {
  GeocodeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Geocodificación con Google Geocoding API (navegación en mapa de registro).
class GeocodeService {
  Future<LatLng?> buscarDireccion(String consulta) async {
    final q = consulta.trim();
    if (q.isEmpty) return null;

    final key = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
    if (key == null || key.isEmpty) {
      throw GeocodeException('Falta GOOGLE_MAPS_API_KEY en .env');
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': q,
      'key': key,
      'region': 'cl',
      'components': 'country:CL',
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw GeocodeException('Geocodificación falló (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';
    if (status != 'OK') {
      if (status == 'ZERO_RESULTS') return null;
      throw GeocodeException('No se encontró la dirección ($status).');
    }

    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final loc = (results.first as Map<String, dynamic>)['geometry']?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;

    final lat = (loc['lat'] as num?)?.toDouble();
    final lon = (loc['lng'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }
}
