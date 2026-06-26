enum GrifoFiltroEstado { todos, operativos, danados, mantenimiento, desconocidos }

/// Cantidad de grifos por página en consultas paginadas.
const int kGrifosListaPagina = 20;

bool grifoCoincideFiltro(String estado, GrifoFiltroEstado filtro) {
  final e = estado.toLowerCase();
  switch (filtro) {
    case GrifoFiltroEstado.todos:
      return true;
    case GrifoFiltroEstado.operativos:
      return e.contains('operativo');
    case GrifoFiltroEstado.danados:
      return e.contains('dañado') || e.contains('danado');
    case GrifoFiltroEstado.mantenimiento:
      return e.contains('mantenimiento');
    case GrifoFiltroEstado.desconocidos:
      return e.contains('desconocido') || e.contains('sin verificar') || e.isEmpty;
  }
}

int totalGrifosParaFiltro(Map<String, int> estadisticas, GrifoFiltroEstado filtro) {
  switch (filtro) {
    case GrifoFiltroEstado.todos:
      return estadisticas['total'] ?? 0;
    case GrifoFiltroEstado.operativos:
      return estadisticas['operativos'] ?? 0;
    case GrifoFiltroEstado.danados:
      return estadisticas['danados'] ?? 0;
    case GrifoFiltroEstado.mantenimiento:
      return estadisticas['mantenimiento'] ?? 0;
    case GrifoFiltroEstado.desconocidos:
      return estadisticas['sin_verificar'] ?? 0;
  }
}

Map<String, int> grifoEstadisticasVacias() => const {
      'total': 0,
      'operativos': 0,
      'danados': 0,
      'mantenimiento': 0,
      'sin_verificar': 0,
    };

Map<String, int> grifoEstadisticasDesdeEstados(List<String> estados) {
  int contar(bool Function(String) pred) => estados.where((e) => pred(e.toLowerCase())).length;

  return {
    'total': estados.length,
    'operativos': contar((e) => e.contains('operativo')),
    'danados': contar((e) => e.contains('dañado') || e.contains('danado')),
    'mantenimiento': contar((e) => e.contains('mantenimiento')),
    'sin_verificar': contar((e) => e.contains('desconocido') || e.contains('sin verificar') || e.isEmpty),
  };
}
