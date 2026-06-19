import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grifo_mapa.dart';
import 'mapa_grifo_service.dart';

class GrifoEdicionException implements Exception {
  GrifoEdicionException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Registra una nueva inspección / actualización en `info_grifo`.
class GrifoEdicionService {
  GrifoEdicionService(this._client);

  final SupabaseClient _client;

  static String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String? _nota(String? notas) {
    final t = notas?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length <= 100 ? t : t.substring(0, 100);
  }

  Future<GrifoMapaResultado> actualizarInspeccion({
    required int idGrifo,
    required int idEstadoGr,
    required int rutNumBombero,
    String? notas,
  }) async {
    try {
      await _client.from('info_grifo').insert({
        'id_grifo': idGrifo,
        'fecha_registro': _fechaHoy(),
        'nota_g': _nota(notas),
        'id_estado_gr': idEstadoGr,
        'rut_num': rutNumBombero,
      });

      final actualizado = await MapaGrifoService(_client).buscarPorId(idGrifo: idGrifo);
      if (actualizado == null) {
        throw GrifoEdicionException('No se pudo cargar el grifo actualizado.');
      }
      return actualizado;
    } on MapaGrifoException catch (e) {
      throw GrifoEdicionException(e.message);
    } on PostgrestException catch (e) {
      throw GrifoEdicionException(e.message);
    }
  }
}
