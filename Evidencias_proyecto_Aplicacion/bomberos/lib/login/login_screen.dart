import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_utils.dart';
import '../auth/bombero_access.dart';
import '../models/bombero_perfil.dart';
import '../screens/home_bombero_screen.dart';
import '../widgets/custom_widgets.dart';

/// Login con Supabase Auth; solo continúa si existe fila en `bombero` con `user_id` del usuario.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      final row = await obtenerBomberoPorUsuario(client);
      if (row == null) {
        await client.auth.signOut();
        if (!mounted) return;
        _showSnack(
          'Esta aplicación es solo para bomberos. Tu cuenta no está registrada en el sistema o falta vincular tu usuario en la tabla bombero.',
        );
        return;
      }

      final perfil = BomberoPerfil.fromMap(row);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => HomeBomberoScreen(perfil: perfil)),
        (_) => false,
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
    final tituloLogin = screenW >= 900 ? 24.0 : screenW >= 600 ? 22.0 : 20.0;
    final subtituloLogin = screenW >= 900 ? 15.0 : 14.0;

    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(
            title: 'App Bomberos',
            subtitle: 'Inicia sesión para continuar',
            showBack: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: screenW >= 600 ? 28 : 16),
              child: ResponsiveContainer(
                child: Column(
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: tituloLogin, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: screenW >= 600 ? 10 : 8),
                    Text(
                      'Usa el correo vinculado a tu registro de bombero',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: subtituloLogin),
                    ),
                    SizedBox(height: screenW >= 600 ? 28 : 20),
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
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¿No puedes entrar? Solicita en tu compañía que te den de alta y vinculen tu correo en la tabla bombero (user_id).',
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
