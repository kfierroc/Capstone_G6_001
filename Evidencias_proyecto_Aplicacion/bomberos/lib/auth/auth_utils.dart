import 'package:supabase_flutter/supabase_flutter.dart';

/// Mensaje legible en español a partir de errores de Supabase Auth.
String mensajeAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    if (msg.contains('user already registered')) {
      return 'Este correo ya está registrado. Inicia sesión o recupera tu contraseña.';
    }
    return error.message;
  }
  return 'No se pudo completar la operación. Intenta de nuevo.';
}
