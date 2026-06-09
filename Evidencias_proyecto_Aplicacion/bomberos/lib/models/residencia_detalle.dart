class MaterialPeligrosoDetalle {
  MaterialPeligrosoDetalle({required this.tipo, required this.cantidad, this.notas});

  final String tipo;
  final int cantidad;
  final String? notas;
}

class PersonaDetalle {
  PersonaDetalle({
    required this.etiqueta,
    required this.edad,
    required this.esTitular,
    this.rutMostrar,
    required this.condiciones,
  });

  final String etiqueta;
  final int edad;
  final bool esTitular;
  final String? rutMostrar;
  final List<String> condiciones;
}

class MascotaDetalle {
  MascotaDetalle({required this.nombre, required this.especie, required this.tamano});

  final String nombre;
  final String especie;
  final String tamano;
}

/// Vista completa de un domicilio para operaciones de emergencia.
class ResidenciaDetalle {
  ResidenciaDetalle({
    required this.idRegistro,
    required this.idResidencia,
    required this.direccionCompleta,
    required this.tipoVivienda,
    required this.estadoVivienda,
    required this.materialDepartamento,
    required this.instruccionesEspeciales,
    required this.fechaUltimaActualizacion,
    required this.telefonoTitular,
    required this.cantidadPersonas,
    required this.cantidadMascotas,
    required this.cantidadConCondiciones,
    required this.cantidadMaterialesPeligrosos,
    required this.materialesPeligrosos,
    required this.personas,
    required this.mascotas,
    required this.lat,
    required this.lon,
  });

  final int idRegistro;
  final int idResidencia;
  final String direccionCompleta;
  final String tipoVivienda;
  final String estadoVivienda;
  final String materialDepartamento;
  final String? instruccionesEspeciales;
  final DateTime fechaUltimaActualizacion;
  final String telefonoTitular;
  final int cantidadPersonas;
  final int cantidadMascotas;
  final int cantidadConCondiciones;
  final int cantidadMaterialesPeligrosos;
  final List<MaterialPeligrosoDetalle> materialesPeligrosos;
  final List<PersonaDetalle> personas;
  final List<MascotaDetalle> mascotas;
  final double lat;
  final double lon;

  String get fechaUltimaFormateada {
    final y = fechaUltimaActualizacion.year;
    final m = fechaUltimaActualizacion.month.toString().padLeft(2, '0');
    final d = fechaUltimaActualizacion.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
