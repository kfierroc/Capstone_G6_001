/// Valores iniciales del editor de ubicación (registro o gestión).
class UbicacionResidenciaInicial {
  const UbicacionResidenciaInicial({
    this.calle,
    this.nroDireccion,
    this.unidad,
    required this.lat,
    required this.lon,
    this.direccionYaCargada = false,
  });

  final String? calle;
  final int? nroDireccion;
  final String? unidad;
  final double lat;
  final double lon;

  /// Si ya hay calle y número guardados (edición o borrador rellenado).
  final bool direccionYaCargada;
}

/// Resultado al confirmar el formulario de ubicación.
class UbicacionResidenciaResultado {
  const UbicacionResidenciaResultado({
    required this.calle,
    required this.nroDireccion,
    this.unidad,
    required this.lat,
    required this.lon,
  });

  final String calle;
  final int nroDireccion;
  final String? unidad;
  final double lat;
  final double lon;
}
