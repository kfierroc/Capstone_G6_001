/// Borrador del flujo de registro bombero (pasos 2–3 + metadatos para BD).
class RegistroBomberoBorrador {
  String? email;
  int? rutNum;
  String? rutDv;
  String? nombBombero;
  String? apePBombero;
  int? idCompania;
}

/// Acepta RUT con o sin puntos y con guion.
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
