import 'package:flutter/services.dart';

/// Formato chileno mientras se escribe: móvil `9 4444 4444`.
class ChileTelefonoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('56') && digits.length > 9) {
      digits = digits.substring(2);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final out = _formatearDigitos(digits);
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  static String _formatearDigitos(String digits) {
    if (digits.length <= 1) return digits;
    if (digits.length <= 5) {
      return '${digits[0]} ${digits.substring(1)}';
    }
    return '${digits[0]} ${digits.substring(1, 5)} ${digits.substring(5)}';
  }
}
