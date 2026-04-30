import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class RegistroPaso1 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const RegistroPaso1({super.key, required this.onNext, required this.onCancel});

  @override
  State<RegistroPaso1> createState() => _RegistroPaso1State();
}

class _RegistroPaso1State extends State<RegistroPaso1> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
        const TextField(decoration: InputDecoration(hintText: "tu@email.com")),
        const InputLabel(label: "Contraseña", required: true),
        TextField(
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
                onPressed: widget.onCancel,
                child: const Text("¿Ya tienes cuenta?"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onNext,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
