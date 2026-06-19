import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_catalog_definition.dart';
import 'admin_catalog_service.dart';

class AdminCatalogCrudException implements Exception {
  AdminCatalogCrudException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AdminCatalogCrudService {
  AdminCatalogCrudService(this._client);

  final SupabaseClient _client;

  String _trunc(String s, int max) => s.length <= max ? s : s.substring(0, max);

  Future<int> _siguienteId(AdminCatalogDefinition def) async {
    final rows = await _client
        .from(def.tabla)
        .select(def.idColumn)
        .order(def.idColumn, ascending: false)
        .limit(1);
    if (rows.isEmpty) return 1;
    final v = rows.first[def.idColumn];
    if (v is num) return v.toInt() + 1;
    return 1;
  }

  Future<List<CatalogItem>> listar(AdminCatalogDefinition def) async {
    if (def.esCondicionesUnificadas || def.tabla.isEmpty) return [];
    try {
      final raw = await _client
          .from(def.tabla)
          .select('${def.idColumn}, ${def.labelColumn}')
          .order(def.idColumn, ascending: true);

      return raw
          .map(
            (r) => CatalogItem(
              id: (r[def.idColumn] as num).toInt(),
              label: (r[def.labelColumn] as String).trim(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> crear(AdminCatalogDefinition def, String label, {int? foreignKeyId}) async {
    final texto = _trunc(label.trim(), def.labelMaxLength);
    if (texto.isEmpty) throw AdminCatalogCrudException('El nombre no puede estar vacío.');

    final id = await _siguienteId(def);
    final payload = <String, dynamic>{def.idColumn: id, def.labelColumn: texto};

    if (def.key == AdminCatalogDefinitions.condiciones.key) {
      if (foreignKeyId == null) throw AdminCatalogCrudException('Selecciona una categoría.');
      payload['id_categ_c'] = foreignKeyId;
    }

    await _client.from(def.tabla).insert(payload);
  }

  Future<void> actualizar(
    AdminCatalogDefinition def,
    int id,
    String label, {
    int? foreignKeyId,
  }) async {
    final texto = _trunc(label.trim(), def.labelMaxLength);
    if (texto.isEmpty) throw AdminCatalogCrudException('El nombre no puede estar vacío.');

    final payload = <String, dynamic>{def.labelColumn: texto};
    if (def.key == AdminCatalogDefinitions.condiciones.key) {
      if (foreignKeyId == null) throw AdminCatalogCrudException('Selecciona una categoría.');
      payload['id_categ_c'] = foreignKeyId;
    }

    await _client.from(def.tabla).update(payload).eq(def.idColumn, id);
  }

  Future<void> eliminar(AdminCatalogDefinition def, int id) async {
    try {
      await _client.from(def.tabla).delete().eq(def.idColumn, id);
    } catch (_) {
      throw AdminCatalogCrudException(
        'No se pudo eliminar. Puede estar en uso por registros existentes.',
      );
    }
  }
}
