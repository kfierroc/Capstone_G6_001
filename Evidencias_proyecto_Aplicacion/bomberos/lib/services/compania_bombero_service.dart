import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/compania_bombero_info.dart';
import '../utils/supabase_parse.dart';

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
}
