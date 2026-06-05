/// Perfil mínimo desde la tabla `bombero`.
class BomberoPerfil {
  BomberoPerfil({
    required this.rutNum,
    required this.rutDv,
    required this.nombBombero,
    required this.apePBombero,
    required this.isAdmin,
    required this.idCompania,
  });

  final int rutNum;
  final String rutDv;
  final String nombBombero;
  final String apePBombero;
  final bool isAdmin;
  final int idCompania;

  String get nombreCompleto => '$nombBombero $apePBombero'.trim();

  String get rutMostrar {
    var s = rutNum.toString();
    final partes = <String>[];
    while (s.length > 3) {
      partes.add(s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    if (s.isNotEmpty) partes.add(s);
    final cuerpo = partes.reversed.join('.');
    return '$cuerpo-${rutDv.toUpperCase()}';
  }

  factory BomberoPerfil.fromMap(Map<String, dynamic> m) {
    return BomberoPerfil(
      rutNum: (m['rut_num'] as num).toInt(),
      rutDv: (m['rut_dv'] as String).trim(),
      nombBombero: (m['nomb_bombero'] as String).trim(),
      apePBombero: (m['ape_p_bombero'] as String).trim(),
      isAdmin: m['is_admin'] == true,
      idCompania: (m['id_compania'] as num).toInt(),
    );
  }
}
