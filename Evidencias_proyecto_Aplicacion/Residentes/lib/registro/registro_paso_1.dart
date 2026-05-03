import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_utils.dart';
import '../widgets/custom_widgets.dart';

class RegistroPaso1 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const RegistroPaso1({super.key, required this.onNext, required this.onCancel});

  @override
  State<RegistroPaso1> createState() => _RegistroPaso1State();
}

class _RegistroPaso1State extends State<RegistroPaso1> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUpAndContinue() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('Completa todos los campos obligatorios.');
      return;
    }
    if (password.length < 8) {
      _showSnack('La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (password != confirm) {
      _showSnack('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        _showSnack('No se pudo crear la cuenta. Revisa los datos e intenta de nuevo.');
        return;
      }

      if (response.session == null) {
        _showSnack(
          'Cuenta creada. Si tu proyecto exige confirmar el correo, revisa tu bandeja '
          'y luego inicia sesión. Puedes continuar con el formulario.',
        );
      }

      widget.onNext();
    } on AuthException catch (e) {
      if (mounted) _showSnack(mensajeAuthError(e));
    } catch (e) {
      if (mounted) _showSnack(mensajeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_outline, size: 24),
            SizedBox(width: 8),
            Text(
              "Crear Cuenta",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Regístrate como titular del domicilio",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const InputLabel(label: "Email", required: true),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(hintText: "tu@email.com"),
        ),
        const InputLabel(label: "Contraseña", required: true),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: "Mínimo 8 caracteres",
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const InputLabel(label: "Confirmar contraseña", required: true),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: "Confirma tu contraseña",
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : widget.onCancel,
                child: const Text("¿Ya tienes cuenta?"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _signUpAndContinue,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
