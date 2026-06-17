import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_catalog_definition.dart';
import '../models/condiciones_catalogo_admin.dart';
import 'admin_catalog_crud_service.dart';

class CondicionesCatalogoAdminService {
  CondicionesCatalogoAdminService(this._client);

  final SupabaseClient _client;
  AdminCatalogCrudService get _crud => AdminCatalogCrudService(_client);

  static AdminCatalogDefinition get _categ => AdminCatalogDefinitions.categCondiciones;
  static AdminCatalogDefinition get _cond => AdminCatalogDefinitions.condiciones;

  Future<List<CategoriaCondicionAdmin>> listarAgrupado() async {
    try {
      final rawCats = await _client
          .from(_categ.tabla)
          .select('${_categ.idColumn}, ${_categ.labelColumn}')
          .order(_categ.idColumn, ascending: true);
      final rawConds = await _client
          .from(_cond.tabla)
          .select('${_cond.idColumn}, ${_cond.labelColumn}, id_categ_c')
          .order(_cond.idColumn, ascending: true);

      final porCategoria = <int, List<CondicionAdminItem>>{};
      for (final row in rawConds) {
        final idCat = (row['id_categ_c'] as num).toInt();
        porCategoria.putIfAbsent(idCat, () => []).add(
              CondicionAdminItem(
                idCondicion: (row[_cond.idColumn] as num).toInt(),
                tipoCondicion: (row[_cond.labelColumn] as String).trim(),
                idCategC: idCat,
              ),
            );
      }

      return rawCats
          .map((row) {
            final id = (row[_categ.idColumn] as num).toInt();
            return CategoriaCondicionAdmin(
              idCategC: id,
              categoriaC: (row[_categ.labelColumn] as String).trim(),
              condiciones: List<CondicionAdminItem>.from(porCategoria[id] ?? const []),
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> crearCategoria(String nombre) => _crud.crear(_categ, nombre);

  Future<void> actualizarCategoria(int id, String nombre) => _crud.actualizar(_categ, id, nombre);

  Future<void> eliminarCategoria(int id) => _crud.eliminar(_categ, id);

  Future<void> crearCondicion({required int idCategC, required String nombre}) =>
      _crud.crear(_cond, nombre, foreignKeyId: idCategC);

  Future<void> actualizarCondicion({
    required int idCondicion,
    required int idCategC,
    required String nombre,
  }) =>
      _crud.actualizar(_cond, idCondicion, nombre, foreignKeyId: idCategC);

  Future<void> eliminarCondicion(int idCondicion) => _crud.eliminar(_cond, idCondicion);
}
