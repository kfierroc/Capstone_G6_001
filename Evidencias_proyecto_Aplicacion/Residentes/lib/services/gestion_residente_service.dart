import 'package:supabase_flutter/supabase_flutter.dart';

import 'registro_residente_service.dart';

/// Vista de integrante para las pantallas de gestión.
class IntegranteVista {
  IntegranteVista({
    required this.idIntegrante,
    required this.isTitular,
    required this.anioNacimiento,
    required this.idsCondiciones,
    required this.etiqueta,
  });

  final int idIntegrante;
  final bool isTitular;
  final int anioNacimiento;
  final List<int> idsCondiciones;
  final String etiqueta;
}

class MascotaVista {
  MascotaVista({
    required this.idMascota,
    required this.nombre,
    required this.especie,
    required this.tamano,
  });

  final int idMascota;
  final String nombre;
  final String especie;
  final String tamano;
}

class MatPeligrosoVista {
  MatPeligrosoVista({
    required this.idMatPelig,
    required this.tipoMat,
    required this.cantidad,
  });

  final int idMatPelig;
  final String tipoMat;
  final int cantidad;
}

/// Contexto del residente autenticado: grupo familiar y registro de vivienda vigente.
class ContextoResidente {
  ContextoResidente({required this.idGrupof, this.idRegistro});

  final int idGrupof;
  /// [registro_v] vigente; puede ser null si aún no hay vivienda registrada.
  final int? idRegistro;
}

/// Piso asociado al registro de vivienda (`piso_v`).
class PisoDomicilioVista {
  PisoDomicilioVista({required this.numerop, required this.materialPiso});

  final int numerop;
  final String materialPiso;
}

/// Datos del domicilio para pantalla de gestión (residencia + registro vigente + pisos).
class DomicilioVista {
  DomicilioVista({
    required this.idGrupof,
    required this.idRegistro,
    required this.idResidencia,
    required this.calle,
    required this.nroDireccion,
    required this.lat,
    required this.lon,
    required this.cutCom,
    required this.comunaNombre,
    required this.unidad,
    required this.descDeptoCond,
    required this.notasV,
    required this.tipoVivienda,
    required this.estadoVivienda,
    required this.idTipoV,
    required this.idEstadoV,
    required this.fechaUltConfirm,
    required this.fechaExpiracion,
    required this.fechaIniR,
    required this.pisos,
  });

  final int idGrupof;
  final int idRegistro;
  final int idResidencia;
  final String calle;
  final int nroDireccion;
  final double lat;
  final double lon;
  final int cutCom;
  final String comunaNombre;
  final String? unidad;
  final String? descDeptoCond;
  final String? notasV;
  final String tipoVivienda;
  final String estadoVivienda;
  final int idTipoV;
  final int idEstadoV;
  final DateTime fechaUltConfirm;
  final DateTime fechaExpiracion;
  final DateTime fechaIniR;
  final List<PisoDomicilioVista> pisos;

  bool get esDepartamento => tipoVivienda.trim() == 'Departamento';

  /// Material mostrado cuando es departamento (un solo piso en BD).
  String? get materialDepartamentoSiAplica {
    if (!esDepartamento || pisos.isEmpty) return null;
    return pisos.first.materialPiso;
  }
}

/// Información de cuenta para configuración (grupo + titular + auth).
class CuentaConfigVista {
  CuentaConfigVista({
    required this.idGrupof,
    required this.rutTitularNum,
    required this.rutDv,
    required this.telefonoTitular,
    required this.email,
    required this.anioNacTitular,
    required this.fechaUltConfirm,
    required this.fechaExpiracion,
  });

  final int idGrupof;
  final int rutTitularNum;
  final String rutDv;
  final String telefonoTitular;
  final String email;
  final int? anioNacTitular;
  final DateTime? fechaUltConfirm;
  final DateTime? fechaExpiracion;
}

/// Alta/edición de integrantes, mascotas y materiales peligrosos contra Supabase.
class GestionResidenteService {
  GestionResidenteService(this._client);

