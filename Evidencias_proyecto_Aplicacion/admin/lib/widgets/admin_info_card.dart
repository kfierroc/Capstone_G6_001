import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class AdminInfoFila {
  const AdminInfoFila(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;
}

class AdminInfoCard extends StatelessWidget {
  const AdminInfoCard({
    super.key,
    required this.titulo,
    required this.icono,
    required this.filas,
    this.onEditar,
  });

  final String titulo;
  final IconData icono;
  final List<AdminInfoFila> filas;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: AdminTheme.infoBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.titleText,
                  ),
                ),
              ),
              if (onEditar != null)
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...filas.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      f.etiqueta,
                      style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.valor,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AdminTheme.titleText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
