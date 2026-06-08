/// Resultado de búsqueda de domicilios con registro vigente.
class ResidenciaBusquedaResultado {
  ResidenciaBusquedaResultado({
    required this.idRegistro,
    required this.idResidencia,
    required this.idGrupof,
    required this.direccionCompleta,
    required this.cantidadPersonas,
    required this.cantidadMascotas,
    required this.fechaUltimaActualizacion,
  });

  final int idRegistro;
  final int idResidencia;
  final int idGrupof;
  final String direccionCompleta;
  final int cantidadPersonas;
  final int cantidadMascotas;
  final DateTime fechaUltimaActualizacion;

  String get fechaUltimaFormateada {
    final y = fechaUltimaActualizacion.year;
    final m = fechaUltimaActualizacion.month.toString().padLeft(2, '0');
    final d = fechaUltimaActualizacion.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
