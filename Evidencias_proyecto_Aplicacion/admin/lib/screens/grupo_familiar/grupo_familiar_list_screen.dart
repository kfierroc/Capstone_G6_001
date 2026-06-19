import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/grupo_familiar_list_item.dart';
import '../../services/grupo_familiar_service.dart';
import '../../theme/admin_theme.dart';
import '../../utils/filtro_ubicacion_lista.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_lista_filtros_ubicacion.dart';
import '../residencias/residencia_edit_screen.dart';
import 'grupo_familiar_detail_screen.dart';

class GrupoFamiliarSection extends StatefulWidget {
  const GrupoFamiliarSection({
    super.key,
    required this.alertCount,
    this.detalleInicialId,
    this.onDetalleInicialConsumido,
  });

  final int alertCount;
  final int? detalleInicialId;
  final VoidCallback? onDetalleInicialConsumido;

  @override
  State<GrupoFamiliarSection> createState() => _GrupoFamiliarSectionState();
}

class _GrupoFamiliarSectionState extends State<GrupoFamiliarSection> {
  int? _detalleId;
  int? _editResidenciaId;
  int _detalleRefreshNonce = 0;

  @override
  void initState() {
    super.initState();
    _aplicarDetalleInicial();
  }

  @override
  void didUpdateWidget(covariant GrupoFamiliarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detalleInicialId != null &&
        widget.detalleInicialId != oldWidget.detalleInicialId) {
      setState(_aplicarDetalleInicial);
    }
  }

  void _aplicarDetalleInicial() {
    final id = widget.detalleInicialId;
    if (id == null) return;
    _detalleId = id;
    _editResidenciaId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDetalleInicialConsumido?.call();
    });
  }

  void _abrirDetalle(int idGrupof) => setState(() => _detalleId = idGrupof);

  void _volverLista() => setState(() {
        _detalleId = null;
        _editResidenciaId = null;
      });

  void _abrirEditResidencia(int idResidencia) => setState(() => _editResidenciaId = idResidencia);

  void _volverEditResidencia({bool guardado = false}) => setState(() {
        _editResidenciaId = null;
        if (guardado) _detalleRefreshNonce++;
      });

  @override
  Widget build(BuildContext context) {
    if (_editResidenciaId != null) {
      return ResidenciaEditScreen(
        idResidencia: _editResidenciaId!,
        alertCount: widget.alertCount,
        volverLabel: 'Volver al detalle',
        onVolver: () => _volverEditResidencia(),
        onGuardado: () => _volverEditResidencia(guardado: true),
        onVerGrupoFamiliar: _detalleId != null ? (_) => _volverEditResidencia() : null,
      );
    }

    if (_detalleId != null) {
      return GrupoFamiliarDetailScreen(
        idGrupof: _detalleId!,
        alertCount: widget.alertCount,
        refreshNonce: _detalleRefreshNonce,
        onVolver: _volverLista,
        onVerEditarResidencia: _abrirEditResidencia,
      );
    }

    return GrupoFamiliarListScreen(
      alertCount: widget.alertCount,
      onVerDetalle: _abrirDetalle,
    );
  }
}

class GrupoFamiliarListScreen extends StatefulWidget {
  const GrupoFamiliarListScreen({
    super.key,
    required this.alertCount,
    required this.onVerDetalle,
  });

  final int alertCount;
  final ValueChanged<int> onVerDetalle;

  @override
  State<GrupoFamiliarListScreen> createState() => _GrupoFamiliarListScreenState();
}

