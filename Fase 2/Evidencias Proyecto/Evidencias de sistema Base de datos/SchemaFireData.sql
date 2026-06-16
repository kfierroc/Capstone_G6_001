

CREATE TABLE residencia (
  id_residencia INTEGER PRIMARY KEY NOT NULL,
  calle VARCHAR(150) NOT NULL,
  nro_direccion INTEGER NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lon DOUBLE PRECISION NOT NULL,
  geom_r GEOGRAPHY(POINT, 4326)
    GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::GEOGRAPHY
    ) STORED,
  CUT_COM INTEGER NOT NULL REFERENCES comunas(CUT_COM)
);


CREATE TABLE grupofamiliar(
  id_grupof INTEGER PRIMARY KEY NOT NULL,
  rut_titular INTEGER NOT NULL,
  rut_dv CHAR(1) NOT NULL,
  telefono_titular VARCHAR(13) NOT NULL,
  CHECK (telefono_titular ~ '^\+56[2-9][0-9]{8}$'),
  fecha_creacion DATE NOT NULL,
  user_id UUID UNIQUE REFERENCES auth.users(id)
);

CREATE TABLE tipo_vivienda(
  id_tipo_v INTEGER PRIMARY KEY NOT NULL,
  tipo_v VARCHAR(30) NOT NULL
);


CREATE TABLE estado_vivienda(
  id_estado_v INTEGER PRIMARY KEY NOT NULL,
  estado_v VARCHAR(20) NOT NULL
);


CREATE TABLE registro_v (
  id_registro INTEGER PRIMARY KEY NOT NULL,
  vigente BOOLEAN NOT NULL,
  id_estado_v INTEGER NOT NULL REFERENCES estado_vivienda(id_estado_v),
  id_tipo_v INTEGER NOT NULL REFERENCES tipo_vivienda(id_tipo_v),
  unidad VARCHAR(20),
  desc_depto_cond VARCHAR(50),
  notas_v varchar(100),
  fecha_ult_confirm DATE NOT NULL,
  fecha_expiracion DATE NOT NULL,
  fecha_ini_r DATE NOT NULL,
  fecha_fin_r DATE,
  id_residencia INTEGER NOT NULL REFERENCES residencia(id_residencia),
  id_grupof INTEGER NOT NULL REFERENCES grupofamiliar(id_grupof),

  CONSTRAINT chk_expiracion
  CHECK (fecha_expiracion >= fecha_ult_confirm),

  CONSTRAINT chk_inicio_confirm
  CHECK (fecha_ini_r <= fecha_ult_confirm),

  CONSTRAINT chk_inicio_expiracion
  CHECK (fecha_ini_r <= fecha_expiracion),

  CONSTRAINT chk_vigencia_fechas
  CHECK (
    (vigente = TRUE AND fecha_fin_r IS NULL)
    OR
    (vigente = FALSE AND fecha_fin_r IS NOT NULL)
  )
);

CREATE TABLE tipo_mat_piso(
  id_mat_piso INTEGER PRIMARY KEY NOT NULL,
  material_piso VARCHAR(20) NOT NULL
);


CREATE TABLE piso_v (
  numerop INTEGER NOT NULL,
  id_mat_piso INTEGER NOT NULL REFERENCES tipo_mat_piso(id_mat_piso),
  id_registro INTEGER NOT NULL REFERENCES registro_v(id_registro),
  PRIMARY KEY (id_registro, numerop)
);


CREATE TABLE tipo_mat_peligroso(
  id_mat_pelig INTEGER PRIMARY KEY NOT NULL,
  tipo_mat VARCHAR(30) NOT NULL
);


CREATE TABLE mat_peligroso(
  cantidad INTEGER NOT NULL,
  id_mat_pelig INTEGER NOT NULL REFERENCES tipo_mat_peligroso(id_mat_pelig),
  id_registro INTEGER NOT NULL REFERENCES registro_v(id_registro),
  PRIMARY KEY (id_registro, id_mat_pelig)
);


