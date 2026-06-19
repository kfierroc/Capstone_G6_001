/// Filtra ítems de listas admin por región/comuna (vía `cut_com`).
bool filtroUbicacion({
  required int? cutComItem,
  required int? cutRegFiltro,
  required int? cutComFiltro,
  required Map<int, int> comunaARegion,
}) {
  if (cutComFiltro != null) {
    return cutComItem == cutComFiltro;
  }
  if (cutRegFiltro != null) {
    if (cutComItem == null) return false;
    return comunaARegion[cutComItem] == cutRegFiltro;
  }
  return true;
}

/// Filtra por coincidencia parcial del ID numérico.
bool filtroId({required int id, required String idQuery}) {
  final q = idQuery.trim();
  if (q.isEmpty) return true;
  return id.toString().contains(q);
}
