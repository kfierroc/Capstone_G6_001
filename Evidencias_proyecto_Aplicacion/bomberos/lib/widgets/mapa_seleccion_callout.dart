import 'package:flutter/material.dart';

/// Cartel sobre el mapa (sustituto del InfoWindow nativo con mejor diseño).
class MapaSeleccionCallout extends StatelessWidget {
  const MapaSeleccionCallout({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.onCerrar,
    this.accentColor = const Color(0xFF1565C0),
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback onCerrar;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCerrar,
                    icon: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  subtitulo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
