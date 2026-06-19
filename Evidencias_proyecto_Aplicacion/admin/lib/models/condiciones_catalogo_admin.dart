/// Condición médica del catálogo admin.
class CondicionAdminItem {
  const CondicionAdminItem({
    required this.idCondicion,
    required this.tipoCondicion,
    required this.idCategC,
  });

  final int idCondicion;
  final String tipoCondicion;
  final int idCategC;
}

/// Categoría con sus condiciones agrupadas.
class CategoriaCondicionAdmin {
  const CategoriaCondicionAdmin({
    required this.idCategC,
    required this.categoriaC,
    required this.condiciones,
  });

  final int idCategC;
  final String categoriaC;
  final List<CondicionAdminItem> condiciones;
}