  final SupabaseClient _client;

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  String _isoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _trunc(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  Future<int> _siguienteId(String tabla, String columna) async {
    final rows = await _client.from(tabla).select(columna).order(columna, ascending: false).limit(1);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return 1;
    final v = (list.first as Map<String, dynamic>)[columna];
    if (v is int) return v + 1;
    if (v is num) return v.toInt() + 1;
    return 1;
  }

  /// Grupo familiar del usuario y [registro_v] vigente asociado (para pisos / materiales).
  Future<ContextoResidente?> contextoResidente() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    final gf = await _client.from('grupofamiliar').select('id_grupof').eq('user_id', uid).maybeSingle();
    if (gf == null) return null;
    final idGf = (gf['id_grupof'] as num).toInt();

    final rv = await _client
        .from('registro_v')
        .select('id_registro')
        .eq('id_grupof', idGf)
        .eq('vigente', true)
        .maybeSingle();
    final idReg = rv == null ? null : (rv['id_registro'] as num).toInt();
    return ContextoResidente(idGrupof: idGf, idRegistro: idReg);
  }

  Future<List<IntegranteVista>> listarIntegrantes(int idGrupof) async {
    final raw = await _client
        .from('integrante')
        .select('id_integrante, is_titular, anio_nac')
        .eq('id_grupof', idGrupof)
        .isFilter('fecha_fin_i', null)
        .order('is_titular', ascending: false)
        .order('id_integrante');

    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return [];

    final ids = rows.map((r) => (r['id_integrante'] as num).toInt()).toList();
    final rawCi = await _client.from('condiciones_integ').select('id_integrante, id_condicion').inFilter('id_integrante', ids);

    final condPorInt = <int, List<int>>{};
    for (final row in List<Map<String, dynamic>>.from(rawCi as List)) {
      final idI = (row['id_integrante'] as num).toInt();
      final idC = (row['id_condicion'] as num).toInt();
      condPorInt.putIfAbsent(idI, () => []).add(idC);
    }

    var nNoTitular = 0;
    final out = <IntegranteVista>[];
    for (final r in rows) {
      final idI = (r['id_integrante'] as num).toInt();
      final titular = r['is_titular'] == true;
      final anio = (r['anio_nac'] as num).toInt();
      late final String etiqueta;
      if (titular) {
        etiqueta = 'Titular';
      } else {
        nNoTitular++;
        etiqueta = 'Integrante $nNoTitular';
      }
      out.add(
        IntegranteVista(
          idIntegrante: idI,
          isTitular: titular,
          anioNacimiento: anio,
          idsCondiciones: List<int>.from(condPorInt[idI] ?? const []),
          etiqueta: etiqueta,
        ),
      );
    }
    return out;
  }

  void _validarEdadIntegrante({required bool esTitular, required int anioNac}) {
    final edad = DateTime.now().year - anioNac;
    if (esTitular) {
      if (edad < 16 || edad > 120) {
        throw RegistroResidenteException('El titular debe tener entre 16 y 120 años según el registro.');
      }
    } else {
      if (edad < 1 || edad > 120) {
        throw RegistroResidenteException('La edad del integrante debe estar entre 1 y 120 años.');
      }
    }
  }

