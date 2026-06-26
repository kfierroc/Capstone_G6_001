import 'package:flutter/material.dart';

import '../../models/grifo_filtro_estado.dart';
import '../../models/grifo_mapa.dart';
import '../../utils/grifo_estado_utils.dart';

export '../../models/grifo_filtro_estado.dart' show GrifoFiltroEstado, kGrifosListaPagina;

/// Filtra y resume resultados de grifos (mapa y lista).
class GrifoListaUtils {
  GrifoListaUtils._();

  static bool _estadoEs(String estado, String fragmento) =>
      estado.toLowerCase().contains(fragmento.toLowerCase());

  static List<GrifoMapaResultado> filtrar(
    List<GrifoMapaResultado> list,
    GrifoFiltroEstado filtro,
  ) {
    switch (filtro) {
      case GrifoFiltroEstado.todos:
        return list;
      case GrifoFiltroEstado.operativos:
        return list.where((g) => _estadoEs(g.estado, 'operativo')).toList();
      case GrifoFiltroEstado.danados:
        return list.where((g) => _estadoEs(g.estado, 'dañado') || _estadoEs(g.estado, 'danado')).toList();
      case GrifoFiltroEstado.mantenimiento:
        return list.where((g) => _estadoEs(g.estado, 'mantenimiento')).toList();
      case GrifoFiltroEstado.desconocidos:
        return list
            .where(
              (g) =>
                  _estadoEs(g.estado, 'desconocido') ||
                  _estadoEs(g.estado, 'sin verificar') ||
                  g.estado.isEmpty,
            )
            .toList();
    }
  }

  static Map<String, int> estadisticasVacias() => grifoEstadisticasVacias();

  static bool coincideFiltro(String estado, GrifoFiltroEstado filtro) =>
      grifoCoincideFiltro(estado, filtro);

  static int totalParaFiltro(Map<String, int> estadisticas, GrifoFiltroEstado filtro) =>
      totalGrifosParaFiltro(estadisticas, filtro);

  static Map<String, int> estadisticas(List<GrifoMapaResultado> base) =>
      grifoEstadisticasDesdeEstados(base.map((g) => g.estado).toList());
}

/// Tarjetas de resumen (total, operativos, etc.).
class GrifosEstadisticasTarjetas extends StatelessWidget {
  const GrifosEstadisticasTarjetas({super.key, required this.estadisticas});

  static const _azul = Color(0xFF1565C0);

  final Map<String, int> estadisticas;

  @override
  Widget build(BuildContext context) {
    Widget card(String valor, String etiqueta, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Text(
                etiqueta,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final s = estadisticas;
    return Column(
      children: [
        Row(
          children: [
            card('${s['total']}', 'Total', _azul),
            const SizedBox(width: 8),
            card('${s['operativos']}', 'Operativos', GrifoEstadoUtils.verde),
            const SizedBox(width: 8),
            card('${s['danados']}', 'Dañados', GrifoEstadoUtils.rojo),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            card('${s['mantenimiento']}', 'Mantenimiento', GrifoEstadoUtils.amarillo),
            const SizedBox(width: 8),
            card('${s['sin_verificar']}', 'Sin verificar', GrifoEstadoUtils.gris),
          ],
        ),
      ],
    );
  }
}

/// Chips para filtrar por estado.
class GrifosFiltroEstadoChips extends StatelessWidget {
  const GrifosFiltroEstadoChips({
    super.key,
    required this.filtro,
    required this.onFiltroChanged,
  });

  static const _azul = Color(0xFF1565C0);

  final GrifoFiltroEstado filtro;
  final ValueChanged<GrifoFiltroEstado> onFiltroChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, GrifoFiltroEstado valor) {
      final sel = filtro == valor;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: FilterChip(
          label: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.black87)),
          selected: sel,
          onSelected: (_) => onFiltroChanged(valor),
          selectedColor: _azul,
          backgroundColor: Colors.white,
          side: BorderSide(color: sel ? _azul : Colors.grey.shade300),
          showCheckmark: false,
        ),
      );
    }

    return Wrap(
      children: [
        chip('Todos', GrifoFiltroEstado.todos),
        chip('Operativos', GrifoFiltroEstado.operativos),
        chip('Dañados', GrifoFiltroEstado.danados),
        chip('Mantenimiento', GrifoFiltroEstado.mantenimiento),
        chip('Desconocidos', GrifoFiltroEstado.desconocidos),
      ],
    );
  }
}

/// Tarjeta de un grifo en la lista.
class GrifoTarjetaLista extends StatelessWidget {
  const GrifoTarjetaLista({
    super.key,
    required this.grifo,
    this.destacado = false,
    this.onVerEnMapa,
    this.onEditar,
  });

  static const _azul = Color(0xFF1565C0);
  static const _naranja = Color(0xFFE65100);

