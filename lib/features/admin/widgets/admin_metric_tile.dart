import 'package:flutter/material.dart';

import '../../../core/utils/extensions.dart';

class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(value, style: context.textTheme.titleLarge),
        subtitle: Text(label),
      ),
    );
  }
}
