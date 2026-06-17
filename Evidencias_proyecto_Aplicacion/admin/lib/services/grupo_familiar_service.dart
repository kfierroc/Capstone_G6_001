import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grupo_familiar_detalle.dart';
import '../models/grupo_familiar_list_item.dart';
import '../utils/rut_utils.dart';

class GrupoFamiliarService {
  GrupoFamiliarService(this._client);

  final SupabaseClient _client;

  Future<List<GrupoFamiliarListItem>> listarGrupos() async {
    try {
      final raw = await _client
          .from('grupofamiliar')
          .select(
            'id_grupof, rut_titular, rut_dv, telefono_titular, fecha_creacion, '
            'registro_v(vigente, unidad, desc_depto_cond, residencia(calle, nro_direccion))',
          )
          .order('fecha_creacion', ascending: false);

      return raw.map(_mapListItem).whereType<GrupoFamiliarListItem>().toList();
    } catch (_) {
      return [];
    }
  }

  GrupoFamiliarListItem? _mapListItem(dynamic row) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);

    final id = _asInt(m['id_grupof']);
    final rutNum = _asInt(m['rut_titular']);
    final dv = m['rut_dv'] as String?;
    if (id == null || rutNum == null || dv == null) return null;

    final rut = RutUtils.formatear(rutNum, dv);
    final telefono = (m['telefono_titular'] as String? ?? '').trim();
    final fecha = _formatearFecha(m['fecha_creacion']);
    final direccion = _direccionDesdeRegistros(m['registro_v']);
    final vigente = _tieneRegistroVigente(m['registro_v']);

    return GrupoFamiliarListItem(
      idGrupof: id,
      rutFormateado: rut,
      telefono: telefono.isEmpty ? '—' : telefono,
      direccion: direccion.isEmpty ? '—' : direccion,
      fechaRegistro: fecha,
      registroVigente: vigente,
    );
  }

  Future<GrupoFamiliarDetalle?> obtenerDetalle(int idGrupof) async {
    try {
      final gf = await _client
          .from('grupofamiliar')
          .select(
            'id_grupof, rut_titular, rut_dv, telefono_titular, fecha_creacion, user_id, '
            'registro_v('
            'id_registro, vigente, unidad, desc_depto_cond, notas_v, '
            'fecha_ini_r, fecha_ult_confirm, fecha_expiracion, '
            'id_tipo_v, id_estado_v, '
            'residencia(id_residencia, calle, nro_direccion, lat, lon, cut_com)'
            ')',
          )
          .eq('id_grupof', idGrupof)
          .maybeSingle();
      if (gf == null) return null;

      final rutNum = _asInt(gf['rut_titular'])!;
      final dv = (gf['rut_dv'] as String).trim();
      final rut = RutUtils.formatear(rutNum, dv);
      final telefono = (gf['telefono_titular'] as String? ?? '').trim();

      final integrantes = await _cargarIntegrantes(idGrupof, rutNum, dv);
      final mascotas = await _cargarMascotas(idGrupof);

      final registroVigente = _registroVigenteMap(gf['registro_v']);
      final idRegistro = registroVigente != null ? _asInt(registroVigente['id_registro']) : null;
      final materiales = idRegistro != null ? await _cargarMateriales(idRegistro) : <MaterialPeligrosoGrupo>[];
      final pisos = idRegistro != null ? await _cargarPisos(idRegistro) : <PisoViviendaGrupo>[];

      final titularIntegrante = integrantes.where((i) => i.esTitular);
      final titularRow = titularIntegrante.isEmpty ? null : titularIntegrante.first;
      final titular = titularRow?.etiqueta ?? 'Titular del grupo';

      final domicilio = await _cargarDomicilio(registroVigente);
      final cuenta = CuentaGrupoInfo(
        idGrupof: idGrupof,
        idIntegranteTitular: titularRow?.idIntegrante,
        rutFormateado: rut,
        telefono: telefono.isEmpty ? '—' : telefono,
        fechaCreacion: _formatearFecha(gf['fecha_creacion']),
        cuentaVinculada: gf['user_id'] != null,
        email: await _obtenerEmail(gf['user_id'] as String?),
        edadTitular: titularRow?.edad,
        anioNacTitular: titularRow?.anioNac,
      );

      return GrupoFamiliarDetalle(
        idGrupof: idGrupof,
        rutFormateado: rut,
        titularEtiqueta: titular,
        telefono: telefono.isEmpty ? '—' : telefono,
        direccion: domicilio.direccionCompleta == '—' ? 'Sin domicilio registrado' : domicilio.direccionCompleta,
        cuenta: cuenta,
        domicilio: domicilio,
        integrantes: integrantes,
        mascotas: mascotas,
        materiales: materiales,
        pisos: pisos,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _obtenerEmail(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    try {
      final row = await _client.from('usuarios_residente').select('email').eq('user_id', userId).maybeSingle();
      return (row?['email'] as String?)?.trim();
    } catch (_) {
      // Sin vista expuesta: el email no está disponible vía PostgREST con anon key.
      return null;
    }
  }

  Future<DomicilioGrupoInfo> cargarDomicilioDesdeRegistro(
    Map<String, dynamic> registro, {
    required Map<String, dynamic> residencia,
  }) async {
    return _cargarDomicilio({...registro, 'residencia': residencia});
  }

  Future<DomicilioGrupoInfo> _cargarDomicilio(Map<String, dynamic>? rv) async {
    if (rv == null) return DomicilioGrupoInfo.sinRegistro;

    final res = _nestedMap(rv['residencia']);
    if (res == null) return DomicilioGrupoInfo.sinRegistro;

    final calle = res['calle'] as String?;
    final nro = _asInt(res['nro_direccion']);
    if (calle == null || nro == null) return DomicilioGrupoInfo.sinRegistro;

    final cut = _asInt(res['cut_com']);
    var comuna = '—';
    if (cut != null) {
      try {
        final row = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
        comuna = (row?['comuna'] as String? ?? 'Comuna $cut').trim();
      } catch (_) {
        comuna = 'Comuna $cut';
      }
    }

    final unidad = (rv['unidad'] as String?)?.trim();
    final descDepto = (rv['desc_depto_cond'] as String?)?.trim();
    final idRegistro = _asInt(rv['id_registro']);
    final idResidencia = _asInt(res['id_residencia']);

    final idTipo = _asInt(rv['id_tipo_v']);
    final idEst = _asInt(rv['id_estado_v']);
    final tipoV = idTipo != null ? await _etiquetaCatalogo('tipo_vivienda', 'id_tipo_v', idTipo, 'tipo_v') : '—';
    final estadoV = idEst != null ? await _etiquetaCatalogo('estado_vivienda', 'id_estado_v', idEst, 'estado_v') : '—';

    final materialData = idRegistro != null ? await _materialesResidenciaData(idRegistro) : (null, null);
    final materialResidencia = materialData.$1;
    final idMatPiso = materialData.$2;

    final partes = <String>['$calle $nro'];
    if (unidad != null && unidad.isNotEmpty) {
      partes.add(unidad);
    }
    partes.add(comuna);

    final lat = _asDouble(res['lat']);
    final lon = _asDouble(res['lon']);

    return DomicilioGrupoInfo(
      tieneRegistro: true,
      vigente: rv['vigente'] == true,
      direccionCompleta: partes.join(', '),
      comuna: comuna,
      tipoVivienda: tipoV,
      estadoVivienda: estadoV,
      fechaInicio: _formatearFecha(rv['fecha_ini_r']),
      fechaUltConfirm: _formatearFecha(rv['fecha_ult_confirm']),
      fechaExpiracion: _formatearFecha(rv['fecha_expiracion']),
      idRegistro: idRegistro,
      idResidencia: idResidencia,
      idTipoV: idTipo,
      idEstadoV: idEst,
      cutCom: cut,
      unidad: unidad?.isNotEmpty == true ? unidad : null,
      materialResidencia: materialResidencia?.isNotEmpty == true ? materialResidencia : null,
      idMatPiso: idMatPiso,
      descDeptoCond: _esDeptoOCondominio(tipoV) && descDepto != null && descDepto.isNotEmpty ? descDepto : null,
      calle: calle,
      nroDireccion: nro,
      notas: (rv['notas_v'] as String?)?.trim(),
      lat: lat,
      lon: lon,
    );
  }

  Future<String> _etiquetaCatalogo(String tabla, String idCol, int id, String labelCol) async {
    try {
      final row = await _client.from(tabla).select(labelCol).eq(idCol, id).maybeSingle();
      return (row?[labelCol] as String? ?? '—').trim();
    } catch (_) {
      return '—';
    }
  }

  Future<(String?, int?)> _materialesResidenciaData(int idRegistro) async {
    try {
      final raw = await _client
          .from('piso_v')
          .select('numerop, id_mat_piso, tipo_mat_piso(material_piso)')
          .eq('id_registro', idRegistro)
          .order('numerop');

      if (raw.isEmpty) return (null, null);

      final partes = <String>[];
      int? firstMatId;
      for (final row in raw) {
        final material = _nestedString(row['tipo_mat_piso'], 'material_piso');
        final idMat = _asInt(row['id_mat_piso']);
        firstMatId ??= idMat;
        if (material == null || material.isEmpty) continue;
        final piso = _asInt(row['numerop']);
        if (piso != null) {
          partes.add('Piso $piso: $material');
        } else {
          partes.add(material);
        }
      }
      return (partes.isEmpty ? null : partes.join(' · '), firstMatId);
    } catch (_) {
      return (null, null);
    }
  }

  Future<List<PisoViviendaGrupo>> _cargarPisos(int idRegistro) async {
    try {
      final raw = await _client
          .from('piso_v')
          .select('numerop, id_mat_piso, tipo_mat_piso(material_piso)')
          .eq('id_registro', idRegistro)
          .order('numerop');

      return raw.map((row) {
        final numerop = _asInt(row['numerop'])!;
        final idMat = _asInt(row['id_mat_piso'])!;
        final material = _nestedString(row['tipo_mat_piso'], 'material_piso') ?? '—';
        return PisoViviendaGrupo(numerop: numerop, idMatPiso: idMat, material: material);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  bool _esDeptoOCondominio(String tipoVivienda) {
    final t = tipoVivienda.trim().toLowerCase();
    return t == 'departamento' || t == 'condominio';
  }

  Map<String, dynamic>? _registroVigenteMap(dynamic registrosRaw) {
    for (final rv in _normalizarLista(registrosRaw)) {
      if (rv['vigente'] == true) return rv;
    }
    return null;
  }

  bool _tieneRegistroVigente(dynamic registrosRaw) => _registroVigenteMap(registrosRaw) != null;

  Future<List<IntegranteGrupo>> _cargarIntegrantes(int idGrupof, int rutNum, String dv) async {
    final raw = await _client
        .from('integrante')
        .select('id_integrante, is_titular, anio_nac')
        .eq('id_grupof', idGrupof)
        .isFilter('fecha_fin_i', null)
        .order('is_titular', ascending: false)
        .order('id_integrante');

    if (raw.isEmpty) return [];

    final ids = raw.map((r) => _asInt(r['id_integrante'])!).toList();
    final condData = await _condicionesPorIntegrante(ids);
    final anioActual = DateTime.now().year;
    var nNoTitular = 0;

    return raw.map((r) {
      final idI = _asInt(r['id_integrante'])!;
      final titular = r['is_titular'] == true;
      final anio = _asInt(r['anio_nac']) ?? anioActual;
      final edad = anioActual - anio;

      late final String etiqueta;
      if (titular) {
        etiqueta = 'Titular del domicilio';
      } else {
        nNoTitular++;
        etiqueta = 'Persona $nNoTitular';
      }

      return IntegranteGrupo(
        idIntegrante: idI,
        etiqueta: etiqueta,
        anioNac: anio,
        edad: edad,
        esTitular: titular,
        rutMostrar: titular ? RutUtils.formatear(rutNum, dv) : null,
        condiciones: condData.textos[idI] ?? const [],
        idsCondiciones: condData.ids[idI] ?? const [],
      );
    }).toList();
  }

  Future<({Map<int, List<int>> ids, Map<int, List<String>> textos})> _condicionesPorIntegrante(
    List<int> ids,
  ) async {
    if (ids.isEmpty) {
      return (ids: <int, List<int>>{}, textos: <int, List<String>>{});
    }
    final raw = await _client
        .from('condiciones_integ')
        .select('id_integrante, id_condicion, observacion, condiciones(tipo_condicion)')
        .inFilter('id_integrante', ids);

    final idsMap = <int, List<int>>{};
    final textosMap = <int, List<String>>{};
    for (final row in raw) {
      final idI = _asInt(row['id_integrante']);
      final idCond = _asInt(row['id_condicion']);
      if (idI == null) continue;
      if (idCond != null) {
        idsMap.putIfAbsent(idI, () => []).add(idCond);
      }
      var texto = _nestedString(row['condiciones'], 'tipo_condicion') ?? '';
      final obs = row['observacion'] as String?;
      if (obs != null && obs.isNotEmpty) {
        texto = texto.isEmpty ? obs : '$texto - $obs';
      }
      if (texto.isNotEmpty) {
        textosMap.putIfAbsent(idI, () => []).add(texto);
      }
    }
    return (ids: idsMap, textos: textosMap);
  }

  Future<List<MascotaGrupo>> _cargarMascotas(int idGrupof) async {
    final raw = await _client
        .from('mascota')
        .select('id_mascota, nombre_m, id_especie, id_tamanio')
        .eq('id_grupof', idGrupof)
        .order('id_mascota');
    if (raw.isEmpty) return [];

    final especies = await _mapCatalogo('tipo_especie', 'id_especie', 'especie');
    final tamanios = await _mapCatalogo('tipo_tamanio', 'id_tamanio', 'tamanio');

    return raw.map((r) {
      final idE = _asInt(r['id_especie']);
      final idT = _asInt(r['id_tamanio']);
      return MascotaGrupo(
        idMascota: _asInt(r['id_mascota']) ?? 0,
        nombre: (r['nombre_m'] as String? ?? 'Sin nombre').trim(),
        especie: idE != null ? (especies[idE] ?? '—') : '—',
        tamanio: idT != null ? (tamanios[idT] ?? '—') : '—',
        idEspecie: idE ?? 0,
        idTamanio: idT ?? 0,
      );
    }).toList();
  }

  Future<List<MaterialPeligrosoGrupo>> _cargarMateriales(int idRegistro) async {
    final raw = await _client
        .from('mat_peligroso')
        .select('cantidad, id_mat_pelig, tipo_mat_peligroso(tipo_mat)')
        .eq('id_registro', idRegistro);

    return raw.map((r) {
      final idMat = _asInt(r['id_mat_pelig']) ?? 0;
      final tipo = _nestedString(r['tipo_mat_peligroso'], 'tipo_mat') ?? 'Material';
      final cant = _asInt(r['cantidad']) ?? 0;
      return MaterialPeligrosoGrupo(idMatPelig: idMat, tipo: tipo, cantidad: cant);
    }).toList();
  }

  Future<Map<int, String>> _mapCatalogo(String tabla, String idCol, String labelCol) async {
    final raw = await _client.from(tabla).select('$idCol, $labelCol');
    final out = <int, String>{};
    for (final r in raw) {
      final id = _asInt(r[idCol]);
      final label = r[labelCol] as String?;
      if (id != null && label != null) out[id] = label.trim();
    }
    return out;
  }

  String _direccionDesdeRegistros(dynamic registrosRaw) {
    final lista = _normalizarLista(registrosRaw);
    for (final rv in lista) {
      if (rv['vigente'] != true) continue;
      final res = rv['residencia'];
      if (res is! Map) continue;
      final calle = res['calle'] as String?;
      final nro = _asInt(res['nro_direccion']);
      if (calle == null || nro == null) continue;

      final partes = <String>['$calle $nro'];
      final unidad = rv['unidad'] as String?;
      if (unidad != null && unidad.isNotEmpty) {
        partes.add(unidad);
      }
      return partes.join(', ');
    }
    return '';
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (raw is Map) return [Map<String, dynamic>.from(raw)];
    return [];
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String? _nestedString(dynamic nested, String key) {
    if (nested is Map) return nested[key] as String?;
    return null;
  }

  double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  String _formatearFecha(dynamic v) {
    if (v == null) return '—';
    if (v is String) return v.split('T').first;
    if (v is DateTime) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    return v.toString();
  }
}
