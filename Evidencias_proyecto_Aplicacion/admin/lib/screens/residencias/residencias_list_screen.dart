import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/residencia_admin_detalle.dart';
import '../../services/admin_edit_service.dart';
import '../../services/residencias_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../utils/filtro_ubicacion_lista.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_edit_sheets.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_lista_filtros_ubicacion.dart';
import '../../widgets/admin_lista_pie_paginacion.dart';
import 'residencia_edit_screen.dart';

class ResidenciasListScreen extends StatefulWidget {
  const ResidenciasListScreen({
    super.key,
    required this.alertCount,
    required this.onVerDetalle,
  });

  final int alertCount;
  final ValueChanged<int> onVerDetalle;

  @override
  State<ResidenciasListScreen> createState() => _ResidenciasListScreenState();
}

class _ResidenciasListScreenState extends State<ResidenciasListScreen> {
  final _filtrosKey = GlobalKey<AdminListaFiltrosUbicacionState>();
  final _idController = TextEditingController();
  final _busquedaController = TextEditingController();
  final _service = ResidenciasAdminService(Supabase.instance.client);
  List<ResidenciaListItem> _residencias = [];
  bool _loading = true;
  bool _cargandoMas = false;
  bool _hayMas = false;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  @override
  void dispose() {
    _idController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _loading = true;
      _residencias = [];
      _offset = 0;
      _hayMas = false;
    });
    await _cargarPagina(reemplazar: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas || _loading) return;
    setState(() => _cargandoMas = true);
    await _cargarPagina(reemplazar: false);
    if (mounted) setState(() => _cargandoMas = false);
  }

  Future<void> _cargarPagina({required bool reemplazar}) async {
    final p = parametrosFiltroUbicacion(
      filtros: _filtrosKey.currentState,
      idText: _idController.text,
    );
    final pag = await _service.listarResidenciasPaginado(
      offset: _offset,
      cutCom: p.cutCom,
      cutComsRegion: p.cutComsRegion,
      idResidenciaExacto: p.idExacto,
    );
    if (!mounted) return;
    setState(() {
      if (reemplazar) {
        _residencias = pag.items;
      } else {
        _residencias = [..._residencias, ...pag.items];
      }
      _offset = _residencias.length;
      _hayMas = pag.hayMas;
    });
  }

  void _onFiltrosCambiados() => _cargarInicial();

  void _onIdCambiado() {
    final idText = _idController.text.trim();
    if (idText.isEmpty || int.tryParse(idText) != null) {
      _cargarInicial();
    } else {
      setState(() {});
    }
  }


  Future<void> _eliminarResidencia(ResidenciaListItem r) async {
    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar residencia',
      mensaje:
          'Se eliminará la residencia #${r.idResidencia} (${r.direccion}, ${r.comuna}). '
          'Esta acción no se puede deshacer.',
    );
    if (ok != true) return;
    try {
      await AdminEditService(Supabase.instance.client).eliminarResidencia(r.idResidencia);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Residencia eliminada.')));
        _cargarInicial();
      }
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    }
  }

  List<ResidenciaListItem> get _filtrados {
    final q = _busquedaController.text.trim();
    final idText = _idController.text.trim();
    var lista = _residencias;
    if (idText.isNotEmpty && int.tryParse(idText) == null) {
      lista = lista.where((r) => filtroId(id: r.idResidencia, idQuery: idText)).toList();
    }
    if (q.isNotEmpty) {
      lista = lista.where((r) => r.coincideConBusqueda(q)).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Residencias', alertCount: widget.alertCount),
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
              idHint: 'ID de residencia',
              busquedaHint: 'Buscar por dirección o estado...',
              onChanged: _onFiltrosCambiados,
              onIdChanged: _onIdCambiado,
              onBusquedaChanged: () => setState(() {})
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
                            _residencias.isEmpty && !_hayMas
                                ? 'No hay residencias registradas.'
                                : 'Sin resultados para los filtros aplicados.',
                            style: const TextStyle(color: AdminTheme.mutedText),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _cargarInicial,
                                child: esAncho
                                    ? _TablaDesktop(
                                        residencias: filtrados,
                                        onVerDetalle: widget.onVerDetalle,
                                        onEliminar: _eliminarResidencia,
                                      )
                                    : _ListaMobile(
                                        residencias: filtrados,
                                        onVerDetalle: widget.onVerDetalle,
                                        onEliminar: _eliminarResidencia,
                                      ),
                              ),
                            ),
                            if (_hayMas || _cargandoMas)
                              AdminListaPiePaginacion(
                                totalMostrado: _residencias.length,
                                etiquetaSingular: 'residencia',
                                etiquetaPlural: 'residencias',
                                hayMas: _hayMas,
                                cargandoMas: _cargandoMas,
                                onCargarMas: _cargarMas,
                              ),
                          ],
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
    required this.residencias,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final List<ResidenciaListItem> residencias;
  final ValueChanged<int> onVerDetalle;
  final ValueChanged<ResidenciaListItem> onEliminar;

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminTheme.mutedText,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(flex: 1, child: Text('ID', style: _headerStyle)),
              Expanded(flex: 3, child: Text('DIRECCIÓN', style: _headerStyle)),
              Expanded(flex: 2, child: Text('COMUNA', style: _headerStyle)),
              Expanded(flex: 2, child: Text('ESTADO', style: _headerStyle)),
              Expanded(flex: 2, child: Text('GRUPO FAMILIAR', style: _headerStyle)),
              SizedBox(width: 260, child: Text('ACCIONES', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
        ...residencias.map(
          (r) => _FilaDesktop(
            residencia: r,
            onVerDetalle: () => onVerDetalle(r.idResidencia),
            onEliminar: () => onEliminar(r),
          ),
        ),
      ],
    );
  }
}

