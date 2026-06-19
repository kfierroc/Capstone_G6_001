import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ubicacion_residencia.dart';
import '../services/gestion_residente_service.dart';
import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/ubicacion_residencia_form.dart';

/// Edición de dirección con el mismo flujo que el paso 3 del registro.
class EditarDomicilioUbicacionScreen extends StatelessWidget {
  const EditarDomicilioUbicacionScreen({super.key, required this.domicilio});

  final DomicilioVista domicilio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Editar dirección',
            subtitle: 'Busca en Google Maps o ingresa manualmente',
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ResponsiveContainer(
                fillHeight: !kIsWeb,
                child: kIsWeb
                    ? SingleChildScrollView(
                        child: UbicacionResidenciaForm(
                          titulo: 'Ubicación del domicilio',
                          etiquetaPrimaria: 'Guardar',
                          etiquetaSecundaria: 'Cancelar',
                          onSecundario: () => Navigator.pop(context),
                          inicial: UbicacionResidenciaInicial(
                            calle: domicilio.calle,
                            nroDireccion: domicilio.nroDireccion,
                            unidad: domicilio.unidad,
                            lat: domicilio.lat,
                            lon: domicilio.lon,
                            direccionYaCargada: true,
                          ),
                          onConfirmar: (r) => _guardar(context, r),
                        ),
                      )
                    : UbicacionResidenciaForm(
                        titulo: 'Ubicación del domicilio',
                        etiquetaPrimaria: 'Guardar',
                        etiquetaSecundaria: 'Cancelar',
                        onSecundario: () => Navigator.pop(context),
                        inicial: UbicacionResidenciaInicial(
                          calle: domicilio.calle,
                          nroDireccion: domicilio.nroDireccion,
                          unidad: domicilio.unidad,
                          lat: domicilio.lat,
                          lon: domicilio.lon,
                          direccionYaCargada: true,
                        ),
                        onConfirmar: (r) => _guardar(context, r),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar(BuildContext context, UbicacionResidenciaResultado r) async {
    final ges = GestionResidenteService(Supabase.instance.client);
    try {
      await ges.guardarUbicacionResidencia(
        idResidencia: domicilio.idResidencia,
        calle: r.calle,
        nroDireccion: r.nroDireccion,
        lat: r.lat,
        lon: r.lon,
      );
      await ges.guardarReferenciasRegistro(
        idRegistro: domicilio.idRegistro,
        unidad: r.unidad,
        descDeptoCond: domicilio.descDeptoCond,
        notasV: domicilio.notasV,
      );
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } on RegistroResidenteException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
