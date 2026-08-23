import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/supabase_providers.dart';

/// Bölüm 5.1: "Hesabı admin tarafından henüz onaylanmamış veya pasif
/// kullanıcılar için uyarı mesajı gösterilir."
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top, size: 64, color: AppTheme.accent),
              const SizedBox(height: 24),
              Text(
                'Hesabınız Onay Bekliyor',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hesabınız henüz İSG Yöneticisi tarafından onaylanmadı veya pasif duruma alınmış. '
                'Onaylandığında sisteme giriş yapabileceksiniz.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
