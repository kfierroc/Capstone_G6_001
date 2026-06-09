import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/residencia_busqueda.dart';
import '../utils/supabase_parse.dart';

class BusquedaResidenciaException implements Exception {
  BusquedaResidenciaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Búsqueda de residencias con [registro_v] vigente y no expirado.
class BusquedaResidenciaService {
  BusquedaResidenciaService(this._client);

  final SupabaseClient _client;

  static String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseFecha(dynamic v) {
    if (v is String) return DateTime.parse(v.split('T').first);
    return DateTime.now();
  }

  Future<List<ResidenciaBusquedaResultado>> buscarActivas(String termino) async {
    final t = termino.trim();
    final hoy = _fechaHoy();

    try {
      var query = _client
          .from('registro_v')
          .select(
            'id_registro, id_residencia, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, '
            'residencia(id_residencia, calle, nro_direccion, cut_com)',
          )
          .eq('vigente', true)
          .gte('fecha_expiracion', hoy);

      if (t.isNotEmpty) {
        query = query.filter('residencia.calle', 'ilike', '%$t%');
      }

      final raw = await query.order('fecha_ult_confirm', ascending: false).limit(25);
      final filas = List<Map<String, dynamic>>.from(raw as List);
      if (filas.isEmpty) return [];

      final cuts = <int>{};
      for (final rv in filas) {
        final res = SupabaseParse.asMap(rv['residencia']);
        final cut = SupabaseParse.asInt(res?['cut_com']);
        if (cut != null) cuts.add(cut);
      }

      final comunasPorCut = await _mapaComunas(cuts);
      final grupos = filas
          .map((r) => SupabaseParse.asInt(r['id_grupof']))
          .whereType<int>()
          .toSet()
          .toList();
      final personasPorGrupo = await _conteoIntegrantes(grupos);
      final mascotasPorGrupo = await _conteoMascotas(grupos);

      final resultados = <ResidenciaBusquedaResultado>[];
      for (final rv in filas) {
        final res = SupabaseParse.asMap(rv['residencia']);
        if (res == null) continue;

        final idReg = SupabaseParse.asInt(rv['id_registro']);
        final idRes = SupabaseParse.asInt(rv['id_residencia']) ?? SupabaseParse.asInt(res['id_residencia']);
        final idGf = SupabaseParse.asInt(rv['id_grupof']);
        final cut = SupabaseParse.asInt(res['cut_com']);
        final calle = SupabaseParse.asString(res['calle']);
        final nro = SupabaseParse.asInt(res['nro_direccion']);
        if (idReg == null || idRes == null || idGf == null || cut == null || calle == null || nro == null) {
          continue;
        }

        final comuna = comunasPorCut[cut] ?? 'Comuna $cut';
        final unidad = SupabaseParse.asString(rv['unidad']);
        final descDepto = SupabaseParse.asString(rv['desc_depto_cond']);

        resultados.add(
          ResidenciaBusquedaResultado(
            idRegistro: idReg,
            idResidencia: idRes,
            idGrupof: idGf,
            direccionCompleta: _formatearDireccion(
              calle: calle,
              nro: nro,
              unidad: unidad,
              descDepto: descDepto,
              comuna: comuna,
            ),
            cantidadPersonas: personasPorGrupo[idGf] ?? 0,
            cantidadMascotas: mascotasPorGrupo[idGf] ?? 0,
            fechaUltimaActualizacion: _parseFecha(rv['fecha_ult_confirm']),
          ),
        );
      }
      return resultados;
    } on FormatException catch (e) {
      throw BusquedaResidenciaException(e.message);
    } on PostgrestException catch (e) {
      throw BusquedaResidenciaException(e.message);
    }
  }

  Future<Map<int, String>> _mapaComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
    final map = <int, String>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final cut = SupabaseParse.asInt(row['cut_com']);
      final nombre = SupabaseParse.asString(row['comuna']);
      if (cut != null && nombre != null) map[cut] = nombre;
    }
    return map;
  }

  Future<Map<int, int>> _conteoIntegrantes(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client
        .from('integrante')
        .select('id_grupof')
        .inFilter('id_grupof', idGrupos)
        .isFilter('fecha_fin_i', null);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, int>> _conteoMascotas(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client.from('mascota').select('id_grupof').inFilter('id_grupof', idGrupos);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  static String _formatearDireccion({
    required String calle,
    required int nro,
    String? unidad,
    String? descDepto,
    required String comuna,
  }) {
    final partes = <String>['$calle $nro'];
    if (unidad != null && unidad.isNotEmpty) {
      partes.add(unidad);
    } else if (descDepto != null && descDepto.isNotEmpty) {
      partes.add(descDepto);
    }
    partes.addAll([comuna, 'Santiago']);
    return partes.join(', ');
  }
}
