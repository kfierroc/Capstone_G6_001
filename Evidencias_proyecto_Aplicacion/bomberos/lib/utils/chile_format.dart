/// Formateo y parseo de datos chilenos (RUT, teléfono).
class ChileFormat {
  ChileFormat._();

  /// Puntos de miles + guion para el cuerpo y dígito verificador.
  static String formatearRut(int rutNum, String dv) {
    return '${_puntosCuerpoRut(rutNum.toString())}-${dv.toUpperCase()}';
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

  /// Formato móvil chileno: `9 4444 4444`. Tolera prefijo +56.
  static String formatearTelefono(String? raw) {
    if (raw == null) return '—';
    final t = raw.trim();
    if (t.isEmpty || t == '—') return t.isEmpty ? '—' : t;

    var digits = t.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('56') && digits.length >= 11) {
      digits = digits.substring(2);
    }

    if (digits.length == 9 && digits.startsWith('9')) {
      return '${digits[0]} ${digits.substring(1, 5)} ${digits.substring(5)}';
    }
    if (digits.length == 8) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 1)} ${digits.substring(1, 5)} ${digits.substring(5)}';
    }
    return t;
  }

  /// Extrae dígitos iniciales de un número de dirección (ej. `1234-A` → 1234).
  static int? parseNroDireccion(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final directo = int.tryParse(s);
    if (directo != null) return directo;
    final m = RegExp(r'^(\d+)').firstMatch(s);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  /// Texto legible del número de dirección tal como está en BD.
  static String nroDireccionMostrar(dynamic v) {
    if (v == null) return 's/n';
    final s = v.toString().trim();
    return s.isEmpty ? 's/n' : s;
  }
}
