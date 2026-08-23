import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/taslak_kuyruk_ogesi.dart';
import '../data/repositories/taslak_kuyruk_deposu.dart';

final taslakKuyrukDeposuProvider = Provider<TaslakKuyrukDeposu>((ref) {
  return TaslakKuyrukDeposu();
});

/// Bekleyen (henüz gönderilmemiş) taslakların listesi. Kuyruğa ekleme/silme
/// veya senkronizasyon sonrası `ref.invalidate(taslakKuyrukListProvider)`
/// ile tazelenir.
final taslakKuyrukListProvider = FutureProvider.autoDispose<List<TaslakKuyrukOgesi>>((ref) {
  return ref.watch(taslakKuyrukDeposuProvider).tumunuGetir();
});

final bekleyenTaslakSayisiProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(taslakKuyrukListProvider).valueOrNull?.length ?? 0;
});
