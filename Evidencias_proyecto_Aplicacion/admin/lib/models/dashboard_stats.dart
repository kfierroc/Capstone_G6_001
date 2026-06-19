/// Estadísticas agregadas para el dashboard del panel admin.
class DashboardStats {
  const DashboardStats({
    required this.totalResidentes,
    required this.residentesEsteMes,
    required this.totalHogares,
    required this.hogaresEsteMes,
    required this.totalBomberos,
    required this.totalCompanias,
    required this.totalGrifos,
    required this.grifosRequierenAtencion,
    required this.totalMascotas,
    required this.totalMaterialesPeligrosos,
    required this.totalCondicionesMedicas,
    required this.totalAlertas,
  });

  final int totalResidentes;
  final int residentesEsteMes;
  final int totalHogares;
  final int hogaresEsteMes;
  final int totalBomberos;
  final int totalCompanias;
  final int totalGrifos;
  final int grifosRequierenAtencion;
  final int totalMascotas;
  final int totalMaterialesPeligrosos;
  final int totalCondicionesMedicas;
  final int totalAlertas;

  static const empty = DashboardStats(
    totalResidentes: 0,
    residentesEsteMes: 0,
    totalHogares: 0,
    hogaresEsteMes: 0,
    totalBomberos: 0,
    totalCompanias: 0,
    totalGrifos: 0,
    grifosRequierenAtencion: 0,
    totalMascotas: 0,
    totalMaterialesPeligrosos: 0,
    totalCondicionesMedicas: 0,
    totalAlertas: 0,
  );
}
