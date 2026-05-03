import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_utils.dart';
import '../auth/residente_access.dart';
import '../widgets/custom_widgets.dart';
import '../registro/registro_screen.dart';

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

      final tieneGrupo = await usuarioTieneGrupoFamiliar(client);
      if (!tieneGrupo) {
        if (!mounted) return;
        _showSnack('Tu cuenta aún no está vinculada a un grupo familiar. Completa el registro.');
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const RegistroScreen(saltarRegistroAuth: true),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/gestion-familia',
        (route) => false,
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
    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(
            title: "App para Residentes",
            subtitle: "Inicia sesión para continuar",
            showBack: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ResponsiveContainer(
                child: Column(
                  children: [
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Accede a tu información familiar registrada",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const InputLabel(label: "Correo electrónico"),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(hintText: "tu@email.com"),
                    ),
                    const InputLabel(label: "Contraseña"),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Tu contraseña",
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
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Iniciar Sesión"),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegistroScreen()),
                              );
                            },
                      child: const Text(
                        "¿No tienes cuenta? Regístrate aquí",
                        style: TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold),
                      ),
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
