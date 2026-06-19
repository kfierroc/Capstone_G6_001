/// Formateo de RUT chileno.
abstract final class RutUtils {
  static String formatear(int rutNum, String dv) {
    var s = rutNum.toString();
    final partes = <String>[];
    while (s.length > 3) {
      partes.add(s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    if (s.isNotEmpty) partes.add(s);
    return '${partes.reversed.join('.')}-${dv.toUpperCase()}';
  }

  static String normalizarParaBusqueda(String texto) =>
      texto.replaceAll('.', '').replaceAll('-', '').toLowerCase().trim();
}
