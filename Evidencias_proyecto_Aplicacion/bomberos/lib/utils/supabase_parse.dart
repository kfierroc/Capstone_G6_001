/// Lectura segura de valores desde filas de Supabase/PostgREST.
class SupabaseParse {
  SupabaseParse._();

  static int? asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double? asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static String? asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int requireInt(dynamic v, String campo) {
    final n = asInt(v);
    if (n == null) {
      throw FormatException('Campo "$campo" nulo o inválido en la respuesta de la BD.');
    }
    return n;
  }

  static double requireDouble(dynamic v, String campo) {
    final n = asDouble(v);
    if (n == null) {
      throw FormatException('Campo "$campo" nulo o inválido en la respuesta de la BD.');
    }
    return n;
  }

  static String requireString(dynamic v, String campo) {
    final s = asString(v);
    if (s == null) {
      throw FormatException('Campo "$campo" nulo o vacío en la respuesta de la BD.');
    }
    return s;
  }

  static Map<String, dynamic>? asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }
}
