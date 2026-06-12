import 'package:supabase_flutter/supabase_flutter.dart';

/// Fila de [bombero] vinculada al usuario autenticado (`user_id` = `auth.users.id`).
Future<Map<String, dynamic>?> obtenerBomberoPorUsuario(SupabaseClient client) async {
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  return client
      .from('bombero')
      .select('rut_num, rut_dv, nomb_bombero, ape_p_bombero, is_admin, id_compania, user_id')
      .eq('user_id', uid)
      .maybeSingle();
}

Future<bool> usuarioEsBomberoRegistrado(SupabaseClient client) async {
  final row = await obtenerBomberoPorUsuario(client);
  return row != null;
}
