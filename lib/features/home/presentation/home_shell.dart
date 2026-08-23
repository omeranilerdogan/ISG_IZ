import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../providers/bildirim_providers.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/role_badge.dart';
import 'admin_dashboard.dart';
import 'personel_dashboard.dart';
import 'yonetici_dashboard.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final okunmamisBildirimSayisi = ref.watch(okunmamisBildirimSayisiProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Widget dashboard = switch (profile.rol) {
      KullaniciRolu.admin => const AdminDashboard(),
      KullaniciRolu.isgUzmani || KullaniciRolu.santiyeSefi => const YoneticiDashboard(),
      KullaniciRolu.personel => const PersonelDashboard(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('İSG Uygunsuzluk Tespit Tutanağı'),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            icon: Badge(
              label: Text('$okunmamisBildirimSayisi'),
              isLabelVisible: okunmamisBildirimSayisi > 0,
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => context.push('/bildirimler'),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.adSoyad, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    RoleBadge(rol: profile.rol),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Ana Sayfa'),
                onTap: () => context.pop(),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profil / Ayarlar'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('İndirilen Dosyalar'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/indirilenler');
                },
              ),
              if (profile.rol == KullaniciRolu.admin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Personel Yönetimi'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/personel');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.apartment_outlined),
                  title: const Text('Proje / Firma Tanımları'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/proje-firma');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: const Text('Kullanıcı Yetki'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/admin/kullanici-yetki');
                  },
                ),
              ],
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await PushNotificationService.tokenSil(ref);
                  await ref.read(authRepositoryProvider).signOut();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: dashboard,
    );
  }
}
