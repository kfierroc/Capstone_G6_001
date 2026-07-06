import 'package:flutter/material.dart';

import '../models/dashboard_desglose.dart';
import '../theme/admin_theme.dart';

/// Lista de barras horizontales para desgloses del dashboard.
class DashboardDesgloseBars extends StatelessWidget {
  const DashboardDesgloseBars({
    super.key,
    required this.items,
    this.maxItems = 8,
    this.color = AdminTheme.infoBlue,
    this.emptyMessage = 'Sin datos en este ámbito.',
  });

  final List<DashboardDesglose> items;
  final int maxItems;
  final Color color;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(emptyMessage, style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText));
    }

    final visibles = items.take(maxItems).toList();
    final maxCantidad = visibles.map((e) => e.cantidad).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < visibles.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _BarraFila(
            etiqueta: visibles[i].etiqueta,
            cantidad: visibles[i].cantidad,
            maxCantidad: maxCantidad,
            color: color,
          ),
        ],
      ],
    );
  }
}

class _BarraFila extends StatelessWidget {
  const _BarraFila({
    required this.etiqueta,
    required this.cantidad,
    required this.maxCantidad,
    required this.color,
  });

  final String etiqueta;
  final int cantidad;
  final int maxCantidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraccion = maxCantidad > 0 ? cantidad / maxCantidad : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                etiqueta,
                style: const TextStyle(fontSize: 13, color: AdminTheme.titleText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$cantidad',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraccion,
            minHeight: 6,
            backgroundColor: const Color(0xFFF3F4F6),
            color: color,
          ),
        ),
      ],
    );
  }
}
