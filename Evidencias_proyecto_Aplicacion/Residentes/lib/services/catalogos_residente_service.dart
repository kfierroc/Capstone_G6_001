import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/condiciones_catalogo.dart';

/// Opciones de desplegables leídas desde las tablas de catálogo en Supabase.
class CatalogosResidenteService {
  CatalogosResidenteService(this._client);

  final SupabaseClient _client;

  Future<List<String>> tiposVivienda() async {
    final raw = await _client.from('tipo_vivienda').select('tipo_v').order('id_tipo_v');
    return _columnasTexto(_asRows(raw), 'tipo_v');
  }

  Future<List<String>> estadosVivienda() async {
    final raw = await _client.from('estado_vivienda').select('estado_v').order('id_estado_v');
    return _columnasTexto(_asRows(raw), 'estado_v');
  }

  Future<List<String>> materialesPiso() async {
    final raw = await _client.from('tipo_mat_piso').select('material_piso').order('id_mat_piso');
    return _columnasTexto(_asRows(raw), 'material_piso');
  }

  /// Categorías (`categ_condiciones`) con sus condiciones (`condiciones`).
  Future<List<CategoriaCondicion>> condicionesPorCategoria() async {
    final rawCats = await _client.from('categ_condiciones').select('id_categ_c, categoria_c').order('id_categ_c');
    final rawConds =
        await _client.from('condiciones').select('id_condicion, tipo_condicion, id_categ_c').order('id_condicion');
    final cats = _asRows(rawCats);
    final conds = _asRows(rawConds);
    final porCategoria = <int, List<CondicionCatalogo>>{};
    for (final row in conds) {
      final idCat = (row['id_categ_c'] as num).toInt();
      porCategoria.putIfAbsent(idCat, () => []).add(
            CondicionCatalogo(
              idCondicion: (row['id_condicion'] as num).toInt(),
              tipoCondicion: (row['tipo_condicion'] as String).trim(),
              idCategC: idCat,
            ),
          );
    }
    final out = <CategoriaCondicion>[];
    for (final row in cats) {
      final id = (row['id_categ_c'] as num).toInt();
      final nombre = (row['categoria_c'] as String).trim();
      out.add(
        CategoriaCondicion(
          idCategC: id,
          categoriaC: nombre,
          condiciones: List<CondicionCatalogo>.from(porCategoria[id] ?? const []),
        ),
      );
    }
    return out;
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  List<String> _columnasTexto(List<Map<String, dynamic>> rows, String key) {
    final out = <String>[];
    for (final row in rows) {
      final v = row[key];
      if (v is String && v.trim().isNotEmpty) {
        out.add(v.trim());
      }
    }
    return out;
  }
}
