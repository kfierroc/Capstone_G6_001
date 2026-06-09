import 'dart:math' as math;

/// Utilidades geográficas para búsqueda por área en mapa.
class GeoUtils {
  GeoUtils._();

  static const _radioTierraM = 6371000.0;

  /// Distancia en metros entre dos puntos (fórmula de Haversine).
  static double distanciaMetros(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradosARadianes(lat1)) *
            math.cos(_gradosARadianes(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _radioTierraM * c;
  }

  static double _gradosARadianes(double grados) => grados * math.pi / 180;

  /// Caja delimitadora cuadrada alrededor de un centro (metros reales).
  static ({double minLat, double maxLat, double minLon, double maxLon}) boundingBox(
    double lat,
    double lon,
    double radioMetros,
  ) {
    final deltaLat = radioMetros / _radioTierraM * (180 / math.pi);
    final deltaLon = deltaLat / math.cos(_gradosARadianes(lat)).clamp(0.2, 1.0);
    return (
      minLat: lat - deltaLat,
      maxLat: lat + deltaLat,
      minLon: lon - deltaLon,
      maxLon: lon + deltaLon,
    );
  }

  /// Clave de caché: centro aproximado + radio + límite.
  static String claveCache(double lat, double lon, int radioMetros, int limite) {
    final latR = (lat * 1000).round() / 1000;
    final lonR = (lon * 1000).round() / 1000;
    return '${latR}_${lonR}_${radioMetros}_$limite';
  }
}
