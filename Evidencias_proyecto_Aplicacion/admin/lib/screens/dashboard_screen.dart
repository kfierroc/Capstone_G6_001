import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_desglose.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import '../theme/admin_theme.dart';
import '../utils/filtro_ubicacion_lista.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_lista_filtros_ubicacion.dart';
import '../widgets/dashboard_desglose_bars.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.alertCount,
    this.onStatsLoaded,
  });

  final int alertCount;
  final ValueChanged<DashboardStats>? onStatsLoaded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _filtrosKey = GlobalKey<AdminListaFiltrosUbicacionState>();
  final _idDummy = TextEditingController();
  final _service = DashboardService(Supabase.instance.client);

  DashboardStats _stats = DashboardStats.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _idDummy.dispose();
    super.dispose();
  }

  DashboardFiltroUbicacion _filtroActual() {
    final p = parametrosFiltroUbicacion(
      filtros: _filtrosKey.currentState,
      idText: '',
    );
    return DashboardFiltroUbicacion(
      cutCom: p.cutCom,
      cutComsRegion: p.cutComsRegion,
      etiqueta: _filtrosKey.currentState?.etiquetaFiltroActivo ?? 'Todo Chile',
    );
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.cargarEstadisticas(filtro: _filtroActual());
      if (mounted) {
        setState(() => _stats = stats);
        widget.onStatsLoaded?.call(stats);
      }
    } catch (_) {
      // Mantiene valores en cero si falla la consulta.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Dashboard', alertCount: widget.alertCount),
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
              idController: _idDummy,
              mostrarCampoId: false,
              onChanged: _cargar,
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _UbicacionBanner(etiqueta: _stats.etiquetaUbicacion),
                        if (_stats.totalAlertas > 0) ...[
                          const SizedBox(height: 16),
                          _PanelAlertas(stats: _stats),
                        ],
                        const SizedBox(height: 20),
                        _SummaryGrid(stats: _stats),
                        const SizedBox(height: 20),
                        _IndicadoresSecundarios(stats: _stats),
                        const SizedBox(height: 24),
                        _SeccionesDetalle(stats: _stats),
                        const SizedBox(height: 24),
                        _AnaliticaAvanzada(stats: _stats),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _IndicadoresSecundarios extends StatelessWidget {
  const _IndicadoresSecundarios({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= 1000 ? 4 : ancho >= 600 ? 2 : 1;

    final chips = [
      _MiniIndicador(
        icon: Icons.family_restroom_outlined,
        label: 'Grupos familiares',
        value: '${stats.totalGruposFamiliares}',
        detalle: '${stats.gruposConCuenta} con cuenta (${stats.porcentajeCuentasVinculadas}%)',
        color: AdminTheme.infoBlue,
      ),
      _MiniIndicador(
        icon: Icons.people_alt_outlined,
        label: 'Promedio por hogar',
        value: stats.promedioIntegrantesPorHogar.toStringAsFixed(1),
        detalle: 'integrantes por vivienda vigente',
        color: AdminTheme.successGreen,
      ),
      _MiniIndicador(
        icon: Icons.home_work_outlined,
        label: 'Viviendas en mal estado',
        value: '${stats.hogaresEstadoDeficiente}',
        detalle: 'estado Malo o Muy malo',
        color: stats.hogaresEstadoDeficiente > 0 ? AdminTheme.alertRed : AdminTheme.mutedText,
      ),
      _MiniIndicador(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Bomberos admin',
        value: '${stats.bomberosAdministradores}',
        detalle: 'de ${stats.totalBomberos} en el ámbito',
        color: AdminTheme.warningOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 12.0;
        final anchoChip = (constraints.maxWidth - gap * (columnas - 1)) / columnas;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: chips
              .map((c) => SizedBox(width: columnas == 1 ? constraints.maxWidth : anchoChip, child: c))
              .toList(),
        );
      },
    );
  }
}

class _MiniIndicador extends StatelessWidget {
  const _MiniIndicador({
    required this.icon,
    required this.label,
    required this.value,
    required this.detalle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText)),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
                ),
                Text(detalle, style: const TextStyle(fontSize: 11, color: AdminTheme.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnaliticaAvanzada extends StatelessWidget {
  const _AnaliticaAvanzada({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final dosColumnas = ancho >= 900;

    final filas = <Widget>[
      _FilaAnalitica(
        izquierda: _PanelDesglose(
          titulo: 'Tipos de vivienda',
          subtitulo: 'Hogares vigentes por categoría',
          icono: Icons.apartment_outlined,
          items: stats.tiposVivienda,
          color: AdminTheme.infoBlue,
        ),
        derecha: _PanelDesglose(
          titulo: 'Estado de viviendas',
          subtitulo: 'Condición declarada del inmueble',
          icono: Icons.fact_check_outlined,
          items: stats.estadosVivienda,
          color: AdminTheme.successGreen,
        ),
        dosColumnas: dosColumnas,
      ),
      const SizedBox(height: 16),
      _FilaAnalitica(
        izquierda: _PanelPerfilEtario(perfil: stats.perfilEtario),
        derecha: _PanelDesglose(
          titulo: 'Condiciones por categoría',
          subtitulo: 'Movilidad, cognitivo, médicas…',
          icono: Icons.medical_information_outlined,
          items: stats.categoriasCondicion,
          color: AdminTheme.alertRed,
        ),
        dosColumnas: dosColumnas,
      ),
      const SizedBox(height: 16),
      _FilaAnalitica(
        izquierda: _PanelDesglose(
          titulo: 'Mascotas por especie',
          subtitulo: 'Registro en grupos familiares',
          icono: Icons.pets_outlined,
          items: stats.especiesMascota,
          color: const Color(0xFF7C3AED),
        ),
        derecha: _PanelDesglose(
          titulo: 'Materiales peligrosos',
          subtitulo: 'Unidades por tipo de material',
          icono: Icons.warning_amber_outlined,
          items: stats.materialesPeligrososPorTipo,
          color: AdminTheme.warningOrange,
        ),
        dosColumnas: dosColumnas,
      ),
      const SizedBox(height: 16),
      _FilaAnalitica(
        izquierda: _PanelDesglose(
          titulo: 'Materiales de piso',
          subtitulo: 'Pisos registrados en viviendas',
          icono: Icons.layers_outlined,
          items: stats.materialesPiso,
          color: const Color(0xFF0D9488),
        ),
        derecha: _PanelDesglose(
          titulo: 'Estado de grifos',
          subtitulo: 'Último registro por grifo',
          icono: Icons.water_drop_outlined,
          items: stats.estadosGrifo,
          color: AdminTheme.infoBlue,
        ),
        dosColumnas: dosColumnas,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis detallado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
        ),
        const SizedBox(height: 4),
        const Text(
          'Desgloses según el territorio seleccionado',
          style: TextStyle(fontSize: 13, color: AdminTheme.mutedText),
        ),
        const SizedBox(height: 16),
        ...filas,
      ],
    );
  }
}

class _FilaAnalitica extends StatelessWidget {
  const _FilaAnalitica({
    required this.izquierda,
    required this.derecha,
    required this.dosColumnas,
  });

  final Widget izquierda;
  final Widget derecha;
  final bool dosColumnas;

  @override
  Widget build(BuildContext context) {
    if (!dosColumnas) {
      return Column(
        children: [izquierda, const SizedBox(height: 16), derecha],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: izquierda),
        const SizedBox(width: 16),
        Expanded(child: derecha),
      ],
    );
  }
}

class _PanelDesglose extends StatelessWidget {
  const _PanelDesglose({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.items,
    required this.color,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<DashboardDesglose> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                    ),
                    Text(subtitulo, style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DashboardDesgloseBars(items: items, color: color),
        ],
      ),
    );
  }
}

