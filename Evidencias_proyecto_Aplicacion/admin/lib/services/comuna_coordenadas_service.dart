import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_edit_service.dart';

/// Resuelve `cut_com` vía RPC Supabase configurada en `.env`.
class ComunaCoordenadasService {
  ComunaCoordenadasService(this._client);

  final SupabaseClient _client;

  static int interpretarCutCom(dynamic raw) {
    if (raw == null) {
      throw AdminEditException('No se pudo determinar la comuna para las coordenadas.');
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
      if (raw.isEmpty) {
        throw AdminEditException(
          'Las coordenadas no intersectan ninguna comuna registrada.',
        );
      }
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

    throw AdminEditException(
      'La RPC devolvió datos pero sin cut_com reconocible.',
    );
  }

  Future<int> obtenerCutCom(double lat, double lon) async {
    final nombre = dotenv.env['SUPABASE_RPC_NAME']?.trim();
    final pLat = dotenv.env['SUPABASE_RPC_PARAM_LAT']?.trim();
    final pLng = dotenv.env['SUPABASE_RPC_PARAM_LNG']?.trim();
    if (nombre == null || nombre.isEmpty || pLat == null || pLng == null) {
      throw AdminEditException('Falta configurar SUPABASE_RPC_* en el archivo .env');
    }

    try {
      final raw = await _client.rpc(nombre, params: {pLat: lat, pLng: lon});
      return interpretarCutCom(raw);
    } on PostgrestException catch (e) {
      final code = e.code;
      final hint = e.hint ?? '';
      if (code == 'PGRST202' ||
          hint.contains('schema cache') ||
          e.message.toLowerCase().contains('could not find')) {
        throw AdminEditException(
          'La función obtener_comuna_por_coordenadas no está disponible en Supabase. '
          'Revísala en el SQL Editor y los permisos GRANT EXECUTE.',
        );
      }
      rethrow;
    }
  }

  Future<({int cutCom, String nombre})> resolverComuna(double lat, double lon) async {
    final cutCom = await obtenerCutCom(lat, lon);
    final row = await _client.from('comunas').select('comuna').eq('cut_com', cutCom).maybeSingle();
    final nombre = (row?['comuna'] as String? ?? 'Comuna $cutCom').trim();
    return (cutCom: cutCom, nombre: nombre);
  }
}
