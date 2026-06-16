class IntegranteGrupo {
  const IntegranteGrupo({
    required this.idIntegrante,
    required this.etiqueta,
    required this.edad,
    required this.esTitular,
    this.rutMostrar,
    this.condiciones = const [],
  });

  final int idIntegrante;
  final String etiqueta;
  final int edad;
  final bool esTitular;
  final String? rutMostrar;
  final List<String> condiciones;
}

class MascotaGrupo {
  const MascotaGrupo({
    required this.idMascota,
    required this.nombre,
    required this.especie,
    required this.tamanio,
  });

  final int idMascota;
  final String nombre;
  final String especie;
  final String tamanio;
}

class MaterialPeligrosoGrupo {
  const MaterialPeligrosoGrupo({
    required this.tipo,
    required this.cantidad,
  });

  final String tipo;
  final int cantidad;
}

/// Datos de la cuenta del titular (grupofamiliar + auth).
class CuentaGrupoInfo {
  const CuentaGrupoInfo({
    required this.rutFormateado,
    required this.telefono,
    required this.fechaCreacion,
    required this.cuentaVinculada,
    this.email,
    this.edadTitular,
  });

  final String rutFormateado;
  final String telefono;
  final String fechaCreacion;
  final bool cuentaVinculada;
  final String? email;
  final int? edadTitular;
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
    this.unidad,
    this.materialResidencia,
    this.descDeptoCond,
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
  final String? unidad;
  final String? materialResidencia;
  final String? descDeptoCond;
  final String? notas;
  final double? lat;
  final double? lon;

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
}
