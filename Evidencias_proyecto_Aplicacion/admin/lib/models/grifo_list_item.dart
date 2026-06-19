class GrifoListItem {
  const GrifoListItem({
    required this.idGrifo,
    required this.lat,
    required this.lon,
    required this.comuna,
    required this.estadoActual,
    this.cutCom,
    this.idEstadoGr,
    this.registradoPor,
    this.notaActual,
  });

  final int idGrifo;
  final double lat;
  final double lon;
  final String comuna;
  final String estadoActual;
  final int? cutCom;
  final int? idEstadoGr;
  final String? registradoPor;
  final String? notaActual;

  bool get requiereAtencion {
    final e = estadoActual.toLowerCase();
    return e.contains('dañado') || e.contains('danado') || e.contains('mantenimiento');
  }
}

class InfoGrifoRegistro {
  const InfoGrifoRegistro({
    required this.idRegGrifo,
    required this.fechaRegistro,
    required this.estado,
    required this.idEstadoGr,
    required this.registradoPor,
    this.nota,
  });

  final int idRegGrifo;
  final String fechaRegistro;
  final String estado;
  final int idEstadoGr;
  final String registradoPor;
  final String? nota;
}

class GrifoDetalle {
  const GrifoDetalle({
    required this.idGrifo,
    required this.lat,
    required this.lon,
    required this.comuna,
    required this.cutCom,
    required this.estadoActual,
    required this.idEstadoGr,
    required this.fechaUltimoRegistro,
    this.notaActual,
    required this.historial,
  });

  final int idGrifo;
  final double lat;
  final double lon;
  final String comuna;
  final int cutCom;
  final String estadoActual;
  final int idEstadoGr;
  final String fechaUltimoRegistro;
  final String? notaActual;
  final List<InfoGrifoRegistro> historial;
}
