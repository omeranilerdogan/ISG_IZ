/// Uygulama genelinde kullanılan sabitler: tablo adları, storage bucket'ları vb.
library;

class DbTables {
  DbTables._();

  static const profiles = 'profiles';
  static const firmalar = 'firmalar';
  static const projeler = 'projeler';
  static const osgblar = 'osgblar';
  static const kullaniciProjeAtamalari = 'kullanici_proje_atamalari';
  static const tutanaklar = 'tutanaklar';
  static const tutanakFotograflari = 'tutanak_fotograflari';
  static const tutanakGecmisi = 'tutanak_gecmisi';
  static const tutanakYorumlari = 'tutanak_yorumlari';
  static const tutanakYorumFotograflari = 'tutanak_yorum_fotograflari';
  static const tutanakGecmisiFotograflari = 'tutanak_gecmisi_fotograflari';
  static const bildirimler = 'bildirimler';
  static const pushTokens = 'push_tokens';
}

class DbFunctions {
  DbFunctions._();

  static const getTutanaklar = 'get_tutanaklar';
  static const setCezaTutari = 'set_ceza_tutari';
  static const tutanakDurumDegistir = 'tutanak_durum_degistir';
  static const tutanakYorumEkle = 'tutanak_yorum_ekle';
  static const claimPushToken = 'claim_push_token';
}

class AppUrls {
  AppUrls._();

  /// Firebase Hosting'de yayınlanan web uygulamasının adresi. Mobilden istenen
  /// şifre sıfırlama bağlantıları da bu adrese yönlenir.
  static const web = 'https://isg-uygunsuzluk-tespit.web.app';

  /// Şifre sıfırlama e-postasındaki bağlantıya eklenen işaret parametresi;
  /// uygulama açılışta bunu görünce yeni şifre ekranına yönlendirir.
  static const sifreYenilemeParametresi = 'sifre_yenile';

  /// Supabase "Reset Password" e-posta şablonunun bağlantıya eklediği
  /// doğrulama değeri: `{{ .SiteURL }}/?sifre_yenile=1&token_hash={{ .TokenHash }}&type=recovery`
  static const tokenHashParametresi = 'token_hash';
}

class StorageBuckets {
  StorageBuckets._();

  static const tutanakFotograflari = 'tutanak-fotograflari';
  static const tutanakEkFotograflari = 'tutanak-ek-fotograflari';
  static const profilResimleri = 'profil-resimleri';
}
