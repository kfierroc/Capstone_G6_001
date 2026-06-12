import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_stats.dart';

/// Consultas agregadas para el dashboard admin.
class DashboardService {
  DashboardService(this._client);

  final SupabaseClient _client;

  Future<DashboardStats> cargarEstadisticas() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0);
    final desde = _formatoFecha(inicioMes);
    final hasta = _formatoFecha(finMes);

    final resultados = await Future.wait<int>([
      _contarActivos('integrante', 'fecha_fin_i'),
      _contarEnRango('integrante', 'fecha_ini_i', desde, hasta),
      _contar('registro_v', eq: {'vigente': true}),
      _contarEnRango('grupofamiliar', 'fecha_creacion', desde, hasta),
      _contar('bombero'),
      _contarCompanias(),
      _contar('grifo'),
      _contarGrifosAtencion(),
      _contar('mascota'),
      _sumarMaterialesPeligrosos(),
      _contar('condiciones_integ'),
      _contarRegistrosPorExpirar(),
    ]);

    final grifosAtencion = resultados[7];
    final registrosPorExpirar = resultados[11];

    return DashboardStats(
      totalResidentes: resultados[0],
      residentesEsteMes: resultados[1],
      totalHogares: resultados[2],
      hogaresEsteMes: resultados[3],
      totalBomberos: resultados[4],
      totalCompanias: resultados[5],
      totalGrifos: resultados[6],
      grifosRequierenAtencion: grifosAtencion,
      totalMascotas: resultados[8],
      totalMaterialesPeligrosos: resultados[9],
      totalCondicionesMedicas: resultados[10],
      totalAlertas: grifosAtencion + registrosPorExpirar,
    );
  }

  String _formatoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> _contar(String tabla, {Map<String, dynamic>? eq}) async {
    try {
      var query = _client.from(tabla).select('*');
      if (eq != null) {
        for (final entry in eq.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarActivos(String tabla, String columnaFin) async {
    try {
      final res = await _client.from(tabla).select('*').isFilter(columnaFin, null).count(CountOption.exact);
      return res.count;
    } catch (_) {
      return _contar(tabla);
    }
  }

  Future<int> _contarEnRango(String tabla, String columna, String desde, String hasta) async {
    try {
      final res = await _client
          .from(tabla)
          .select('*')
          .gte(columna, desde)
          .lte(columna, hasta)
          .count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarCompanias() async {
    try {
      final raw = await _client.from('bombero').select('id_compania');
      final ids = raw.map((r) => r['id_compania']).whereType<num>().map((n) => n.toInt()).toSet();
      return ids.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarGrifosAtencion() async {
    try {
      final estados = await _client.from('estado_grifo').select('id_estado_gr, estado_g');
      final idsAtencion = estados
          .where((e) {
            final estado = (e['estado_g'] as String? ?? '').toLowerCase();
            return estado.contains('dañado') ||
                estado.contains('danado') ||
                estado.contains('mantenimiento');
          })
          .map((e) => (e['id_estado_gr'] as num).toInt())
          .toList();
      if (idsAtencion.isEmpty) return 0;

      final res = await _client
          .from('info_grifo')
          .select('id_grifo')
          .inFilter('id_estado_gr', idsAtencion)
          .count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _sumarMaterialesPeligrosos() async {
    try {
      final raw = await _client.from('mat_peligroso').select('cantidad');
      var total = 0;
      for (final row in raw) {
        final c = row['cantidad'];
        if (c is num) total += c.toInt();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarRegistrosPorExpirar() async {
    try {
      final limite = _formatoFecha(DateTime.now().add(const Duration(days: 30)));
      final hoy = _formatoFecha(DateTime.now());
      final res = await _client
          .from('registro_v')
          .select('*')
          .eq('vigente', true)
          .gte('fecha_expiracion', hoy)
          .lte('fecha_expiracion', limite)
          .count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }
}
