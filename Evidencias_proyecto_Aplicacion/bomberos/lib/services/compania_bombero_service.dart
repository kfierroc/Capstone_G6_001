import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compania_bombero_info.dart';
import '../utils/supabase_parse.dart';
import 'geocode_service.dart';

class CompaniaBomberoException implements Exception {
  CompaniaBomberoException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Consulta [companias_bomberos] y la [comunas] asociada por [cut_com].
class CompaniaBomberoService {
  CompaniaBomberoService(this._client);

  final SupabaseClient _client;

  Future<CompaniaBomberoInfo?> obtenerPorIdCompania(int idCompania) async {
    try {
      final compania = await _client
          .from('companias_bomberos')
          .select('id_compania, nombre, cut_com')
          .eq('id_compania', idCompania)
          .maybeSingle();

      if (compania == null) return null;

      final cutCom = SupabaseParse.requireInt(compania['cut_com'], 'cut_com');
      final nombre = SupabaseParse.requireString(compania['nombre'], 'nombre');

      final comunaRow = await _client.from('comunas').select('comuna').eq('cut_com', cutCom).maybeSingle();

      final nombreComuna = SupabaseParse.asString(comunaRow?['comuna']) ?? 'Comuna $cutCom';

      return CompaniaBomberoInfo(
        idCompania: idCompania,
        nombre: nombre,
        cutCom: cutCom,
        nombreComuna: nombreComuna,
      );
    } on PostgrestException catch (e) {
      throw CompaniaBomberoException(e.message);
    } on FormatException catch (e) {
      throw CompaniaBomberoException(e.message);
    }
  }

  /// Región y comuna de una compañía (para preseleccionar desplegables).
  Future<({int cutReg, int cutCom})?> obtenerUbicacionPorIdCompania(int idCompania) async {
    try {
      final compania = await _client
          .from('companias_bomberos')
          .select('cut_com')
          .eq('id_compania', idCompania)
          .maybeSingle();
      if (compania == null) return null;

      final cutCom = SupabaseParse.requireInt(compania['cut_com'], 'cut_com');
      final comuna = await _client.from('comunas').select('cut_prov').eq('cut_com', cutCom).maybeSingle();
      if (comuna == null) return null;

      final cutProv = SupabaseParse.requireInt(comuna['cut_prov'], 'cut_prov');
      final prov = await _client.from('provincias').select('cut_reg').eq('cut_prov', cutProv).maybeSingle();
      if (prov == null) return null;

      final cutReg = SupabaseParse.requireInt(prov['cut_reg'], 'cut_reg');
      return (cutReg: cutReg, cutCom: cutCom);
    } on PostgrestException catch (e) {
      throw CompaniaBomberoException(e.message);
    }
  }

  /// Centro geográfico de la comuna de la compañía (fallback cuando no hay GPS).
  Future<LatLng?> obtenerCentroComunaPorIdCompania(int idCompania) async {
    final info = await obtenerPorIdCompania(idCompania);
    if (info == null) return null;
    return obtenerCentroPorCutCom(info.cutCom, info.nombreComuna);
  }

  Future<LatLng?> obtenerCentroPorCutCom(int cutCom, String nombreComuna) async {
    final desdeBd = await _coordenadasComunaEnBd(cutCom);
    if (desdeBd != null) return desdeBd;

    try {
      final geo = await GeocodeService().buscarDireccion('$nombreComuna, Chile');
      if (geo != null) return geo;
    } on GeocodeException catch (_) {}

    return _centroPromedioEnComuna(cutCom);
  }

  Future<LatLng?> _coordenadasComunaEnBd(int cutCom) async {
    try {
      final row = await _client.from('comunas').select('lat, lon').eq('cut_com', cutCom).maybeSingle();
      if (row == null) return null;
      final lat = SupabaseParse.asDouble(row['lat']);
      final lon = SupabaseParse.asDouble(row['lon']);
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } on PostgrestException catch (_) {
      return null;
    }
  }

  Future<LatLng?> _centroPromedioEnComuna(int cutCom) async {
    for (final tabla in ['grifo', 'residencia']) {
      try {
        final raw = await _client.from(tabla).select('lat, lon').eq('cut_com', cutCom).limit(300);
        final rows = List<Map<String, dynamic>>.from(raw as List);
        if (rows.isEmpty) continue;

        var sumLat = 0.0;
        var sumLon = 0.0;
        var n = 0;
        for (final row in rows) {
          final lat = SupabaseParse.asDouble(row['lat']);
          final lon = SupabaseParse.asDouble(row['lon']);
          if (lat == null || lon == null) continue;
          sumLat += lat;
          sumLon += lon;
          n++;
        }
        if (n > 0) return LatLng(sumLat / n, sumLon / n);
      } on PostgrestException catch (_) {}
    }
    return null;
  }
}
