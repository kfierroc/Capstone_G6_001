import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.footerIcon,
    required this.footerText,
    required this.footerColor,
  });

  final String title;
  final String value;
  final IconData footerIcon;
  final String footerText;
  final Color footerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AdminTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AdminTheme.titleText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(footerIcon, size: 16, color: footerColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  footerText,
                  style: TextStyle(
                    fontSize: 12,
                    color: footerColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatListTile extends StatelessWidget {
  const StatListTile({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AdminTheme.titleText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
