import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/profile_providers.dart';
import '../../../shared/widgets/feature_placeholder_card.dart';

/// Firma Yetkilisi / Firma Sorumlusu: kendi firmalarına ait UTTS raporlarını
/// görüntüler (Firma Sorumlusu ayrıca rapor detayından yorum ekleyebilir).
class FirmaDashboard extends ConsumerWidget {
  const FirmaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Merhaba, ${profile?.adSoyad ?? ''}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(profile?.rol.etiket ?? ''),
        const SizedBox(height: 20),
        FeaturePlaceholderCard(
          icon: Icons.assignment_outlined,
          title: 'Firma Raporları',
          subtitle: 'Firmanıza ait UTTS raporlarını görüntüleyin.',
          onTap: () => context.push('/tutanak'),
        ),
      ],
    );
  }
}
