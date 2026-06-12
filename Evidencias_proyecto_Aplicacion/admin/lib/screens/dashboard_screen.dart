import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_header.dart';
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
  DashboardStats _stats = DashboardStats.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final stats = await DashboardService(Supabase.instance.client).cargarEstadisticas();
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
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryGrid(stats: _stats),
                        const SizedBox(height: 24),
                        _EstadisticasGenerales(stats: _stats),
                      ],
                    ),
                  ),
                ),
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
        footerIcon: Icons.person_outline,
        footerText: stats.residentesEsteMes > 0
            ? '+${stats.residentesEsteMes} este mes'
            : 'Sin registros este mes',
        footerColor: AdminTheme.successGreen,
      ),
      StatCard(
        title: 'Total Hogares',
        value: '${stats.totalHogares}',
        footerIcon: Icons.home_outlined,
        footerText: stats.hogaresEsteMes > 0
            ? '+${stats.hogaresEsteMes} este mes'
            : 'Sin registros este mes',
        footerColor: AdminTheme.successGreen,
      ),
      StatCard(
        title: 'Total Bomberos',
        value: '${stats.totalBomberos}',
        footerIcon: Icons.shield_outlined,
        footerText: '${stats.totalCompanias} compañía${stats.totalCompanias == 1 ? '' : 's'}',
        footerColor: AdminTheme.infoBlue,
      ),
      StatCard(
        title: 'Total Grifos',
        value: '${stats.totalGrifos}',
        footerIcon: Icons.water_drop_outlined,
        footerText: stats.grifosRequierenAtencion > 0
            ? '${stats.grifosRequierenAtencion} requieren atención'
            : 'Todos operativos',
        footerColor: stats.grifosRequierenAtencion > 0 ? AdminTheme.alertRed : AdminTheme.infoBlue,
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

class _EstadisticasGenerales extends StatelessWidget {
  const _EstadisticasGenerales({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final maxAncho = ancho >= 900 ? 560.0 : double.infinity;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxAncho),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estadísticas Generales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.titleText,
                ),
              ),
              const SizedBox(height: 20),
              StatListTile(
                label: 'Mascotas Registradas',
                value: '${stats.totalMascotas}',
                valueColor: AdminTheme.infoBlue,
                backgroundColor: const Color(0xFFEFF6FF),
              ),
              const SizedBox(height: 12),
              StatListTile(
                label: 'Materiales Peligrosos',
                value: '${stats.totalMaterialesPeligrosos}',
                valueColor: AdminTheme.warningOrange,
                backgroundColor: const Color(0xFFFFF7ED),
              ),
              const SizedBox(height: 12),
              StatListTile(
                label: 'Condiciones Médicas',
                value: '${stats.totalCondicionesMedicas}',
                valueColor: AdminTheme.alertRed,
                backgroundColor: const Color(0xFFFEF2F2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
