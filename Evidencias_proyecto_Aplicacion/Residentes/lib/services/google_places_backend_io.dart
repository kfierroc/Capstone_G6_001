import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'google_places_models.dart';

Future<List<PlaceAutocompletePrediction>> googlePlacesAutocomplete(String input) async {
  if (input.trim().length < 3) return [];
  final key = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
  if (key == null || key.isEmpty) return [];

  final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
    'input': input.trim(),
    'key': key,
    'components': 'country:cl',
    'language': 'es',
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) return [];
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final status = data['status'] as String?;
  if (status != 'OK' && status != 'ZERO_RESULTS') {
    // REQUEST_DENIED, OVER_QUERY_LIMIT, etc.: devolver vacío para no romper la UI.
    return [];
  }
  final preds = data['predictions'] as List<dynamic>? ?? [];
  return preds.map((p) {
    final m = p as Map<String, dynamic>;
    return PlaceAutocompletePrediction(
      placeId: m['place_id'] as String,
      description: m['description'] as String? ?? '',
    );
  }).toList();
}

Future<PlaceDetailsResult> googlePlacesPlaceDetails(String placeId) async {
  final key = dotenv.env['GOOGLE_MAPS_API_KEY']?.trim();
  if (key == null || key.isEmpty) {
    throw GooglePlacesException('Configura GOOGLE_MAPS_API_KEY en .env');
  }

  final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
    'place_id': placeId,
    'key': key,
    'language': 'es',
    'fields': 'geometry,address_component,formatted_address',
  });

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw GooglePlacesException('Error HTTP al consultar Place Details (${res.statusCode})');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final status = data['status'] as String?;
  if (status != 'OK') {
    throw GooglePlacesException(
      data['error_message'] as String? ?? 'Place Details: $status',
    );
  }

  final result = data['result'] as Map<String, dynamic>;
  return PlaceDetailsResult.fromDetailsJson(result);
}
