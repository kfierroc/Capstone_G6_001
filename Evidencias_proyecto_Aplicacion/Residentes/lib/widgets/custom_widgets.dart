import 'package:flutter/material.dart';

/// Contenedor centrado con ancho máximo según el viewport (login, registro, etc.).
/// En pantallas anchas (web/tablet) usa más ancho y más padding que en móvil.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  /// Si no es null, limita el ancho del contenido (p. ej. paso 3 con mapa amplio).
  final double? maxWidth;

  const ResponsiveContainer({super.key, required this.child, this.maxWidth});

  static double _defaultMaxWidth(double screenWidth) {
    if (screenWidth >= 1400) return 1080;
    if (screenWidth >= 1100) return 920;
    if (screenWidth >= 800) return 720;
    if (screenWidth >= 600) return 580;
    return 520;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final effectiveMax = maxWidth ?? _defaultMaxWidth(screenW);
    final outer = screenW >= 900
        ? 40.0
        : screenW >= 600
            ? 28.0
            : 20.0;
    final inner = screenW >= 900
        ? 36.0
        : screenW >= 600
            ? 28.0
            : 22.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(outer, outer, outer, outer + 8),
          child: Card(
            elevation: screenW >= 600 ? 3 : 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(inner),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  /// Acción o icono a la derecha (p. ej. notificaciones en el home residente).
  final Widget? trailing;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF00A84E),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack ?? () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 48),
              const Icon(Icons.home_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class StepIndicator extends StatelessWidget {
  final int currentStep;
  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontal = w >= 1100 ? 56.0 : w >= 800 ? 36.0 : w >= 600 ? 20.0 : 0.0;
    final vertical = w >= 900 ? 24.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          int step = index + 1;
          bool isCompleted = step < currentStep;
          bool isActive = step == currentStep;

          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive || isCompleted ? const Color(0xFF00A84E) : const Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "$step",
                    style: TextStyle(
                      color: isActive || isCompleted ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < 3)
                Container(
                  width: 30,
                  height: 2,
                  color: isCompleted ? const Color(0xFF00A84E) : const Color(0xFFE0E0E0),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class InputLabel extends StatelessWidget {
  final String label;
  final bool required;
  const InputLabel({super.key, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (required)
            const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
