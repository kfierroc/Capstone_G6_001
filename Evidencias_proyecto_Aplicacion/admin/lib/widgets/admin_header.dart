import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.title,
    this.alertCount = 0,
  });

  final String title;
  final int alertCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Row(
        children: [
          Icon(Icons.grid_view_rounded, size: 22, color: AdminTheme.infoBlue.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Text(title, style: AdminTheme.sectionTitle),
          const Spacer(),
          if (alertCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AdminTheme.alertRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$alertCount Alerta${alertCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
