import '../../core/offline/yerel_depo.dart';
import '../models/taslak_kuyruk_ogesi.dart';

const _kuyrukAnahtari = 'taslak_kuyrugu';
const _fotografDizini = 'taslak_kuyrugu_fotograflari';

/// Bağlantı yokken oluşturulan tutanak taslaklarının cihazda saklandığı
/// yer (Faz 5 — offline senkronizasyon kuyruğu).
class TaslakKuyrukDeposu {
  Future<List<TaslakKuyrukOgesi>> tumunuGetir() async {
    final ham = await YerelDepo.oku(_kuyrukAnahtari);
    if (ham == null) return [];
    return (ham as List)
        .map((e) => TaslakKuyrukOgesi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _kaydet(List<TaslakKuyrukOgesi> liste) {
    return YerelDepo.yaz(_kuyrukAnahtari, liste.map((o) => o.toJson()).toList());
  }

  Future<void> ekle(TaslakKuyrukOgesi oge) async {
    final liste = await tumunuGetir();
    liste.add(oge);
    await _kaydet(liste);
  }

  Future<void> guncelle(TaslakKuyrukOgesi oge) async {
    final liste = await tumunuGetir();
    final index = liste.indexWhere((o) => o.id == oge.id);
    if (index == -1) return;
    liste[index] = oge;
    await _kaydet(liste);
  }

  Future<void> sil(String id) async {
    final liste = await tumunuGetir();
    final eslesenler = liste.where((o) => o.id == id);
    final oge = eslesenler.isEmpty ? null : eslesenler.first;
    liste.removeWhere((o) => o.id == id);
    await _kaydet(liste);
    if (oge != null) {
      for (final yol in oge.fotografYollari) {
        await YerelDepo.dosyaSil(yol);
      }
    }
  }

  /// Yeni bir taslağın fotoğraflarını kalıcı depoya yazar, dosya yollarını döner.
  Future<List<String>> fotograflariKaydet(String taslakId, List<List<int>> fotografBytesListesi) async {
    final yollar = <String>[];
    var siraNo = 0;
    for (final bytes in fotografBytesListesi) {
      final yol = await YerelDepo.ikiliYaz(
        '$_fotografDizini/$taslakId',
        '${siraNo++}.jpg',
        bytes,
      );
      yollar.add(yol);
    }
    return yollar;
  }
}