CREATE TABLE integrante(
  id_integrante INTEGER PRIMARY KEY NOT NULL,
  is_titular BOOLEAN NOT NULL,
  anio_nac INTEGER NOT NULL,
  fecha_ini_i DATE NOT NULL,
  fecha_fin_i DATE,
  id_grupof INTEGER NOT NULL REFERENCES grupofamiliar(id_grupof),


  CONSTRAINT chk_anio_nac
  CHECK (
    anio_nac <= EXTRACT(YEAR FROM CURRENT_DATE)
    AND (
      (is_titular = TRUE AND 
        (EXTRACT(YEAR FROM CURRENT_DATE) - anio_nac) BETWEEN 16 AND 120)
      OR
      (is_titular = FALSE AND 
        (EXTRACT(YEAR FROM CURRENT_DATE) - anio_nac) BETWEEN 1 AND 120)
    )
  )
);


CREATE TABLE categ_condiciones(
  id_categ_c INTEGER PRIMARY KEY NOT NULL,
  categoria_c VARCHAR(30) NOT NULL
);

CREATE TABLE condiciones(
  id_condicion INTEGER PRIMARY KEY NOT NULL,
  tipo_condicion VARCHAR(40) NOT NULL,
  id_categ_c INTEGER NOT NULL REFERENCES categ_condiciones(id_categ_c)
);

CREATE TABLE condiciones_integ(
  id_integrante INTEGER NOT NULL REFERENCES integrante(id_integrante),
  id_condicion INTEGER NOT NULL REFERENCES condiciones(id_condicion),
  observacion VARCHAR(100),

  PRIMARY KEY (id_integrante, id_condicion)
);


CREATE TABLE tipo_especie(
  id_especie INTEGER PRIMARY KEY NOT NULL,
  especie VARCHAR(30) NOT NULL
);


CREATE TABLE tipo_tamanio(
  id_tamanio INTEGER PRIMARY KEY NOT NULL,
  tamanio VARCHAR(30) NOT NULL
);


CREATE TABLE mascota(
  id_mascota INTEGER PRIMARY KEY NOT NULL,
  nombre_m VARCHAR(30) NOT NULL,
  fecha_reg_m DATE NOT NULL,
  id_especie INTEGER NOT NULL REFERENCES tipo_especie(id_especie),
  id_tamanio INTEGER NOT NULL REFERENCES tipo_tamanio(id_tamanio),
  id_grupof INTEGER NOT NULL REFERENCES grupofamiliar(id_grupof)
);

CREATE TABLE grifo (
  id_grifo INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
  lat DECIMAL(12,6) NOT NULL,
  lon DECIMAL(12,6) NOT NULL,
  geom_g GEOGRAPHY(POINT, 4326)
      GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::GEOGRAPHY
    ) STORED,
  CUT_COM INTEGER NOT NULL REFERENCES comunas(CUT_COM)
);

CREATE TABLE bombero (
  rut_num INTEGER PRIMARY KEY NOT NULL,
  rut_dv CHAR(1) NOT NULL,
  nomb_bombero VARCHAR(50) NOT NULL,
  ape_p_bombero VARCHAR(50) NOT NULL,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  user_id UUID UNIQUE REFERENCES auth.users(id),
  id_compania INTEGER NOT NULL REFERENCES companias_bomberos(id_compania),

  CONSTRAINT uq_rut UNIQUE (rut_num, rut_dv)
);

CREATE TABLE estado_grifo(
  id_estado_gr INTEGER PRIMARY KEY NOT NULL,
  estado_g VARCHAR(15) NOT NULL
);


CREATE TABLE info_grifo (
  id_reg_grifo INTEGER GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
  id_grifo INTEGER NOT NULL REFERENCES grifo(id_grifo),
  fecha_registro DATE NOT NULL,
  nota_g varchar(100),
  id_estado_gr INTEGER NOT NULL REFERENCES estado_grifo(id_estado_gr),
  rut_num INTEGER NOT NULL REFERENCES bombero(rut_num)
);



---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

CREATE TABLE companias_bomberos (
    id_compania SERIAL PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL,
    direccion TEXT,
    telefono TEXT,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    geometry GEOMETRY(POINT, 4326)
    GENERATED ALWAYS AS (
        ST_SetSRID(
            ST_MakePoint(longitud, latitud),
            4326
        )
    ) STORED,
    cut_com INTEGER NOT NULL REFERENCES comunas(cut_com)
);


