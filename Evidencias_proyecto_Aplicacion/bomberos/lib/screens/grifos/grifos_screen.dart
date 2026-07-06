import 'package:flutter/material.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../widgets/custom_widgets.dart';
import 'grifo_edicion_screen.dart';
import 'grifos_lista_tab.dart';
import 'grifos_mapa_tab.dart';
import 'grifos_mis_grifos_tab.dart';
import 'grifos_registro_tab.dart';

/// Módulo de grifos: mapa, lista, mis grifos y registro.
class GrifosScreen extends StatefulWidget {
  const GrifosScreen({super.key, this.perfil});

  final BomberoPerfil? perfil;

  @override
  State<GrifosScreen> createState() => _GrifosScreenState();
}

class _GrifosScreenState extends State<GrifosScreen> with SingleTickerProviderStateMixin {
  static const _azul = Color(0xFF1565C0);

  late final TabController _tabs;
  List<GrifoMapaResultado> _resultados = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _actualizarResultados(List<GrifoMapaResultado> lista) {
    setState(() => _resultados = lista);
  }

  void _aplicarGrifoActualizado(GrifoMapaResultado actualizado) {
    final i = _resultados.indexWhere((g) => g.idGrifo == actualizado.idGrifo);
    if (i < 0) return;
    final copy = List<GrifoMapaResultado>.from(_resultados);
    copy[i] = actualizado;
    setState(() => _resultados = copy);
  }

  Future<void> _editarGrifo(GrifoMapaResultado grifo) async {
    final actualizado = await Navigator.push<GrifoMapaResultado>(
      context,
      MaterialPageRoute(
        builder: (_) => GrifoEdicionScreen(grifo: grifo, perfil: widget.perfil),
      ),
    );
    if (actualizado == null || !mounted) return;
    _aplicarGrifoActualizado(actualizado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Grifo #${actualizado.idGrifo} actualizado.')),
    );
  }

  String get _subtitulo {
    final p = widget.perfil;
    if (p != null) return 'Bienvenido, ${p.nombreCompleto}';
    return 'Consulta y registro de grifos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          CustomAppBar(
            title: 'Sistema de Grifos de Agua',
            subtitle: _subtitulo,
            leadingIcon: Icons.water_drop_outlined,
            backgroundColor: _azul,
          ),
          Material(
            color: _azul,
            child: TabBar(
              controller: _tabs,
              tabAlignment: TabAlignment.fill,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Mapa'),
                Tab(text: 'Lista'),
                Tab(text: 'Mis grifos'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Registrar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                GrifosMapaTab(
                  resultados: _resultados,
                  onResultados: _actualizarResultados,
                  perfil: widget.perfil,
                  onEditar: _editarGrifo,
                ),
                GrifosListaTab(
                  resultados: _resultados,
                  onResultados: _actualizarResultados,
                  perfil: widget.perfil,
                  onEditar: _editarGrifo,
                ),
                GrifosMisGrifosTab(
                  perfil: widget.perfil,
                  onEditar: _editarGrifo,
                ),
                GrifosRegistroTab(perfil: widget.perfil),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
