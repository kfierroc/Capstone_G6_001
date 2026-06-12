/// Datos de la compañía del bombero y su comuna (vía [companias_bomberos.cut_com]).
class CompaniaBomberoInfo {
  CompaniaBomberoInfo({
    required this.idCompania,
    required this.nombre,
    required this.cutCom,
    required this.nombreComuna,
  });

  final int idCompania;
  final String nombre;
  final int cutCom;
  final String nombreComuna;
}