  Future<void> agregarIntegrante({
    required int idGrupof,
    required int anioNac,
    required Set<int> idsCondiciones,
  }) async {
    _validarEdadIntegrante(esTitular: false, anioNac: anioNac);

    final idInt = await _siguienteId('integrante', 'id_integrante');
    final hoy = _soloFecha(DateTime.now());

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
    final row =
        await _client.from('integrante').select('is_titular').eq('id_integrante', idIntegrante).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Integrante no encontrado.');
    }
    if (row['is_titular'] == true) {
      throw RegistroResidenteException('No se puede eliminar al titular.');
    }
    await _client.from('condiciones_integ').delete().eq('id_integrante', idIntegrante);
    await _client.from('integrante').delete().eq('id_integrante', idIntegrante);
  }

  Future<List<MascotaVista>> listarMascotas(int idGrupof) async {
    final raw = await _client.from('mascota').select().eq('id_grupof', idGrupof).order('id_mascota');
    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return [];

    final espRows = await _client.from('tipo_especie').select('id_especie, especie');
    final tamRows = await _client.from('tipo_tamanio').select('id_tamanio, tamanio');
    final mapEsp = <int, String>{};
    for (final r in List<Map<String, dynamic>>.from(espRows as List)) {
      mapEsp[(r['id_especie'] as num).toInt()] = (r['especie'] as String).trim();
    }
    final mapTam = <int, String>{};
    for (final r in List<Map<String, dynamic>>.from(tamRows as List)) {
      mapTam[(r['id_tamanio'] as num).toInt()] = (r['tamanio'] as String).trim();
    }

    return rows.map((r) {
      final idE = (r['id_especie'] as num).toInt();
      final idT = (r['id_tamanio'] as num).toInt();
      return MascotaVista(
        idMascota: (r['id_mascota'] as num).toInt(),
        nombre: (r['nombre_m'] as String).trim(),
        especie: mapEsp[idE] ?? '#$idE',
        tamano: mapTam[idT] ?? '#$idT',
      );
    }).toList();
  }

  Future<void> agregarMascota({
    required int idGrupof,
    required String nombre,
    required int idEspecie,
    required int idTamanio,
  }) async {
    final id = await _siguienteId('mascota', 'id_mascota');
    final hoy = _soloFecha(DateTime.now());
    await _client.from('mascota').insert({
      'id_mascota': id,
      'nombre_m': _trunc(nombre.trim(), 30),
      'fecha_reg_m': _isoFecha(hoy),
      'id_especie': idEspecie,
      'id_tamanio': idTamanio,
      'id_grupof': idGrupof,
    });
  }

  Future<void> eliminarMascota(int idMascota) async {
    await _client.from('mascota').delete().eq('id_mascota', idMascota);
  }

  Future<List<MatPeligrosoVista>> listarMaterialesPeligrosos(int? idRegistro) async {
    if (idRegistro == null || idRegistro <= 0) return [];

    final raw = await _client
        .from('mat_peligroso')
        .select('cantidad, id_mat_pelig, tipo_mat_peligroso(tipo_mat)')
        .eq('id_registro', idRegistro);

    final list = <MatPeligrosoVista>[];
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final nested = row['tipo_mat_peligroso'];
      String tipo = '';
      if (nested is Map<String, dynamic>) {
        tipo = (nested['tipo_mat'] as String?)?.trim() ?? '';
      }
      list.add(
        MatPeligrosoVista(
          idMatPelig: (row['id_mat_pelig'] as num).toInt(),
          tipoMat: tipo.isNotEmpty ? tipo : '#${row['id_mat_pelig']}',
          cantidad: (row['cantidad'] as num).toInt(),
        ),
      );
    }
    return list;
  }

  /// Inserta o actualiza la cantidad para el par ([idRegistro], [idMatPelig]).
  Future<void> upsertMaterialPeligroso({
    required int idRegistro,
    required int idMatPelig,
    required int cantidad,
  }) async {
    if (cantidad < 1) {
      throw RegistroResidenteException('La cantidad debe ser al menos 1.');
    }
    await _client.from('mat_peligroso').upsert(
      {
        'id_registro': idRegistro,
        'id_mat_pelig': idMatPelig,
        'cantidad': cantidad,
      },
      onConflict: 'id_registro,id_mat_pelig',
    );
  }

  Future<void> eliminarMaterialPeligroso({
    required int idRegistro,
    required int idMatPelig,
  }) async {
    await _client.from('mat_peligroso').delete().eq('id_registro', idRegistro).eq('id_mat_pelig', idMatPelig);
  }

  // --- Domicilio / registro de vivienda ---

  DateTime _addCalendarMonths(DateTime d, int months) {
    final total = d.month - 1 + months;
    final y = d.year + total ~/ 12;
    final m = total % 12 + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  Future<int> _idTipoViviendaEtiqueta(String etiqueta) async {
    final row = await _client.from('tipo_vivienda').select('id_tipo_v').eq('tipo_v', etiqueta.trim()).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Tipo de vivienda no encontrado en la base: $etiqueta');
    }
    return (row['id_tipo_v'] as num).toInt();
  }

  Future<int> _idEstadoViviendaEtiqueta(String etiqueta) async {
    final row = await _client.from('estado_vivienda').select('id_estado_v').eq('estado_v', etiqueta.trim()).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Estado de vivienda no encontrado en la base: $etiqueta');
    }
    return (row['id_estado_v'] as num).toInt();
  }

  Future<int> _idMaterialPisoEtiqueta(String material) async {
    final row =
        await _client.from('tipo_mat_piso').select('id_mat_piso').eq('material_piso', material.trim()).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Material de piso no encontrado en la base: $material');
    }
    return (row['id_mat_piso'] as num).toInt();
  }

  /// Vista completa del domicilio vigente o null si no hay grupo/registro.
  Future<DomicilioVista?> obtenerDomicilio() async {
    final ctx = await contextoResidente();
    if (ctx == null || ctx.idRegistro == null) return null;

    final idReg = ctx.idRegistro!;
    final idGf = ctx.idGrupof;

    final rv = await _client
        .from('registro_v')
        .select(
          'id_registro, unidad, desc_depto_cond, notas_v, fecha_ult_confirm, fecha_expiracion, fecha_ini_r, id_residencia, id_tipo_v, id_estado_v',
        )
        .eq('id_registro', idReg)
        .eq('vigente', true)
        .maybeSingle();
    if (rv == null) return null;

    final idRes = (rv['id_residencia'] as num).toInt();
    final resRow = await _client.from('residencia').select('calle, nro_direccion, lat, lon, cut_com').eq('id_residencia', idRes).maybeSingle();
    if (resRow == null) return null;

    final cut = (resRow['cut_com'] as num).toInt();
    final comRow = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
    final comunaNombre = (comRow?['comuna'] as String?)?.trim() ?? 'Comuna $cut';

    final idTipo = (rv['id_tipo_v'] as num).toInt();
    final idEst = (rv['id_estado_v'] as num).toInt();
    final tipoRow = await _client.from('tipo_vivienda').select('tipo_v').eq('id_tipo_v', idTipo).maybeSingle();
    final estRow = await _client.from('estado_vivienda').select('estado_v').eq('id_estado_v', idEst).maybeSingle();
    final tipoV = (tipoRow?['tipo_v'] as String?)?.trim() ?? '';
    final estV = (estRow?['estado_v'] as String?)?.trim() ?? '';

    final rawPisos = await _client
        .from('piso_v')
        .select('numerop, tipo_mat_piso(material_piso)')
        .eq('id_registro', idReg)
        .order('numerop');

    final pisos = <PisoDomicilioVista>[];
    for (final row in List<Map<String, dynamic>>.from(rawPisos as List)) {
      final n = (row['numerop'] as num).toInt();
      String mat = '';
      final nested = row['tipo_mat_piso'];
      if (nested is Map<String, dynamic>) {
        mat = (nested['material_piso'] as String?)?.trim() ?? '';
      }
      pisos.add(PisoDomicilioVista(numerop: n, materialPiso: mat.isEmpty ? '—' : mat));
    }

    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.parse(v.split('T').first);
      return DateTime.now();
    }

    return DomicilioVista(
      idGrupof: idGf,
      idRegistro: idReg,
      idResidencia: idRes,
      calle: (resRow['calle'] as String).trim(),
      nroDireccion: (resRow['nro_direccion'] as num).toInt(),
      lat: (resRow['lat'] as num).toDouble(),
      lon: (resRow['lon'] as num).toDouble(),
      cutCom: cut,
      comunaNombre: comunaNombre,
      unidad: (rv['unidad'] as String?)?.trim(),
      descDeptoCond: (rv['desc_depto_cond'] as String?)?.trim(),
      notasV: (rv['notas_v'] as String?)?.trim(),
      tipoVivienda: tipoV,
      estadoVivienda: estV,
      idTipoV: idTipo,
      idEstadoV: idEst,
      fechaUltConfirm: parseDate(rv['fecha_ult_confirm']),
      fechaExpiracion: parseDate(rv['fecha_expiracion']),
      fechaIniR: parseDate(rv['fecha_ini_r']),
      pisos: pisos,
    );
  }

  /// Actualiza calle, número, coordenadas y recalcula comuna (`cut_com`).
  Future<void> guardarUbicacionResidencia({
    required int idResidencia,
    required String calle,
    required int nroDireccion,
    required double lat,
    required double lon,
  }) async {
    final regSvc = RegistroResidenteService(_client);
    final cutCom = await regSvc.obtenerCutCom(lat, lon);
    await _client.from('residencia').update({
      'calle': _trunc(calle.trim(), 150),
      'nro_direccion': nroDireccion,
      'lat': lat,
      'lon': lon,
      'cut_com': cutCom,
    }).eq('id_residencia', idResidencia);
  }

  Future<void> guardarReferenciasRegistro({
    required int idRegistro,
    String? unidad,
    String? descDeptoCond,
    String? notasV,
  }) async {
    final u = unidad?.trim();
    final d = descDeptoCond?.trim();
    final n = notasV?.trim();
    await _client.from('registro_v').update({
      'unidad': (u == null || u.isEmpty) ? null : _trunc(u, 20),
      'desc_depto_cond': (d == null || d.isEmpty) ? null : _trunc(d, 50),
      'notas_v': (n == null || n.isEmpty) ? null : _trunc(n, 100),
    }).eq('id_registro', idRegistro);
  }

  Future<void> guardarTipoEstadoVivienda({
    required int idRegistro,
    required String tipoViviendaEtiqueta,
    required String estadoViviendaEtiqueta,
  }) async {
    final idTipo = await _idTipoViviendaEtiqueta(tipoViviendaEtiqueta);
    final idEst = await _idEstadoViviendaEtiqueta(estadoViviendaEtiqueta);
    await _client.from('registro_v').update({
      'id_tipo_v': idTipo,
      'id_estado_v': idEst,
    }).eq('id_registro', idRegistro);
  }

  /// Sustituye todos los pisos del registro (transacción lógica: borrar + insertar).
  Future<void> reemplazarPisos({
    required int idRegistro,
    required List<PisoDomicilioVista> pisos,
  }) async {
    await _client.from('piso_v').delete().eq('id_registro', idRegistro);
    for (final p in pisos) {
      final idMat = await _idMaterialPisoEtiqueta(p.materialPiso);
      await _client.from('piso_v').insert({
        'id_registro': idRegistro,
        'numerop': p.numerop,
        'id_mat_piso': idMat,
      });
    }
  }

  /// Renueva confirmación y fecha de expiración (1–24 meses desde hoy).
  Future<void> renovarPermanenciaMeses({
    required int idRegistro,
    required int meses,
  }) async {
    if (meses < 1 || meses > 24) {
      throw RegistroResidenteException('El período debe estar entre 1 y 24 meses.');
    }
    final hoy = _soloFecha(DateTime.now());
    final exp = _addCalendarMonths(hoy, meses);
    await _client.from('registro_v').update({
      'fecha_ult_confirm': _isoFecha(hoy),
      'fecha_expiracion': _isoFecha(exp),
    }).eq('id_registro', idRegistro);
  }

  /// Teléfono titular en `grupofamiliar` (formato `+56…` según CHECK).
  Future<void> actualizarTelefonoTitular({
    required int idGrupof,
    required String telefonoNormalizado,
  }) async {
    await _client.from('grupofamiliar').update({
      'telefono_titular': telefonoNormalizado,
    }).eq('id_grupof', idGrupof);
  }

  Future<CuentaConfigVista?> obtenerCuentaConfig() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final ctx = await contextoResidente();
    if (ctx == null) return null;

    final gf = await _client
        .from('grupofamiliar')
        .select('rut_titular, rut_dv, telefono_titular')
        .eq('id_grupof', ctx.idGrupof)
        .maybeSingle();
    if (gf == null) return null;

    final tit = await _client
        .from('integrante')
        .select('anio_nac')
        .eq('id_grupof', ctx.idGrupof)
        .eq('is_titular', true)
        .maybeSingle();

    Map<String, dynamic>? rv;
    if (ctx.idRegistro != null) {
      rv = await _client
          .from('registro_v')
          .select('fecha_ult_confirm, fecha_expiracion')
          .eq('id_registro', ctx.idRegistro!)
          .maybeSingle();
    }

    DateTime? fu;
    DateTime? fe;
    if (rv != null) {
      dynamic a = rv['fecha_ult_confirm'];
      dynamic b = rv['fecha_expiracion'];
      if (a is String) fu = DateTime.parse(a.split('T').first);
      if (b is String) fe = DateTime.parse(b.split('T').first);
    }

    return CuentaConfigVista(
      idGrupof: ctx.idGrupof,
      rutTitularNum: (gf['rut_titular'] as num).toInt(),
      rutDv: (gf['rut_dv'] as String).trim(),
      telefonoTitular: (gf['telefono_titular'] as String).trim(),
      email: user.email ?? '',
      anioNacTitular: tit == null ? null : (tit['anio_nac'] as num).toInt(),
      fechaUltConfirm: fu,
      fechaExpiracion: fe,
    );
  }

  /// Cierra el registro de vivienda vigente (no borra filas dependientes).
  Future<void> marcarRegistroNoVigente(int idRegistro) async {
    final hoy = _soloFecha(DateTime.now());
    await _client.from('registro_v').update({
      'vigente': false,
      'fecha_fin_r': _isoFecha(hoy),
    }).eq('id_registro', idRegistro);
  }
}
