import '../widgets/admin_lista_filtros_ubicacion.dart';

/// Parámetros de filtro región/comuna/ID para consultas paginadas.
({int? cutCom, List<int>? cutComsRegion, int? idExacto}) parametrosFiltroUbicacion({
  required AdminListaFiltrosUbicacionState? filtros,
  required String idText,
}) {
  final idExacto = idText.trim().isEmpty ? null : int.tryParse(idText.trim());
  final cutCom = filtros?.cutComFiltro;
  List<int>? cutComsRegion;
  if (cutCom == null && filtros?.cutRegFiltro != null) {
    final reg = filtros!.cutRegFiltro!;
    cutComsRegion = filtros.comunaARegion.entries
        .where((e) => e.value == reg)
        .map((e) => e.key)
        .toList();
  }
  return (cutCom: cutCom, cutComsRegion: cutComsRegion, idExacto: idExacto);
}

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
