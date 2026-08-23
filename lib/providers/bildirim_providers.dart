import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bildirim_model.dart';
import 'supabase_providers.dart';

/// Oturum sahibine ait bildirimleri realtime izler. Giriş yapılmamışsa boş liste yayınlar.
final bildirimListProvider = StreamProvider.autoDispose<List<BildirimModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(const <BildirimModel>[]);
  }
  return ref.watch(bildirimRepositoryProvider).watchAll(userId);
});

/// Uygulama çubuğundaki bildirim rozetinde gösterilecek okunmamış sayısı.
final okunmamisBildirimSayisiProvider = Provider.autoDispose<int>((ref) {
  final liste = ref.watch(bildirimListProvider).valueOrNull ?? const [];
  return liste.where((b) => !b.okundu).length;
});
