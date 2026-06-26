import 'package:flutter/material.dart';

/// Paleta alineada a los mockups de registro bombero.
const Color kBomberosRojo = Color(0xFFC62828);
const Color kBomberosRojoOscuro = Color(0xFFB71C1C);
const Color kBomberosFondoCrema = Color(0xFFFFF8F6);
const Color kBomberosInputFill = Color(0xFFF3F4F6);

class BomberosRegistroAppBar extends StatelessWidget {
  const BomberosRegistroAppBar({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: kBomberosRojo,
      child: Padding(
        padding: EdgeInsets.only(top: top + 8, bottom: 12, left: 8, right: 16),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: onVolver,
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              label: const Text(
                'Volver',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Crear Cuenta - Bomberos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de 3 pasos (mockup: completados y actual en rojo, futuros en gris).
class BomberosRegistroStepIndicator extends StatelessWidget {
  const BomberosRegistroStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitle,
  });

  final int currentStep;
  final String stepTitle;

  @override
  Widget build(BuildContext context) {
    Widget circulo(int s) {
      final activo = s <= currentStep;
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: activo ? kBomberosRojo : const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$s',
            style: TextStyle(
              color: activo ? Colors.white : const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    Widget linea(bool activa) {
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 14),
          color: activa ? kBomberosRojo : const Color(0xFFE0E0E0),
        ),
      );
    }

    return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 44),
              circulo(1),
              linea(currentStep >= 2),
              circulo(2),
              linea(currentStep >= 3),
              circulo(3),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stepTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
    );
  }
}

class BomberosRegistroInputLabel extends StatelessWidget {
  const BomberosRegistroInputLabel({super.key, required this.label, this.required = true});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (required)
            const Text(' *', style: TextStyle(color: kBomberosRojo, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

InputDecoration bomberosRegistroFieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
    filled: true,
    fillColor: kBomberosInputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBomberosRojo, width: 1.5),
    ),
  );
}
