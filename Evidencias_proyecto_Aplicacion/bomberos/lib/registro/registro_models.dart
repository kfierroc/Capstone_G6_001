/// Borrador del flujo de registro bombero (pasos 2–3 + metadatos para BD).
class RegistroBomberoBorrador {
  String? email;
  int? rutNum;
  String? rutDv;
  String? nombBombero;
  String? apePBombero;
  int? idCompania;
}

/// Acepta RUT solo con guion y DV. Mínimo 8 dígitos (ej. 2.022.222-2).
({int num, String dv})? parsearRutChileno(String raw) {
  final t = raw.trim().toUpperCase();
  if (!t.contains('-')) return null;

  final partes = t.split('-');
  if (partes.length != 2) return null;

  final body = partes[0].replaceAll(RegExp(r'[^0-9]'), '');
  final dv = partes[1].replaceAll(RegExp(r'[^0-9K]'), '');

  if (body.length < 7 || body.length > 8 || dv.length != 1) return null;
  if (!RegExp(r'^[\dK]$').hasMatch(dv)) return null;

  final totalDigitos = body.length + dv.length;
  if (totalDigitos < 8 || totalDigitos > 9) return null;

  final n = int.tryParse(body);
  if (n == null) return null;

  return (num: n, dv: dv);
}
