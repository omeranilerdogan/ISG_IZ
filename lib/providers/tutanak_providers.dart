import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_enums.dart';
import '../data/models/tutanak_fotograf_model.dart';
import '../data/models/tutanak_model.dart';
import 'supabase_providers.dart';

class TutanakFiltre {
  const TutanakFiltre({this.projeId, this.durum});

  final String? projeId;
  final TutanakDurumu? durum;

  @override
  bool operator ==(Object other) =>
      other is TutanakFiltre && other.projeId == projeId && other.durum == durum;

  @override
  int get hashCode => Object.hash(projeId, durum);
}

/// Rol bazlı görünürlük `get_tutanaklar()` RPC'si (dolayısıyla RLS) tarafından
/// zaten uygulanır; bu sağlayıcı yalnızca ek proje/durum filtresi ekler.
final tutanakListProvider =
    FutureProvider.autoDispose.family<List<TutanakModel>, TutanakFiltre>((ref, filtre) {
  return ref
      .watch(tutanakRepositoryProvider)
      .fetchList(projeId: filtre.projeId, durum: filtre.durum);
});

final tutanakDetayProvider = FutureProvider.autoDispose.family<TutanakModel?, String>((ref, id) {
  return ref.watch(tutanakRepositoryProvider).fetchById(id);
});

final tutanakFotograflarProvider =
    FutureProvider.autoDispose.family<List<TutanakFotografModel>, String>((ref, tutanakId) {
  return ref.watch(tutanakRepositoryProvider).fetchFotograflar(tutanakId);
});

typedef TutanakFotografUrl = ({TutanakFotografModel foto, String url});

/// Detay ekranındaki galeri için: her fotoğrafın kısa ömürlü signed URL'i
/// ile birlikte döner (bucket private — Bölüm 11, 14).
final tutanakFotografUrlleriProvider =
    FutureProvider.autoDispose.family<List<TutanakFotografUrl>, String>((ref, tutanakId) async {
  final repo = ref.watch(tutanakRepositoryProvider);
  final fotograflar = await repo.fetchFotograflar(tutanakId);
  final sonuc = <TutanakFotografUrl>[];
  for (final f in fotograflar) {
    final url = await repo.getSignedUrl(f.storagePath);
    sonuc.add((foto: f, url: url));
  }
  return sonuc;
});
