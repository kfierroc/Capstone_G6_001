import 'package:supabase_flutter/supabase_flutter.dart';

/// Solo usuarios con fila en `grupofamiliar` (rol residente vía tabla) acceden a la app.
Future<bool> usuarioTieneGrupoFamiliar(SupabaseClient client) async {
  final uid = client.auth.currentUser?.id;
  if (uid == null) return false;
  final row = await client
      .from('grupofamiliar')
      .select('id_grupof')
      .eq('user_id', uid)
      .maybeSingle();
  return row != null;
}
