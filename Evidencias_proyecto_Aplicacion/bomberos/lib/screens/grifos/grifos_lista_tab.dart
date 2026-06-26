import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../services/catalogos_bombero_service.dart';
import '../../services/compania_bombero_service.dart';
import '../../services/mapa_grifo_service.dart';
import '../../widgets/custom_widgets.dart';
import 'grifos_resultados_widgets.dart';

/// Pestaña lista: búsqueda por comuna y por ID (adicional).
class GrifosListaTab extends StatefulWidget {
  const GrifosListaTab({
    super.key,
    required this.resultados,
    required this.onResultados,
    this.perfil,
    this.onEditar,
  });

  final List<GrifoMapaResultado> resultados;
  final ValueChanged<List<GrifoMapaResultado>> onResultados;
  final BomberoPerfil? perfil;
  final Future<void> Function(GrifoMapaResultado)? onEditar;

  @override
  State<GrifosListaTab> createState() => _GrifosListaTabState();
}

class _GrifosListaTabState extends State<GrifosListaTab> {
  static const _azul = Color(0xFF1565C0);

  late final MapaGrifoService _svc;
  final _buscarIdCtrl = TextEditingController();

  List<({int cutReg, String nombre})> _regiones = [];
  List<({int cutCom, String nombre})> _comunas = [];
  int? _cutRegSeleccionada;
  int? _cutComSeleccionada;
  bool _busquedaLibre = false;
  bool _cargandoFiltros = true;
  bool _cargandoComunas = false;
  bool _buscandoComuna = false;
  bool _buscandoId = false;

  GrifoFiltroEstado _filtroEstado = GrifoFiltroEstado.todos;

  Map<String, int> _estadisticas = GrifoListaUtils.estadisticasVacias();
  int? _cutComActiva;
  int _cursorGrifo = 0;
  bool _hayMas = false;
  bool _cargandoMas = false;

  @override
  void initState() {
    super.initState();
    _svc = MapaGrifoService(Supabase.instance.client);
    _cargarFiltrosUbicacion();
  }