class _FilaDesktop extends StatelessWidget {
  const _FilaDesktop({
    required this.residencia,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final ResidenciaListItem residencia;
  final VoidCallback onVerDetalle;
  final VoidCallback onEliminar;

  static const _cellStyle = TextStyle(fontSize: 14, color: AdminTheme.titleText);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 1, child: Text('${residencia.idResidencia}', style: _cellStyle)),
              Expanded(flex: 3, child: Text(residencia.direccion, style: _cellStyle)),
              Expanded(flex: 2, child: Text(residencia.comuna, style: _cellStyle)),
              Expanded(flex: 2, child: _EstadoBadge(vigente: residencia.registroVigente)),
              Expanded(flex: 2, child: _GrupoBadge(vinculado: residencia.tieneGrupoVinculado)),
              SizedBox(
                width: 260,
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
          vigente ? 'Vigente' : 'Sin registro vigente',
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

class _GrupoBadge extends StatelessWidget {
  const _GrupoBadge({required this.vinculado});

  final bool vinculado;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: vinculado ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          vinculado ? 'Vinculado' : 'Sin grupo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: vinculado ? AdminTheme.infoBlue : AdminTheme.mutedText,
          ),
        ),
      ),
    );
  }
}

class _ListaMobile extends StatelessWidget {
  const _ListaMobile({
    required this.residencias,
    required this.onVerDetalle,
    required this.onEliminar,
  });

  final List<ResidenciaListItem> residencias;
  final ValueChanged<int> onVerDetalle;
  final ValueChanged<ResidenciaListItem> onEliminar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: residencias.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = residencias[i];
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
                    child: Text(
                      r.direccion,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  _EstadoBadge(vigente: r.registroVigente),
                ],
              ),
              const SizedBox(height: 4),
              Text('ID ${r.idResidencia} · ${r.comuna}', style: const TextStyle(color: AdminTheme.mutedText, fontSize: 13)),
              const SizedBox(height: 8),
              _GrupoBadge(vinculado: r.tieneGrupoVinculado),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminOutlineButton(label: 'Ver Detalle', onPressed: () => onVerDetalle(r.idResidencia)),
                  AdminDangerButton(label: 'Eliminar', onPressed: () => onEliminar(r)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ResidenciaSection extends StatefulWidget {
  const ResidenciaSection({
    super.key,
    required this.alertCount,
    required this.onVerGrupoFamiliar,
  });

  final int alertCount;
  final ValueChanged<int> onVerGrupoFamiliar;

  @override
  State<ResidenciaSection> createState() => _ResidenciaSectionState();
}

class _ResidenciaSectionState extends State<ResidenciaSection> {
  int? _editResidenciaId;

  void _volverLista() => setState(() => _editResidenciaId = null);

  void _abrirMapaResidencia(int idResidencia) => setState(() => _editResidenciaId = idResidencia);

  @override
  Widget build(BuildContext context) {
    if (_editResidenciaId != null) {
      return ResidenciaEditScreen(
        idResidencia: _editResidenciaId!,
        alertCount: widget.alertCount,
        volverLabel: 'Volver a Residencias',
        onVolver: _volverLista,
        onGuardado: _volverLista,
        onVerGrupoFamiliar: widget.onVerGrupoFamiliar,
      );
    }

    return ResidenciasListScreen(
      alertCount: widget.alertCount,
      onVerDetalle: _abrirMapaResidencia,
    );
  }
}
