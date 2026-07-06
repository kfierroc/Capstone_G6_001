import 'dashboard_desglose.dart';

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
    required this.registrosPorExpirar,
    required this.totalAlertas,
    required this.totalGruposFamiliares,
    required this.gruposConCuenta,
    required this.hogaresEstadoDeficiente,
    required this.bomberosAdministradores,
    required this.perfilEtario,
    required this.tiposVivienda,
    required this.estadosVivienda,
    required this.categoriasCondicion,
    required this.especiesMascota,
    required this.materialesPeligrososPorTipo,
    required this.materialesPiso,
    required this.estadosGrifo,
    this.etiquetaUbicacion = 'Todo Chile',
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
  final int registrosPorExpirar;
  final int totalAlertas;
  final String etiquetaUbicacion;

  final int totalGruposFamiliares;
  final int gruposConCuenta;
  final int hogaresEstadoDeficiente;
  final int bomberosAdministradores;
  final DashboardPerfilEtario perfilEtario;
  final List<DashboardDesglose> tiposVivienda;
  final List<DashboardDesglose> estadosVivienda;
  final List<DashboardDesglose> categoriasCondicion;
  final List<DashboardDesglose> especiesMascota;
  final List<DashboardDesglose> materialesPeligrososPorTipo;
  final List<DashboardDesglose> materialesPiso;
  final List<DashboardDesglose> estadosGrifo;

  int get gruposSinCuenta => totalGruposFamiliares - gruposConCuenta;

  double get promedioIntegrantesPorHogar =>
      totalHogares > 0 ? totalResidentes / totalHogares : 0;

  int get porcentajeCuentasVinculadas =>
      totalGruposFamiliares > 0 ? ((gruposConCuenta * 100) / totalGruposFamiliares).round() : 0;

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
    registrosPorExpirar: 0,
    totalAlertas: 0,
    totalGruposFamiliares: 0,
    gruposConCuenta: 0,
    hogaresEstadoDeficiente: 0,
    bomberosAdministradores: 0,
    perfilEtario: DashboardPerfilEtario.empty,
    tiposVivienda: [],
    estadosVivienda: [],
    categoriasCondicion: [],
    especiesMascota: [],
    materialesPeligrososPorTipo: [],
    materialesPiso: [],
    estadosGrifo: [],
  );
}
