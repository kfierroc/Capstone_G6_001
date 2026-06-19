/// Perfil mínimo del administrador (tabla `bombero`, is_admin = true).
class AdminBomberoPerfil {
  AdminBomberoPerfil({
    required this.rutNum,
    required this.rutDv,
    required this.nombBombero,
    required this.apePBombero,
    required this.idCompania,
  });

  final int rutNum;
  final String rutDv;
  final String nombBombero;
  final String apePBombero;
  final int idCompania;

  String get nombreCompleto => '$nombBombero $apePBombero'.trim();

  factory AdminBomberoPerfil.fromMap(Map<String, dynamic> m) {
    return AdminBomberoPerfil(
      rutNum: (m['rut_num'] as num).toInt(),
      rutDv: (m['rut_dv'] as String).trim(),
      nombBombero: (m['nomb_bombero'] as String).trim(),
      apePBombero: (m['ape_p_bombero'] as String).trim(),
      idCompania: (m['id_compania'] as num).toInt(),
    );
  }
}
