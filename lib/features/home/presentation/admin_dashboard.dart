import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/profile_providers.dart';
import '../../../shared/widgets/feature_placeholder_card.dart';

final _bekleyenOnayCountProvider = Provider.autoDispose<int>((ref) {
  final profiles = ref.watch(allProfilesProvider).valueOrNull ?? [];
  return profiles.where((p) => !p.aktif).length;
});

/// Bölüm 5.3 / 5.7 — Admin: genel istatistikler ve yönetim ekranlarına erişim.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final bekleyen = ref.watch(_bekleyenOnayCountProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Merhaba, ${profile?.adSoyad ?? ''}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('İSG Yöneticisi (Admin)'),
        const SizedBox(height: 20),
        if (bekleyen > 0)
          Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: Colors.orange),
              title: Text('$bekleyen kullanıcı onay bekliyor'),
              subtitle: const Text('Personel Yönetimi ekranından onaylayabilirsiniz.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/personel'),
            ),
          ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.groups_outlined,
          title: 'Personel Yönetimi',
          subtitle: 'Kayıt onaylama, rol atama, proje ataması, hesap aktif/pasif.',
          onTap: () => context.push('/admin/personel'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.grid_view_outlined,
          title: 'Kullanıcı Yetki',
          subtitle: 'Kullanıcı ve rol ızgaralarından hızlı yetki ataması.',
          onTap: () => context.push('/admin/kullanici-yetki'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.apartment_outlined,
          title: 'Proje / Firma Tanımları',
          subtitle: 'Proje ekleme-düzenleme, taşeron/firma tanımları.',
          onTap: () => context.push('/admin/proje-firma'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.fact_check_outlined,
          title: 'Tutanak Yönetimi ve Onay Kuyruğu',
          subtitle: 'Tüm tutanakların listesi, inceleme/onay/red işlemleri.',
          onTap: () => context.push('/tutanak'),
        ),
        const SizedBox(height: 12),
        FeaturePlaceholderCard(
          icon: Icons.bar_chart_outlined,
          title: 'Raporlama',
          subtitle: 'Uygunsuzluk trendleri, tehlike sınıfı dağılımı, ceza tutarları.',
          onTap: () => context.push('/raporlar'),
        ),
      ],
    );
  }
}
