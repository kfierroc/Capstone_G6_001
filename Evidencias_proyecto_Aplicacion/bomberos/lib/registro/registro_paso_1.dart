import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_utils.dart';
import '../widgets/bomberos_registro_widgets.dart';
import 'registro_models.dart';

/// Paso 1 — credenciales (misma lógica que Residentes: `signUp` y continuar).
class RegistroPaso1 extends StatefulWidget {
  const RegistroPaso1({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onIrALogin,
  });

  final RegistroBomberoBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onIrALogin;

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

      widget.draft.email = email;

      if (response.session == null) {
        _showSnack(
          'Cuenta creada. Si tu proyecto exige confirmar el correo, revisa tu bandeja '
          'antes de poder usar la app. Puedes continuar con el formulario si ya tienes sesión.',
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Crear Cuenta Nueva',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Paso 1 de 3 - Credenciales de Acceso',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        const BomberosRegistroInputLabel(label: 'Email'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: bomberosRegistroFieldDecoration(hint: 'tu@bomberos.cl'),
        ),
        const BomberosRegistroInputLabel(label: 'Contraseña'),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: bomberosRegistroFieldDecoration(hint: 'Mínimo 8 caracteres').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const BomberosRegistroInputLabel(label: 'Confirmar contraseña'),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirmPassword,
          decoration: bomberosRegistroFieldDecoration(hint: 'Confirma tu contraseña').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _loading ? null : _signUpAndContinue,
            style: FilledButton.styleFrom(
              backgroundColor: kBomberosRojo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: _loading ? null : widget.onIrALogin,
            child: const Text(
              '¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(
                color: kBomberosRojo,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
