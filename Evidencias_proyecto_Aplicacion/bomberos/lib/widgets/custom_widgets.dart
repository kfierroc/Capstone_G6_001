import 'package:flutter/material.dart';

/// Anchos y márgenes para celular y tablet.
class AppLayout {
  AppLayout._();

  static double contentMaxWidth(double screenWidth) {
    if (screenWidth >= 1200) return 1100;
    if (screenWidth >= 900) return 960;
    return double.infinity;
  }

  static double horizontalPadding(double screenWidth) {
    if (screenWidth >= 900) return 20;
    if (screenWidth >= 600) return 16;
    return 12;
  }

  /// Altura del mapa según ancho de pantalla (crece de forma gradual).
  ///
  /// [scale] permite ajustar por contexto (p. ej. registro un poco más bajo).
  static double mapHeight(double screenWidth, {double scale = 1.0}) {
    const puntos = <(double w, double h)>[
      (360, 420),
      (600, 500),
      (900, 560),
      (1200, 640),
    ];

    final w = screenWidth.clamp(puntos.first.$1, puntos.last.$1);
    for (var i = 0; i < puntos.length - 1; i++) {
      final a = puntos[i];
      final b = puntos[i + 1];
      if (w <= b.$1) {
        final t = (w - a.$1) / (b.$1 - a.$1);
        return (a.$2 + (b.$2 - a.$2) * t) * scale;
      }
    }
    return puntos.last.$2 * scale;
  }
}

/// Centra el contenido con ancho máximo adaptable (inicio, grifos, configuración, etc.).
class AppWidthContainer extends StatelessWidget {
  const AppWidthContainer({
    super.key,
    required this.child,
    this.padding,
    this.includeVerticalPadding = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool includeVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxW = AppLayout.contentMaxWidth(w);
    final h = AppLayout.horizontalPadding(w);
    final effective = padding ??
        EdgeInsets.fromLTRB(
          h,
          includeVerticalPadding ? 16 : 0,
          h,
          includeVerticalPadding ? 24 : 0,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(padding: effective, child: child),
      ),
    );
  }
}

/// Misma idea que en la app Residentes: ancho máximo según viewport.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  static double _defaultMaxWidth(double screenWidth) {
    if (screenWidth >= 1400) return 1200;
    if (screenWidth >= 1100) return 1000;
    if (screenWidth >= 800) return 900;
    if (screenWidth >= 600) return 680;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final effectiveMax = maxWidth ?? _defaultMaxWidth(screenW);
    final outer = screenW >= 900 ? 28.0 : screenW >= 600 ? 20.0 : 12.0;
    final inner = screenW >= 900 ? 32.0 : screenW >= 600 ? 24.0 : 18.0;

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
  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.leadingIcon = Icons.local_fire_department_outlined,
    this.showLeadingIconWhenNoBack = false,
    this.backgroundColor = const Color(0xFFC62828),
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final IconData leadingIcon;
  final bool showLeadingIconWhenNoBack;
  final Color backgroundColor;

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
      decoration: BoxDecoration(color: backgroundColor),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack ?? () => Navigator.pop(context),
                )
              else if (showLeadingIconWhenNoBack)
                const SizedBox(width: 8)
              else
                const SizedBox(width: 48),
              Icon(leadingIcon, color: Colors.white, size: 28),
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

class InputLabel extends StatelessWidget {
  const InputLabel({super.key, required this.label, this.required = false});

  final String label;
  final bool required;

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
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
