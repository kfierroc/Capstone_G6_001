/// Item resumido para la tabla de grupos familiares.
class GrupoFamiliarListItem {
  const GrupoFamiliarListItem({
    required this.idGrupof,
    required this.rutFormateado,
    required this.telefono,
    required this.direccion,
    required this.fechaRegistro,
    required this.registroVigente,
  });

  final int idGrupof;
  final String rutFormateado;
  final String telefono;
  final String direccion;
  final String fechaRegistro;
  /// `true` si tiene un `registro_v` vigente asociado a una residencia.
  final bool registroVigente;

  String get estadoEtiqueta => registroVigente ? 'Vigente' : 'Sin domicilio';

  bool coincideConBusqueda(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return rutFormateado.toLowerCase().contains(q) ||
        telefono.toLowerCase().contains(q) ||
        direccion.toLowerCase().contains(q) ||
        estadoEtiqueta.toLowerCase().contains(q);
  }
}
