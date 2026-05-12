/// Error al llamar a Places (red, API, formato).
class GooglePlacesException implements Exception {
  GooglePlacesException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Modelos compartidos para respuestas de Google Places (detalle de lugar).
class PlaceAutocompletePrediction {
  PlaceAutocompletePrediction({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

/// Resultado de detalle: coordenadas y calle/número si Google devolvió el formato esperado.
class PlaceDetailsResult {
  PlaceDetailsResult({
    required this.lat,
    required this.lng,
    this.calle,
    this.nroDireccion,
    this.formattedAddress,
    required this.tieneFormatoCalleNumero,
  });

  final double lat;
  final double lng;
  final String? calle;
  final int? nroDireccion;
  final String? formattedAddress;

  /// `true` si hay [calle] no vacía (≤150), [nroDireccion] entero > 0 y número parseable.
  final bool tieneFormatoCalleNumero;

  static int? parseNroCalle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final direct = int.tryParse(s);
    if (direct != null) return direct;
    final m = RegExp(r'^(\d+)').firstMatch(s);
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  /// Parsea el objeto `result` del JSON de Place Details (REST).
  static PlaceDetailsResult fromDetailsJson(Map<String, dynamic> result) {
    final geom = result['geometry'] as Map<String, dynamic>?;
    final loc = geom?['location'] as Map<String, dynamic>?;
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lng = (loc?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw const FormatException('Sin coordenadas en la respuesta de Places');
    }

    String? route;
    String? streetNumber;
    final components = result['address_components'] as List<dynamic>? ?? [];
    for (final c in components) {
      final m = c as Map<String, dynamic>;
      final types = (m['types'] as List<dynamic>?)?.cast<String>() ?? [];
      if (types.contains('route')) {
        route = m['long_name'] as String?;
      }
      if (types.contains('street_number')) {
        streetNumber = m['long_name'] as String?;
      }
    }

    final calle = route?.trim();
    final nro = parseNroCalle(streetNumber);
    final ok = calle != null &&
        calle.isNotEmpty &&
        nro != null &&
        nro > 0 &&
        calle.length <= 150;

    return PlaceDetailsResult(
      lat: lat,
      lng: lng,
      calle: calle,
      nroDireccion: nro,
      formattedAddress: result['formatted_address'] as String?,
      tieneFormatoCalleNumero: ok,
    );
  }
}
