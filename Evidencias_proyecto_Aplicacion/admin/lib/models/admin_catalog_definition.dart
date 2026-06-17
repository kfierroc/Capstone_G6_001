/// Definición de un catálogo administrable desde el panel.
class AdminCatalogDefinition {
  const AdminCatalogDefinition({
    required this.key,
    required this.titulo,
    required this.descripcion,
    required this.tabla,
    required this.idColumn,
    required this.labelColumn,
    required this.labelMaxLength,
    this.esCondicionesUnificadas = false,
  });

  final String key;
  final String titulo;
  final String descripcion;
  final String tabla;
  final String idColumn;
  final String labelColumn;
  final int labelMaxLength;
  /// Vista especial: categorías + condiciones en un solo panel.
  final bool esCondicionesUnificadas;
}

/// Catálogos que el admin puede gestionar (sin compañías, comunas, regiones ni provincias).
class AdminCatalogDefinitions {
  AdminCatalogDefinitions._();

  /// Tablas internas para CRUD de condiciones (no aparecen en el menú lateral).
  static const categCondiciones = AdminCatalogDefinition(
    key: 'categ_condiciones',
    titulo: 'Categorías de condiciones',
    descripcion: '',
    tabla: 'categ_condiciones',
    idColumn: 'id_categ_c',
    labelColumn: 'categoria_c',
    labelMaxLength: 30,
  );

  static const condiciones = AdminCatalogDefinition(
    key: 'condiciones',
    titulo: 'Condiciones',
    descripcion: '',
    tabla: 'condiciones',
    idColumn: 'id_condicion',
    labelColumn: 'tipo_condicion',
    labelMaxLength: 40,
  );

  static const List<AdminCatalogDefinition> todos = [
    AdminCatalogDefinition(
      key: 'tipos_vivienda',
      titulo: 'Tipos de vivienda',
      descripcion: 'Casa, departamento, condominio, etc.',
      tabla: 'tipo_vivienda',
      idColumn: 'id_tipo_v',
      labelColumn: 'tipo_v',
      labelMaxLength: 50,
    ),
    AdminCatalogDefinition(
      key: 'estados_vivienda',
      titulo: 'Estados de vivienda',
      descripcion: 'Estados del registro de vivienda.',
      tabla: 'estado_vivienda',
      idColumn: 'id_estado_v',
      labelColumn: 'estado_v',
      labelMaxLength: 50,
    ),
    AdminCatalogDefinition(
      key: 'especies_mascota',
      titulo: 'Especies de mascota',
      descripcion: 'Perro, gato, ave, etc.',
      tabla: 'tipo_especie',
      idColumn: 'id_especie',
      labelColumn: 'especie',
      labelMaxLength: 30,
    ),
    AdminCatalogDefinition(
      key: 'tamanios_mascota',
      titulo: 'Tamaños de mascota',
      descripcion: 'Pequeño, mediano, grande, etc.',
      tabla: 'tipo_tamanio',
      idColumn: 'id_tamanio',
      labelColumn: 'tamanio',
      labelMaxLength: 30,
    ),
    AdminCatalogDefinition(
      key: 'materiales_peligrosos',
      titulo: 'Materiales peligrosos',
      descripcion: 'Tipos de materiales peligrosos registrados en viviendas.',
      tabla: 'tipo_mat_peligroso',
      idColumn: 'id_mat_pelig',
      labelColumn: 'tipo_mat',
      labelMaxLength: 80,
    ),
    AdminCatalogDefinition(
      key: 'materiales_piso',
      titulo: 'Materiales de piso',
      descripcion: 'Materiales del primer piso de la residencia.',
      tabla: 'tipo_mat_piso',
      idColumn: 'id_mat_piso',
      labelColumn: 'material_piso',
      labelMaxLength: 50,
    ),
    AdminCatalogDefinition(
      key: 'condiciones_salud',
      titulo: 'Condiciones de salud',
      descripcion: 'Categorías y condiciones médicas asociadas.',
      tabla: '',
      idColumn: '',
      labelColumn: '',
      labelMaxLength: 0,
      esCondicionesUnificadas: true,
    ),
    AdminCatalogDefinition(
      key: 'estados_grifo',
      titulo: 'Estados de grifo',
      descripcion: 'Estados operativos de grifos.',
      tabla: 'estado_grifo',
      idColumn: 'id_estado_gr',
      labelColumn: 'estado_g',
      labelMaxLength: 50,
    ),
  ];

  static AdminCatalogDefinition? porKey(String key) {
    for (final d in todos) {
      if (d.key == key) return d;
    }
    if (key == categCondiciones.key) return categCondiciones;
    if (key == condiciones.key) return condiciones;
    return null;
  }
}
