import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/residencia_busqueda.dart';

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
            'id_registro, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, '
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
        final res = rv['residencia'];
        if (res is Map<String, dynamic>) {
          cuts.add((res['cut_com'] as num).toInt());
        }
      }

      final comunasPorCut = await _mapaComunas(cuts);
      final grupos = filas.map((r) => (r['id_grupof'] as num).toInt()).toSet().toList();
      final personasPorGrupo = await _conteoIntegrantes(grupos);
      final mascotasPorGrupo = await _conteoMascotas(grupos);

      final resultados = <ResidenciaBusquedaResultado>[];
      for (final rv in filas) {
        final res = rv['residencia'];
        if (res is! Map<String, dynamic>) continue;

        final idRes = (res['id_residencia'] as num).toInt();
        final cut = (res['cut_com'] as num).toInt();
        final comuna = comunasPorCut[cut] ?? 'Comuna $cut';
        final calle = (res['calle'] as String).trim();
        final nro = (res['nro_direccion'] as num).toInt();
        final unidad = (rv['unidad'] as String?)?.trim();
        final descDepto = (rv['desc_depto_cond'] as String?)?.trim();
        final idGf = (rv['id_grupof'] as num).toInt();

        resultados.add(
          ResidenciaBusquedaResultado(
            idRegistro: (rv['id_registro'] as num).toInt(),
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
    } on PostgrestException catch (e) {
      throw BusquedaResidenciaException(e.message);
    }
  }

  Future<Map<int, String>> _mapaComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
    final map = <int, String>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      map[(row['cut_com'] as num).toInt()] = (row['comuna'] as String).trim();
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
      final id = (row['id_grupof'] as num).toInt();
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, int>> _conteoMascotas(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client.from('mascota').select('id_grupof').inFilter('id_grupof', idGrupos);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = (row['id_grupof'] as num).toInt();
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
