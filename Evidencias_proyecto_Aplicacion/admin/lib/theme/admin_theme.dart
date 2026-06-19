import 'package:flutter/material.dart';

/// Paleta y estilos del panel admin (según diseño de referencia).
abstract final class AdminTheme {
  static const sidebarBg = Color(0xFF111827);
  static const sidebarText = Color(0xFF9CA3AF);
  static const sidebarActive = Color(0xFF2563EB);
  static const pageBg = Color(0xFFF9FAFB);
  static const cardBorder = Color(0xFFE5E7EB);
  static const titleText = Color(0xFF111827);
  static const mutedText = Color(0xFF6B7280);
  static const alertRed = Color(0xFFDC2626);
  static const successGreen = Color(0xFF16A34A);
  static const infoBlue = Color(0xFF2563EB);
  static const warningOrange = Color(0xFFEA580C);

  static const sidebarWidth = 240.0;

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: titleText,
      );
}
