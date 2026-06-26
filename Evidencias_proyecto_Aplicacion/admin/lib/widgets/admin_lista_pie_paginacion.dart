import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

/// Pie reutilizable: contador + botón «Ver más registros».
class AdminListaPiePaginacion extends StatelessWidget {
  const AdminListaPiePaginacion({
    super.key,
    required this.totalMostrado,
    required this.etiquetaSingular,
    required this.etiquetaPlural,
    required this.hayMas,
    required this.cargandoMas,
    required this.onCargarMas,
  });

  final int totalMostrado;
  final String etiquetaSingular;
  final String etiquetaPlural;
  final bool hayMas;
  final bool cargandoMas;
  final VoidCallback onCargarMas;

  @override
  Widget build(BuildContext context) {
    if (!hayMas && !cargandoMas && totalMostrado == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminTheme.cardBorder)),
      ),
      child: Column(
        children: [
          if (totalMostrado > 0)
            Text(
              'Mostrando $totalMostrado ${totalMostrado == 1 ? etiquetaSingular : etiquetaPlural}',
              style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
            ),
          if (hayMas) ...[
            if (totalMostrado > 0) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cargandoMas ? null : onCargarMas,
              icon: cargandoMas
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more, size: 20),
              label: Text(cargandoMas ? 'Cargando…' : 'Ver más registros'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.infoBlue,
                side: const BorderSide(color: AdminTheme.infoBlue),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
