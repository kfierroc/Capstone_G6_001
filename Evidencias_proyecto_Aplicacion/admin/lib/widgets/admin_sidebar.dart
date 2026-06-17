import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

/// Secciones del panel admin.
enum AdminSection {
  dashboard('Dashboard', Icons.dashboard_outlined),
  residencias('Residencias', Icons.home_outlined),
  grupoFamiliar('Grupo Familiar', Icons.people_outline),
  catalogos('Catálogos', Icons.list_alt_outlined),
  bomberos('Bomberos', Icons.shield_outlined),
  grifos('Grifos', Icons.water_drop_outlined);

  const AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onVolverInicio,
  });

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelected;
  final VoidCallback? onVolverInicio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AdminTheme.sidebarWidth,
      color: AdminTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Text(
              'Panel Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: AdminSection.values.map((section) {
                final activo = section == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: activo ? AdminTheme.sidebarActive : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => onSelected(section),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              section.icon,
                              size: 20,
                              color: activo ? Colors.white : AdminTheme.sidebarText,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              section.label,
                              style: TextStyle(
                                color: activo ? Colors.white : AdminTheme.sidebarText,
                                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Color(0xFF374151), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: onVolverInicio,
              icon: const Icon(Icons.arrow_back, size: 18, color: AdminTheme.sidebarText),
              label: const Text(
                'Volver al inicio',
                style: TextStyle(color: AdminTheme.sidebarText, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
