import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grifo_list_item.dart';
import '../models/pagina_lista.dart';

class GrifosAdminService {
  GrifosAdminService(this._client);

  final SupabaseClient _client;

  static const tamanoPagina = kTamanoPaginaLista;

  /// Solo columnas de la tabla `grifo` (sin historial embebido).
  static const _selectListaGrifo = 'id_grifo, lat, lon, cut_com';

  /// Último registro por grifo (consulta aparte, 1 fila).
  static const _selectUltimoInfo =
      'id_reg_grifo, fecha_registro, id_estado_gr, rut_num, estado_grifo(estado_g)';

  static const _selectDetalleGrifo =
      'id_grifo, lat, lon, cut_com, comunas(comuna), '
      'info_grifo(id_reg_grifo, fecha_registro, nota_g, id_estado_gr, estado_grifo(estado_g), '
      'bombero(nomb_bombero, ape_p_bombero))';

  static const _selectDetalleGrifoSinComuna =
      'id_grifo, lat, lon, cut_com, '
      'info_grifo(id_reg_grifo, fecha_registro, nota_g, id_estado_gr, estado_grifo(estado_g), '
      'bombero(nomb_bombero, ape_p_bombero))';

  /// Página de grifos (máx. [limit], por defecto 20). [offset] = índice desde el que cargar.
  Future<PaginaLista<GrifoListItem>> listarGrifosPaginado({
    required int offset,
    int limit = tamanoPagina,
    int? cutCom,
    List<int>? cutComsRegion,
    int? idGrifoExacto,
  }) async {
    if (cutComsRegion != null && cutComsRegion.isEmpty) {
      return const PaginaLista(items: [], hayMas: false);
    }

    try {
      return await _listarPagina(
        offset: offset,
        limit: limit,
        cutCom: cutCom,
        cutComsRegion: cutComsRegion,
        idGrifoExacto: idGrifoExacto,
      );
    } catch (_) {
      return const PaginaLista(items: [], hayMas: false);
    }
  }

  Future<PaginaLista<GrifoListItem>> _listarPagina({
    required int offset,
    required int limit,
    int? cutCom,
    List<int>? cutComsRegion,
    int? idGrifoExacto,
  }) async {
    final pedido = limit + 1;
    var query = _client.from('grifo').select(_selectListaGrifo);

    if (idGrifoExacto != null) {
      query = query.eq('id_grifo', idGrifoExacto);
    } else if (cutCom != null) {
      query = query.eq('cut_com', cutCom);
    } else if (cutComsRegion != null) {
      query = query.inFilter('cut_com', cutComsRegion);
    }

    final raw = await query.order('id_grifo').range(offset, offset + pedido - 1);
    final hayMas = raw.length > limit;
    final slice = hayMas ? raw.sublist(0, limit) : raw;

    final ids = slice.map((r) => _asInt(r['id_grifo'])).whereType<int>().toList();
    final comunas = await _mapComunas(
      slice.map((r) => _asInt(r['cut_com'])).whereType<int>().toSet(),
    );
    final ultimos = await _ultimosRegistrosPorGrifo(ids);

    final items = slice
        .map((row) => _mapListItemDesdeGrifo(row, comunas: comunas, ultimo: ultimos[_asInt(row['id_grifo'])]))
        .whereType<GrifoListItem>()
        .toList();

    return PaginaLista(items: items, hayMas: hayMas);
  }

  /// Último `info_grifo` por cada id (consultas livianas de 1 fila).
  Future<Map<int, InfoGrifoRegistro>> _ultimosRegistrosPorGrifo(List<int> idsGrifo) async {
    if (idsGrifo.isEmpty) return {};

    final filas = await Future.wait(idsGrifo.map(_ultimoRegistroGrifo));
    final rutNums = <int>{};
    final porId = <int, InfoGrifoRegistro>{};

    final rutPorGrifo = <int, int?>{};

    for (final par in filas) {
      if (par == null) continue;
      porId[par.idGrifo] = par.registro;
      rutPorGrifo[par.idGrifo] = par.rutNum;
      final rut = par.rutNum;
      if (rut != null) rutNums.add(rut);
    }

    if (rutNums.isEmpty) return porId;

    final nombres = await _mapBomberosPorRut(rutNums);
    return {
      for (final e in porId.entries)
        e.key: InfoGrifoRegistro(
          idRegGrifo: e.value.idRegGrifo,
          fechaRegistro: e.value.fechaRegistro,
          estado: e.value.estado,
          idEstadoGr: e.value.idEstadoGr,
          registradoPor: _nombreBombero(nombres, rutPorGrifo[e.key]) ?? e.value.registradoPor,
          nota: e.value.nota,
        ),
    };
  }

  String? _nombreBombero(Map<int, String> nombres, int? rutNum) {
    if (rutNum == null) return null;
    final nombre = nombres[rutNum]?.trim();
    return (nombre != null && nombre.isNotEmpty) ? nombre : null;
  }

