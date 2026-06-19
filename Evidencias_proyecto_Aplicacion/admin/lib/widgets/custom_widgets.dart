import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  static double _defaultMaxWidth(double screenWidth) {
    if (screenWidth >= 1400) return 520;
    if (screenWidth >= 900) return 480;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final effectiveMax = maxWidth ?? _defaultMaxWidth(screenW);
    final outer = screenW >= 900 ? 32.0 : screenW >= 600 ? 24.0 : 16.0;
    final inner = screenW >= 900 ? 36.0 : screenW >= 600 ? 28.0 : 22.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(outer, outer + 24, outer, outer),
          child: Card(
            elevation: screenW >= 600 ? 4 : 2,
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
    this.leadingIcon = Icons.admin_panel_settings_outlined,
    this.backgroundColor = const Color(0xFF283593),
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Color backgroundColor;
  final Widget? trailing;

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
      child: Row(
        children: [
          Icon(leadingIcon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class InputLabel extends StatelessWidget {
  const InputLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}
