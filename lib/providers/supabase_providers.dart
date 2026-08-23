import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/bildirim_repository.dart';
import '../data/repositories/firma_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/proje_repository.dart';
import '../data/repositories/push_token_repository.dart';
import '../data/repositories/tutanak_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final projeRepositoryProvider = Provider<ProjeRepository>((ref) {
  return ProjeRepository(ref.watch(supabaseClientProvider));
});

final firmaRepositoryProvider = Provider<FirmaRepository>((ref) {
  return FirmaRepository(ref.watch(supabaseClientProvider));
});

final tutanakRepositoryProvider = Provider<TutanakRepository>((ref) {
  return TutanakRepository(ref.watch(supabaseClientProvider));
});

final bildirimRepositoryProvider = Provider<BildirimRepository>((ref) {
  return BildirimRepository(ref.watch(supabaseClientProvider));
});

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(ref.watch(supabaseClientProvider));
});

/// Supabase Auth oturum durumu değişikliklerini (giriş/çıkış/token yenileme) yayınlar.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Şu anki oturum sahibinin kullanıcı kimliği (giriş yapılmamışsa null).
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user.id ?? ref.watch(supabaseClientProvider).auth.currentUser?.id;
});