CREATE TABLE comunas (
    cut_com INTEGER PRIMARY KEY NOT NULL,
    comuna TEXT NOT NULL,
    superficie DECIMAL(10,2) NOT NULL,
    geometry geometry(MULTIPOLYGON, 4326) NOT NULL,
    cut_prov INTEGER NOT NULL REFERENCES provincias(cut_prov)
);
CREATE TABLE provincias (
    cut_prov INTEGER PRIMARY KEY NOT NULL,
    provincia TEXT NOT NULL,
    cut_reg INTEGER NOT NULL REFERENCES regiones(cut_reg)
);

CREATE TABLE regiones (
    cut_reg INTEGER PRIMARY KEY NOT NULL,
    region TEXT NOT NULL
);

------------------------------------------------------------------------
------------------------------------------------------------------------

INSERT INTO tipo_vivienda (id_tipo_v, tipo_v) VALUES
(1, 'Casa'),
(2, 'Departamento'),
(3, 'Empresa'),
(4, 'Local'),
(5, 'Comercial'),
(6, 'Oficina'),
(7, 'Bodega'),
(8, 'Otro');



INSERT INTO estado_vivienda (id_estado_v, estado_v) VALUES
(1, 'Excelente'),
(2, 'Bueno'),
(3, 'Regular'),
(4, 'Malo'),
(5, 'Muy malo');



INSERT INTO tipo_mat_piso (id_mat_piso, material_piso) VALUES
(1, 'Hormigón'),
(2, 'Ladrillo'),
(3, 'Madera'),
(4, 'Metal'),
(5, 'Prefabricado'),
(6, 'Adobe'),
(7, 'Bloque'),
(8, 'Panel sip'),
(9, 'Yeso-cartón'),
(10, 'Otro');



INSERT INTO tipo_mat_peligroso (id_mat_pelig, tipo_mat) VALUES
(1, 'Balón de gas'),
(2, 'Combustible líquido'),
(3, 'Parafina'),
(4, 'Generador eléctrico'),
(5, 'Oxígeno medicinal'),
(6, 'Aerosoles inflamables'),
(7, 'Químicos domésticos'),
(8, 'Pinturas y solventes'),
(9, 'Material inflamable sólido'),
(10, 'Baterías'),
(11, 'Acidos/quimicos potentes'),
(12, 'Otro');



INSERT INTO tipo_especie (id_especie, especie) VALUES
(1, 'Perro'),
(2, 'Gato'),
(3, 'Ave'),
(4, 'Roedor'),
(5, 'Conejo'),
(6, 'Pez'),
(7, 'Reptil'),
(8, 'Anfibio'),
(9, 'Hurón'),
(10, 'Otro');



INSERT INTO tipo_tamanio (id_tamanio, tamanio) VALUES
(1, 'Muy pequeño'),
(2, 'Pequeño'),
(3, 'Mediano'),
(4, 'Grande'),
(5, 'Muy grande');



INSERT INTO estado_grifo (id_estado_gr, estado_g) VALUES
(1, 'Operativo'),
(2, 'Dañado'),
(3, 'Mantenimiento'),
(4, 'Sin verificar');



INSERT INTO categ_condiciones (id_categ_c, categoria_c) VALUES
(1, 'Movilidad'),
(2, 'Estado cognitivo'),
(3, 'Riesgo crisis médica'),
(4, 'Dependencia médica'),
(5, 'Sensorial comunicación');


INSERT INTO condiciones (id_condicion, tipo_condicion, id_categ_c) VALUES

-- Movilidad
(1, 'Camina con dificultad', 1),
(2, 'Usa apoyo (bastón/andador)', 1),
(3, 'Silla de ruedas', 1),
(4, 'Postrado', 1),

-- Estado cognitivo / conducta
(5, 'Desorientación frecuente', 2),
(6, 'No responde a órdenes', 2),
(7, 'Puede alterarse/agresivo en crisis', 2),

-- Riesgo de crisis médica
(8, 'Convulsiones (epilepsia)', 3),
(9, 'Problemas respiratorios', 3),
(10, 'Problemas cardíacos', 3),
(11, 'Riesgo de desmayo', 3),

-- Dependencia médica
(12, 'Usa oxígeno', 4),
(13, 'Equipo médico eléctrico', 4),
(14, 'Medicación crítica', 4),

-- Sensorial / comunicación
(15, 'No ve', 5),
(16, 'No oye', 5),
(17, 'No habla / dificultad para comunicarse', 5);
