import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grifo_mapa.dart';
import '../utils/geo_utils.dart';
import '../utils/supabase_parse.dart';

class MapaGrifoException implements Exception {
  MapaGrifoException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MapaGrifoService {
  MapaGrifoService(this._client);

  final SupabaseClient _client;

  static DateTime _parseFecha(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.parse(v.split('T').first);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  Future<List<EstadoGrifoOpcion>> listarEstados() async {
    final raw = await _client.from('estado_grifo').select('id_estado_gr, estado_g').order('id_estado_gr');
    return List<Map<String, dynamic>>.from(raw as List).map((r) {
      return EstadoGrifoOpcion(
        id: SupabaseParse.requireInt(r['id_estado_gr'], 'id_estado_gr'),
        nombre: SupabaseParse.requireString(r['estado_g'], 'estado_g'),
      );
    }).toList();
  }

  Future<List<({int cutCom, String comuna})>> listarComunasConGrifos() async {
    final raw = await _client.from('grifo').select('cut_com');
    final cuts = <int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final c = SupabaseParse.asInt(row['cut_com']);
      if (c != null) cuts.add(c);
    }
    if (cuts.isEmpty) return [];

    final comRaw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
    final list = <({int cutCom, String comuna})>[];
    for (final row in List<Map<String, dynamic>>.from(comRaw as List)) {
      final cut = SupabaseParse.asInt(row['cut_com']);
      final nombre = SupabaseParse.asString(row['comuna']);
      if (cut != null && nombre != null) list.add((cutCom: cut, comuna: nombre));
    }
    list.sort((a, b) => a.comuna.compareTo(b.comuna));
    return list;
  }

  /// Grifos vinculados al bombero ([rutNum] en `info_grifo`), con estado actual.
  Future<List<GrifoMapaResultado>> listarPorBombero(int rutNum) async {
    try {
      final rawInfo = await _client.from('info_grifo').select('id_grifo').eq('rut_num', rutNum);

      final ids = <int>{};
      for (final row in List<Map<String, dynamic>>.from(rawInfo as List)) {
        final id = SupabaseParse.asInt(row['id_grifo']);
        if (id != null) ids.add(id);
      }
      if (ids.isEmpty) return [];

      final idList = ids.toList();
      final rawGrifos = await _client
          .from('grifo')
          .select('id_grifo, lat, lon, cut_com')
          .inFilter('id_grifo', idList);

      final infoPorGrifo = await _ultimaInfoPorGrifo(idList);
      final cuts = <int>{};
      final resultados = <GrifoMapaResultado>[];

      for (final g in List<Map<String, dynamic>>.from(rawGrifos as List)) {
        final id = SupabaseParse.requireInt(g['id_grifo'], 'id_grifo');
        final info = infoPorGrifo[id];
        if (info == null) continue;

        final cut = SupabaseParse.requireInt(g['cut_com'], 'cut_com');
        cuts.add(cut);
        resultados.add(
          GrifoMapaResultado(
            idGrifo: id,
            lat: SupabaseParse.requireDouble(g['lat'], 'lat'),
            lon: SupabaseParse.requireDouble(g['lon'], 'lon'),
            cutCom: cut,
            comunaNombre: '',
            estado: info.estado,
            idEstadoGr: info.idEstadoGr,
            fechaRegistro: info.fechaRegistro,
            notas: info.notas,
            reportadoPor: info.reportadoPor,
          ),
        );
      }

      final comunas = await _mapaComunas(cuts);
      final conComuna = resultados
          .map(
            (g) => GrifoMapaResultado(
              idGrifo: g.idGrifo,
              lat: g.lat,
              lon: g.lon,
              cutCom: g.cutCom,
              comunaNombre: comunas[g.cutCom] ?? 'Comuna ${g.cutCom}',
              estado: g.estado,
              idEstadoGr: g.idEstadoGr,
              fechaRegistro: g.fechaRegistro,
              notas: g.notas,
              reportadoPor: g.reportadoPor,
            ),
          )
          .toList();
      conComuna.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      return conComuna;

    } on PostgrestException catch (e) {
      throw MapaGrifoException(e.message);
    } on FormatException catch (e) {
      throw MapaGrifoException(e.message);
    }
  }

  /// Busca un grifo por [idGrifo]; si [cutCom] no es null, debe coincidir con la comuna del grifo.
  Future<GrifoMapaResultado?> buscarPorId({
    required int idGrifo,
    int? cutCom,
  }) async {
    try {
      final raw = await _client
          .from('grifo')
          .select('id_grifo, lat, lon, cut_com')
          .eq('id_grifo', idGrifo)
          .maybeSingle();

      if (raw == null) return null;

      final cut = SupabaseParse.requireInt(raw['cut_com'], 'cut_com');
      if (cutCom != null && cut != cutCom) return null;

      final infoPorGrifo = await _ultimaInfoPorGrifo([idGrifo]);
      final info = infoPorGrifo[idGrifo];
      if (info == null) return null;

      final comunas = await _mapaComunas({cut});

      return GrifoMapaResultado(
        idGrifo: idGrifo,
        lat: SupabaseParse.requireDouble(raw['lat'], 'lat'),
        lon: SupabaseParse.requireDouble(raw['lon'], 'lon'),
        cutCom: cut,
        comunaNombre: comunas[cut] ?? 'Comuna $cut',
        estado: info.estado,
        idEstadoGr: info.idEstadoGr,
        fechaRegistro: info.fechaRegistro,
        notas: info.notas,
        reportadoPor: info.reportadoPor,
      );
    } on PostgrestException catch (e) {
      throw MapaGrifoException(e.message);
    } on FormatException catch (e) {
      throw MapaGrifoException(e.message);
    }
  }

  /// Hasta [limite] grifos con estado operativo dentro de [radioMetros] (p. ej. 1 km).
  Future<List<GrifoMapaResultado>> grifosOperativosCercanos({
    required double lat,
    required double lon,
    int radioMetros = 1000,
    int limite = 3,
  }) async {
    final todos = await buscarEnArea(
      latCentro: lat,
      lonCentro: lon,
      radioMetros: radioMetros,
      limiteMaximo: limite * 5,
    );
    final operativos = todos
        .where((g) => g.estado.toLowerCase().contains('operativo'))
        .toList();
    if (operativos.length <= limite) return operativos;
    return operativos.sublist(0, limite);
  }

  /// Todos los grifos con información vigente en una comuna.
  Future<List<GrifoMapaResultado>> listarPorComuna(int cutCom) async {
    try {
      final rawGrifos = await _client
          .from('grifo')
          .select('id_grifo, lat, lon, cut_com')
          .eq('cut_com', cutCom);

      final rows = List<Map<String, dynamic>>.from(rawGrifos as List);
      if (rows.isEmpty) return [];

      final ids = rows.map((r) => SupabaseParse.requireInt(r['id_grifo'], 'id_grifo')).toList();
      final infoPorGrifo = await _ultimaInfoPorGrifo(ids);
      final comunas = await _mapaComunas({cutCom});
      final comunaNombre = comunas[cutCom] ?? 'Comuna $cutCom';

      final resultados = <GrifoMapaResultado>[];
      for (final g in rows) {
        final id = SupabaseParse.requireInt(g['id_grifo'], 'id_grifo');
        final info = infoPorGrifo[id];
        if (info == null) continue;

        resultados.add(
          GrifoMapaResultado(
            idGrifo: id,
            lat: SupabaseParse.requireDouble(g['lat'], 'lat'),
            lon: SupabaseParse.requireDouble(g['lon'], 'lon'),
            cutCom: cutCom,
            comunaNombre: comunaNombre,
            estado: info.estado,
            idEstadoGr: info.idEstadoGr,
            fechaRegistro: info.fechaRegistro,
            notas: info.notas,
            reportadoPor: info.reportadoPor,
          ),
        );
      }

      resultados.sort((a, b) => a.idGrifo.compareTo(b.idGrifo));
      return resultados;
    } on FormatException catch (e) {
      throw MapaGrifoException(e.message);
    } on PostgrestException catch (e) {
      throw MapaGrifoException(e.message);
    }
  }

  Future<List<GrifoMapaResultado>> buscarEnArea({
    required double latCentro,
    required double lonCentro,
    required int radioMetros,
    required int limiteMaximo,
  }) async {
    final radio = radioMetros.toDouble();
    final bbox = GeoUtils.boundingBox(latCentro, lonCentro, radio);

    try {
      final candidatosConDist = await _grifosEnRadioOrdenados(
        latCentro: latCentro,
        lonCentro: lonCentro,
        radioMetros: radio,
        bbox: bbox,
      );
      if (candidatosConDist.isEmpty) return [];

      final resultados = <GrifoMapaResultado>[];
      final comunasCache = <int, String>{};
      var indice = 0;

      while (resultados.length < limiteMaximo && indice < candidatosConDist.length) {
        final fin = (indice + 50).clamp(0, candidatosConDist.length);
        final lote = candidatosConDist.sublist(indice, fin);
        indice = fin;

        final ids = lote.map((c) => SupabaseParse.requireInt(c.row['id_grifo'], 'id_grifo')).toList();
        final infoPorGrifo = await _ultimaInfoPorGrifo(ids);

        final cutsNuevos = lote
            .map((c) => SupabaseParse.requireInt(c.row['cut_com'], 'cut_com'))
            .where((cut) => !comunasCache.containsKey(cut))
            .toSet();
        if (cutsNuevos.isNotEmpty) {
          comunasCache.addAll(await _mapaComunas(cutsNuevos));
        }

        for (final c in lote) {
          final g = c.row;
          final id = SupabaseParse.requireInt(g['id_grifo'], 'id_grifo');
          final info = infoPorGrifo[id];
          if (info == null) continue;

          final cut = SupabaseParse.requireInt(g['cut_com'], 'cut_com');
          resultados.add(
            GrifoMapaResultado(
              idGrifo: id,
              lat: SupabaseParse.requireDouble(g['lat'], 'lat'),
              lon: SupabaseParse.requireDouble(g['lon'], 'lon'),
              cutCom: cut,
              comunaNombre: comunasCache[cut] ?? 'Comuna $cut',
              estado: info.estado,
              idEstadoGr: info.idEstadoGr,
              fechaRegistro: info.fechaRegistro,
              notas: info.notas,
              reportadoPor: info.reportadoPor,
            ),
          );
          if (resultados.length >= limiteMaximo) break;
        }
      }

      return resultados;
    } on FormatException catch (e) {
      throw MapaGrifoException(e.message);
    } on PostgrestException catch (e) {
      throw MapaGrifoException(e.message);
    }
  }

  /// Todos los grifos dentro del radio, ordenados por distancia al centro (más cercano primero).
  Future<List<({Map<String, dynamic> row, double distanciaMetros})>> _grifosEnRadioOrdenados({
    required double latCentro,
    required double lonCentro,
    required double radioMetros,
    required ({double minLat, double maxLat, double minLon, double maxLon}) bbox,
  }) async {
    const pageSize = 200;
    const maxFilas = 2000;
    var offset = 0;
    final candidatos = <({Map<String, dynamic> row, double distanciaMetros})>[];

    while (offset < maxFilas) {
      final rawGrifos = await _client
          .from('grifo')
          .select('id_grifo, lat, lon, cut_com')
          .gte('lat', bbox.minLat)
          .lte('lat', bbox.maxLat)
          .gte('lon', bbox.minLon)
          .lte('lon', bbox.maxLon)
          .range(offset, offset + pageSize - 1);

      final batch = List<Map<String, dynamic>>.from(rawGrifos as List);
      if (batch.isEmpty) break;

      for (final row in batch) {
        final lat = SupabaseParse.asDouble(row['lat']);
        final lon = SupabaseParse.asDouble(row['lon']);
        if (lat == null || lon == null) continue;

        final dist = GeoUtils.distanciaMetros(latCentro, lonCentro, lat, lon);
        if (dist <= radioMetros) {
          candidatos.add((row: row, distanciaMetros: dist));
        }
      }

      if (batch.length < pageSize) break;
      offset += pageSize;
    }

    candidatos.sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
    return candidatos;
  }

  Future<Map<int, _InfoGrifo>> _ultimaInfoPorGrifo(List<int> idsGrifo) async {
    if (idsGrifo.isEmpty) return {};

    final raw = await _client
        .from('info_grifo')
        .select(
          'id_grifo, fecha_registro, nota_g, id_estado_gr, '
          'estado_grifo(estado_g), '
          'bombero(nomb_bombero, ape_p_bombero)',
        )
        .inFilter('id_grifo', idsGrifo)
        .order('fecha_registro', ascending: false);

    final map = <int, _InfoGrifo>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final idG = SupabaseParse.asInt(row['id_grifo']);
      if (idG == null || map.containsKey(idG)) continue;

      final estNested = SupabaseParse.asMap(row['estado_grifo']);
      final bomNested = SupabaseParse.asMap(row['bombero']);
      final estado = SupabaseParse.asString(estNested?['estado_g']) ?? 'Sin verificar';
      final nomb = SupabaseParse.asString(bomNested?['nomb_bombero']) ?? '';
      final ape = SupabaseParse.asString(bomNested?['ape_p_bombero']) ?? '';
      final reportado = '$nomb $ape'.trim();

      map[idG] = _InfoGrifo(
        idEstadoGr: SupabaseParse.requireInt(row['id_estado_gr'], 'id_estado_gr'),
        estado: estado,
        fechaRegistro: _parseFecha(row['fecha_registro']),
        notas: SupabaseParse.asString(row['nota_g']),
        reportadoPor: reportado.isEmpty ? '—' : reportado,
      );
    }
    return map;
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

  /// Grifos para mostrar contexto en mapa de registro (área amplia).
  Future<List<GrifoMapaResultado>> grifosEnBoundingBox({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int limite = 80,
  }) async {
    final raw = await _client
        .from('grifo')
        .select('id_grifo, lat, lon, cut_com')
        .gte('lat', minLat)
        .lte('lat', maxLat)
        .gte('lon', minLon)
        .lte('lon', maxLon)
        .limit(limite);

    final rows = List<Map<String, dynamic>>.from(raw as List);
    if (rows.isEmpty) return [];

    final ids = rows.map((r) => SupabaseParse.requireInt(r['id_grifo'], 'id_grifo')).toList();
    final infoPorGrifo = await _ultimaInfoPorGrifo(ids);
    final cuts = rows.map((r) => SupabaseParse.requireInt(r['cut_com'], 'cut_com')).toSet();
    final comunas = await _mapaComunas(cuts);

    return rows.map((g) {
      final id = SupabaseParse.requireInt(g['id_grifo'], 'id_grifo');
      final info = infoPorGrifo[id];
      final cut = SupabaseParse.requireInt(g['cut_com'], 'cut_com');
      return GrifoMapaResultado(
        idGrifo: id,
        lat: SupabaseParse.requireDouble(g['lat'], 'lat'),
        lon: SupabaseParse.requireDouble(g['lon'], 'lon'),
        cutCom: cut,
        comunaNombre: comunas[cut] ?? '',
        estado: info?.estado ?? 'Sin verificar',
        idEstadoGr: info?.idEstadoGr ?? 4,
        fechaRegistro: info?.fechaRegistro ?? DateTime.now(),
        notas: info?.notas,
        reportadoPor: info?.reportadoPor ?? '—',
      );
    }).toList();
  }
}

class _InfoGrifo {
  _InfoGrifo({
    required this.idEstadoGr,
    required this.estado,
    required this.fechaRegistro,
    required this.reportadoPor,
    this.notas,
  });

  final int idEstadoGr;
  final String estado;
  final DateTime fechaRegistro;
  final String? notas;
  final String reportadoPor;
}
