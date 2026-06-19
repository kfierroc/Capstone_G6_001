import 'package:supabase_flutter/supabase_flutter.dart';

import '../registro/registro_models.dart';

class RegistroBomberoException implements Exception {
  RegistroBomberoException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RegistroBomberoService {
  RegistroBomberoService(this._client);

  final SupabaseClient _client;

  String _trunc(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  /// Inserta fila en `bombero` para el usuario autenticado actual.
  Future<void> registrar(RegistroBomberoBorrador d) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw RegistroBomberoException(
        'No hay sesión activa. Si debes confirmar el correo, hazlo e inicia sesión antes de finalizar.',
      );
    }
    if (d.rutNum == null ||
        d.rutDv == null ||
        d.nombBombero == null ||
        d.nombBombero!.trim().isEmpty ||
        d.apePBombero == null ||
        d.apePBombero!.trim().isEmpty ||
        d.idCompania == null) {
      throw RegistroBomberoException('Faltan datos obligatorios del formulario.');
    }

    final porUser = await _client.from('bombero').select('rut_num').eq('user_id', uid).maybeSingle();
    if (porUser != null) {
      throw RegistroBomberoException('Tu usuario ya tiene un perfil de bombero registrado.');
    }

    final porRut =
        await _client.from('bombero').select('rut_num').eq('rut_num', d.rutNum!).maybeSingle();
    if (porRut != null) {
      throw RegistroBomberoException('Este RUT ya está registrado como bombero.');
    }

    try {
      await _client.from('bombero').insert({
        'rut_num': d.rutNum,
        'rut_dv': d.rutDv!.toUpperCase(),
        'nomb_bombero': _trunc(d.nombBombero!.trim(), 50),
        'ape_p_bombero': _trunc(d.apePBombero!.trim(), 50),
        'is_admin': false,
        'user_id': uid,
        'id_compania': d.idCompania,
      });
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('duplicate') || msg.contains('unique') || msg.contains('23505')) {
        throw RegistroBomberoException('Ya existe un registro en conflicto (RUT o usuario duplicado).');
      }
      throw RegistroBomberoException(msg);
    }
  }
}
