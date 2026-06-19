import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_header.dart';

/// Pantalla temporal para secciones aún no implementadas.
class PlaceholderSectionScreen extends StatelessWidget {
  const PlaceholderSectionScreen({
    super.key,
    required this.title,
    required this.description,
    this.alertCount = 0,
  });

  final String title;
  final String description;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: title, alertCount: alertCount),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AdminTheme.sectionTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AdminTheme.mutedText, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
