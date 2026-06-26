import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bombero_list_item.dart';
import '../models/pagina_lista.dart';
import '../utils/rut_utils.dart';

class BomberosAdminService {
  BomberosAdminService(this._client);

  final SupabaseClient _client;

  Future<List<BomberoListItem>> listarBomberos() async {
    final pag = await listarBomberosPaginado(offset: 0, limit: 10000);
    return pag.items;
  }

  /// Página de bomberos (máx. [limit], por defecto 20).
  Future<PaginaLista<BomberoListItem>> listarBomberosPaginado({
    required int offset,
    int limit = kTamanoPaginaLista,
  }) async {
    try {
      return await _listarBomberosPagina(offset: offset, limit: limit, conEmbedComuna: true);
    } catch (_) {
      try {
        return await _listarBomberosPagina(offset: offset, limit: limit, conEmbedComuna: false);
      } catch (_) {
        return const PaginaLista(items: [], hayMas: false);
      }
    }
  }

  Future<PaginaLista<BomberoListItem>> _listarBomberosPagina({
    required int offset,
    required int limit,
    required bool conEmbedComuna,
  }) async {
    final pedido = limit + 1;
    final select = conEmbedComuna
        ? 'rut_num, rut_dv, nomb_bombero, ape_p_bombero, is_admin, user_id, '
            'companias_bomberos(nombre, id_compania, cut_com, comunas(comuna))'
        : 'rut_num, rut_dv, nomb_bombero, ape_p_bombero, is_admin, user_id, '
            'companias_bomberos(nombre, id_compania, cut_com)';

    final raw = await _client
        .from('bombero')
        .select(select)
        .order('ape_p_bombero')
        .order('nomb_bombero')
        .range(offset, offset + pedido - 1);

    final hayMas = raw.length > limit;
    final slice = hayMas ? raw.sublist(0, limit) : raw;

    if (conEmbedComuna) {
      final items = slice.map(_mapItem).whereType<BomberoListItem>().toList();
      return PaginaLista(items: items, hayMas: hayMas);
    }

    final comunas = await _mapComunas(
      slice
          .map((r) => _nestedMap(r['companias_bomberos'])?['cut_com'])
          .whereType<num>()
          .map((n) => n.toInt())
          .toSet(),
    );

    final items = slice
        .map((row) {
          final item = _mapItem(row);
          if (item == null) return null;
          final cut = _nestedInt(_nestedMap(row['companias_bomberos']), 'cut_com');
          if (cut == null) return item;
          return BomberoListItem(
            rutNum: item.rutNum,
            rutFormateado: item.rutFormateado,
            nombBombero: item.nombBombero,
            apePBombero: item.apePBombero,
            nombreCompleto: item.nombreCompleto,
            compania: item.compania,
            idCompania: item.idCompania,
            comuna: comunas[cut] ?? item.comuna,
            esAdmin: item.esAdmin,
            tieneCuenta: item.tieneCuenta,
          );
        })
        .whereType<BomberoListItem>()
        .toList();

    return PaginaLista(items: items, hayMas: hayMas);
  }

  BomberoListItem? _mapItem(dynamic row) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);

    final rutNum = _asInt(m['rut_num']);
    final dv = m['rut_dv'] as String?;
    if (rutNum == null || dv == null) return null;

    final nomb = (m['nomb_bombero'] as String? ?? '').trim();
    final ape = (m['ape_p_bombero'] as String? ?? '').trim();
    final companiaData = _nestedMap(m['companias_bomberos']);
    final compania = (companiaData?['nombre'] as String? ?? '—').trim();
    final idCompania = _asInt(companiaData?['id_compania']);

    var comuna = '—';
    final comunasNested = _nestedMap(companiaData?['comunas']);
    if (comunasNested != null) {
      comuna = (comunasNested['comuna'] as String? ?? '—').trim();
    }

    return BomberoListItem(
      rutNum: rutNum,
      rutFormateado: RutUtils.formatear(rutNum, dv),
      nombBombero: nomb,
      apePBombero: ape,
      nombreCompleto: '$nomb $ape'.trim(),
      compania: compania.isEmpty ? '—' : compania,
      idCompania: idCompania,
      comuna: comuna.isEmpty ? '—' : comuna,
      esAdmin: m['is_admin'] == true,
      tieneCuenta: m['user_id'] != null,
    );
  }

  Future<Map<int, String>> _mapComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    try {
      final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
      return {
        for (final r in raw)
          if (_asInt(r['cut_com']) != null) _asInt(r['cut_com'])!: (r['comuna'] as String).trim(),
      };
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  int? _nestedInt(Map<String, dynamic>? m, String key) {
    if (m == null) return null;
    return _asInt(m[key]);
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}
