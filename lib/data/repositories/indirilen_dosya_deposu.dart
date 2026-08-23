import '../../core/offline/yerel_depo.dart';
import '../models/indirilen_dosya.dart';

const _kayitAnahtari = 'indirilen_dosyalar';

/// PDF/Excel dışa aktarımlarının "İndirilen Dosyalar" ekranında
/// listelenebilmesi için cihazda tutulan kayıt defteri.
class IndirilenDosyaDeposu {
  Future<List<IndirilenDosya>> tumunuGetir() async {
    final ham = await YerelDepo.oku(_kayitAnahtari);
    if (ham == null) return [];
    final liste = (ham as List)
        .map((e) => IndirilenDosya.fromJson(e as Map<String, dynamic>))
        .toList();
    liste.sort((a, b) => b.olusturmaZamani.compareTo(a.olusturmaZamani));
    return liste;
  }

  Future<void> ekle(IndirilenDosya dosya) async {
    final liste = await tumunuGetir();
    liste.add(dosya);
    await YerelDepo.yaz(_kayitAnahtari, liste.map((d) => d.toJson()).toList());
  }

  Future<void> sil(String id) async {
    final liste = await tumunuGetir();
    final eslesenler = liste.where((d) => d.id == id);
    final dosya = eslesenler.isEmpty ? null : eslesenler.first;
    liste.removeWhere((d) => d.id == id);
    await YerelDepo.yaz(_kayitAnahtari, liste.map((d) => d.toJson()).toList());
    if (dosya?.dosyaYolu != null) {
      await YerelDepo.dosyaSil(dosya!.dosyaYolu!);
    }
  }
}
