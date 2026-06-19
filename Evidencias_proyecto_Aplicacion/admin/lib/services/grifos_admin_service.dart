import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grifo_list_item.dart';

class GrifosAdminService {
  GrifosAdminService(this._client);

  final SupabaseClient _client;

  Future<List<GrifoListItem>> listarGrifos() async {
    try {
      final raw = await _client
          .from('grifo')
          .select(
            'id_grifo, lat, lon, cut_com, comunas(comuna), '
            'info_grifo(id_reg_grifo, fecha_registro, nota_g, id_estado_gr, estado_grifo(estado_g), '
            'bombero(nomb_bombero, ape_p_bombero))',
          )
          .order('id_grifo');

      return raw.map(_mapListItem).whereType<GrifoListItem>().toList();
    } catch (_) {
      return _listarSinEmbedComuna();
    }
  }

  Future<List<GrifoListItem>> _listarSinEmbedComuna() async {
    try {
      final raw = await _client
          .from('grifo')
          .select(
            'id_grifo, lat, lon, cut_com, '
            'info_grifo(id_reg_grifo, fecha_registro, nota_g, id_estado_gr, estado_grifo(estado_g), '
            'bombero(nomb_bombero, ape_p_bombero))',
          )
          .order('id_grifo');

      final comunas = await _mapComunas(
        raw.map((r) => _asInt(r['cut_com'])).whereType<int>().toSet(),
      );

      return raw
          .map((row) {
            final item = _mapListItem(row);
            if (item == null) return null;
            final cut = _asInt(row['cut_com']);
            if (cut == null) return item;
            return GrifoListItem(
              idGrifo: item.idGrifo,
              lat: item.lat,
              lon: item.lon,
              comuna: comunas[cut] ?? item.comuna,
              estadoActual: item.estadoActual,
              cutCom: cut,
              idEstadoGr: item.idEstadoGr,
              registradoPor: item.registradoPor,
              notaActual: item.notaActual,
            );
          })
          .whereType<GrifoListItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<GrifoDetalle?> obtenerDetalle(int idGrifo) async {
    try {
      final row = await _client
          .from('grifo')
          .select(
            'id_grifo, lat, lon, cut_com, comunas(comuna), '
            'info_grifo(id_reg_grifo, fecha_registro, nota_g, id_estado_gr, estado_grifo(estado_g), '
            'bombero(nomb_bombero, ape_p_bombero))',
          )
          .eq('id_grifo', idGrifo)
          .maybeSingle();
      if (row == null) return null;

      final id = _asInt(row['id_grifo'])!;
      final lat = _asDouble(row['lat'])!;
      final lon = _asDouble(row['lon'])!;
      final cut = _asInt(row['cut_com'])!;

      var comuna = _nestedString(row['comunas'], 'comuna') ?? 'Comuna $cut';
      if (comuna == 'Comuna $cut') {
        try {
          final cRow = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
          comuna = (cRow?['comuna'] as String? ?? comuna).trim();
        } catch (_) {}
      }

      final historial = _historialDesde(row['info_grifo']);
      if (historial.isEmpty) {
        return GrifoDetalle(
          idGrifo: id,
          lat: lat,
          lon: lon,
          comuna: comuna,
          cutCom: cut,
          estadoActual: 'Sin registro',
          idEstadoGr: 4,
          fechaUltimoRegistro: '—',
          historial: const [],
        );
      }

      final ultimo = historial.first;
      return GrifoDetalle(
        idGrifo: id,
        lat: lat,
        lon: lon,
        comuna: comuna,
        cutCom: cut,
        estadoActual: ultimo.estado,
        idEstadoGr: ultimo.idEstadoGr,
        fechaUltimoRegistro: ultimo.fechaRegistro,
        notaActual: ultimo.nota,
        historial: historial,
      );
    } catch (_) {
      return null;
    }
  }

  GrifoListItem? _mapListItem(dynamic row) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);

    final id = _asInt(m['id_grifo']);
    final lat = _asDouble(m['lat']);
    final lon = _asDouble(m['lon']);
    if (id == null || lat == null || lon == null) return null;

    final cut = _asInt(m['cut_com']);
    var comuna = _nestedString(m['comunas'], 'comuna') ?? (cut != null ? 'Comuna $cut' : '—');

    final historial = _historialDesde(m['info_grifo']);
    if (historial.isEmpty) {
      return GrifoListItem(
        idGrifo: id,
        lat: lat,
        lon: lon,
        comuna: comuna,
        estadoActual: 'Sin registro',
        cutCom: cut,
      );
    }

    final ultimo = historial.first;
    return GrifoListItem(
      idGrifo: id,
      lat: lat,
      lon: lon,
      comuna: comuna,
      estadoActual: ultimo.estado,
      cutCom: cut,
      idEstadoGr: ultimo.idEstadoGr,
      registradoPor: ultimo.registradoPor,
      notaActual: ultimo.nota,
    );
  }

  List<InfoGrifoRegistro> _historialDesde(dynamic raw) {
    if (raw == null) return [];
    final lista = raw is List ? raw : [raw];
    final registros = <InfoGrifoRegistro>[];

    for (final item in lista) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final idReg = _asInt(m['id_reg_grifo']);
      final idEst = _asInt(m['id_estado_gr']);
      final fecha = _formatearFecha(m['fecha_registro']);
      if (idEst == null) continue;

      final estado = _nestedString(m['estado_grifo'], 'estado_g') ?? '—';
      final nota = (m['nota_g'] as String?)?.trim();
      final bombero = _nestedMap(m['bombero']);
      final registradoPor = bombero == null
          ? '—'
          : '${(bombero['nomb_bombero'] as String? ?? '').trim()} ${(bombero['ape_p_bombero'] as String? ?? '').trim()}'
              .trim();

      registros.add(
        InfoGrifoRegistro(
          idRegGrifo: idReg ?? 0,
          fechaRegistro: fecha,
          estado: estado,
          idEstadoGr: idEst,
          registradoPor: registradoPor.isEmpty ? '—' : registradoPor,
          nota: nota?.isNotEmpty == true ? nota : null,
        ),
      );
    }

    registros.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return registros;
  }

  Future<Map<int, String>> _mapComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    try {
      final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
      return {
        for (final row in raw)
          (row['cut_com'] as num).toInt(): (row['comuna'] as String).trim(),
      };
    } catch (_) {
      return {};
    }
  }

  String _formatearFecha(dynamic v) {
    if (v == null) return '—';
    if (v is String) return v.split('T').first;
    return v.toString();
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String? _nestedString(dynamic parent, String key) {
    final m = parent is Map ? _nestedMap(parent) : null;
    if (m == null) return null;
    return (m[key] as String?)?.trim();
  }
}
