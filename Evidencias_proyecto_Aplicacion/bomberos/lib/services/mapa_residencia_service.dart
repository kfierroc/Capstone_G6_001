import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/residencia_mapa.dart';
import '../utils/geo_utils.dart';
import '../utils/supabase_parse.dart';

class MapaResidenciaException implements Exception {
  MapaResidenciaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Consulta residencias activas cercanas al centro del mapa (Supabase, sin Places API).
class MapaResidenciaService {
  MapaResidenciaService(this._client);

  final SupabaseClient _client;

  static String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseFecha(dynamic v) {
    if (v is String) return DateTime.parse(v.split('T').first);
    return DateTime.now();
  }

  Future<List<ResidenciaMapaResultado>> buscarEnArea({
    required double latCentro,
    required double lonCentro,
    required int radioMetros,
    required int limiteMaximo,
  }) async {
    final hoy = _fechaHoy();
    final radio = radioMetros.toDouble();
    final bbox = GeoUtils.boundingBox(latCentro, lonCentro, radio);
    final topeConsulta = (limiteMaximo * 4).clamp(20, 120);

    try {
      final rawRes = await _client
          .from('residencia')
          .select('id_residencia, calle, nro_direccion, lat, lon, cut_com')
          .gte('lat', bbox.minLat)
          .lte('lat', bbox.maxLat)
          .gte('lon', bbox.minLon)
          .lte('lon', bbox.maxLon)
          .limit(topeConsulta);

      final candidatas = <Map<String, dynamic>>[];
      for (final row in List<Map<String, dynamic>>.from(rawRes as List)) {
        final lat = SupabaseParse.asDouble(row['lat']);
        final lon = SupabaseParse.asDouble(row['lon']);
        if (lat == null || lon == null) continue;
        if (GeoUtils.distanciaMetros(latCentro, lonCentro, lat, lon) <= radio) {
          candidatas.add(row);
        }
      }
      if (candidatas.isEmpty) return [];

      final idsRes = candidatas
          .map((r) => SupabaseParse.asInt(r['id_residencia']))
          .whereType<int>()
          .toList();

      final rawRv = await _client
          .from('registro_v')
          .select(
            'id_registro, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, id_residencia, id_tipo_v',
          )
          .inFilter('id_residencia', idsRes)
          .eq('vigente', true)
          .gte('fecha_expiracion', hoy);

      final registros = List<Map<String, dynamic>>.from(rawRv as List);
      if (registros.isEmpty) return [];

      final resPorId = <int, Map<String, dynamic>>{};
      for (final r in candidatas) {
        final id = SupabaseParse.asInt(r['id_residencia']);
        if (id != null) resPorId[id] = r;
      }
      final cuts = candidatas.map((r) => SupabaseParse.asInt(r['cut_com'])).whereType<int>().toSet();
      final comunas = await _mapaComunas(cuts);

      final grupos = registros.map((r) => SupabaseParse.asInt(r['id_grupof'])).whereType<int>().toSet().toList();
      final idRegistros = registros.map((r) => SupabaseParse.asInt(r['id_registro'])).whereType<int>().toList();
      final idTipos = registros.map((r) => SupabaseParse.asInt(r['id_tipo_v'])).whereType<int>().toSet().toList();

      final personas = await _conteoIntegrantes(grupos);
      final mascotas = await _conteoMascotas(grupos);
      final materiales = await _conteoMateriales(idRegistros);
      final tipos = await _mapaTiposVivienda(idTipos);
      final alertas = await _alertasPorGrupo(grupos);

      final resultados = <ResidenciaMapaResultado>[];
      for (final rv in registros) {
        final idRes = SupabaseParse.asInt(rv['id_residencia']);
        final idReg = SupabaseParse.asInt(rv['id_registro']);
        final idGf = SupabaseParse.asInt(rv['id_grupof']);
        final idTipo = SupabaseParse.asInt(rv['id_tipo_v']);
        if (idRes == null || idReg == null || idGf == null || idTipo == null) continue;

        final res = resPorId[idRes];
        if (res == null) continue;

        final cut = SupabaseParse.asInt(res['cut_com']);
        final calle = SupabaseParse.asString(res['calle']);
        final nro = SupabaseParse.asInt(res['nro_direccion']);
        final lat = SupabaseParse.asDouble(res['lat']);
        final lon = SupabaseParse.asDouble(res['lon']);
        if (cut == null || calle == null || nro == null || lat == null || lon == null) continue;

        final comuna = comunas[cut] ?? 'Comuna $cut';
        final unidad = SupabaseParse.asString(rv['unidad']);
        final descDepto = SupabaseParse.asString(rv['desc_depto_cond']);

        resultados.add(
          ResidenciaMapaResultado(
            idRegistro: idReg,
            idResidencia: idRes,
            idGrupof: idGf,
            lat: lat,
            lon: lon,
            direccionCompleta: _formatearDireccion(
              calle: calle,
              nro: nro,
              unidad: unidad,
              descDepto: descDepto,
              comuna: comuna,
            ),
            cantidadPersonas: personas[idGf] ?? 0,
            cantidadMascotas: mascotas[idGf] ?? 0,
            tipoVivienda: tipos[idTipo] ?? 'Vivienda',
            cantidadMaterialesPeligrosos: materiales[idReg] ?? 0,
            alertasMedicas: alertas[idGf] ?? const [],
            fechaUltimaActualizacion: _parseFecha(rv['fecha_ult_confirm']),
          ),
        );
      }

      resultados.sort((a, b) {
        final da = GeoUtils.distanciaMetros(latCentro, lonCentro, a.lat, a.lon);
        final db = GeoUtils.distanciaMetros(latCentro, lonCentro, b.lat, b.lon);
        return da.compareTo(db);
      });
      if (resultados.length > limiteMaximo) {
        return resultados.sublist(0, limiteMaximo);
      }
      return resultados;
    } on FormatException catch (e) {
      throw MapaResidenciaException(e.message);
    } on PostgrestException catch (e) {
      throw MapaResidenciaException(e.message);
    }
  }

