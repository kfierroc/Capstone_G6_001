import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/admin_access.dart';
import '../auth/auth_utils.dart';
import '../models/admin_bombero_perfil.dart';
import '../widgets/custom_widgets.dart';
import 'admin_home_screen.dart';

/// Login con Supabase Auth; solo administradores (`is_admin` = true).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF283593);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Ingresa correo y contraseña.');
      return;
    }

    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      await client.auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;

      final bombero = await obtenerBomberoPorUsuario(client);
      if (bombero == null) {
        await client.auth.signOut();
        if (!mounted) return;
        _showSnack(
          'Tu cuenta no está registrada como bombero o falta vincular tu usuario en la tabla bombero.',
        );
        return;
      }

      if (bombero['is_admin'] != true) {
        await client.auth.signOut();
        if (!mounted) return;
        _showSnack(
          'Acceso denegado. Solo bomberos con rol administrador (is_admin) pueden ingresar al panel.',
        );
        return;
      }

      final perfil = AdminBomberoPerfil.fromMap(bombero);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => AdminHomeScreen(perfil: perfil)),
      );
    } on AuthException catch (e) {
      if (mounted) _showSnack(mensajeAuthError(e));
    } catch (e) {
      if (mounted) _showSnack(mensajeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Panel de Administración',
            subtitle: 'Acceso restringido a administradores',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: screenW >= 600 ? 22 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usa el mismo correo y contraseña de tu cuenta de bombero',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.35),
                    ),
                    const InputLabel(label: 'Correo electrónico'),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(hintText: 'tu@email.com'),
                    ),
                    const InputLabel(label: 'Contraseña'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Tu contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay registro en este panel. Si necesitas acceso administrativo, '
                      'solicítalo en tu compañía.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
