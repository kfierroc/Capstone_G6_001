class IntegranteGrupo {
  const IntegranteGrupo({
    required this.idIntegrante,
    required this.etiqueta,
    required this.anioNac,
    required this.edad,
    required this.esTitular,
    this.rutMostrar,
    this.condiciones = const [],
    this.idsCondiciones = const [],
  });

  final int idIntegrante;
  final String etiqueta;
  final int anioNac;
  final int edad;
  final bool esTitular;
  final String? rutMostrar;
  final List<String> condiciones;
  final List<int> idsCondiciones;
}

class MascotaGrupo {
  const MascotaGrupo({
    required this.idMascota,
    required this.nombre,
    required this.especie,
    required this.tamanio,
    required this.idEspecie,
    required this.idTamanio,
  });

  final int idMascota;
  final String nombre;
  final String especie;
  final String tamanio;
  final int idEspecie;
  final int idTamanio;
}

class MaterialPeligrosoGrupo {
  const MaterialPeligrosoGrupo({
    required this.idMatPelig,
    required this.tipo,
    required this.cantidad,
  });

  final int idMatPelig;
  final String tipo;
  final int cantidad;
}

/// Datos de la cuenta del titular (grupofamiliar + auth).
class CuentaGrupoInfo {
  const CuentaGrupoInfo({
    required this.idGrupof,
    this.idIntegranteTitular,
    required this.rutFormateado,
    required this.telefono,
    required this.fechaCreacion,
    required this.cuentaVinculada,
    this.email,
    this.edadTitular,
    this.anioNacTitular,
  });

  final int idGrupof;
  final int? idIntegranteTitular;
  final String rutFormateado;
  final String telefono;
  final String fechaCreacion;
  final bool cuentaVinculada;
  final String? email;
  final int? edadTitular;
  final int? anioNacTitular;
}

/// Registro vigente de vivienda asociado al grupo.
class DomicilioGrupoInfo {
  const DomicilioGrupoInfo({
    required this.tieneRegistro,
    required this.vigente,
    required this.direccionCompleta,
    required this.comuna,
    required this.tipoVivienda,
    required this.estadoVivienda,
    required this.fechaInicio,
    required this.fechaUltConfirm,
    required this.fechaExpiracion,
    this.idRegistro,
    this.idResidencia,
    this.idTipoV,
    this.idEstadoV,
    this.cutCom,
    this.unidad,
    this.materialResidencia,
    this.idMatPiso,
    this.descDeptoCond,
    this.calle,
    this.nroDireccion,
    this.notas,
    this.lat,
    this.lon,
  });

  final bool tieneRegistro;
  final bool vigente;
  final String direccionCompleta;
  final String comuna;
  final String tipoVivienda;
  final String estadoVivienda;
  final String fechaInicio;
  final String fechaUltConfirm;
  final String fechaExpiracion;
  final int? idRegistro;
  final int? idResidencia;
  final int? idTipoV;
  final int? idEstadoV;
  final int? cutCom;
  final String? unidad;
  final String? materialResidencia;
  final int? idMatPiso;
  final String? descDeptoCond;
  final String? calle;
  final int? nroDireccion;
  final String? notas;
  final double? lat;
  final double? lon;

  bool get esDeptoOCondominio {
    final t = tipoVivienda.trim().toLowerCase();
    return t == 'departamento' || t == 'condominio';
  }

  static const sinRegistro = DomicilioGrupoInfo(
    tieneRegistro: false,
    vigente: false,
    direccionCompleta: '—',
    comuna: '—',
    tipoVivienda: '—',
    estadoVivienda: '—',
    fechaInicio: '—',
    fechaUltConfirm: '—',
    fechaExpiracion: '—',
  );
}

class GrupoFamiliarDetalle {
  const GrupoFamiliarDetalle({
    required this.idGrupof,
    required this.rutFormateado,
    required this.titularEtiqueta,
    required this.telefono,
    required this.direccion,
    required this.cuenta,
    required this.domicilio,
    required this.integrantes,
    required this.mascotas,
    required this.materiales,
  });

  final int idGrupof;
  final String rutFormateado;
  final String titularEtiqueta;
  final String telefono;
  final String direccion;
  final CuentaGrupoInfo cuenta;
  final DomicilioGrupoInfo domicilio;
  final List<IntegranteGrupo> integrantes;
  final List<MascotaGrupo> mascotas;
  final List<MaterialPeligrosoGrupo> materiales;

  int? get idRegistro => domicilio.idRegistro;
}
