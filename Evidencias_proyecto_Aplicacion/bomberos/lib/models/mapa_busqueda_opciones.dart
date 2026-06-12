/// Opciones de radio y límite para búsqueda en mapa.
class MapaBusquedaOpciones {
  MapaBusquedaOpciones._();

  static const int radioPorDefectoMetros = 1000;
  static const int limitePorDefecto = 10;

  static const List<int> radiosMetros = [100, 500, 1000, 2000, 5000, 10000, 20000];
  static const List<int> limitesResultados = [1, 3, 5, 10, 20, 30];

  static String etiquetaRadio(int metros) {
    if (metros >= 1000) {
      final km = metros / 1000;
      return km == km.roundToDouble() ? '${km.toInt()} km' : '$km km';
    }
    return '${metros}m';
  }
}
