import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Faz 1'de henüz kodlanmamış, sonraki fazlarda gelecek özellikler için
/// tutarlı bir "yakında" kartı.
class FeaturePlaceholderCard extends StatelessWidget {
  const FeaturePlaceholderCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.fazEtiketi,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? fazEtiketi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title — ${fazEtiketi ?? 'yakında'} eklenecek.')),
              );
            },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (fazEtiketi != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(fazEtiketi!, style: Theme.of(context).textTheme.labelSmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
