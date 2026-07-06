/// Ítem de un desglose analítico (etiqueta + cantidad).
class DashboardDesglose {
  const DashboardDesglose({
    required this.etiqueta,
    required this.cantidad,
  });

  final String etiqueta;
  final int cantidad;
}

/// Perfil etario de integrantes activos.
class DashboardPerfilEtario {
  const DashboardPerfilEtario({
    required this.menores,
    required this.adultos,
    required this.adultosMayores,
  });

  final int menores;
  final int adultos;
  final int adultosMayores;

  int get total => menores + adultos + adultosMayores;

  static const empty = DashboardPerfilEtario(menores: 0, adultos: 0, adultosMayores: 0);
}
