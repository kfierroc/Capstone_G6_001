import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/grupo_familiar_detalle.dart';
import '../../services/grupo_familiar_service.dart';
import '../../widgets/admin_detail_shell.dart';
import '../../widgets/grupo_familiar_detail_content.dart';

class GrupoFamiliarDetailScreen extends StatefulWidget {
  const GrupoFamiliarDetailScreen({
    super.key,
    required this.idGrupof,
    required this.alertCount,
    required this.onVolver,
    this.refreshNonce = 0,
    this.onVerEditarResidencia,
  });

  final int idGrupof;
  final int alertCount;
  final VoidCallback onVolver;
  final int refreshNonce;
  final ValueChanged<int>? onVerEditarResidencia;

  @override
  State<GrupoFamiliarDetailScreen> createState() => _GrupoFamiliarDetailScreenState();
}

class _GrupoFamiliarDetailScreenState extends State<GrupoFamiliarDetailScreen> {
  GrupoFamiliarDetalle? _detalle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant GrupoFamiliarDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNonce != widget.refreshNonce) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final detalle = await GrupoFamiliarService(Supabase.instance.client).obtenerDetalle(widget.idGrupof);
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

    return AdminDetailShell(
      headerTitle: 'Grupo Familiar',
      alertCount: widget.alertCount,
      volverLabel: 'Volver a Grupos Familiares',
      onVolver: widget.onVolver,
      loading: _loading,
      subtitulo: d?.titularEtiqueta,
      descripcion: d?.direccion,
      errorMessage: d == null && !_loading ? 'No se pudo cargar el grupo familiar.' : null,
      child: d == null
          ? null
          : GrupoFamiliarDetailContent(
              detalle: d,
              onReload: _cargar,
              onVerEditarResidencia: widget.onVerEditarResidencia,
            ),
    );
  }
}