  final GrifoMapaResultado grifo;
  final bool destacado;
  final VoidCallback? onVerEnMapa;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final color = GrifoEstadoUtils.colorPorEstado(grifo.estado);
    final mostrarMapa = onVerEnMapa != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacado ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destacado ? _naranja : Colors.grey.shade200,
          width: destacado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('#${grifo.idGrifo}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        grifo.estado,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (mostrarMapa) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: onVerEnMapa,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: destacado ? _naranja : _azul,
                        side: BorderSide(color: destacado ? _naranja : _azul),
                        backgroundColor: destacado ? const Color(0xFFFFE0B2) : Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        destacado ? 'En mapa' : 'Ver en mapa',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.edit_outlined, color: _azul, size: 22),
                      tooltip: 'Editar grifo',
                      onPressed: onEditar,
                    ),
                  ],
                ),
              ] else if (onEditar != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: _azul),
                  tooltip: 'Editar grifo',
                  onPressed: onEditar,
                ),
            ],
          ),
          _filaDetalle('Última inspección', grifo.fechaFormateada),
          if (grifo.notas != null && grifo.notas!.isNotEmpty) _filaDetalle('Notas', grifo.notas!),
          if (grifo.comunaNombre.isNotEmpty) _filaDetalle('Comuna', grifo.comunaNombre),
          const SizedBox(height: 8),
          Text(
            'Reportado por ${grifo.reportadoPor} el ${grifo.fechaFormateada}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _filaDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.35),
          children: [
            TextSpan(
              text: '$etiqueta: ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}

/// Lista de tarjetas con botón «cargar más» (paginación desde servidor).
class GrifosListaPaginada extends StatelessWidget {
  const GrifosListaPaginada({
    super.key,
    required this.grifos,
    required this.total,
    this.idGrifoDestacado,
    this.onVerEnMapa,
    this.onEditar,
    this.hayMas = false,
    this.cargandoMas = false,
    this.onCargarMas,
  });

  final List<GrifoMapaResultado> grifos;
  final int total;
  final int? idGrifoDestacado;
  final ValueChanged<GrifoMapaResultado>? onVerEnMapa;
  final Future<void> Function(GrifoMapaResultado)? onEditar;
  final bool hayMas;
  final bool cargandoMas;
  final VoidCallback? onCargarMas;

  static const _azul = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    if (grifos.isEmpty) return const SizedBox.shrink();

    final mostrando = grifos.length;
    final siguiente = (total - mostrando).clamp(1, kGrifosListaPagina);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...grifos.map(
          (g) => GrifoTarjetaLista(
            grifo: g,
            destacado: g.idGrifo == idGrifoDestacado,
            onVerEnMapa: onVerEnMapa != null ? () => onVerEnMapa!(g) : null,
            onEditar: onEditar != null ? () { onEditar!(g); } : null,
          ),
        ),
        if (hayMas) ...[
          const SizedBox(height: 4),
          Center(
            child: OutlinedButton(
              onPressed: cargandoMas ? null : onCargarMas,
              style: OutlinedButton.styleFrom(
                foregroundColor: _azul,
                side: const BorderSide(color: _azul),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: cargandoMas
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _azul),
                    )
                  : Text(
                      'Mostrar $siguiente más',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          hayMas ? 'Mostrando $mostrando de $total' : 'Mostrando $mostrando grifo${mostrando == 1 ? '' : 's'}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// Estadísticas, filtros y lista de grifos (reutilizable en mapa y lista).
class GrifosPanelResultados extends StatelessWidget {
  const GrifosPanelResultados({
    super.key,
    required this.resultados,
    required this.filtro,
    required this.onFiltroChanged,
    this.estadisticas,
    this.mensajeVacio = 'Busca en el mapa o por ID para ver grifos en la lista.',
    this.mostrarTitulo = true,
    this.idGrifoDestacado,
    this.onVerEnMapa,
    this.onEditar,
    this.hayMas = false,
    this.cargandoMas = false,
    this.onCargarMas,
  });

  final List<GrifoMapaResultado> resultados;
  final GrifoFiltroEstado filtro;
  final ValueChanged<GrifoFiltroEstado> onFiltroChanged;
  final Map<String, int>? estadisticas;
  final String mensajeVacio;
  final bool mostrarTitulo;
  final int? idGrifoDestacado;
  final ValueChanged<GrifoMapaResultado>? onVerEnMapa;
  final Future<void> Function(GrifoMapaResultado)? onEditar;
  final bool hayMas;
  final bool cargandoMas;
  final VoidCallback? onCargarMas;

  @override
  Widget build(BuildContext context) {
    final stats = estadisticas ?? GrifoListaUtils.estadisticas(resultados);
    final visibles = estadisticas != null
        ? resultados
        : GrifoListaUtils.filtrar(resultados, filtro);
    final totalFiltro = estadisticas != null
        ? GrifoListaUtils.totalParaFiltro(stats, filtro)
        : visibles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GrifosEstadisticasTarjetas(estadisticas: stats),
        const SizedBox(height: 16),
        if (mostrarTitulo)
          Text(
            'Lista de Grifos ($totalFiltro)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        if (mostrarTitulo) const SizedBox(height: 10),
        GrifosFiltroEstadoChips(filtro: filtro, onFiltroChanged: onFiltroChanged),
        const SizedBox(height: 8),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              totalFiltro == 0 && filtro != GrifoFiltroEstado.todos
                  ? 'Ningún grifo coincide con el filtro de estado.'
                  : mensajeVacio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          )
        else
          GrifosListaPaginada(
            grifos: visibles,
            total: totalFiltro,
            idGrifoDestacado: idGrifoDestacado,
            onVerEnMapa: onVerEnMapa,
            onEditar: onEditar,
            hayMas: hayMas,
            cargandoMas: cargandoMas,
            onCargarMas: onCargarMas,
          ),
      ],
    );
  }
}
