/// Punto de interés de distribución (Google Places).
class CentroDistribucion {
  CentroDistribucion({
    required this.placeId,
    required this.nombre,
    required this.lat,
    required this.lon,
    required this.distanciaMetros,
    required this.categorias,
    this.direccion,
  });

  final String placeId;
  final String nombre;
  final double lat;
  final double lon;
  final double distanciaMetros;
  final List<String> categorias;
  final String? direccion;

  String get categoriasTexto => categorias.join(' • ');

  String get distanciaTexto {
    if (distanciaMetros >= 1000) {
      return '${(distanciaMetros / 1000).toStringAsFixed(1)} km';
    }
    return '${distanciaMetros.round()} m';
  }
}
