import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/recordatorio_permanencia_service.dart';

/// Diálogo y campana de recordatorios mensuales de permanencia.
class RecordatorioPermanenciaUi {
  RecordatorioPermanenciaUi._();

  static int? _dialogMostradoSesionRegistro;

  /// Muestra el diálogo si pasó ≥ 1 mes desde la última confirmación.
  static Future<void> verificarAlEntrar(BuildContext context) async {
    final estado = await RecordatorioPermanenciaService(Supabase.instance.client).evaluar();
    if (!context.mounted || estado == null || !estado.requiereConfirmacionMensual) return;
    if (_dialogMostradoSesionRegistro == estado.idRegistro) return;
    _dialogMostradoSesionRegistro = estado.idRegistro;
    await mostrarDialogoConfirmacion(context, estado);
  }

  static Future<void> mostrarDialogoConfirmacion(
    BuildContext context,
    EstadoRecordatorioPermanencia estado,
  ) async {
    final mesTxt =
        estado.mesesDesdeConfirmacion == 1 ? '1 mes' : '${estado.mesesDesdeConfirmacion} meses';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: Color(0xFF00A84E)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmación mensual',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Han pasado $mesTxt desde tu última confirmación en esta residencia.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿La información de tu domicilio y familia sigue siendo correcta? '
              'Recibirás este recordatorio cada mes hasta que desvincules el domicilio.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.35),
            ),
            if (estado.permanenciaVencida) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: const Text(
                  'Tu tiempo de permanencia declarado ya venció. Renueva el período o desvincula el domicilio en Configuración.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC2410C)),
                ),
              ),
            ] else if (estado.permanenciaPorVencer) ...[
              const SizedBox(height: 12),
              Text(
                'Tu permanencia vence en ${estado.diasHastaExpiracion} día(s).',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2C5BA9)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/gestion-configuracion');
            },
            child: const Text('Revisar datos'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await RecordatorioPermanenciaService(Supabase.instance.client)
                    .confirmarInformacionMensual(estado.idRegistro);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gracias. Próximo recordatorio en un mes.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Sí, confirmo'),
          ),
        ],
      ),
    );
  }

  static Future<void> mostrarPanelNotificaciones(BuildContext context) async {
    final svc = RecordatorioPermanenciaService(Supabase.instance.client);
    final estado = await svc.evaluar();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (estado == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay registro de vivienda activo.'),
          );
        }

        final items = <Widget>[];

        if (estado.requiereConfirmacionMensual) {
          final mesTxt =
              estado.mesesDesdeConfirmacion == 1 ? '1 mes' : '${estado.mesesDesdeConfirmacion} meses';
          items.add(
            _tileAlerta(
              icon: Icons.event_repeat,
              color: const Color(0xFF00A84E),
              titulo: 'Confirmación mensual pendiente',
              subtitulo: 'Han pasado $mesTxt desde tu última confirmación.',
              onTap: () {
                Navigator.pop(ctx);
                mostrarDialogoConfirmacion(context, estado);
              },
            ),
          );
        }

        if (estado.permanenciaVencida) {
          items.add(
            _tileAlerta(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEA580C),
              titulo: 'Permanencia vencida',
              subtitulo: 'Actualiza el tiempo en residencia o desvincula el domicilio.',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/gestion-configuracion');
              },
            ),
          );
        } else if (estado.permanenciaPorVencer) {
          items.add(
            _tileAlerta(
              icon: Icons.schedule,
              color: const Color(0xFF2C5BA9),
              titulo: 'Permanencia por vencer',
              subtitulo: 'Quedan ${estado.diasHastaExpiracion} día(s) del período declarado.',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/gestion-configuracion');
              },
            ),
          );
        }

        if (items.isEmpty) {
          items.add(
            const ListTile(
              leading: Icon(Icons.check_circle_outline, color: Color(0xFF00A84E)),
              title: Text('Sin alertas pendientes'),
              subtitle: Text('Te avisaremos cada mes para confirmar tus datos.'),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notificaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Última confirmación: ${_fmt(estado.fechaUltConfirm)} · '
                  'Vence: ${_fmt(estado.fechaExpiracion)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                ...items,
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _tileAlerta({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Campana con badge para pantallas de gestión del residente.
class NotificacionesResidenteButton extends StatefulWidget {
  const NotificacionesResidenteButton({super.key});

  @override
  State<NotificacionesResidenteButton> createState() => _NotificacionesResidenteButtonState();
}

class _NotificacionesResidenteButtonState extends State<NotificacionesResidenteButton> {
  static const _verdeApp = Color(0xFF00A84E);
  EstadoRecordatorioPermanencia? _estado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final e = await RecordatorioPermanenciaService(Supabase.instance.client).evaluar();
    if (!mounted) return;
    setState(() => _estado = e);
  }

  @override
  Widget build(BuildContext context) {
    final alertas = _estado?.cantidadAlertas ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await RecordatorioPermanenciaUi.mostrarPanelNotificaciones(context);
          await _cargar();
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                alertas > 0 ? Icons.notifications_active : Icons.notifications_none_rounded,
                color: _verdeApp,
                size: 22,
              ),
              if (alertas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$alertas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Llama tras cargar datos en pantallas de gestión.
Future<void> ejecutarRecordatorioPermanenciaTrasCarga(BuildContext context) async {
  try {
    final estado = await RecordatorioPermanenciaService(Supabase.instance.client).evaluar();
    if (estado != null) {
      await RecordatorioPermanenciaService(Supabase.instance.client)
          .sincronizarTrasActualizarPermanencia(estado.idRegistro);
    }
    if (!context.mounted) return;
    await RecordatorioPermanenciaUi.verificarAlEntrar(context);
  } catch (e, st) {
    debugPrint('Recordatorio de permanencia al cargar: $e\n$st');
  }
}
