import '../../core/constants/app_enums.dart';

/// Bağlantı yokken oluşturulup cihazda bekletilen, bağlantı gelince
/// otomatik gönderilecek bir tutanak taslağı (Faz 5 — offline kuyruk).
class TaslakKuyrukOgesi {
  final String id;
  final String projeId;
  final String projeAdi;
  final String firmaId;
  final String firmaAdi;
  final DateTime tespitTarihi;
  final TehlikeSinifi tehlikeSinifi;
  final String aciklama;
  final String? tavsiyeOneri;
  final String? terminTarihi;
  final TutanakDurumu durum;
  final List<String> fotografYollari;
  final DateTime olusturmaZamani;
  final String? sonHata;

  const TaslakKuyrukOgesi({
    required this.id,
    required this.projeId,
    required this.projeAdi,
    required this.firmaId,
    required this.firmaAdi,
    required this.tespitTarihi,
    required this.tehlikeSinifi,
    required this.aciklama,
    this.tavsiyeOneri,
    this.terminTarihi,
    required this.durum,
    required this.fotografYollari,
    required this.olusturmaZamani,
    this.sonHata,
  });

  TaslakKuyrukOgesi hataIle(String? hata) => TaslakKuyrukOgesi(
        id: id,
        projeId: projeId,
        projeAdi: projeAdi,
        firmaId: firmaId,
        firmaAdi: firmaAdi,
        tespitTarihi: tespitTarihi,
        tehlikeSinifi: tehlikeSinifi,
        aciklama: aciklama,
        tavsiyeOneri: tavsiyeOneri,
        terminTarihi: terminTarihi,
        durum: durum,
        fotografYollari: fotografYollari,
        olusturmaZamani: olusturmaZamani,
        sonHata: hata,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'proje_id': projeId,
        'proje_adi': projeAdi,
        'firma_id': firmaId,
        'firma_adi': firmaAdi,
        'tespit_tarihi': tespitTarihi.toIso8601String(),
        'tehlike_sinifi': tehlikeSinifi.name,
        'aciklama': aciklama,
        'tavsiye_oneri': tavsiyeOneri,
        'termin_tarihi': terminTarihi,
        'durum': durum.dbValue,
        'fotograf_yollari': fotografYollari,
        'olusturma_zamani': olusturmaZamani.toIso8601String(),
        'son_hata': sonHata,
      };

  factory TaslakKuyrukOgesi.fromJson(Map<String, dynamic> json) {
    return TaslakKuyrukOgesi(
      id: json['id'] as String,
      projeId: json['proje_id'] as String,
      projeAdi: json['proje_adi'] as String,
      firmaId: json['firma_id'] as String,
      firmaAdi: json['firma_adi'] as String,
      tespitTarihi: DateTime.parse(json['tespit_tarihi'] as String),
      tehlikeSinifi: TehlikeSinifi.fromDb(json['tehlike_sinifi'] as String),
      aciklama: json['aciklama'] as String,
      tavsiyeOneri: json['tavsiye_oneri'] as String?,
      terminTarihi: json['termin_tarihi'] as String?,
      durum: TutanakDurumu.fromDb(json['durum'] as String),
      fotografYollari: (json['fotograf_yollari'] as List).cast<String>(),
      olusturmaZamani: DateTime.parse(json['olusturma_zamani'] as String),
      sonHata: json['son_hata'] as String?,
    );
  }
}
