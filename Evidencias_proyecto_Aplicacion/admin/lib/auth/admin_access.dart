import 'package:supabase_flutter/supabase_flutter.dart';

const _selectBombero =
    'rut_num, rut_dv, nomb_bombero, ape_p_bombero, is_admin, id_compania, user_id';

/// Fila de [bombero] vinculada al usuario autenticado.
Future<Map<String, dynamic>?> obtenerBomberoPorUsuario(SupabaseClient client) async {
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  return client.from('bombero').select(_selectBombero).eq('user_id', uid).maybeSingle();
}

/// Solo bomberos con [is_admin] = true pueden acceder al panel.
Future<Map<String, dynamic>?> obtenerBomberoAdminPorUsuario(SupabaseClient client) async {
  final row = await obtenerBomberoPorUsuario(client);
  if (row == null) return null;
  if (row['is_admin'] != true) return null;
  return row;
}
