import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/supabase_providers.dart';
import '../../providers/taslak_kuyruk_providers.dart';
import '../../providers/tutanak_providers.dart';

/// Faz 5 — bağlantı geldiğinde `taslak_kuyruk_deposu`ndaki bekleyen
/// tutanakları sırayla Supabase'e gönderir. Bir öge başarısız olursa
/// kuyrukta kalır (hata mesajıyla işaretlenir) ve bir sonraki bağlantı
/// olayında tekrar denenir; diğer ögelerin gönderimini engellemez.
class TaslakSenkronizasyonServisi {
  TaslakSenkronizasyonServisi(this._ref);

  final Ref _ref;
  bool _calisiyor = false;

  void baslat() {
    Connectivity().onConnectivityChanged.listen((sonuclar) {
      if (!sonuclar.contains(ConnectivityResult.none)) {
        senkronizeEt();
      }
    });
    senkronizeEt();
  }

  Future<void> senkronizeEt() async {
    if (_calisiyor) return;
    if (_ref.read(currentUserIdProvider) == null) return;

    _calisiyor = true;
    try {
      final depo = _ref.read(taslakKuyrukDeposuProvider);
      final repo = _ref.read(tutanakRepositoryProvider);
      final kuyruk = await depo.tumunuGetir();

      for (final oge in kuyruk) {
        try {
          final tutanakId = await repo.createTutanak(
            projeId: oge.projeId,
            firmaId: oge.firmaId,
            tespitTarihi: oge.tespitTarihi,
            tehlikeSinifi: oge.tehlikeSinifi,
            aciklama: oge.aciklama,
            tavsiyeOneri: oge.tavsiyeOneri,
            terminTarihi: oge.terminTarihi,
            durum: oge.durum,
          );

          var siraNo = 0;
          for (final yol in oge.fotografYollari) {
            final dosya = File(yol);
            if (!await dosya.exists()) continue;
            await repo.uploadFotograf(
              projeId: oge.projeId,
              tutanakId: tutanakId,
              siraNo: siraNo++,
              bytes: await dosya.readAsBytes(),
            );
          }

          await depo.sil(oge.id);
        } catch (e) {
          await depo.guncelle(oge.hataIle('Gönderilemedi: $e'));
        }
      }

      _ref.invalidate(taslakKuyrukListProvider);
      _ref.invalidate(tutanakListProvider);
    } finally {
      _calisiyor = false;
    }
  }
}

final taslakSenkronizasyonServisiProvider = Provider<TaslakSenkronizasyonServisi>((ref) {
  final servis = TaslakSenkronizasyonServisi(ref);
  servis.baslat();
  return servis;
});
