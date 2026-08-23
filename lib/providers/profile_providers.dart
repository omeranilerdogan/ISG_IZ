import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_enums.dart';
import '../data/models/profile_model.dart';
import 'supabase_providers.dart';

/// Oturum açmış kullanıcının profilini (rol, aktif durumu dahil) realtime izler.
/// Giriş yapılmamışsa null yayınlar.
final currentProfileProvider = StreamProvider<ProfileModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }
  return ref.watch(profileRepositoryProvider).watchById(userId);
});

final currentRoleProvider = Provider<KullaniciRolu?>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull?.rol;
});

/// Admin — Personel Yönetimi ekranı için tüm kullanıcı profillerini realtime izler.
final allProfilesProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(profileRepositoryProvider).watchAll();
});
