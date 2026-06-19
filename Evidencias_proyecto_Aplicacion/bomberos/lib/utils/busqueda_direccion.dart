/// Parseo de términos de búsqueda de domicilio (calle + número).
class TerminoDireccionBusqueda {
  const TerminoDireccionBusqueda({
    required this.original,
    this.calle,
    this.numero,
  });

  final String original;
  final String? calle;
  final int? numero;

  bool get soloNumero => numero != null && (calle == null || calle!.isEmpty);
  bool get soloCalle => numero == null && calle != null && calle!.isNotEmpty;
  bool get calleYNumero => numero != null && calle != null && calle!.isNotEmpty;
}

TerminoDireccionBusqueda parsearTerminoDireccion(String raw) {
  var t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.isEmpty) {
    return TerminoDireccionBusqueda(original: raw);
  }

  int? numero;
  var calle = t;

  // N° 1234, #1234, nro 1234 al final o en cualquier parte.
  final patronesNumero = [
    RegExp(r'(?:^|\s)(?:n[°ºo]\.?\s*|#)\s*(\d{1,6})\s*$', caseSensitive: false),
    RegExp(r'(?:^|\s)(\d{1,6})\s*$'),
  ];

  for (final patron in patronesNumero) {
    final m = patron.firstMatch(t);
    if (m != null) {
      numero = int.tryParse(m.group(1)!);
      calle = t.substring(0, m.start).trim();
      if (calle.endsWith(',') || calle.endsWith('-')) {
        calle = calle.substring(0, calle.length - 1).trim();
      }
      break;
    }
  }

  // Solo dígitos → búsqueda por número.
  if (numero == null && RegExp(r'^\d{1,6}$').hasMatch(t)) {
    return TerminoDireccionBusqueda(original: raw, numero: int.parse(t));
  }

  if (calle.isEmpty && numero != null) {
    return TerminoDireccionBusqueda(original: raw, numero: numero);
  }

  // Quitar prefijos frecuentes para ampliar coincidencias en calle.
  calle = calle
      .replaceFirst(RegExp(r'^(av\.?|avenida|calle|pasaje|psje\.?)\s+', caseSensitive: false), '')
      .trim();

  return TerminoDireccionBusqueda(
    original: raw,
    calle: calle.isEmpty ? null : calle,
    numero: numero,
  );
}

/// Escapa caracteres especiales de ILIKE en PostgreSQL.
String escaparIlike(String s) => s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

/// Palabras significativas para búsqueda parcial (ignora artículos cortos).
List<String> palabrasClaveCalle(String calle) {
  return calle
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'[^\wáéíóúñÁÉÍÓÚÑ]'), ''))
      .where((w) => w.length >= 3)
      .toList();
}
