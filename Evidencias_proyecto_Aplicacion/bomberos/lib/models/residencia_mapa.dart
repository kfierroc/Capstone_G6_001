/// Residencia activa mostrada en el mapa y en la lista inferior.
class ResidenciaMapaResultado {
  ResidenciaMapaResultado({
    required this.idRegistro,
    required this.idResidencia,
    required this.idGrupof,
    required this.lat,
    required this.lon,
    required this.direccionCompleta,
    required this.cantidadPersonas,
    required this.cantidadMascotas,
    required this.tipoVivienda,
    required this.cantidadMaterialesPeligrosos,
    required this.alertasMedicas,
    required this.fechaUltimaActualizacion,
  });

  final int idRegistro;
  final int idResidencia;
  final int idGrupof;
  final double lat;
  final double lon;
  final String direccionCompleta;
  final int cantidadPersonas;
  final int cantidadMascotas;
  final String tipoVivienda;
  final int cantidadMaterialesPeligrosos;
  final List<String> alertasMedicas;
  final DateTime fechaUltimaActualizacion;

  String get fechaUltimaFormateada {
    final y = fechaUltimaActualizacion.year;
    final m = fechaUltimaActualizacion.month.toString().padLeft(2, '0');
    final d = fechaUltimaActualizacion.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