class _GrupoFamiliarListScreenState extends State<GrupoFamiliarListScreen> {
  final _filtrosKey = GlobalKey<AdminListaFiltrosUbicacionState>();
  final _idController = TextEditingController();
  final _busquedaController = TextEditingController();
  List<GrupoFamiliarListItem> _grupos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _idController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final lista = await GrupoFamiliarService(Supabase.instance.client).listarGrupos();
    if (mounted) {
      setState(() {
        _grupos = lista;
        _loading = false;
      });
    }
  }

  void _proximamente(String accion) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$accion — próximamente.')));
  }

  List<GrupoFamiliarListItem> get _filtrados {
    final q = _busquedaController.text.trim();
    final f = _filtrosKey.currentState;
    final comunaMap = f?.comunaARegion ?? const {};
    return _grupos.where((g) {
      if (!filtroUbicacion(
        cutComItem: g.cutCom,
        cutRegFiltro: f?.cutRegFiltro,
        cutComFiltro: f?.cutComFiltro,
        comunaARegion: comunaMap,
      )) {
        return false;
      }
      if (!filtroId(id: g.idGrupof, idQuery: _idController.text)) return false;
      return g.coincideConBusqueda(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Grupo Familiar', alertCount: widget.alertCount),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.cardBorder),
            ),
            child: AdminListaFiltrosUbicacion(
              key: _filtrosKey,
              idController: _idController,
              busquedaController: _busquedaController,
              idHint: 'ID del grupo',
              busquedaHint: 'Buscar por RUT, teléfono o dirección...',
              onChanged: () => setState(() {}),
              trailing: AdminPrimaryButton(
                label: 'Agregar Grupo Familiar',
                icon: Icons.add,
                onPressed: () => _proximamente('Agregar grupo familiar'),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.cardBorder),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtrados.isEmpty
                      ? Center(
                          child: Text(
                            _grupos.isEmpty ? 'No hay grupos familiares registrados.' : 'Sin resultados para la búsqueda.',
                            style: const TextStyle(color: AdminTheme.mutedText),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: esAncho
                              ? _TablaDesktop(
                                  grupos: filtrados,
                                  onVerDetalle: widget.onVerDetalle,
                                  onEliminar: () => _proximamente('Eliminar'),
                                )
                              : _ListaMobile(
                                  grupos: filtrados,
                                  onVerDetalle: widget.onVerDetalle,
                                  onEliminar: () => _proximamente('Eliminar'),
                                ),
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TablaDesktop extends StatelessWidget {
  const _TablaDesktop({
    required this.grupos,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final List<GrupoFamiliarListItem> grupos;
  final ValueChanged<int> onVerDetalle;
  final VoidCallback onEliminar;

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminTheme.mutedText,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('RUT TITULAR', style: _headerStyle)),
              Expanded(flex: 2, child: Text('ESTADO', style: _headerStyle)),
              Expanded(flex: 2, child: Text('TELÉFONO', style: _headerStyle)),
              Expanded(flex: 3, child: Text('DIRECCIÓN', style: _headerStyle)),
              Expanded(flex: 2, child: Text('FECHA REGISTRO', style: _headerStyle)),
              SizedBox(width: 180, child: Text('ACCIONES', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
        ...grupos.map((g) => _FilaDesktop(
              grupo: g,
              onVerDetalle: () => onVerDetalle(g.idGrupof),
              onEliminar: onEliminar,
            )),
      ],
    );
  }
}

class _FilaDesktop extends StatelessWidget {
  const _FilaDesktop({
    required this.grupo,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final GrupoFamiliarListItem grupo;
  final VoidCallback onVerDetalle;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 2, child: Text(grupo.rutFormateado, style: _cellStyle)),
              Expanded(flex: 2, child: _EstadoBadge(vigente: grupo.registroVigente)),
              Expanded(flex: 2, child: Text(grupo.telefono, style: _cellStyle)),
              Expanded(flex: 3, child: Text(grupo.direccion, style: _cellStyle)),
              Expanded(flex: 2, child: Text(grupo.fechaRegistro, style: _cellStyle)),
              SizedBox(
                width: 180,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminOutlineButton(label: 'Ver Detalle', onPressed: onVerDetalle),
                    AdminDangerButton(label: 'Eliminar', onPressed: onEliminar),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
      ],
    );
  }

  static const _cellStyle = TextStyle(fontSize: 14, color: AdminTheme.titleText);
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.vigente});

  final bool vigente;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: vigente ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          vigente ? 'Vigente' : 'Sin domicilio',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: vigente ? AdminTheme.successGreen : AdminTheme.mutedText,
          ),
        ),
      ),
    );
  }
}

class _ListaMobile extends StatelessWidget {
  const _ListaMobile({
    required this.grupos,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final List<GrupoFamiliarListItem> grupos;
  final ValueChanged<int> onVerDetalle;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final g = grupos[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AdminTheme.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(g.rutFormateado, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _EstadoBadge(vigente: g.registroVigente),
                ],
              ),
              const SizedBox(height: 8),
              Text(g.direccion, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text('${g.telefono} · ${g.fechaRegistro}', style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminOutlineButton(label: 'Ver Detalle', onPressed: () => onVerDetalle(g.idGrupof)),
                  AdminDangerButton(label: 'Eliminar', onPressed: onEliminar),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
