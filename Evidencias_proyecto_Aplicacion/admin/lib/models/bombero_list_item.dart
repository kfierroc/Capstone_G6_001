import '../utils/rut_utils.dart';

/// Item resumido para la tabla de bomberos.
class BomberoListItem {
  const BomberoListItem({
    required this.rutNum,
    required this.rutFormateado,
    required this.nombreCompleto,
    required this.compania,
    required this.comuna,
    required this.esAdmin,
    required this.tieneCuenta,
  });

  final int rutNum;
  final String rutFormateado;
  final String nombreCompleto;
  final String compania;
  final String comuna;
  final bool esAdmin;
  final bool tieneCuenta;

  bool coincideConBusqueda(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final rutNorm = RutUtils.normalizarParaBusqueda(rutFormateado);
    final qNorm = RutUtils.normalizarParaBusqueda(q);
    return nombreCompleto.toLowerCase().contains(q) ||
        rutFormateado.toLowerCase().contains(q) ||
        rutNorm.contains(qNorm) ||
        compania.toLowerCase().contains(q) ||
        comuna.toLowerCase().contains(q) ||
        (esAdmin && q.contains('admin'));
  }
}
