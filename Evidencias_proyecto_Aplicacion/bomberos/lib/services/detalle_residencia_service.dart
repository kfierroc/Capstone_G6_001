import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/residencia_detalle.dart';
import '../utils/chile_format.dart';
import '../utils/supabase_parse.dart';

class DetalleResidenciaException implements Exception {
  DetalleResidenciaException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DetalleResidenciaService {
  DetalleResidenciaService(this._client);

  final SupabaseClient _client;

  static DateTime _parseFecha(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.parse(v.split('T').first);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static String _formatearRut(int rutNum, String dv) => ChileFormat.formatearRut(rutNum, dv);

  Future<ResidenciaDetalle?> obtenerPorRegistro(int idRegistro) async {
    try {
      final rv = await _client
          .from('registro_v')
          .select(
            'id_registro, unidad, desc_depto_cond, notas_v, fecha_ult_confirm, id_grupof, '
            'id_residencia, id_tipo_v, id_estado_v, vigente, '
            'residencia(calle, nro_direccion, lat, lon, cut_com)',
          )
          .eq('id_registro', idRegistro)
          .maybeSingle();
      if (rv == null) return null;

      final idGf = SupabaseParse.requireInt(rv['id_grupof'], 'id_grupof');
      final idRes = SupabaseParse.requireInt(rv['id_residencia'], 'id_residencia');

      final res = await _obtenerResidencia(rv, idRes);
      if (res == null) return null;

      final cut = SupabaseParse.requireInt(res['cut_com'], 'cut_com');

      final comRow = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
      final comuna = SupabaseParse.asString(comRow?['comuna']) ?? 'Comuna $cut';

      final idTipo = SupabaseParse.requireInt(rv['id_tipo_v'], 'id_tipo_v');
      final idEst = SupabaseParse.requireInt(rv['id_estado_v'], 'id_estado_v');
      final tipoRow = await _client.from('tipo_vivienda').select('tipo_v').eq('id_tipo_v', idTipo).maybeSingle();
      final estRow = await _client.from('estado_vivienda').select('estado_v').eq('id_estado_v', idEst).maybeSingle();

      final gf = await _client
          .from('grupofamiliar')
          .select('rut_titular, rut_dv, telefono_titular')
          .eq('id_grupof', idGf)
          .maybeSingle();

      final calle = SupabaseParse.requireString(res['calle'], 'calle');
      final nroMostrar = ChileFormat.nroDireccionMostrar(res['nro_direccion']);
      final unidad = SupabaseParse.asString(rv['unidad']);
      final descDepto = SupabaseParse.asString(rv['desc_depto_cond']);

      final direccion = _armarDireccion(calle, nroMostrar, unidad, descDepto, comuna);
      final materialDept = (descDepto != null && descDepto.isNotEmpty)
          ? descDepto
          : await _materialPrimerPiso(idRegistro);

      final personas = await _cargarPersonas(idGf, gf);
      final mascotas = await _cargarMascotas(idGf);
      final materiales = await _cargarMateriales(idRegistro);

      final conCondiciones = personas.where((p) => p.condiciones.isNotEmpty).length;

      return ResidenciaDetalle(
        idRegistro: idRegistro,
        idResidencia: idRes,
        direccionCompleta: direccion,
        tipoVivienda: SupabaseParse.asString(tipoRow?['tipo_v']) ?? '—',
        estadoVivienda: SupabaseParse.asString(estRow?['estado_v']) ?? '—',
        materialDepartamento: materialDept.isEmpty ? '—' : materialDept,
        instruccionesEspeciales: SupabaseParse.asString(rv['notas_v']),
        fechaUltimaActualizacion: _parseFecha(rv['fecha_ult_confirm']),
        telefonoTitular: ChileFormat.formatearTelefono(SupabaseParse.asString(gf?['telefono_titular'])),
        cantidadPersonas: personas.length,
        cantidadMascotas: mascotas.length,
        cantidadConCondiciones: conCondiciones,
        cantidadMaterialesPeligrosos: materiales.length,
        materialesPeligrosos: materiales,
        personas: personas,
        mascotas: mascotas,
        lat: SupabaseParse.requireDouble(res['lat'], 'lat'),
        lon: SupabaseParse.requireDouble(res['lon'], 'lon'),
      );
    } on FormatException catch (e) {
      throw DetalleResidenciaException(e.message);
    } on PostgrestException catch (e) {
      throw DetalleResidenciaException(e.message);
    }
  }

  /// Usa el embed si viene completo; si no, consulta [residencia] por PK.
  Future<Map<String, dynamic>?> _obtenerResidencia(Map<String, dynamic> rv, int idRes) async {
    final embed = SupabaseParse.asMap(rv['residencia']);
    if (embed != null &&
        embed['calle'] != null &&
        embed['lat'] != null &&
        embed['lon'] != null &&
        embed['cut_com'] != null) {
      return embed;
    }

    final row = await _client
        .from('residencia')
        .select('id_residencia, calle, nro_direccion, lat, lon, cut_com')
        .eq('id_residencia', idRes)
        .maybeSingle();
    return SupabaseParse.asMap(row);
  }

  static String _armarDireccion(
    String calle,
    String nroMostrar,
    String? unidad,
    String? descDepto,
    String comuna,
  ) {
    final partes = <String>['$calle $nroMostrar'];
    if (unidad != null && unidad.isNotEmpty) {
      partes.add(unidad);
    } else if (descDepto != null && descDepto.isNotEmpty) {
      partes.add(descDepto);
    }
    partes.addAll([comuna, 'Santiago']);
    return partes.join(', ');
  }

  Future<String> _materialPrimerPiso(int idRegistro) async {
    final raw = await _client
        .from('piso_v')
        .select('tipo_mat_piso(material_piso)')
        .eq('id_registro', idRegistro)
        .order('numerop')
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return '';
    final nested = SupabaseParse.asMap(rows.first['tipo_mat_piso']);
    return SupabaseParse.asString(nested?['material_piso']) ?? '';
  }

  Future<List<PersonaDetalle>> _cargarPersonas(int idGf, Map<String, dynamic>? gf) async {
    final raw = await _client
        .from('integrante')
        .select('id_integrante, is_titular, anio_nac')
        .eq('id_grupof', idGf)
        .isFilter('fecha_fin_i', null)
        .order('is_titular', ascending: false)
        .order('id_integrante');

    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return [];

    final ids = rows.map((r) => SupabaseParse.requireInt(r['id_integrante'], 'id_integrante')).toList();

    final condPorInt = <int, List<String>>{};
    if (ids.isNotEmpty) {
      final rawCi = await _client
          .from('condiciones_integ')
          .select('id_integrante, observacion, condiciones(tipo_condicion)')
          .inFilter('id_integrante', ids);

      for (final row in List<Map<String, dynamic>>.from(rawCi as List)) {
        final idI = SupabaseParse.requireInt(row['id_integrante'], 'id_integrante');
        var texto = SupabaseParse.asString(SupabaseParse.asMap(row['condiciones'])?['tipo_condicion']) ?? '';
        final obs = SupabaseParse.asString(row['observacion']);
        if (obs != null && obs.isNotEmpty) {
          texto = texto.isEmpty ? obs : '$texto - $obs';
        }
        if (texto.isNotEmpty) {
          condPorInt.putIfAbsent(idI, () => []).add(texto);
        }
      }
    }

    final anioActual = DateTime.now().year;
    var nNoTitular = 0;
    final out = <PersonaDetalle>[];
    for (final r in rows) {
      final idI = SupabaseParse.requireInt(r['id_integrante'], 'id_integrante');
      final titular = r['is_titular'] == true;
      final anio = SupabaseParse.requireInt(r['anio_nac'], 'anio_nac');

      late final String etiqueta;
      if (titular) {
        etiqueta = 'Titular del domicilio';
      } else {
        nNoTitular++;
        etiqueta = 'Persona $nNoTitular';
      }

      String? rut;
      if (titular && gf != null) {
        final rutNum = SupabaseParse.asInt(gf['rut_titular']);
        final dv = SupabaseParse.asString(gf['rut_dv']);
        if (rutNum != null && dv != null) {
          rut = _formatearRut(rutNum, dv);
        }
      }

      out.add(
        PersonaDetalle(
          etiqueta: etiqueta,
          edad: anioActual - anio,
          esTitular: titular,
          rutMostrar: rut,
          condiciones: condPorInt[idI] ?? const [],
        ),
      );
    }
    return out;
  }

  Future<List<MascotaDetalle>> _cargarMascotas(int idGf) async {
    final raw = await _client.from('mascota').select().eq('id_grupof', idGf).order('id_mascota');
    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return [];

    final espRows = await _client.from('tipo_especie').select('id_especie, especie');
    final tamRows = await _client.from('tipo_tamanio').select('id_tamanio, tamanio');
    final mapEsp = <int, String>{};
    for (final r in List<Map<String, dynamic>>.from(espRows as List)) {
      final id = SupabaseParse.asInt(r['id_especie']);
      final nombre = SupabaseParse.asString(r['especie']);
      if (id != null && nombre != null) mapEsp[id] = nombre;
    }
    final mapTam = <int, String>{};
    for (final r in List<Map<String, dynamic>>.from(tamRows as List)) {
      final id = SupabaseParse.asInt(r['id_tamanio']);
      final nombre = SupabaseParse.asString(r['tamanio']);
      if (id != null && nombre != null) mapTam[id] = nombre;
    }

    return rows.map((r) {
      final idE = SupabaseParse.asInt(r['id_especie']);
      final idT = SupabaseParse.asInt(r['id_tamanio']);
      return MascotaDetalle(
        nombre: SupabaseParse.asString(r['nombre_m']) ?? 'Sin nombre',
        especie: idE != null ? (mapEsp[idE] ?? '—') : '—',
        tamano: idT != null ? (mapTam[idT] ?? '—') : '—',
      );
    }).toList();
  }

  Future<List<MaterialPeligrosoDetalle>> _cargarMateriales(int idRegistro) async {
    final raw = await _client
        .from('mat_peligroso')
        .select('cantidad, tipo_mat_peligroso(tipo_mat)')
        .eq('id_registro', idRegistro);

    final list = <MaterialPeligrosoDetalle>[];
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final nested = SupabaseParse.asMap(row['tipo_mat_peligroso']);
      final tipo = SupabaseParse.asString(nested?['tipo_mat']);
      if (tipo == null) continue;

      final cantidad = SupabaseParse.asInt(row['cantidad']);
      if (cantidad == null || cantidad < 1) continue;

      list.add(MaterialPeligrosoDetalle(tipo: tipo, cantidad: cantidad));
    }
    return list;
  }
}