  @override
  void dispose() {
    _buscarIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarFiltrosUbicacion() async {
    final client = Supabase.instance.client;
    final catalogos = CatalogosBomberoService(client);
    setState(() => _cargandoFiltros = true);
    try {
      final regiones = await catalogos.regiones();
      int? cutReg;
      int? cutCom;
      List<({int cutCom, String nombre})> comunas = [];

      final idCompania = widget.perfil?.idCompania;
      if (idCompania != null) {
        final ubicacion = await CompaniaBomberoService(client).obtenerUbicacionPorIdCompania(idCompania);
        if (ubicacion != null) {
          cutReg = ubicacion.cutReg;
          cutCom = ubicacion.cutCom;
          comunas = await catalogos.comunasPorRegion(cutReg);
        }
      }

      if (!mounted) return;
      setState(() {
        _regiones = regiones;
        _cutRegSeleccionada = cutReg;
        _comunas = comunas;
        _cutComSeleccionada = cutCom;
        _cargandoFiltros = false;
      });

      if (cutCom != null && !_busquedaLibre) {
        await _buscarPorComuna();
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoFiltros = false);
    }
  }

  Future<void> _onRegionChanged(int? cutReg) async {
    setState(() {
      _cutRegSeleccionada = cutReg;
      _cutComSeleccionada = null;
      _comunas = [];
    });
    if (cutReg == null) return;

    setState(() => _cargandoComunas = true);
    try {
      final list = await CatalogosBomberoService(Supabase.instance.client).comunasPorRegion(cutReg);
      if (!mounted) return;
      setState(() {
        _comunas = list;
        _cargandoComunas = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoComunas = false);
        _snack('No se pudieron cargar las comunas.');
      }
    }
  }

  Future<void> _onComunaChanged(int? cutCom) async {
    setState(() => _cutComSeleccionada = cutCom);
    if (cutCom != null && !_busquedaLibre) {
      await _buscarPorComuna();
    }
  }

  bool get _filtroUbicacionCompleto => _cutRegSeleccionada != null && _cutComSeleccionada != null;

  bool get _puedeBuscarComuna => !_busquedaLibre && _filtroUbicacionCompleto;

  bool get _puedeBuscarId => _busquedaLibre || _filtroUbicacionCompleto;

  bool get _buscando => _buscandoComuna || _buscandoId;

  void _alternarBusquedaLibre() {
    setState(() => _busquedaLibre = !_busquedaLibre);
  }

  Future<void> _buscarPorComuna() async {
    if (_busquedaLibre) return;
    if (_cutRegSeleccionada == null) {
      _snack('Selecciona una región.');
      return;
    }
    if (_cutComSeleccionada == null) {
      _snack('Selecciona una comuna.');
      return;
    }

    setState(() => _buscandoComuna = true);
    try {
      final cutCom = _cutComSeleccionada!;
      final statsFuture = _svc.estadisticasPorComuna(cutCom);
      final paginaFuture = _svc.listarPorComunaPaginado(
        cutCom: cutCom,
        cursorGrifo: 0,
        filtro: _filtroEstado,
      );
      final stats = await statsFuture;
      final pagina = await paginaFuture;
      if (!mounted) return;

      setState(() {
        _cutComActiva = cutCom;
        _cursorGrifo = pagina.siguienteCursor;
        _hayMas = pagina.hayMas;
        _estadisticas = stats;
      });
      widget.onResultados(pagina.items);

      if (pagina.items.isEmpty && GrifoListaUtils.totalParaFiltro(stats, _filtroEstado) == 0) {
        final nombre = _comunas.where((c) => c.cutCom == cutCom).map((c) => c.nombre).firstOrNull;
        _snack('No hay grifos registrados en ${nombre ?? 'la comuna seleccionada'}.');
      }
    } on MapaGrifoException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Error al buscar grifos: $e');
    } finally {
      if (mounted) setState(() => _buscandoComuna = false);
    }
  }

