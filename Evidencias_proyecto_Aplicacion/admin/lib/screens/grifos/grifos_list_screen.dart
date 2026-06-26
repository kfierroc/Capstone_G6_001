import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_bombero_perfil.dart';
import '../../models/grifo_list_item.dart';
import '../../services/grifos_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../utils/filtro_ubicacion_lista.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/admin_lista_filtros_ubicacion.dart';
import '../../widgets/admin_lista_pie_paginacion.dart';
import 'grifo_edit_screen.dart';

class GrifosListScreen extends StatefulWidget {
  const GrifosListScreen({
    super.key,
    required this.alertCount,
    required this.onVerDetalle,
    required this.onAgregar,
  });

  final int alertCount;
  final ValueChanged<int> onVerDetalle;
  final VoidCallback onAgregar;

  @override
  State<GrifosListScreen> createState() => _GrifosListScreenState();
}

class _GrifosListScreenState extends State<GrifosListScreen> {
  final _filtrosKey = GlobalKey<AdminListaFiltrosUbicacionState>();
  final _idController = TextEditingController();
  final _service = GrifosAdminService(Supabase.instance.client);

  List<GrifoListItem> _grifos = [];
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
    super.dispose();
  }

  ({int? cutCom, List<int>? cutComsRegion, int? idGrifoExacto}) _parametrosFiltro() {
    final p = parametrosFiltroUbicacion(
      filtros: _filtrosKey.currentState,
      idText: _idController.text,
    );
    return (cutCom: p.cutCom, cutComsRegion: p.cutComsRegion, idGrifoExacto: p.idExacto);
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _loading = true;
      _grifos = [];
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
    final p = _parametrosFiltro();
    final pag = await _service.listarGrifosPaginado(
      offset: _offset,
      cutCom: p.cutCom,
      cutComsRegion: p.cutComsRegion,
      idGrifoExacto: p.idGrifoExacto,
    );
    if (!mounted) return;
    setState(() {
      if (reemplazar) {
        _grifos = pag.items;
      } else {
        _grifos = [..._grifos, ...pag.items];
      }
      _offset = _grifos.length;
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

  List<GrifoListItem> get _filtrados {
    final idText = _idController.text.trim();
    if (idText.isEmpty || int.tryParse(idText) != null) {
      return _grifos;
    }
    return _grifos.where((g) => filtroId(id: g.idGrifo, idQuery: idText)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Grifos', alertCount: widget.alertCount),
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
              idHint: 'ID del grifo',
              onChanged: _onFiltrosCambiados,
              onIdChanged: _onIdCambiado,
              trailing: AdminPrimaryButton(
                label: 'Agregar Grifo',
                icon: Icons.add,
                onPressed: widget.onAgregar,
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
                            _grifos.isEmpty && !_hayMas
                                ? 'No hay grifos registrados.'
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
                                    ? _TablaDesktop(grifos: filtrados, onVerDetalle: widget.onVerDetalle)
                                    : _ListaMobile(grifos: filtrados, onVerDetalle: widget.onVerDetalle),
                              ),
                            ),
                            if (_hayMas || _cargandoMas)
                              AdminListaPiePaginacion(
                                totalMostrado: _grifos.length,
                                etiquetaSingular: 'grifo',
                                etiquetaPlural: 'grifos',
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
  const _TablaDesktop({required this.grifos, required this.onVerDetalle});

  final List<GrifoListItem> grifos;
  final ValueChanged<int> onVerDetalle;

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
              Expanded(flex: 2, child: Text('COMUNA', style: _headerStyle)),
              Expanded(flex: 2, child: Text('ESTADO', style: _headerStyle)),
              Expanded(flex: 2, child: Text('COORDENADAS', style: _headerStyle)),
              Expanded(flex: 2, child: Text('REGISTRADO POR', style: _headerStyle)),
              SizedBox(width: 140, child: Text('ACCIONES', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
        ...grifos.map(
          (g) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('${g.idGrifo}', style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 2, child: Text(g.comuna, style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 2, child: _EstadoGrifoBadge(estado: g.estadoActual, atencion: g.requiereAtencion)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Lat ${g.lat.toStringAsFixed(5)}\nLong ${g.lon.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 13, color: AdminTheme.titleText),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(g.registradoPor ?? '—', style: const TextStyle(fontSize: 14)),
                    ),
                    SizedBox(
                      width: 140,
                      child: AdminOutlineButton(label: 'Ver Detalle', onPressed: () => onVerDetalle(g.idGrifo)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AdminTheme.cardBorder),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListaMobile extends StatelessWidget {
  const _ListaMobile({required this.grifos, required this.onVerDetalle});

  final List<GrifoListItem> grifos;
  final ValueChanged<int> onVerDetalle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: grifos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final g = grifos[i];
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
                    child: Text('Grifo ${g.idGrifo}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _EstadoGrifoBadge(estado: g.estadoActual, atencion: g.requiereAtencion),
                ],
              ),
              const SizedBox(height: 4),
              Text(g.comuna, style: const TextStyle(color: AdminTheme.mutedText, fontSize: 13)),
              if (g.registradoPor != null && g.registradoPor != '—') ...[
                const SizedBox(height: 4),
                Text(
                  'Registrado por ${g.registradoPor}',
                  style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Lat ${g.lat.toStringAsFixed(5)} · Long ${g.lon.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
              ),
              const SizedBox(height: 12),
              AdminOutlineButton(label: 'Ver Detalle', onPressed: () => onVerDetalle(g.idGrifo)),
            ],
          ),
        );
      },
    );
  }
}

class _EstadoGrifoBadge extends StatelessWidget {
  const _EstadoGrifoBadge({required this.estado, required this.atencion});

  final String estado;
  final bool atencion;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (atencion) {
      bg = const Color(0xFFFFF7ED);
      fg = AdminTheme.warningOrange;
    } else if (estado.toLowerCase().contains('operativo')) {
      bg = const Color(0xFFECFDF5);
      fg = AdminTheme.successGreen;
    } else {
      bg = const Color(0xFFF3F4F6);
      fg = AdminTheme.mutedText;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(estado, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class GrifoSection extends StatefulWidget {
  const GrifoSection({
    super.key,
    required this.alertCount,
    required this.perfil,
  });

  final int alertCount;
  final AdminBomberoPerfil perfil;

  @override
  State<GrifoSection> createState() => _GrifoSectionState();
}

class _GrifoSectionState extends State<GrifoSection> {
  int? _detalleId;
  bool _modoCreacion = false;

  void _volverLista() => setState(() {
        _detalleId = null;
        _modoCreacion = false;
      });

  void _abrirDetalle(int id) => setState(() {
        _detalleId = id;
        _modoCreacion = false;
      });

  void _abrirCreacion() => setState(() {
        _detalleId = null;
        _modoCreacion = true;
      });

  @override
  Widget build(BuildContext context) {
    if (_modoCreacion || _detalleId != null) {
      return GrifoEditScreen(
        idGrifo: _modoCreacion ? null : _detalleId,
        perfil: widget.perfil,
        alertCount: widget.alertCount,
        volverLabel: 'Volver a Grifos',
        onVolver: _volverLista,
        onGuardado: (id) => setState(() {
          _modoCreacion = false;
          _detalleId = id;
        }),
      );
    }

    return GrifosListScreen(
      alertCount: widget.alertCount,
      onVerDetalle: _abrirDetalle,
      onAgregar: _abrirCreacion,
    );
  }
}
