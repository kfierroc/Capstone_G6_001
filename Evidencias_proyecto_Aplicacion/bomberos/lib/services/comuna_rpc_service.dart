import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComunaRpcException implements Exception {
  ComunaRpcException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Obtiene [cut_com] desde coordenadas vía RPC de Supabase.
class ComunaRpcService {
  ComunaRpcService(this._client);

  final SupabaseClient _client;

  static int _interpretarCutCom(dynamic raw) {
    if (raw == null) {
      throw ComunaRpcException('No se pudo determinar la comuna para las coordenadas.');
    }
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    Map<String, dynamic>? comoMap(dynamic x) {
      if (x is Map<String, dynamic>) return x;
      if (x is Map) return Map<String, dynamic>.from(x);
      return null;
    }

    int? cutDesdeFila(Map<String, dynamic> row) {
      final v = row['cut_com'] ?? row['CUT_COM'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return null;
    }

    if (raw is List) {
      for (final item in raw) {
        final row = comoMap(item);
        final cut = row != null ? cutDesdeFila(row) : null;
        if (cut != null) return cut;
      }
    } else {
      final row = comoMap(raw);
      if (row != null) {
        final cut = cutDesdeFila(row);
        if (cut != null) return cut;
      }
    }

    throw ComunaRpcException('La RPC no devolvió cut_com reconocible.');
  }

  Future<int> obtenerCutCom(double lat, double lon) async {
    final nombre = dotenv.env['SUPABASE_RPC_NAME']?.trim();
    final pLat = dotenv.env['SUPABASE_RPC_PARAM_LAT']?.trim();
    final pLng = dotenv.env['SUPABASE_RPC_PARAM_LNG']?.trim();
    if (nombre == null || nombre.isEmpty || pLat == null || pLng == null) {
      throw ComunaRpcException('Configura SUPABASE_RPC_* en .env');
    }
    try {
      final raw = await _client.rpc(nombre, params: {pLat: lat, pLng: lon});
      return _interpretarCutCom(raw);
    } on PostgrestException catch (e) {
      throw ComunaRpcException(e.message);
    }
  }
}
