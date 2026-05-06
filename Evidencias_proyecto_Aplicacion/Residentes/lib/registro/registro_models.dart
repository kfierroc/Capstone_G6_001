/// Datos del flujo de registro residente (pasos 2–4 + metadatos para guardar en BD).
class RegistroResidenteBorrador {
  /// Paso 2 — titular
  int? rutNum;
  String? rutDv;
  String? telefonoNormalizado;
  DateTime? fechaNacimiento;
  final List<String> condicionesMedicas = [];

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
  String? notasVivienda;
  final List<PisoBorrador> pisos = [];
}

class PisoBorrador {
  PisoBorrador({required this.numerop, required this.materialEtiqueta});

  final int numerop;
  final String materialEtiqueta;
}

/// Acepta RUT con o sin puntos y con guion (el formateador añade guion y puntos al escribir).
({int num, String dv})? parsearRutChileno(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[\.\s]'), '').toUpperCase();
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
  final d = raw.replaceAll(RegExp(r'\s'), '');
  if (d.length != 9) return null;
  if (!RegExp(r'^9\d{8}$').hasMatch(d)) return null;
  return '+56$d';
}
