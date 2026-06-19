class GrifoMapaResultado {
  GrifoMapaResultado({
    required this.idGrifo,
    required this.lat,
    required this.lon,
    required this.cutCom,
    required this.comunaNombre,
    required this.estado,
    required this.idEstadoGr,
    required this.fechaRegistro,
    required this.notas,
    required this.reportadoPor,
  });

  final int idGrifo;
  final double lat;
  final double lon;
  final int cutCom;
  final String comunaNombre;
  final String estado;
  final int idEstadoGr;
  final DateTime fechaRegistro;
  final String? notas;
  final String reportadoPor;

  String get fechaFormateada {
    final y = fechaRegistro.year;
    final m = fechaRegistro.month.toString().padLeft(2, '0');
    final d = fechaRegistro.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class EstadoGrifoOpcion {
  EstadoGrifoOpcion({required this.id, required this.nombre});

  final int id;
  final String nombre;
}
