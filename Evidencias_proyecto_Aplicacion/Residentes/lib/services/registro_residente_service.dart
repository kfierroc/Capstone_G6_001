import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../registro/registro_models.dart';

class RegistroResidenteException implements Exception {
  RegistroResidenteException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RegistroResidenteService {
  RegistroResidenteService(this._client);

  final SupabaseClient _client;

  /// Interpreta la respuesta de `obtener_comuna_por_coordenadas` (escalar, fila o lista de filas `RETURNS TABLE`).
  static int interpretarCutCom(dynamic raw) {
    if (raw == null) {
      throw RegistroResidenteException(
        'No se pudo determinar la comuna para las coordenadas.',
      );
    }
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    Map<String, dynamic>? comoMap(dynamic x) {
      if (x is Map<String, dynamic>) return x;
      if (x is Map) return Map<String, dynamic>.from(x);
      return null;
    }

    int? cutDesdeFila(Map<String, dynamic> row) {
      final v = row['cut_com'] ?? row['CUT_COM'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    if (raw is List) {
      if (raw.isEmpty) {
        throw RegistroResidenteException(
          'Las coordenadas no intersectan ninguna fila en la capa comunas (ST_Intersects sin resultado).',
        );
      }
      for (final item in raw) {
        final row = comoMap(item);
        final cut = row != null ? cutDesdeFila(row) : null;
        if (cut != null) return cut;
      }
    } else {
      final row = comoMap(raw);
      if (row != null) {
        final cut = cutDesdeFila(row);
        if (cut != null) return cut;
      }
    }

    throw RegistroResidenteException(
      'La RPC devolvió datos pero sin `cut_com` reconocible. Revisa la función y los permisos.',
    );
  }

  Future<int> obtenerCutCom(double lat, double lon) async {
    final nombre = dotenv.env['SUPABASE_RPC_NAME']?.trim();
    final pLat = dotenv.env['SUPABASE_RPC_PARAM_LAT']?.trim();
    final pLng = dotenv.env['SUPABASE_RPC_PARAM_LNG']?.trim();
    if (nombre == null || nombre.isEmpty || pLat == null || pLng == null) {
      throw RegistroResidenteException('Falta configurar SUPABASE_RPC_* en el archivo .env');
    }
    try {
      final raw = await _client.rpc(nombre, params: {pLat: lat, pLng: lon});
      return interpretarCutCom(raw);
    } on PostgrestException catch (e) {
      final code = e.code;
      final hint = e.hint ?? '';
      if (code == 'PGRST202' ||
          hint.contains('schema cache') ||
          e.message.toLowerCase().contains('could not find')) {
        throw RegistroResidenteException(
          'La función obtener_comuna_por_coordenadas no está disponible en Supabase (404 / PGRST202). '
          'Revísala en el SQL Editor y los permisos GRANT EXECUTE.',
        );
      }
      rethrow;
    }
  }

  /// Inserta el registro completo vía PostgREST (sin RPC propia). Requiere políticas RLS que permitan INSERT.
  Future<void> registrar(RegistroResidenteBorrador d) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw RegistroResidenteException('No hay sesión activa. Vuelve a iniciar sesión.');
    }
    if (d.rutNum == null ||
        d.rutDv == null ||
        d.telefonoNormalizado == null ||
        d.fechaNacimiento == null ||
        d.calle == null ||
        d.calle!.trim().isEmpty ||
        d.nroDireccion == null ||
        d.lat == null ||
        d.lon == null ||
        d.mesesTiempoResidencia == null ||
        d.tipoViviendaEtiqueta == null ||
        d.estadoViviendaEtiqueta == null) {
      throw RegistroResidenteException('Faltan datos obligatorios del formulario.');
    }

    if (d.pisos.isEmpty) {
      throw RegistroResidenteException('Debes registrar al menos un piso en la vivienda.');
    }

    final meses = d.mesesTiempoResidencia!;
    if (meses < 1 || meses > 6) {
      throw RegistroResidenteException('Los meses en la residencia deben estar entre 1 y 6.');
    }

    final existe = await _client.from('grupofamiliar').select('id_grupof').eq('user_id', uid).maybeSingle();
    if (existe != null) {
      throw RegistroResidenteException('Esta cuenta ya tiene un grupo familiar registrado.');
    }

    final idTipo = await _idTipoVivienda(d.tipoViviendaEtiqueta!.trim());
    final idEstado = await _idEstadoVivienda(d.estadoViviendaEtiqueta!.trim());
    final cutCom = await obtenerCutCom(d.lat!, d.lon!);

    final hoy = _soloFecha(DateTime.now());
    final fechaExp = _soloFecha(DateTime(DateTime.now().year, DateTime.now().month + meses, DateTime.now().day));
    final notas = _trunc(d.notasVivienda ?? '', 100);

    final idGf = await _siguienteId('grupofamiliar', 'id_grupof');
    final idRes = await _siguienteId('residencia', 'id_residencia');
    final idReg = await _siguienteId('registro_v', 'id_registro');
    final idInt = await _siguienteId('integrante', 'id_integrante');

    final unidadTrim = d.unidad?.trim();
    final unidadValor = (unidadTrim == null || unidadTrim.isEmpty) ? null : unidadTrim;

    try {
      await _client.from('grupofamiliar').insert({
        'id_grupof': idGf,
        'rut_titular': d.rutNum,
        'rut_dv': d.rutDv,
        'telefono_titular': d.telefonoNormalizado,
        'fecha_creacion': _isoFecha(hoy),
        'user_id': uid,
      });

      await _client.from('residencia').insert({
        'id_residencia': idRes,
        'calle': d.calle!.trim(),
        'nro_direccion': d.nroDireccion,
        'unidad': unidadValor,
        'lat': d.lat,
        'lon': d.lon,
        'geom_r': 'SRID=4326;POINT(${d.lon} ${d.lat})',
        'cut_com': cutCom,
      });

      await _client.from('registro_v').insert({
        'id_registro': idReg,
        'vigente': true,
        'id_estado_v': idEstado,
        'id_tipo_v': idTipo,
        'notas_v': notas.isEmpty ? null : notas,
        'fecha_ult_confirm': _isoFecha(hoy),
        'fecha_expiracion': _isoFecha(fechaExp),
        'fecha_ini_r': _isoFecha(hoy),
        'fecha_fin_r': null,
        'id_residencia': idRes,
        'id_grupof': idGf,
      });

      await _client.from('integrante').insert({
        'id_integrante': idInt,
        'is_titular': true,
        'anio_nac': d.fechaNacimiento!.year,
        'activo_i': true,
        'fecha_ini_i': _isoFecha(hoy),
        'fecha_fin_i': null,
        'id_grupof': idGf,
      });

      final padecimientosVistos = <String>{};
      for (final cond in d.condicionesMedicas) {
        final c = cond.trim();
        if (c.isEmpty) continue;
        final clave = _trunc(c, 46);
        if (!padecimientosVistos.add(clave)) continue;
        await _client.from('padecimiento').insert({
          'padecimiento': clave,
          'fecha_ini_p': _isoFecha(hoy),
          'durabilidad': 365,
          'fecha_fin_p': null,
          'id_integrante': idInt,
        });
      }

      for (final p in d.pisos) {
        final idMat = await _idMaterialPiso(p.materialEtiqueta.trim());
        await _client.from('piso_v').insert({
          'numerop': p.numerop,
          'id_mat_piso': idMat,
          'id_registro': idReg,
        });
      }
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('duplicate') || msg.contains('unique') || msg.contains('23505')) {
        throw RegistroResidenteException('Ya existe un registro que entra en conflicto (RUT, usuario o clave duplicada).');
      }
      throw RegistroResidenteException(msg);
    }
  }

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

  Future<int> _idTipoVivienda(String etiqueta) async {
    final row = await _client.from('tipo_vivienda').select('id_tipo_v').eq('tipo_v', etiqueta).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Tipo de vivienda no encontrado en la base: $etiqueta');
    }
    return (row['id_tipo_v'] as num).toInt();
  }

  Future<int> _idEstadoVivienda(String etiqueta) async {
    final row = await _client.from('estado_vivienda').select('id_estado_v').eq('estado_v', etiqueta).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Estado de vivienda no encontrado en la base: $etiqueta');
    }
    return (row['id_estado_v'] as num).toInt();
  }

  Future<int> _idMaterialPiso(String material) async {
    final row =
        await _client.from('tipo_mat_piso').select('id_mat_piso').eq('material_piso', material).maybeSingle();
    if (row == null) {
      throw RegistroResidenteException('Material de piso no encontrado en la base: $material');
    }
    return (row['id_mat_piso'] as num).toInt();
  }
}
