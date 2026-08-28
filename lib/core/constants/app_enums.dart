/// Veritabanındaki Postgres enum tipleriyle bire bir eşleşir
/// (bkz. supabase/migrations/20260823000001_extensions_enums.sql).
library;

enum KullaniciRolu {
  admin,
  isgUzmani('isg_uzmani'),
  santiyeSefi('santiye_sefi'),
  personel,
  firmaYetkilisi('firma_yetkilisi'),
  firmaSorumlusu('firma_sorumlusu');

  const KullaniciRolu([String? dbValue]) : _dbValue = dbValue;

  final String? _dbValue;

  String get dbValue => _dbValue ?? name;

  static KullaniciRolu fromDb(String value) {
    return KullaniciRolu.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => KullaniciRolu.personel,
    );
  }

  String get etiket {
    switch (this) {
      case KullaniciRolu.admin:
        return 'İSG Yöneticisi';
      case KullaniciRolu.isgUzmani:
        return 'İSG Uzmanı';
      case KullaniciRolu.santiyeSefi:
        return 'Şantiye Şefi';
      case KullaniciRolu.personel:
        return 'Saha Personeli';
      case KullaniciRolu.firmaYetkilisi:
        return 'Firma Yetkilisi';
      case KullaniciRolu.firmaSorumlusu:
        return 'Firma Sorumlusu';
    }
  }
}

enum TehlikeSinifi {
  A,
  B,
  C;

  static TehlikeSinifi fromDb(String value) =>
      TehlikeSinifi.values.firstWhere((e) => e.name == value);
}

enum TutanakDurumu {
  taslak,
  gonderildi,
  incelemede,
  revizyonIstendi('revizyon_istendi'),
  onaylandi,
  reddedildi,
  kapatildi;

  const TutanakDurumu([String? dbValue]) : _dbValue = dbValue;

  final String? _dbValue;

  String get dbValue => _dbValue ?? name;

  static TutanakDurumu fromDb(String value) {
    return TutanakDurumu.values.firstWhere((e) => e.dbValue == value);
  }

  String get etiket {
    switch (this) {
      case TutanakDurumu.taslak:
        return 'Taslak';
      case TutanakDurumu.gonderildi:
        return 'Gönderildi';
      case TutanakDurumu.incelemede:
        return 'İncelemede';
      case TutanakDurumu.revizyonIstendi:
        return 'Revizyon İstendi';
      case TutanakDurumu.onaylandi:
        return 'Onaylandı';
      case TutanakDurumu.reddedildi:
        return 'Reddedildi';
      case TutanakDurumu.kapatildi:
        return 'Kapatıldı';
    }
  }
}
