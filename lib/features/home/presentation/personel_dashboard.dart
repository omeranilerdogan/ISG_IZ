import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/tutanak_providers.dart';
import '../../../shared/widgets/feature_placeholder_card.dart';

/// Bölüm 5.3 — Saha Personeli / İSG Uzmanı: "Yeni Tutanak Oluştur" butonu ve
/// kendi tutanaklarının durum özeti (Taslak/Gönderildi/Onaylandı/Reddedildi).
class PersonelDashboard extends ConsumerWidget {
  const PersonelDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final tutanaklarAsync = ref.watch(tutanakListProvider(const TutanakFiltre()));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Merhaba, ${profile?.adSoyad ?? ''}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(profile?.rol.etiket ?? ''),
        const SizedBox(height: 20),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/tutanak/yeni'),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yeni Tutanak Oluştur', style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Fotoğraflı uygunsuzluk tespit tutanağı doldurun.'),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.assignment_outlined,
          title: 'Tutanaklarım',
          subtitle: 'Taslak / Gönderildi / Onaylandı / Reddedildi durumları.',
          onTap: () => context.push('/tutanak'),
        ),
        const SizedBox(height: 16),
        tutanaklarAsync.when(
          data: (liste) {
            if (liste.isEmpty) return const SizedBox.shrink();
            final sayilar = <TutanakDurumu, int>{};
            for (final t in liste) {
              sayilar[t.durum] = (sayilar[t.durum] ?? 0) + 1;
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sayilar.entries
                  .map((e) => Chip(label: Text('${e.key.etiket}: ${e.value}')))
                  .toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
