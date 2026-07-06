import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/compania_bombero_service.dart';

/// Resuelve el centro inicial de mapas de búsqueda (domicilio / grifos).
class MapaCentroInicial {
  MapaCentroInicial._();

  static const LatLng santiago = LatLng(-33.4489, -70.6693);
  static const double zoomUbicacionExacta = 15;
  static const double zoomComuna = 13;

  /// GPS si está activo; si no, centro de la comuna de la compañía; si no, Santiago.
  static Future<({LatLng centro, double zoom})> resolver({
    required SupabaseClient client,
    int? idCompania,
  }) async {
    final gps = await _intentarUbicacionExacta();
    if (gps != null) {
      return (centro: gps, zoom: zoomUbicacionExacta);
    }

    if (idCompania != null) {
      try {
        final comuna = await CompaniaBomberoService(client).obtenerCentroComunaPorIdCompania(idCompania);
        if (comuna != null) {
          return (centro: comuna, zoom: zoomComuna);
        }
      } catch (_) {}
    }

    return (centro: santiago, zoom: zoomComuna);
  }

  static Future<LatLng?> _intentarUbicacionExacta() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
