import 'package:flutter/services.dart';

/// Formato móvil chileno: 9 4444 4444 (9 dígitos, empieza por 9).
class ChileTelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final capped = digits.length > 9 ? digits.substring(0, 9) : digits;

    late final String out;
    if (capped.length <= 1) {
      out = capped;
    } else if (capped.length <= 5) {
      out = '${capped[0]} ${capped.substring(1)}';
    } else {
      out = '${capped[0]} ${capped.substring(1, 5)} ${capped.substring(5)}';
    }

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
