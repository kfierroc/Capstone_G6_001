import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilBomberoException implements Exception {
  PerfilBomberoException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PerfilBomberoService {
  PerfilBomberoService(this._client);

  final SupabaseClient _client;

  Future<void> actualizarCompania({
    required int rutNum,
    required int idCompania,
  }) async {
    try {
      await _client.from('bombero').update({'id_compania': idCompania}).eq('rut_num', rutNum);
    } on PostgrestException catch (e) {
      throw PerfilBomberoException(e.message);
    }
  }
}
