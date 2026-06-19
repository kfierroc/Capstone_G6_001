import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import 'admin_header.dart';

/// Encabezado común para pantallas de detalle (grupo familiar, residencia, etc.).
class AdminDetailShell extends StatelessWidget {
  const AdminDetailShell({
    super.key,
    required this.headerTitle,
    required this.alertCount,
    required this.volverLabel,
    required this.onVolver,
    required this.subtitulo,
    required this.descripcion,
    required this.loading,
    required this.errorMessage,
    required this.child,
  });

  final String headerTitle;
  final int alertCount;
  final String volverLabel;
  final VoidCallback onVolver;
  final String? subtitulo;
  final String? descripcion;
  final bool loading;
  final String? errorMessage;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: headerTitle, alertCount: alertCount),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: onVolver,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(volverLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.titleText,
                  side: const BorderSide(color: AdminTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 20),
              if (!loading && subtitulo != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitulo!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.titleText,
                        ),
                      ),
                      if (descripcion != null && descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          descripcion!,
                          style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (errorMessage != null)
          Expanded(
            child: Center(
              child: Text(errorMessage!, style: const TextStyle(color: AdminTheme.mutedText)),
            ),
          )
        else if (child != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
              child: child!,
            ),
          ),
      ],
    );
  }
}
