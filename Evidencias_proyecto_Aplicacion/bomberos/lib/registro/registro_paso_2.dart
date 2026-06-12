import 'package:flutter/material.dart';

import '../widgets/bomberos_registro_widgets.dart';
import '../widgets/chile_rut_formatter.dart';
import 'registro_models.dart';

/// Paso 2 — nombre, apellido y RUT.
class RegistroPaso2 extends StatefulWidget {
  const RegistroPaso2({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
    required this.onIrALogin,
  });

  final RegistroBomberoBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onIrALogin;

  @override
  State<RegistroPaso2> createState() => _RegistroPaso2State();
}

class _RegistroPaso2State extends State<RegistroPaso2> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _rutController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _rutController.dispose();
    super.dispose();
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _continuar() {
    final nom = _nombreController.text.trim();
    final ape = _apellidoController.text.trim();
    final parsed = parsearRutChileno(_rutController.text);
    if (nom.isEmpty || ape.isEmpty) {
      _showSnack('Completa nombre y apellido.');
      return;
    }
    if (parsed == null) {
      _showSnack('RUT inválido.');
      return;
    }
    widget.draft.nombBombero = nom;
    widget.draft.apePBombero = ape;
    widget.draft.rutNum = parsed.num;
    widget.draft.rutDv = parsed.dv;
    widget.onNext();
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
          'Paso 2 de 3 - Información Personal',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        const BomberosRegistroInputLabel(label: 'Nombre'),
        TextField(
          controller: _nombreController,
          textCapitalization: TextCapitalization.words,
          decoration: bomberosRegistroFieldDecoration(hint: 'Juan'),
        ),
        const BomberosRegistroInputLabel(label: 'Apellido'),
        TextField(
          controller: _apellidoController,
          textCapitalization: TextCapitalization.words,
          decoration: bomberosRegistroFieldDecoration(hint: 'Pérez Silva'),
        ),
        const BomberosRegistroInputLabel(label: 'RUT'),
        TextField(
          controller: _rutController,
          keyboardType: TextInputType.text,
          inputFormatters: [ChileRutInputFormatter()],
          decoration: bomberosRegistroFieldDecoration(hint: '12.345.678-9'),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _continuar,
                style: FilledButton.styleFrom(
                  backgroundColor: kBomberosRojo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: widget.onIrALogin,
            child: const Text(
              '¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(color: kBomberosRojo, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
