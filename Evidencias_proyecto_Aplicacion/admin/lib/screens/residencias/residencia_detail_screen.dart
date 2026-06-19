import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/residencia_admin_detalle.dart';
import '../../services/admin_edit_service.dart';
import '../../services/residencias_admin_service.dart';
import '../../widgets/admin_edit_sheets.dart';
import '../../widgets/admin_detail_shell.dart';
import '../../widgets/admin_info_card.dart';
import '../../widgets/domicilio_info_cards.dart';
import '../../widgets/grupo_familiar_detail_content.dart';

class ResidenciaDetailScreen extends StatefulWidget {
  const ResidenciaDetailScreen({
    super.key,
    required this.idResidencia,
    required this.alertCount,
    required this.onVolver,
    this.refreshNonce = 0,
    this.onVerEditarResidencia,
  });

  final int idResidencia;
  final int alertCount;
  final VoidCallback onVolver;
  final int refreshNonce;
  final ValueChanged<int>? onVerEditarResidencia;

  @override
  State<ResidenciaDetailScreen> createState() => _ResidenciaDetailScreenState();
}

class _ResidenciaDetailScreenState extends State<ResidenciaDetailScreen> {
  ResidenciaAdminDetalle? _detalle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant ResidenciaDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNonce != widget.refreshNonce) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final detalle = await ResidenciasAdminService(Supabase.instance.client).obtenerDetalle(widget.idResidencia);
    if (mounted) {
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detalle;
    final grupo = d?.grupoDetalle;

    return AdminDetailShell(
      headerTitle: 'Residencias',
      alertCount: widget.alertCount,
      volverLabel: 'Volver a Residencias',
      onVolver: widget.onVolver,
      loading: _loading,
      subtitulo: d?.direccionCorta,
      descripcion: d != null ? '${d.comuna} · ID ${d.idResidencia}' : null,
      errorMessage: d == null && !_loading ? 'No se pudo cargar la residencia.' : null,
      child: d == null
          ? null
          : grupo != null
              ? GrupoFamiliarDetailContent(
                  detalle: grupo,
                  onReload: _cargar,
                  onVerEditarResidencia: widget.onVerEditarResidencia,
                )
              : _ResidenciaSoloContent(
                  detalle: d,
                  onReload: _cargar,
                  onVerEditarResidencia: widget.onVerEditarResidencia,
                ),
    );
  }
}

class _ResidenciaSoloContent extends StatelessWidget {
  const _ResidenciaSoloContent({
    required this.detalle,
    required this.onReload,
    this.onVerEditarResidencia,
  });

  final ResidenciaAdminDetalle detalle;
  final Future<void> Function() onReload;
  final ValueChanged<int>? onVerEditarResidencia;

  void _verEditarResidencia() {
    onVerEditarResidencia?.call(detalle.idResidencia);
  }

  Future<void> _editarRegistroVivienda(BuildContext context) async {
    final ok = await AdminEditSheets.editarRegistroVivienda(context, domicilio: detalle.domicilio);
    if (ok == true) await onReload();
  }

  Future<void> _desvincularResidencia(BuildContext context) async {
    final dom = detalle.domicilio;
    final idReg = dom.idRegistro;
    if (!dom.vigente || idReg == null) return;

    final ok = await AdminEditSheets.confirmarDesvincularResidencia(
      context,
      direccion: dom.direccionCompleta,
      cuentaVinculada: detalle.grupoDetalle?.cuenta.cuentaVinculada ?? false,
    );
    if (ok != true) return;

    try {
      await AdminEditService(Supabase.instance.client).desvincularRegistroResidencia(idReg);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Residencia desvinculada correctamente.')),
        );
      }
      await onReload();
    } catch (e) {
      if (context.mounted) AdminEditSheets.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: DomicilioInfoCard(
        domicilio: detalle.domicilio,
        onVerEditarResidencia: onVerEditarResidencia != null ? _verEditarResidencia : null,
        onEditarRegistro: detalle.domicilio.tieneRegistro && detalle.domicilio.idRegistro != null
            ? () => _editarRegistroVivienda(context)
            : null,
        onDesvincular: detalle.domicilio.vigente && detalle.domicilio.idRegistro != null
            ? () => _desvincularResidencia(context)
            : null,
        encabezadoIzquierdo: AdminInfoCard(
          titulo: 'Residencia sin grupo',
          icono: Icons.location_city_outlined,
          filas: const [
            AdminInfoFila('Grupo familiar', 'Sin grupo vinculado al registro vigente'),
          ],
        ),
      ),
    );
  }
}
