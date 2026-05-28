import 'package:flutter/material.dart';

import '../models/ubicacion_residencia.dart';
import '../widgets/ubicacion_residencia_form.dart';
import 'registro_models.dart';

class RegistroPaso3 extends StatelessWidget {
  final RegistroResidenteBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso3({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  static const double _latIni = -33.4489;
  static const double _lonIni = -70.6693;

  @override
  Widget build(BuildContext context) {
    final d = draft;
    return UbicacionResidenciaForm(
      inicial: UbicacionResidenciaInicial(
        calle: d.calle,
        nroDireccion: d.nroDireccion,
        unidad: d.unidad,
        lat: d.lat ?? _latIni,
        lon: d.lon ?? _lonIni,
        direccionYaCargada: d.calle != null && d.calle!.trim().isNotEmpty && d.nroDireccion != null,
      ),
      onSecundario: onBack,
      onConfirmar: (r) {
        d.calle = r.calle;
        d.nroDireccion = r.nroDireccion;
        d.unidad = r.unidad;
        d.lat = r.lat;
        d.lon = r.lon;
        onNext();
      },
    );
  }
}