  Future<void> _cargarMasComuna() async {
    final cutCom = _cutComActiva ?? _cutComSeleccionada;
    if (cutCom == null || !_hayMas || _cargandoMas) return;

    setState(() => _cargandoMas = true);
    try {
      final pagina = await _svc.listarPorComunaPaginado(
        cutCom: cutCom,
        cursorGrifo: _cursorGrifo,
        filtro: _filtroEstado,
      );
      if (!mounted) return;

      widget.onResultados([...widget.resultados, ...pagina.items]);
      setState(() {
        _cursorGrifo = pagina.siguienteCursor;
        _hayMas = pagina.hayMas;
      });
    } on MapaGrifoException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Error al cargar más grifos: $e');
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _onFiltroEstadoChanged(GrifoFiltroEstado filtro) {
    setState(() => _filtroEstado = filtro);
    if (!_busquedaLibre && _cutComSeleccionada != null) {
      _buscarPorComuna();
    }
  }

  Future<void> _buscarPorId() async {
    final idTxt = _buscarIdCtrl.text.trim().replaceAll('#', '');
    final id = int.tryParse(idTxt);
    if (id == null) {
      _snack('Ingresa un ID de grifo válido.');
      return;
    }
    if (!_busquedaLibre) {
      if (_cutRegSeleccionada == null) {
        _snack('Selecciona una región.');
        return;
      }
      if (_cutComSeleccionada == null) {
        _snack('Selecciona una comuna.');
        return;
      }
    }

    setState(() => _buscandoId = true);
    try {
      final grifo = await _svc.buscarPorId(
        idGrifo: id,
        cutCom: _busquedaLibre ? null : _cutComSeleccionada,
      );
      if (!mounted) return;

      if (grifo == null) {
        widget.onResultados([]);
        setState(() {
          _estadisticas = GrifoListaUtils.estadisticasVacias();
          _hayMas = false;
          _cursorGrifo = 0;
          _cutComActiva = null;
        });
        _snack(_busquedaLibre
            ? 'No se encontró el grifo #$id.'
            : 'No se encontró el grifo #$id en la comuna seleccionada.');
      } else {
        widget.onResultados([grifo]);
        setState(() {
          _estadisticas = GrifoListaUtils.estadisticas([grifo]);
          _hayMas = false;
          _cursorGrifo = 0;
          _cutComActiva = grifo.cutCom;
        });
      }
    } on MapaGrifoException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _buscandoId = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AppWidthContainer(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _seccionTitulo(
                  icon: Icons.filter_list,
                  titulo: 'Buscar grifos',
                  subtitulo:
                      'Selecciona región y comuna para listar grifos. La búsqueda por ID es adicional.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _buscando ? null : _alternarBusquedaLibre,
                    icon: Icon(
                      _busquedaLibre ? Icons.travel_explore : Icons.travel_explore_outlined,
                      size: 20,
                      color: _busquedaLibre ? _azul : Colors.grey.shade700,
                    ),
                    label: Text(
                      _busquedaLibre ? 'Búsqueda libre activa' : 'Activar búsqueda libre',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _busquedaLibre ? _azul : Colors.grey.shade800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _busquedaLibre ? _azul : Colors.grey.shade400),
                      backgroundColor: _busquedaLibre ? const Color(0xFFE3F2FD) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (!_busquedaLibre) ...[
                  const SizedBox(height: 12),
                  _labelObligatorio('Región'),
                  const SizedBox(height: 6),
                  _cargandoFiltros && _regiones.isEmpty
                      ? const LinearProgressIndicator(minHeight: 2)
                      : _dropdownReg(
                          valor: _cutRegSeleccionada,
                          hint: 'Selecciona una región',
                          items: _regiones.map((r) => (r.cutReg, r.nombre)).toList(),
                          onChanged: _buscando ? null : _onRegionChanged,
                        ),
                  const SizedBox(height: 12),
                  _labelObligatorio('Comuna'),
                  const SizedBox(height: 6),
                  if (_cargandoComunas)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    _dropdownReg(
                      valor: _cutComSeleccionada,
                      hint: _cutRegSeleccionada == null
                          ? 'Primero selecciona una región'
                          : 'Selecciona una comuna',
                      items: _comunas.map((c) => (c.cutCom, c.nombre)).toList(),
                      onChanged: (_buscando || _cutRegSeleccionada == null) ? null : _onComunaChanged,
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_buscandoComuna || !_puedeBuscarComuna) ? null : _buscarPorComuna,
                    icon: _buscandoComuna
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search, size: 20),
                    label: Text(_buscandoComuna ? 'Buscando…' : 'Buscar en comuna'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _azul,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Búsqueda adicional por ID',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buscarIdCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_buscandoId,
                        decoration: InputDecoration(
                          hintText: 'ID de grifo…',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        onSubmitted: (_) {
                          if (_puedeBuscarId && !_buscandoId) _buscarPorId();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: (_buscandoId || !_puedeBuscarId) ? null : _buscarPorId,
                      style: FilledButton.styleFrom(
                        backgroundColor: _azul,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _buscandoId
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Buscar ID', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GrifosPanelResultados(
                  resultados: widget.resultados,
                  estadisticas: _estadisticas,
                  filtro: _filtroEstado,
                  onFiltroChanged: _onFiltroEstadoChanged,
                  onEditar: widget.onEditar,
                  hayMas: _hayMas,
                  cargandoMas: _cargandoMas,
                  onCargarMas: _cargarMasComuna,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seccionTitulo({required IconData icon, required String titulo, String? subtitulo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _azul, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3)),
        ],
      ],
    );
  }

  Widget _labelObligatorio(String texto) {
    return Row(
      children: [
        Text(texto, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        const Text(' *', style: TextStyle(color: _azul, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _dropdownReg({
    required int? valor,
    required String hint,
    required List<(int, String)> items,
    required ValueChanged<int?>? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('$hint-$valor'),
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e.$1,
              child: Text(e.$2, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
