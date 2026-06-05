import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogosBomberoService {
  CatalogosBomberoService(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  Future<List<({int cutReg, String nombre})>> regiones() async {
    final raw = await _client.from('regiones').select('cut_reg, region').order('region');
    final out = <({int cutReg, String nombre})>[];
    for (final row in _asRows(raw)) {
      out.add((
        cutReg: (row['cut_reg'] as num).toInt(),
        nombre: (row['region'] as String).trim(),
      ));
    }
    return out;
  }

  /// Comunas cuya provincia pertenece a la región [cutReg].
  Future<List<({int cutCom, String nombre})>> comunasPorRegion(int cutReg) async {
    final rawProv = await _client.from('provincias').select('cut_prov').eq('cut_reg', cutReg);
    final provs = _asRows(rawProv);
    if (provs.isEmpty) return [];
    final ids = provs.map((e) => (e['cut_prov'] as num).toInt()).toList();
    final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_prov', ids).order('comuna');
    final out = <({int cutCom, String nombre})>[];
    for (final row in _asRows(raw)) {
      out.add((
        cutCom: (row['cut_com'] as num).toInt(),
        nombre: (row['comuna'] as String).trim(),
      ));
    }
    return out;
  }

  Future<List<({int id, String nombre})>> companiasPorComuna(int cutCom) async {
    final raw = await _client
        .from('companias_bomberos')
        .select('id_compania, nombre')
        .eq('cut_com', cutCom)
        .order('nombre');
    final out = <({int id, String nombre})>[];
    for (final row in _asRows(raw)) {
      final id = row['id_compania'];
      final nombre = row['nombre'];
      if (id == null || nombre == null) continue;
      out.add((id: (id as num).toInt(), nombre: (nombre as String).trim()));
    }
    return out;
  }
}
