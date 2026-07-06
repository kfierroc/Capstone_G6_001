import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEditException implements Exception {
  AdminEditException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminEditService {
  AdminEditService(this._client);

  final SupabaseClient _client;

  String _isoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _trunc(String s, int max) => s.length <= max ? s : s.substring(0, max);

  Future<int> _siguienteId(String tabla, String columna) async {
    final rows = await _client.from(tabla).select(columna).order(columna, ascending: false).limit(1);
    if (rows.isEmpty) return 1;
    final v = rows.first[columna];
    if (v is num) return v.toInt() + 1;
    return 1;
  }

  String normalizarTelefono(String input) {
    var s = input.replaceAll(RegExp(r'\s'), '');
    if (s.startsWith('+56')) {
      if (!RegExp(r'^\+56[2-9][0-9]{8}$').hasMatch(s)) {
        throw AdminEditException('Teléfono inválido. Formato: +56XXXXXXXXX');
      }
      return s;
    }
    if (RegExp(r'^[2-9][0-9]{8}$').hasMatch(s)) return '+56$s';
    throw AdminEditException('Teléfono inválido. Usa +56 seguido de 9 dígitos.');
  }

  void _validarEdadIntegrante({required bool esTitular, required int anioNac}) {
    final anioActual = DateTime.now().year;
    final edad = anioActual - anioNac;
    if (esTitular) {
      if (edad < 16 || edad > 120) {
        throw AdminEditException('El titular debe tener entre 16 y 120 años.');
      }
    } else if (edad < 1 || edad > 120) {
      throw AdminEditException('La edad del integrante debe estar entre 1 y 120 años.');
    }
  }

  // --- Grupo familiar / cuenta ---

  Future<void> actualizarTelefonoGrupo({required int idGrupof, required String telefono}) async {
    final tel = normalizarTelefono(telefono);
    await _client.from('grupofamiliar').update({'telefono_titular': tel}).eq('id_grupof', idGrupof);
  }

  Future<void> actualizarAnioNacTitular({required int idIntegrante, required int anioNac}) async {
    _validarEdadIntegrante(esTitular: true, anioNac: anioNac);
    await _client.from('integrante').update({'anio_nac': anioNac}).eq('id_integrante', idIntegrante);
  }

  // --- Integrantes ---

  Future<void> agregarIntegrante({
    required int idGrupof,
    required int anioNac,
    required Set<int> idsCondiciones,
  }) async {
    _validarEdadIntegrante(esTitular: false, anioNac: anioNac);
    final idInt = await _siguienteId('integrante', 'id_integrante');
    final hoy = DateTime.now();
    await _client.from('integrante').insert({
      'id_integrante': idInt,
      'is_titular': false,
      'anio_nac': anioNac,
      'fecha_ini_i': _isoFecha(hoy),
      'fecha_fin_i': null,
      'id_grupof': idGrupof,
    });
    for (final idCond in idsCondiciones) {
      await _client.from('condiciones_integ').insert({
        'id_integrante': idInt,
        'id_condicion': idCond,
        'observacion': null,
      });
    }
  }

  Future<void> actualizarIntegrante({
    required int idIntegrante,
    required bool esTitular,
    required int anioNac,
    required Set<int> idsCondiciones,
  }) async {
    _validarEdadIntegrante(esTitular: esTitular, anioNac: anioNac);
    await _client.from('integrante').update({'anio_nac': anioNac}).eq('id_integrante', idIntegrante);
    await _client.from('condiciones_integ').delete().eq('id_integrante', idIntegrante);
    for (final idCond in idsCondiciones) {
      await _client.from('condiciones_integ').insert({
        'id_integrante': idIntegrante,
        'id_condicion': idCond,
        'observacion': null,
      });
    }
  }

  Future<void> eliminarIntegrante(int idIntegrante) async {
    final row = await _client.from('integrante').select('is_titular').eq('id_integrante', idIntegrante).maybeSingle();
    if (row == null) throw AdminEditException('Integrante no encontrado.');
    if (row['is_titular'] == true) throw AdminEditException('No se puede eliminar al titular.');
    await _client.from('condiciones_integ').delete().eq('id_integrante', idIntegrante);
    await _client.from('integrante').delete().eq('id_integrante', idIntegrante);
  }

  // --- Mascotas ---

  Future<void> agregarMascota({
    required int idGrupof,
    required String nombre,
    required int idEspecie,
    required int idTamanio,
  }) async {
    final id = await _siguienteId('mascota', 'id_mascota');
    await _client.from('mascota').insert({
      'id_mascota': id,
      'nombre_m': _trunc(nombre.trim(), 30),
      'fecha_reg_m': _isoFecha(DateTime.now()),
      'id_especie': idEspecie,
      'id_tamanio': idTamanio,
      'id_grupof': idGrupof,
    });
  }

  Future<void> actualizarMascota({
    required int idMascota,
    required String nombre,
    required int idEspecie,
    required int idTamanio,
  }) async {
    await _client.from('mascota').update({
      'nombre_m': _trunc(nombre.trim(), 30),
      'id_especie': idEspecie,
      'id_tamanio': idTamanio,
    }).eq('id_mascota', idMascota);
  }

  Future<void> eliminarMascota(int idMascota) async {
    await _client.from('mascota').delete().eq('id_mascota', idMascota);
  }

  // --- Materiales peligrosos ---

  Future<void> upsertMaterialPeligroso({
    required int idRegistro,
    required int idMatPelig,
    required int cantidad,
  }) async {
    if (cantidad < 1) throw AdminEditException('La cantidad debe ser al menos 1.');
    await _client.from('mat_peligroso').upsert(
      {'id_registro': idRegistro, 'id_mat_pelig': idMatPelig, 'cantidad': cantidad},
      onConflict: 'id_registro,id_mat_pelig',
    );
  }

  Future<void> eliminarMaterialPeligroso({required int idRegistro, required int idMatPelig}) async {
    await _client.from('mat_peligroso').delete().eq('id_registro', idRegistro).eq('id_mat_pelig', idMatPelig);
  }

  // --- Domicilio / residencia / registro ---

  Future<void> actualizarResidencia({
    required int idResidencia,
    required String calle,
    required int nroDireccion,
    required double lat,
    required double lon,
    required int cutCom,
  }) async {
    await _client.from('residencia').update({
      'calle': _trunc(calle.trim(), 150),
      'nro_direccion': nroDireccion,
      'lat': lat,
      'lon': lon,
      'cut_com': cutCom,
    }).eq('id_residencia', idResidencia);
  }

  Future<void> actualizarRegistroVivienda({
    required int idRegistro,
    required int idTipoV,
    required int idEstadoV,
    String? unidad,
    String? descDeptoCond,
    String? notasV,
    String? fechaIniR,
    String? fechaUltConfirm,
  }) async {
    final u = unidad?.trim();
    final d = descDeptoCond?.trim();
    final n = notasV?.trim();
    final payload = <String, dynamic>{
      'id_tipo_v': idTipoV,
      'id_estado_v': idEstadoV,
      'unidad': (u == null || u.isEmpty) ? null : _trunc(u, 20),
      'desc_depto_cond': (d == null || d.isEmpty) ? null : _trunc(d, 50),
      'notas_v': (n == null || n.isEmpty) ? null : _trunc(n, 100),
    };
    if (fechaIniR != null && fechaIniR.isNotEmpty) payload['fecha_ini_r'] = fechaIniR;
    if (fechaUltConfirm != null && fechaUltConfirm.isNotEmpty) {
      payload['fecha_ult_confirm'] = fechaUltConfirm;
    }
    await _client.from('registro_v').update(payload).eq('id_registro', idRegistro);
  }

  Future<void> reemplazarPisos({
    required int idRegistro,
    required List<({int numerop, int idMatPiso})> pisos,
  }) async {
    await _client.from('piso_v').delete().eq('id_registro', idRegistro);
    for (final p in pisos) {
      await _client.from('piso_v').insert({
        'id_registro': idRegistro,
        'numerop': p.numerop,
        'id_mat_piso': p.idMatPiso,
      });
    }
  }

  /// Marca el registro de vivienda vigente como no vigente (desvincula grupo/residencia).
  Future<void> desvincularRegistroResidencia(int idRegistro) async {
    final row = await _client
        .from('registro_v')
        .select('vigente')
        .eq('id_registro', idRegistro)
        .maybeSingle();
    if (row == null) throw AdminEditException('Registro de vivienda no encontrado.');
    if (row['vigente'] != true) {
      throw AdminEditException('El registro ya no está vigente.');
    }
    final hoy = DateTime.now();
    await _client.from('registro_v').update({
      'vigente': false,
      'fecha_fin_r': _isoFecha(hoy),
    }).eq('id_registro', idRegistro);
  }

  // --- Bomberos ---

  Future<void> actualizarBombero({
    required int rutNum,
    required String nombBombero,
    required String apePBombero,
    required bool isAdmin,
    required int idCompania,
  }) async {
    await _client.from('bombero').update({
      'nomb_bombero': _trunc(nombBombero.trim(), 50),
      'ape_p_bombero': _trunc(apePBombero.trim(), 50),
      'is_admin': isAdmin,
      'id_compania': idCompania,
    }).eq('rut_num', rutNum);
  }

  Future<void> crearBombero({
    required int rutNum,
    required String rutDv,
    required String nombBombero,
    required String apePBombero,
    required bool isAdmin,
    required int idCompania,
  }) async {
    final dv = rutDv.trim().toUpperCase();
    if (dv.length != 1) throw AdminEditException('Dígito verificador inválido.');
    await _client.from('bombero').insert({
      'rut_num': rutNum,
      'rut_dv': dv,
      'nomb_bombero': _trunc(nombBombero.trim(), 50),
      'ape_p_bombero': _trunc(apePBombero.trim(), 50),
      'is_admin': isAdmin,
      'id_compania': idCompania,
    });
  }

  Future<void> eliminarBombero(int rutNum) async {
    final registros = await _client.from('info_grifo').select('id_reg_grifo').eq('rut_num', rutNum).limit(1);
    if (registros.isNotEmpty) {
      throw AdminEditException('No se puede eliminar: tiene registros de grifos asociados.');
    }
    await _client.from('bombero').delete().eq('rut_num', rutNum);
  }

  /// Elimina una residencia sin registro de vivienda vigente.
  Future<void> eliminarResidencia(int idResidencia) async {
    final registros = await _client
        .from('registro_v')
        .select('id_registro, vigente')
        .eq('id_residencia', idResidencia);

    if (registros.any((r) => r['vigente'] == true)) {
      throw AdminEditException(
        'No se puede eliminar: tiene un registro de vivienda vigente. '
        'Desvincúlelo desde el grupo familiar primero.',
      );
    }

    for (final r in registros) {
      final idReg = (r['id_registro'] as num).toInt();
      await _client.from('mat_peligroso').delete().eq('id_registro', idReg);
      await _client.from('piso_v').delete().eq('id_registro', idReg);
    }
    if (registros.isNotEmpty) {
      await _client.from('registro_v').delete().eq('id_residencia', idResidencia);
    }
    await _client.from('residencia').delete().eq('id_residencia', idResidencia);
  }

  /// Elimina un grupo familiar y sus datos asociados (integrantes, mascotas, registros).
  Future<void> eliminarGrupoFamiliar(int idGrupof) async {
    final integrantes = await _client.from('integrante').select('id_integrante').eq('id_grupof', idGrupof);
    for (final row in integrantes) {
      final idI = (row['id_integrante'] as num).toInt();
      await _client.from('condiciones_integ').delete().eq('id_integrante', idI);
    }
    await _client.from('integrante').delete().eq('id_grupof', idGrupof);
    await _client.from('mascota').delete().eq('id_grupof', idGrupof);

    final registros = await _client.from('registro_v').select('id_registro').eq('id_grupof', idGrupof);
    for (final row in registros) {
      final idReg = (row['id_registro'] as num).toInt();
      await _client.from('mat_peligroso').delete().eq('id_registro', idReg);
      await _client.from('piso_v').delete().eq('id_registro', idReg);
    }
    if (registros.isNotEmpty) {
      await _client.from('registro_v').delete().eq('id_grupof', idGrupof);
    }

    await _client.from('grupofamiliar').delete().eq('id_grupof', idGrupof);
  }

  // --- Grifos ---

  Future<int> crearGrifo({
    required double lat,
    required double lon,
    required int cutCom,
    required int idEstadoGr,
    required int rutNumBombero,
    String? notaG,
  }) async {
    final insert = await _client
        .from('grifo')
        .insert({'lat': lat, 'lon': lon, 'cut_com': cutCom})
        .select('id_grifo')
        .single();
    final idGrifo = (insert['id_grifo'] as num).toInt();

    await _client.from('info_grifo').insert({
      'id_grifo': idGrifo,
      'fecha_registro': _isoFecha(DateTime.now()),
      'nota_g': _notaGrifo(notaG),
      'id_estado_gr': idEstadoGr,
      'rut_num': rutNumBombero,
    });

    return idGrifo;
  }

  Future<void> actualizarGrifoUbicacion({
    required int idGrifo,
    required double lat,
    required double lon,
    required int cutCom,
  }) async {
    await _client.from('grifo').update({
      'lat': lat,
      'lon': lon,
      'cut_com': cutCom,
    }).eq('id_grifo', idGrifo);
  }

  Future<void> registrarInfoGrifo({
    required int idGrifo,
    required int idEstadoGr,
    required int rutNumBombero,
    String? notaG,
    DateTime? fechaRegistro,
  }) async {
    await _client.from('info_grifo').insert({
      'id_grifo': idGrifo,
      'fecha_registro': _isoFecha(fechaRegistro ?? DateTime.now()),
      'nota_g': _notaGrifo(notaG),
      'id_estado_gr': idEstadoGr,
      'rut_num': rutNumBombero,
    });
  }

  String? _notaGrifo(String? nota) {
    final n = nota?.trim();
    if (n == null || n.isEmpty) return null;
    return _trunc(n, 100);
  }
}
