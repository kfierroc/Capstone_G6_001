/// Filas de `condiciones` + `categ_condiciones` agrupadas para UI y registro.
class CondicionCatalogo {
  const CondicionCatalogo({
    required this.idCondicion,
    required this.tipoCondicion,
    required this.idCategC,
  });

  final int idCondicion;
  final String tipoCondicion;
  final int idCategC;
}

class CategoriaCondicion {
  const CategoriaCondicion({
    required this.idCategC,
    required this.categoriaC,
    required this.condiciones,
  });

  final int idCategC;
  final String categoriaC;
  final List<CondicionCatalogo> condiciones;
}