class _PanelPerfilEtario extends StatelessWidget {
  const _PanelPerfilEtario({required this.perfil});

  final DashboardPerfilEtario perfil;

  @override
  Widget build(BuildContext context) {
    final total = perfil.total;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cake_outlined, size: 22, color: AdminTheme.successGreen),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil etario',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                    ),
                    Text(
                      'Integrantes activos por rango de edad',
                      style: TextStyle(fontSize: 12, color: AdminTheme.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (total == 0)
            const Text('Sin integrantes activos.', style: TextStyle(fontSize: 13, color: AdminTheme.mutedText))
          else ...[
            _RangoEtario(
              etiqueta: 'Menores de 18',
              cantidad: perfil.menores,
              total: total,
              color: AdminTheme.infoBlue,
            ),
            const SizedBox(height: 10),
            _RangoEtario(
              etiqueta: '18 a 64 años',
              cantidad: perfil.adultos,
              total: total,
              color: AdminTheme.successGreen,
            ),
            const SizedBox(height: 10),
            _RangoEtario(
              etiqueta: '65 años o más',
              cantidad: perfil.adultosMayores,
              total: total,
              color: AdminTheme.warningOrange,
            ),
          ],
        ],
      ),
    );
  }
}

class _RangoEtario extends StatelessWidget {
  const _RangoEtario({
    required this.etiqueta,
    required this.cantidad,
    required this.total,
    required this.color,
  });

  final String etiqueta;
  final int cantidad;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? ((cantidad * 100) / total).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 13, color: AdminTheme.titleText))),
            Text(
              '$cantidad ($pct%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? cantidad / total : 0,
            minHeight: 6,
            backgroundColor: const Color(0xFFF3F4F6),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _UbicacionBanner extends StatelessWidget {
  const _UbicacionBanner({required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 20, color: AdminTheme.infoBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Datos para: $etiqueta',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AdminTheme.infoBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAlertas extends StatelessWidget {
  const _PanelAlertas({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AdminTheme.alertRed, size: 22),
              SizedBox(width: 8),
              Text(
                'Requieren atención',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.alertRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.grifosRequierenAtencion > 0)
            _AlertaFila(
              icon: Icons.water_drop_outlined,
              texto: '${stats.grifosRequierenAtencion} grifo${stats.grifosRequierenAtencion == 1 ? '' : 's'} con estado dañado o en mantenimiento',
            ),
          if (stats.grifosRequierenAtencion > 0 && stats.registrosPorExpirar > 0) const SizedBox(height: 8),
          if (stats.registrosPorExpirar > 0)
            _AlertaFila(
              icon: Icons.event_busy_outlined,
              texto: '${stats.registrosPorExpirar} registro${stats.registrosPorExpirar == 1 ? '' : 's'} de vivienda por expirar en 30 días',
            ),
        ],
      ),
    );
  }
}

