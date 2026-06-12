import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Colores y marcadores según [estado_grifo].
class GrifoEstadoUtils {
  GrifoEstadoUtils._();

  static const azul = Color(0xFF1565C0);
  static const verde = Color(0xFF2E7D32);
  static const rojo = Color(0xFFC62828);
  static const amarillo = Color(0xFFF9A825);
  static const gris = Color(0xFF757575);

  static Color colorPorEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('operativo')) return verde;
    if (e.contains('dañado') || e.contains('danado')) return rojo;
    if (e.contains('mantenimiento')) return amarillo;
    return gris;
  }

  static double huePorEstado(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('operativo')) return BitmapDescriptor.hueGreen;
    if (e.contains('dañado') || e.contains('danado')) return BitmapDescriptor.hueRed;
    if (e.contains('mantenimiento')) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueViolet;
  }

  static String normalizar(String estado) => estado.trim();
}
