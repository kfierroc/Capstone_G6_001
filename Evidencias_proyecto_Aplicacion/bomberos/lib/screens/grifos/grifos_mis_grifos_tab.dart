import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../services/mapa_grifo_service.dart';
import '../../widgets/custom_widgets.dart';
import 'grifos_resultados_widgets.dart';

/// Grifos reportados o registrados por el bombero en sesión.
class GrifosMisGrifosTab extends StatefulWidget {
  const GrifosMisGrifosTab({super.key, this.perfil, this.onEditar});

  final BomberoPerfil? perfil;
  final Future<void> Function(GrifoMapaResultado)? onEditar;

  @override
  State<GrifosMisGrifosTab> createState() => _GrifosMisGrifosTabState();
}

class _GrifosMisGrifosTabState extends State<GrifosMisGrifosTab> {
  static const _azul = Color(0xFF1565C0);

  late final MapaGrifoService _svc;
  List<GrifoMapaResultado> _misGrifos = [];
  GrifoFiltroEstado _filtroEstado = GrifoFiltroEstado.todos;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _svc = MapaGrifoService(Supabase.instance.client);
    _cargar();
  }

  Future<void> _editar(GrifoMapaResultado g) async {
    if (widget.onEditar == null) return;
    await widget.onEditar!(g);
    if (mounted) await _cargar();
  }

  Future<void> _cargar() async {
    final perfil = widget.perfil;
    if (perfil == null) {
      setState(() {
        _cargando = false;
        _misGrifos = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final lista = await _svc.listarPorBombero(perfil.rutNum);
      if (!mounted) return;
      setState(() {
        _misGrifos = lista;
        _cargando = false;
      });
    } on MapaGrifoException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar tus grifos: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;

    if (perfil == null) {
      return _mensajeCentrado(
        icon: Icons.person_off_outlined,
        titulo: 'Sesión requerida',
        texto: 'Inicia sesión para ver los grifos registrados a tu nombre.',
      );
    }

    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _azul));
    }

    if (_error != null) {
      return _mensajeCentrado(
        icon: Icons.error_outline,
        titulo: 'No se pudo cargar',
        texto: _error!,
        accion: FilledButton.icon(
          onPressed: _cargar,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reintentar'),
          style: FilledButton.styleFrom(backgroundColor: _azul),
        ),
      );
    }

    return RefreshIndicator(
      color: _azul,
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: AppWidthContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, color: _azul, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mis grifos',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh, color: _azul),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Grifos que has registrado o reportado (${perfil.nombreCompleto}).',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 16),
            GrifosPanelResultados(
              resultados: _misGrifos,
              filtro: _filtroEstado,
              onFiltroChanged: (f) => setState(() => _filtroEstado = f),
              onEditar: _editar,
              mensajeVacio:
                  'Aún no tienes grifos a tu nombre. Registra uno en la pestaña «Registrar Grifo».',
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _mensajeCentrado({
    required IconData icon,
    required String titulo,
    required String texto,
    Widget? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
            if (accion != null) ...[const SizedBox(height: 20), accion],
          ],
        ),
      ),
    );
  }
}
