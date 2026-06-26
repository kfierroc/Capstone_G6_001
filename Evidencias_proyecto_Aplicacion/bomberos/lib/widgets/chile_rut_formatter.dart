import 'package:flutter/services.dart';

/// Mínimo 8 dígitos (7 cuerpo + 1 DV). Máximo 9 (8 cuerpo + 1 DV).
const int rutDigitosMinimo = 8;
const int rutDigitosMaximo = 9;

/// Formato visual chileno mientras se escribe.
///
/// - 1 dígito: solo cuerpo (entrada incompleta).
/// - 2+ dígitos: cuerpo + guion + DV (el último dígito siempre es el DV).
///   Ej: `20222222` → `2.022.222-2`, `202222222` → `20.222.222-2`.
class ChileRutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    if (digits.length > rutDigitosMaximo) {
      digits = digits.substring(0, rutDigitosMaximo);
    }

    final split = _splitBodyDv(digits);
    final prettyBody = _puntosCuerpoRut(split.$1);
    final dv = split.$2;
    final out = dv.isEmpty ? prettyBody : '$prettyBody-$dv';

    final cursor = newValue.selection.isValid && newValue.selection.end >= newValue.text.length
        ? out.length
        : _mapCursor(oldValue, newValue, out);

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: cursor.clamp(0, out.length)),
    );
  }

  /// Con 2+ dígitos el último es siempre el DV (obligatorio el guion).
  static (String, String) _splitBodyDv(String digits) {
    if (digits.length <= 1) {
      return (digits, '');
    }
    return (digits.substring(0, digits.length - 1), digits.substring(digits.length - 1));
  }

  static int _mapCursor(TextEditingValue old, TextEditingValue neu, String out) {
    final oldDigits = old.text.replaceAll(RegExp(r'[^0-9K]'), '').length;
    final newDigits = neu.text.replaceAll(RegExp(r'[^0-9K]'), '').length;
    if (newDigits > oldDigits) return out.length;
    return neu.selection.end.clamp(0, out.length);
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

int contarDigitosRut(String raw) => raw.replaceAll(RegExp(r'[^0-9K]'), '').length;

bool rutChilenoTieneGuion(String raw) => raw.trim().contains('-');

bool rutChilenoLongitudValida(String raw) {
  final n = contarDigitosRut(raw);
  return n >= rutDigitosMinimo && n <= rutDigitosMaximo;
}
