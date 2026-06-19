/// Datos del flujo de registro residente (pasos 2–4 + metadatos para guardar en BD).
class RegistroResidenteBorrador {
  /// Paso 2 — titular
  int? rutNum;
  String? rutDv;
  String? telefonoNormalizado;
  DateTime? fechaNacimiento;
  /// `condiciones.id_condicion` seleccionadas para el titular (paso 2).
  final List<int> idsCondiciones = [];

  /// Paso 3 — domicilio
  String? calle;
  int? nroDireccion;
  String? unidad;
  double? lat;
  double? lon;

  /// Paso 4 — vivienda (1–6 meses; solo front, no hay tabla de catálogo)
  int? mesesTiempoResidencia;
  String? tipoViviendaEtiqueta;
  String? estadoViviendaEtiqueta;
  /// Solo departamento/condominio → columna `desc_depto_cond` (máx. 50 en BD).
  String? descDeptoCond;
  String? notasVivienda;
  final List<PisoBorrador> pisos = [];
}

class PisoBorrador {
  PisoBorrador({required this.numerop, required this.materialEtiqueta});

  final int numerop;
  final String materialEtiqueta;
}

/// Acepta RUT con puntos y guion (el formateador añade guion desde el 8.º dígito).
/// RUT completo: 8–9 caracteres (7–8 cuerpo + 1 DV). Con 8+ dígitos el guion es obligatorio.
({int num, String dv})? parsearRutChileno(String raw) {
  final trimmed = raw.trim().toUpperCase();
  final digitos = trimmed.replaceAll(RegExp(r'[^0-9]'), '').length;
  final total = digitos + (trimmed.contains('K') ? 1 : 0);
  if (total < 8) return null;
  if (total >= 8 && !trimmed.contains('-')) return null;

  var s = trimmed.replaceAll(RegExp(r'[\.\s]'), '');
  if (s.length < 2) return null;
  final dv = s.substring(s.length - 1);
  if (!RegExp(r'^[\dK]$').hasMatch(dv)) return null;
  final body = s.substring(0, s.length - 1).replaceAll(RegExp(r'[^0-9]'), '');
  if (body.isEmpty || body.length > 8) return null;
  final n = int.tryParse(body);
  if (n == null) return null;
  return (num: n, dv: dv);
}

/// Solo el número después de +56 (9 dígitos, móvil 9XXXXXXXX). El usuario no escribe +56 en pantalla.
/// CHECK BD: `^\+56[2-9][0-9]{8}$`
String? normalizarTelefonoSufijoChile(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) return null;
  if (!RegExp(r'^9\d{8}$').hasMatch(d)) return null;
  return '+56$d';
}

/// Sufijo de 9 dígitos con espacios para campos de edición (ej. 9 4444 4444).
String telefonoSufijoParaCampo(String guardado) {
  var d = guardado.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('56') && d.length >= 11) {
    d = d.substring(2);
  }
  if (d.length != 9) return d;
  return formatearTelefonoSufijo(d);
}

/// Formato visual del sufijo móvil (9 4444 4444).
String formatearTelefonoSufijo(String nueveDigitos) {
  final d = nueveDigitos.replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) return nueveDigitos;
  return '${d[0]} ${d.substring(1, 5)} ${d.substring(5)}';
}

/// Formato visual con prefijo +56 (ej. +56 9 4444 4444).
String formatearTelefonoMostrar(String guardado) {
  final norm = guardado.replaceAll(RegExp(r'\s'), '');
  if (norm.startsWith('+56') && norm.length == 12) {
    return '+56 ${formatearTelefonoSufijo(norm.substring(3))}';
  }
  final d = norm.replaceAll(RegExp(r'\D'), '');
  if (d.length == 9) return formatearTelefonoSufijo(d);
  return guardado;
}

/// Formato visual con puntos cada 3 dígitos desde la derecha (ej. 12.345.678-9).
String formatearRutMostrar(int rutNum, String rutDv) {
  var s = rutNum.toString();
  final partes = <String>[];
  while (s.length > 3) {
    partes.add(s.substring(s.length - 3));
    s = s.substring(0, s.length - 3);
  }
  if (s.isNotEmpty) partes.add(s);
  final cuerpo = partes.reversed.join('.');
  return '$cuerpo-${rutDv.toUpperCase()}';
}