  Future<({int idGrifo, int? rutNum, InfoGrifoRegistro registro})?> _ultimoRegistroGrifo(int idGrifo) async {
    try {
      final row = await _client
          .from('info_grifo')
          .select(_selectUltimoInfo)
          .eq('id_grifo', idGrifo)
          .order('fecha_registro', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;

      final idEst = _asInt(row['id_estado_gr']);
      if (idEst == null) return null;

      final rutNum = _asInt(row['rut_num']);
      final estado = _nestedString(row['estado_grifo'], 'estado_g') ?? '—';

      return (
        idGrifo: idGrifo,
        rutNum: rutNum,
        registro: InfoGrifoRegistro(
          idRegGrifo: _asInt(row['id_reg_grifo']) ?? 0,
          fechaRegistro: _formatearFecha(row['fecha_registro']),
          estado: estado,
          idEstadoGr: idEst,
          registradoPor: '—',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, String>> _mapBomberosPorRut(Set<int> rutNums) async {
    if (rutNums.isEmpty) return {};
    try {
      final raw = await _client
          .from('bombero')
          .select('rut_num, nomb_bombero, ape_p_bombero')
          .inFilter('rut_num', rutNums.toList());
      return {
        for (final row in raw)
          if (_asInt(row['rut_num']) != null)
            _asInt(row['rut_num'])!: '${(row['nomb_bombero'] as String? ?? '').trim()} '
                    '${(row['ape_p_bombero'] as String? ?? '').trim()}'
                .trim(),
      };
    } catch (_) {
      return {};
    }
  }

  GrifoListItem? _mapListItemDesdeGrifo(
    dynamic row, {
    required Map<int, String> comunas,
    InfoGrifoRegistro? ultimo,
  }) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);

    final id = _asInt(m['id_grifo']);
    final lat = _asDouble(m['lat']);
    final lon = _asDouble(m['lon']);
    if (id == null || lat == null || lon == null) return null;

    final cut = _asInt(m['cut_com']);
    final comuna = cut != null ? (comunas[cut] ?? 'Comuna $cut') : '—';

    if (ultimo == null) {
      return GrifoListItem(
        idGrifo: id,
        lat: lat,
        lon: lon,
        comuna: comuna,
        estadoActual: 'Sin registro',
        cutCom: cut,
      );
    }

    return GrifoListItem(
      idGrifo: id,
      lat: lat,
      lon: lon,
      comuna: comuna,
      estadoActual: ultimo.estado,
      cutCom: cut,
      idEstadoGr: ultimo.idEstadoGr,
      registradoPor: ultimo.registradoPor,
      notaActual: ultimo.nota,
    );
  }

  Future<GrifoDetalle?> obtenerDetalle(int idGrifo) async {
    try {
      return await _obtenerDetalleConSelect(idGrifo, _selectDetalleGrifo, conEmbedComuna: true);
    } catch (_) {
      try {
        return await _obtenerDetalleConSelect(idGrifo, _selectDetalleGrifoSinComuna, conEmbedComuna: false);
      } catch (_) {
        return null;
      }
    }
  }

  Future<GrifoDetalle?> _obtenerDetalleConSelect(
    int idGrifo,
    String select, {
    required bool conEmbedComuna,
  }) async {
    final row = await _client.from('grifo').select(select).eq('id_grifo', idGrifo).maybeSingle();
    if (row == null) return null;

    final id = _asInt(row['id_grifo'])!;
    final lat = _asDouble(row['lat'])!;
    final lon = _asDouble(row['lon'])!;
    final cut = _asInt(row['cut_com'])!;

    var comuna = _nestedString(row['comunas'], 'comuna') ?? 'Comuna $cut';
    if (!conEmbedComuna || comuna == 'Comuna $cut') {
      try {
        final cRow = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
        comuna = (cRow?['comuna'] as String? ?? comuna).trim();
      } catch (_) {}
    }

    final historial = _historialDesde(row['info_grifo']);
    if (historial.isEmpty) {
      return GrifoDetalle(
        idGrifo: id,
        lat: lat,
        lon: lon,
        comuna: comuna,
        cutCom: cut,
        estadoActual: 'Sin registro',
        idEstadoGr: 4,
        fechaUltimoRegistro: '—',
        historial: const [],
      );
    }

    final ultimo = historial.first;
    return GrifoDetalle(
      idGrifo: id,
      lat: lat,
      lon: lon,
      comuna: comuna,
      cutCom: cut,
      estadoActual: ultimo.estado,
      idEstadoGr: ultimo.idEstadoGr,
      fechaUltimoRegistro: ultimo.fechaRegistro,
      notaActual: ultimo.nota,
      historial: historial,
    );
  }

  List<InfoGrifoRegistro> _historialDesde(dynamic raw) {
    if (raw == null) return [];
    final lista = raw is List ? raw : [raw];
    final registros = <InfoGrifoRegistro>[];

    for (final item in lista) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final idReg = _asInt(m['id_reg_grifo']);
      final idEst = _asInt(m['id_estado_gr']);
      final fecha = _formatearFecha(m['fecha_registro']);
      if (idEst == null) continue;

      final estado = _nestedString(m['estado_grifo'], 'estado_g') ?? '—';
      final nota = (m['nota_g'] as String?)?.trim();
      final bombero = _nestedMap(m['bombero']);
      final registradoPor = bombero == null
          ? '—'
          : '${(bombero['nomb_bombero'] as String? ?? '').trim()} ${(bombero['ape_p_bombero'] as String? ?? '').trim()}'
              .trim();

      registros.add(
        InfoGrifoRegistro(
          idRegGrifo: idReg ?? 0,
          fechaRegistro: fecha,
          estado: estado,
          idEstadoGr: idEst,
          registradoPor: registradoPor.isEmpty ? '—' : registradoPor,
          nota: nota?.isNotEmpty == true ? nota : null,
        ),
      );
    }

    registros.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
    return registros;
  }

  Future<Map<int, String>> _mapComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    try {
      final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
      return {
        for (final row in raw)
          (row['cut_com'] as num).toInt(): (row['comuna'] as String).trim(),
      };
    } catch (_) {
      return {};
    }
  }

  String _formatearFecha(dynamic v) {
    if (v == null) return '—';
    if (v is String) return v.split('T').first;
    return v.toString();
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String? _nestedString(dynamic parent, String key) {
    final m = parent is Map ? _nestedMap(parent) : null;
    if (m == null) return null;
    return (m[key] as String?)?.trim();
  }
}