  Future<Map<int, String>> _mapaComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
    final map = <int, String>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final cut = SupabaseParse.asInt(row['cut_com']);
      final nombre = SupabaseParse.asString(row['comuna']);
      if (cut != null && nombre != null) map[cut] = nombre;
    }
    return map;
  }

  Future<Map<int, String>> _mapaTiposVivienda(List<int> ids) async {
    if (ids.isEmpty) return {};
    final raw = await _client.from('tipo_vivienda').select('id_tipo_v, tipo_v').inFilter('id_tipo_v', ids);
    final map = <int, String>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_tipo_v']);
      final nombre = SupabaseParse.asString(row['tipo_v']);
      if (id != null && nombre != null) map[id] = nombre;
    }
    return map;
  }

  Future<Map<int, int>> _conteoIntegrantes(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client
        .from('integrante')
        .select('id_grupof')
        .inFilter('id_grupof', idGrupos)
        .isFilter('fecha_fin_i', null);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, int>> _conteoMascotas(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client.from('mascota').select('id_grupof').inFilter('id_grupof', idGrupos);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, int>> _conteoMateriales(List<int> idRegistros) async {
    if (idRegistros.isEmpty) return {};
    final raw = await _client.from('mat_peligroso').select('id_registro').inFilter('id_registro', idRegistros);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_registro']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, List<String>>> _alertasPorGrupo(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final rawInt = await _client
        .from('integrante')
        .select('id_integrante, id_grupof')
        .inFilter('id_grupof', idGrupos)
        .isFilter('fecha_fin_i', null);
    final ints = List<Map<String, dynamic>>.from(rawInt as List);
    if (ints.isEmpty) return {};

    final grupoPorInt = <int, int>{};
    final idsInt = <int>[];
    for (final r in ints) {
      final idI = SupabaseParse.asInt(r['id_integrante']);
      final idGf = SupabaseParse.asInt(r['id_grupof']);
      if (idI == null || idGf == null) continue;
      idsInt.add(idI);
      grupoPorInt[idI] = idGf;
    }

    final rawCi = await _client
        .from('condiciones_integ')
        .select('id_integrante, observacion, condiciones(tipo_condicion)')
        .inFilter('id_integrante', idsInt);

    final porGrupo = <int, List<String>>{};
    for (final row in List<Map<String, dynamic>>.from(rawCi as List)) {
      final idI = SupabaseParse.asInt(row['id_integrante']);
      final idGf = idI != null ? grupoPorInt[idI] : null;
      if (idI == null || idGf == null) continue;

      var texto = SupabaseParse.asString(SupabaseParse.asMap(row['condiciones'])?['tipo_condicion']) ?? '';
      final obs = SupabaseParse.asString(row['observacion']);
      if (obs != null && obs.isNotEmpty) {
        texto = texto.isEmpty ? obs : '$texto - $obs';
      }
      if (texto.isEmpty) continue;

      porGrupo.putIfAbsent(idGf, () => []).add(texto);
    }
    return porGrupo;
  }

  static String _formatearDireccion({
    required String calle,
    required int nro,
    String? unidad,
    String? descDepto,
    required String comuna,
  }) {
    final partes = <String>['$calle $nro'];
    if (unidad != null && unidad.isNotEmpty) {
      partes.add(unidad);
    } else if (descDepto != null && descDepto.isNotEmpty) {
      partes.add(descDepto);
    }
    partes.addAll([comuna, 'Santiago']);
    return partes.join(', ');
  }
}