class _AlertaFila extends StatelessWidget {
  const _AlertaFila({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminTheme.alertRed),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: const TextStyle(fontSize: 13, color: AdminTheme.titleText)),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columnas = ancho >= 1200 ? 4 : ancho >= 700 ? 2 : 1;

    final cards = [
      StatCard(
        title: 'Total Residentes',
        value: '${stats.totalResidentes}',
        icon: Icons.people_outline,
        accentColor: AdminTheme.successGreen,
        footerIcon: Icons.trending_up,
        footerText: stats.residentesEsteMes > 0
            ? '+${stats.residentesEsteMes} este mes'
            : 'Sin altas este mes',
        footerColor: AdminTheme.successGreen,
      ),
      StatCard(
        title: 'Hogares Vigentes',
        value: '${stats.totalHogares}',
        icon: Icons.home_outlined,
        accentColor: AdminTheme.infoBlue,
        footerIcon: Icons.add_home_outlined,
        footerText: stats.hogaresEsteMes > 0
            ? '+${stats.hogaresEsteMes} grupos este mes'
            : 'Sin grupos nuevos este mes',
        footerColor: AdminTheme.successGreen,
      ),
      StatCard(
        title: 'Bomberos',
        value: '${stats.totalBomberos}',
        icon: Icons.local_fire_department_outlined,
        accentColor: AdminTheme.warningOrange,
        footerIcon: Icons.shield_outlined,
        footerText: '${stats.totalCompanias} compañía${stats.totalCompanias == 1 ? '' : 's'}',
        footerColor: AdminTheme.infoBlue,
      ),
      StatCard(
        title: 'Grifos',
        value: '${stats.totalGrifos}',
        icon: Icons.water_drop_outlined,
        accentColor: AdminTheme.infoBlue,
        footerIcon: Icons.build_circle_outlined,
        footerText: stats.grifosRequierenAtencion > 0
            ? '${stats.grifosRequierenAtencion} requieren atención'
            : 'Sin incidencias reportadas',
        footerColor: stats.grifosRequierenAtencion > 0 ? AdminTheme.alertRed : AdminTheme.successGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16.0;
        final cardWidth = (constraints.maxWidth - gap * (columnas - 1)) / columnas;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((c) => SizedBox(width: columnas == 1 ? constraints.maxWidth : cardWidth, child: c))
              .toList(),
        );
      },
    );
  }
}

class _SeccionesDetalle extends StatelessWidget {
  const _SeccionesDetalle({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final dosColumnas = ancho >= 900;

    final comunidad = _SeccionPanel(
      titulo: 'Comunidad',
      subtitulo: 'Integrantes, mascotas y condiciones',
      icono: Icons.groups_outlined,
      tiles: [
        StatListTile(
          label: 'Mascotas registradas',
          value: '${stats.totalMascotas}',
          valueColor: AdminTheme.infoBlue,
          backgroundColor: const Color(0xFFEFF6FF),
        ),
        StatListTile(
          label: 'Condiciones médicas',
          value: '${stats.totalCondicionesMedicas}',
          valueColor: AdminTheme.alertRed,
          backgroundColor: const Color(0xFFFEF2F2),
        ),
      ],
    );

    final riesgos = _SeccionPanel(
      titulo: 'Riesgos y materiales',
      subtitulo: 'Inventario de peligros y vencimientos',
      icono: Icons.health_and_safety_outlined,
      tiles: [
        StatListTile(
          label: 'Materiales peligrosos (unidades)',
          value: '${stats.totalMaterialesPeligrosos}',
          valueColor: AdminTheme.warningOrange,
          backgroundColor: const Color(0xFFFFF7ED),
        ),
        StatListTile(
          label: 'Registros por expirar (30 días)',
          value: '${stats.registrosPorExpirar}',
          valueColor: stats.registrosPorExpirar > 0 ? AdminTheme.alertRed : AdminTheme.successGreen,
          backgroundColor: stats.registrosPorExpirar > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        ),
      ],
    );

    if (!dosColumnas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          comunidad,
          const SizedBox(height: 16),
          riesgos,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: comunidad),
        const SizedBox(width: 16),
        Expanded(child: riesgos),
      ],
    );
  }
}

class _SeccionPanel extends StatelessWidget {
  const _SeccionPanel({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.tiles,
  });

  final String titulo;
  final String subtitulo;
  final IconData icono;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 22, color: AdminTheme.mutedText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminTheme.titleText,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            tiles[i],
          ],
        ],
      ),
    );
  }
}
