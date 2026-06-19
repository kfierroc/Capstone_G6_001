import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.label,
    this.subtitle,
    this.foreignKeyId,
  });

  final int id;
  final String label;
  /// Texto auxiliar (p. ej. categoría de una condición).
  final String? subtitle;
  final int? foreignKeyId;
}

class AdminCatalogService {
  AdminCatalogService(this._client);

  final SupabaseClient _client;

  Future<List<CatalogItem>> tiposVivienda() => _load('tipo_vivienda', 'id_tipo_v', 'tipo_v');

  Future<List<CatalogItem>> estadosVivienda() => _load('estado_vivienda', 'id_estado_v', 'estado_v');

  Future<List<CatalogItem>> estadosGrifo() => _load('estado_grifo', 'id_estado_gr', 'estado_g');

  Future<List<CatalogItem>> especiesMascota() => _load('tipo_especie', 'id_especie', 'especie');

  Future<List<CatalogItem>> tamaniosMascota() => _load('tipo_tamanio', 'id_tamanio', 'tamanio');

  Future<List<CatalogItem>> materialesPeligrosos() => _load('tipo_mat_peligroso', 'id_mat_pelig', 'tipo_mat');

  Future<List<CatalogItem>> materialesPiso() => _load('tipo_mat_piso', 'id_mat_piso', 'material_piso');

  Future<List<CatalogItem>> condiciones() => _load('condiciones', 'id_condicion', 'tipo_condicion');

  Future<List<CatalogItem>> comunas() => _load('comunas', 'cut_com', 'comuna');

  Future<List<CatalogItem>> regiones() => _load('regiones', 'cut_reg', 'region');

  Future<List<CatalogItem>> companias() async {
    try {
      final raw = await _client.from('companias_bomberos').select('id_compania, nombre').order('nombre');
      return raw
          .map((r) => CatalogItem(
                id: (r['id_compania'] as num).toInt(),
                label: (r['nombre'] as String).trim(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CatalogItem>> _load(String tabla, String idCol, String labelCol) async {
    try {
      final raw = await _client.from(tabla).select('$idCol, $labelCol').order(idCol, ascending: true);
      return raw
          .map((r) => CatalogItem(
                id: (r[idCol] as num).toInt(),
                label: (r[labelCol] as String).trim(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
