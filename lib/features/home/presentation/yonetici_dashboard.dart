import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/profile_providers.dart';
import '../../../shared/widgets/feature_placeholder_card.dart';

/// Bölüm 5.3 — Şantiye Şefi: kendi proje(leri)ndeki açık tutanak sayısı,
/// son bildirimler (salt okunur — onay/düzenleme yetkisi yok).
class YoneticiDashboard extends ConsumerWidget {
  const YoneticiDashboard({super.key});

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
          icon: Icons.pending_actions_outlined,
          title: 'Açık Tutanaklar',
          subtitle: 'Atandığınız proje(ler)deki tutanakları görüntüleyin.',
          onTap: () => context.push('/tutanak'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.assignment_outlined,
          title: 'Tutanak Listesi',
          subtitle: 'Proje/tarih/tehlike sınıfına göre filtreleme.',
          onTap: () => context.push('/tutanak'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.bar_chart_outlined,
          title: 'Raporlama',
          subtitle: 'Uygunsuzluk trendleri (ceza tutarı hariç).',
          onTap: () => context.push('/raporlar'),
        ),
      ],
    );
  }
}
