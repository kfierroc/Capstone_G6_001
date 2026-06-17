import '../models/grupo_familiar_detalle.dart';

/// Item resumido para la tabla de residencias.
class ResidenciaListItem {
  const ResidenciaListItem({
    required this.idResidencia,
    required this.direccion,
    required this.comuna,
    required this.registroVigente,
    required this.tieneGrupoVinculado,
  });

  final int idResidencia;
  final String direccion;
  final String comuna;
  final bool registroVigente;
  final bool tieneGrupoVinculado;

  String get estadoEtiqueta => registroVigente ? 'Vigente' : 'Sin registro vigente';

  String get grupoEtiqueta => tieneGrupoVinculado ? 'Vinculado' : 'Sin grupo';

  bool coincideConBusqueda(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return direccion.toLowerCase().contains(q) ||
        comuna.toLowerCase().contains(q) ||
        idResidencia.toString().contains(q) ||
        estadoEtiqueta.toLowerCase().contains(q) ||
        grupoEtiqueta.toLowerCase().contains(q);
  }
}

/// Detalle de residencia para el panel admin.
class ResidenciaAdminDetalle {
  const ResidenciaAdminDetalle({
    required this.idResidencia,
    required this.calle,
    required this.nroDireccion,
    required this.cutCom,
    required this.direccionCorta,
    required this.comuna,
    required this.lat,
    required this.lon,
    required this.grupoDetalle,
    required this.domicilio,
  });

  final int idResidencia;
  final String calle;
  final int nroDireccion;
  final int? cutCom;
  final String direccionCorta;
  final String comuna;
  final double? lat;
  final double? lon;
  /// Si hay grupo vinculado al registro vigente, contiene el mismo detalle que Grupo Familiar.
  final GrupoFamiliarDetalle? grupoDetalle;
  /// Info de registro/domicilio cuando no hay grupo o como respaldo.
  final DomicilioGrupoInfo domicilio;

  bool get tieneGrupoVinculado => grupoDetalle != null;
}
