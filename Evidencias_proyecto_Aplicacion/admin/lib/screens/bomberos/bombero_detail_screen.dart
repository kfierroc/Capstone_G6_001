import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_list_item.dart';
import '../../services/admin_edit_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_detail_shell.dart';
import '../../widgets/admin_edit_sheets.dart';

class BomberoDetailScreen extends StatelessWidget {
  const BomberoDetailScreen({
    super.key,
    required this.bombero,
    required this.alertCount,
    required this.onVolver,
    required this.onEditar,
    required this.onEliminado,
  });

  final BomberoListItem bombero;
  final int alertCount;
  final VoidCallback onVolver;
  final ValueChanged<BomberoListItem> onEditar;
  final VoidCallback onEliminado;

  Future<void> _eliminar(BuildContext context) async {
    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar bombero',
      mensaje:
          'Se eliminará a ${bombero.nombreCompleto} (${bombero.rutFormateado}). '
          'Esta acción no se puede deshacer.',
    );
    if (ok != true || !context.mounted) return;

    try {
      await AdminEditService(Supabase.instance.client).eliminarBombero(bombero.rutNum);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bombero eliminado.')));
      onEliminado();
    } catch (e) {
      if (context.mounted) AdminEditSheets.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminDetailShell(
      headerTitle: 'Bomberos',
      alertCount: alertCount,
      volverLabel: 'Volver a Bomberos',
      onVolver: onVolver,
      loading: false,
      subtitulo: bombero.nombreCompleto,
      descripcion: '${bombero.compania} · ${bombero.comuna}',
      errorMessage: null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del bombero',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                  ),
                  const SizedBox(height: 20),
                  _FilaDetalle(label: 'RUT', value: bombero.rutFormateado),
                  _FilaDetalle(label: 'Nombre', value: bombero.nombreCompleto),
                  _FilaDetalle(label: 'Compañía', value: bombero.compania),
                  _FilaDetalle(label: 'Comuna', value: bombero.comuna),
                  _FilaDetalle(
                    label: 'Rol',
                    value: bombero.esAdmin ? 'Administrador' : 'Bombero',
                  ),
                  _FilaDetalle(
                    label: 'Cuenta',
                    value: bombero.tieneCuenta ? 'Vinculada' : 'Sin cuenta',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminOutlineButton(label: 'Editar', onPressed: () => onEditar(bombero)),
                AdminDangerButton(label: 'Eliminar', onPressed: () => _eliminar(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  const _FilaDetalle({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
