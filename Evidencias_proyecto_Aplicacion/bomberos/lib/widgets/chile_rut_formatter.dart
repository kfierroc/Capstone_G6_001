import 'package:flutter/services.dart';

/// Formato visual chileno mientras se escribe (sin obligar a escribir el guion).
class ChileRutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    if (t.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final capped = t.length > 9 ? t.substring(0, 9) : t;

    late final String body;
    late final String dvPart;
    if (capped.length <= 8) {
      body = capped;
      dvPart = '';
    } else {
      body = capped.substring(0, 8);
      dvPart = capped.substring(8, 9);
    }

    final prettyBody = _puntosCuerpoRut(body);
    final out = dvPart.isEmpty ? prettyBody : '$prettyBody-$dvPart';

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }

  static String _puntosCuerpoRut(String body) {
    if (body.isEmpty) return '';
    if (body.length <= 3) return body;
    final rev = body.split('').reversed.join();
    final parts = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      final end = i + 3 < rev.length ? i + 3 : rev.length;
      parts.add(rev.substring(i, end).split('').reversed.join());
    }
    return parts.reversed.join('.');
  }
}
