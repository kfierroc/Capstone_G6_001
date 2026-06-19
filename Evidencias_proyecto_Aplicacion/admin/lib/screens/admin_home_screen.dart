import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_bombero_perfil.dart';
import '../models/dashboard_stats.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_sidebar.dart';
import 'bomberos/bomberos_list_screen.dart';
import 'catalogos/catalogos_screen.dart';
import 'dashboard_screen.dart';
import 'grupo_familiar/grupo_familiar_list_screen.dart';
import 'grifos/grifos_list_screen.dart';
import 'login_screen.dart';
import 'residencias/residencias_list_screen.dart';

/// Shell principal del panel admin con sidebar y navegación entre módulos.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.perfil});

  final AdminBomberoPerfil perfil;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  AdminSection _section = AdminSection.dashboard;
  int _alertCount = 0;
  int? _grupoFamiliarDetallePendiente;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onStatsLoaded(DashboardStats stats) {
    if (_alertCount != stats.totalAlertas) {
      setState(() => _alertCount = stats.totalAlertas);
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _seleccionarSeccion(AdminSection section) {
    setState(() {
      _section = section;
      if (section != AdminSection.grupoFamiliar) {
        _grupoFamiliarDetallePendiente = null;
      }
    });
    if (MediaQuery.sizeOf(context).width < 900) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _abrirGrupoFamiliar(int idGrupof) {
    setState(() {
      _section = AdminSection.grupoFamiliar;
      _grupoFamiliarDetallePendiente = idGrupof;
    });
    if (MediaQuery.sizeOf(context).width < 900) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Widget _contenido() {
    return switch (_section) {
      AdminSection.dashboard => DashboardScreen(
          alertCount: _alertCount,
          onStatsLoaded: _onStatsLoaded,
        ),
      AdminSection.residencias => ResidenciaSection(
          alertCount: _alertCount,
          onVerGrupoFamiliar: _abrirGrupoFamiliar,
        ),
      AdminSection.grupoFamiliar => GrupoFamiliarSection(
          alertCount: _alertCount,
          detalleInicialId: _grupoFamiliarDetallePendiente,
          onDetalleInicialConsumido: () => setState(() => _grupoFamiliarDetallePendiente = null),
        ),
      AdminSection.bomberos => BomberosListScreen(alertCount: _alertCount),
      AdminSection.grifos => GrifoSection(alertCount: _alertCount, perfil: widget.perfil),
      AdminSection.catalogos => CatalogosScreen(alertCount: _alertCount),
    };
  }

  Widget _sidebar({VoidCallback? onVolver}) {
    return AdminSidebar(
      selected: _section,
      onSelected: _seleccionarSeccion,
      onVolverInicio: onVolver ?? _cerrarSesion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final esDesktop = ancho >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.pageBg,
      drawer: esDesktop
          ? null
          : Drawer(
              child: _sidebar(onVolver: () {
                Navigator.of(context).pop();
                _cerrarSesion();
              }),
            ),
      body: Row(
        children: [
          if (esDesktop) _sidebar(),
          Expanded(
            child: Column(
              children: [
                if (!esDesktop)
                  Material(
                    color: AdminTheme.sidebarBg,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                            const Expanded(
                              child: Text(
                                'Panel Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                              tooltip: 'Cerrar sesión',
                              onPressed: _cerrarSesion,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _contenido()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
