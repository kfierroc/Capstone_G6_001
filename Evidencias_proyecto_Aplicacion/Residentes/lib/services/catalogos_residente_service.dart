import 'package:supabase_flutter/supabase_flutter.dart';

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
