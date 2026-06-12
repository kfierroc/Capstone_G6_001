import 'package:supabase_flutter/supabase_flutter.dart';

import 'comuna_rpc_service.dart';

class GrifoRegistroException implements Exception {
  GrifoRegistroException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GrifoRegistroService {
  GrifoRegistroService(this._client) : _comunaRpc = ComunaRpcService(_client);

  final SupabaseClient _client;
  final ComunaRpcService _comunaRpc;

  static String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _trunc(String s, int max) => s.length <= max ? s : s.substring(0, max);

  Future<int> registrar({
    required double lat,
    required double lon,
    required int idEstadoGr,
    required int rutNumBombero,
    String? notas,
  }) async {
    try {
      final cutCom = await _comunaRpc.obtenerCutCom(lat, lon);

      final grifoIns = await _client
          .from('grifo')
          .insert({
            'lat': lat,
            'lon': lon,
            'cut_com': cutCom,
          })
          .select('id_grifo')
          .single();

      final idGrifo = (grifoIns['id_grifo'] as num).toInt();
      final notaValor = notas?.trim();
      final notaFinal = (notaValor == null || notaValor.isEmpty) ? null : _trunc(notaValor, 100);

      await _client.from('info_grifo').insert({
        'id_grifo': idGrifo,
        'fecha_registro': _fechaHoy(),
        'nota_g': notaFinal,
        'id_estado_gr': idEstadoGr,
        'rut_num': rutNumBombero,
      });

      return idGrifo;
    } on ComunaRpcException catch (e) {
      throw GrifoRegistroException(e.message);
    } on PostgrestException catch (e) {
      throw GrifoRegistroException(e.message);
    }
  }
}
