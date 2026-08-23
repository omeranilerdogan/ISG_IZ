# İSG Uygunsuzluk Tespit Tutanağı

Flutter (Android · iOS · Web) + Supabase tabanlı İSG uygunsuzluk tespit tutanağı uygulaması.
"İSG Uygunsuzluk Tespit Tutanağı Uygulaması — Teknik Analiz" dokümanına dayanır.

Bu depo **Faz 1-5**'in tamamını ve **Faz 6**'nın kod gerektiren kısmını kapsar: proje
iskeleti, veritabanı şeması (RLS dahil), kimlik doğrulama, rol bazlı yönlendirme,
Giriş/Kayıt Ol ekranları, Proje/Firma/Personel yönetimi ekranları, çok adımlı tutanak
oluşturma formu (fotoğraf yükleme dahil), tutanak listeleme/filtreleme ve detay ekranı,
onay/red/revizyon akışı, uygulama içi bildirim merkezi + realtime rozet (Faz 3),
raporlama/istatistik ekranı (Faz 4), Firebase push bildirim (Faz 5 — bkz. Bölüm 7),
offline taslak/senkronizasyon kuyruğu (Faz 5 — bkz. Bölüm 8) ve PDF/Excel dışa aktarma
(Faz 6 — bkz. Bölüm 9). Kalan tek iş: mağaza yayını (Faz 6'nın geliştirme dışı kısmı).

## 1. Gereksinimler

- Flutter 3.x / Dart 3.x (bu depo Flutter 3.44 ile geliştirildi)
- Bir [Supabase](https://supabase.com) projesi (ücretsiz plan yeterlidir)
- (Opsiyonel) [Supabase CLI](https://supabase.com/docs/guides/cli) — migration'ları
  tek komutla uygulamak için

## 2. Supabase Kurulumu

### 2.1 Migration'ları uygulama

`supabase/migrations/` klasöründeki SQL dosyaları sırayla (dosya adındaki zaman damgasına
göre) veritabanı şemasını, RLS politikalarını, trigger'ları ve storage bucket'larını
oluşturur.

**Seçenek A — Supabase CLI ile:**

```bash
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push
```

**Seçenek B — Supabase Dashboard SQL Editor ile:**

`supabase/migrations/` altındaki dosyaları numara sırasına göre tek tek kopyalayıp
SQL Editor'de çalıştırın (0001 → 0006).

Yerel geliştirme için örnek firma/proje verisi eklemek isterseniz `supabase/seed.sql`
dosyasını da çalıştırabilirsiniz (`supabase db reset` yerel Docker kurulumunda otomatik
yükler).

### 2.2 İlk yönetici (Admin) hesabını oluşturma

Uygulama içindeki Kayıt Ol ekranı her zaman **"Saha Personeli"** rolüyle ve **onay bekliyor**
(`aktif = false`) durumunda hesap açar (bkz. Bölüm 5.2). Yani ilk Admin hesabı uygulama
üzerinden oluşturulamaz — bootstrap adımı gereklidir:

1. Uygulamadan (veya Supabase Dashboard > Authentication > Users > "Add user" ile)
   normal şekilde bir kullanıcı oluşturun.
2. Supabase Dashboard > Table Editor > `profiles` tablosunda ilgili satırı bulun ve
   SQL Editor'den şu sorguyu çalıştırın:

   ```sql
   update public.profiles
   set rol = 'admin', aktif = true
   where id = '<AUTH_USER_UUID>';
   ```

Bundan sonra bu hesapla giriş yapıp diğer kullanıcıları Personel Yönetimi ekranından
onaylayabilir ve rol atayabilirsiniz.

## 3. Flutter Uygulaması Kurulumu

```bash
cp .env.example .env
# .env dosyasını kendi Supabase URL / anon (publishable) key değerlerinizle doldurun
flutter pub get
flutter run
```

`.env` dosyası `.gitignore` içinde olduğundan repoya eklenmez.

## 4. Klasör Yapısı (özet)

```
lib/
  core/           # config (.env/Supabase), tema, router, sabitler, yardımcılar
  data/
    models/       # Profile, Proje, Firma vb. veri modelleri
    repositories/ # Supabase erişim katmanı
  features/
    auth/         # Giriş, Kayıt Ol, onay bekliyor ekranı
    home/         # Rol bazlı dashboard (Admin / İSG Uzmanı-Şantiye Şefi / Personel)
    admin/        # Personel Yönetimi, Proje/Firma Tanımları
    tutanak/      # Tutanak oluşturma formu, liste, detay
    profile/      # Profil / Ayarlar
  providers/      # Riverpod provider'ları (auth, profil, rol, tutanak)
  shared/widgets/ # Ortak bileşenler
supabase/
  migrations/     # SQL şema, RLS, trigger, storage politikaları
  seed.sql        # Yerel geliştirme için örnek veri
```

## 5. Rol Bazlı Yetkilendirme Notu

Ceza tutarı (`ceza_tutari`) gibi hassas alanlar hem istemci tarafında (widget ağacına hiç
eklenmeden) hem de veritabanı tarafında (RLS + guard trigger + `get_tutanaklar()` /
`set_ceza_tutari()` RPC'leri) çift katmanlı korunur — bkz. Teknik Analiz Bölüm 10.

## 7. Firebase Push Bildirim Kurulumu (Faz 5)

Push bildirimleri, `bildirimler` tablosuna satır eklendiğinde (durum trigger'ı zaten
mevcut) bir Postgres trigger'ının `pg_net` ile çağırdığı `send-push` Edge Function
üzerinden FCM'e gönderilmesiyle çalışır. Bu proje için Firebase kurulumu tamamlanmış
durumda (`isg-uygunsuzluk-tespit` projesi):

- `lib/firebase_options.dart` — Android/iOS/Web istemci yapılandırması (repoya işli;
  Firebase apiKey'leri gizli değildir, güvenlik Security Rules/App Check ile sağlanır).
- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — native
  platform config dosyaları (repoya işli).
- `supabase/functions/send-push/` — FCM HTTP v1 API'sine push gönderen Edge Function.
- Supabase secrets (repoya **işlenmemiş**, `supabase secrets list` ile görülebilir):
  `FCM_SERVICE_ACCOUNT_JSON` (Firebase servis hesabı özel anahtarı) ve `WEBHOOK_SECRET`.
- `vault.decrypted_secrets` içinde `push_webhook_secret` — trigger'ın Edge Function'ı
  çağırırken kullandığı ortak sır, DB tarafındaki eşleniği.

Yeni bir ortama (başka bir Firebase/Supabase projesi) taşırken:

1. Firebase Console'da yeni proje + Android (`com.isgtutanak.isg_uygunsuzluk_tespit`) /
   iOS (`com.isgtutanak.isgUygunsuzlukTespit`) / Web uygulaması kaydedin.
2. İndirilen `google-services.json` / `GoogleService-Info.plist` dosyalarını yukarıdaki
   konumlara koyun, web config değerleriyle `lib/firebase_options.dart` ve
   `web/firebase-messaging-sw.js` içindeki sabitleri güncelleyin.
3. Proje Ayarları > Servis Hesapları'ndan yeni bir özel anahtar indirin,
   `supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)"`.
4. Yeni bir `WEBHOOK_SECRET` üretip hem `supabase secrets set WEBHOOK_SECRET=...` hem de
   `select vault.create_secret('<deger>', 'push_webhook_secret', '...')` ile aynı değeri
   iki tarafa da kurun (bkz. `supabase/migrations/20260823000011_push_gonderim_vault.sql`).
5. `supabase functions deploy send-push` ile fonksiyonu yayınlayın.
6. iOS gerçek cihaz push'u için ayrıca Apple Developer hesabınızdan bir APNs Kimlik
   Doğrulama Anahtarı (.p8) alıp Firebase > Proje Ayarları > Cloud Messaging'e yükleyin
   ve Xcode'da Runner hedefine "Push Notifications" + "Background Modes > Remote
   notifications" capability'lerini ekleyin (bu adım macOS/Xcode gerektirir, bu depoda
   yapılmamıştır).

## 8. Offline Taslak/Senkronizasyon Kuyruğu (Faz 5)

Yeni tutanak oluştururken (`/tutanak/yeni`, düzenleme modu hariç) bağlantı yoksa
(`connectivity_plus` ile tespit edilir), form sunucuya hiç istek atmadan tüm alanları ve
sıkıştırılmış fotoğrafları cihazda kalıcı olarak saklar:

- `lib/core/offline/yerel_depo.dart` — uygulama belgeleri dizininde JSON tabanlı
  anahtar-değer + ikili dosya deposu.
- `lib/data/repositories/taslak_kuyruk_deposu.dart` — bekleyen taslakların CRUD'u.
- `lib/core/offline/taslak_senkronizasyon_servisi.dart` — bağlantı geri geldiğinde
  (`Connectivity().onConnectivityChanged`) veya girişte kuyruğu sırayla sunucuya
  gönderir; bir öge başarısız olursa hata mesajıyla kuyrukta kalır, diğerlerini
  engellemez.
- `/tutanak/kuyruk` ekranı — bekleyen taslakları listeler, manuel "şimdi gönder" ve
  silme imkânı sunar; tutanak listesinde bekleyen varsa turuncu bir banner gösterilir.
- Proje/Firma dropdown listeleri de son başarılı çekimden önbelleğe alınır (aynı
  `YerelDepo`), böylece form bağlantısız açıldığında da doldurulabilir.

Kapsam dışı bırakılan: mevcut (uzak) bir tutanağı **düzenleme** modu bağlantısızken
çalışmaz (zaten kayıt önce uzaktan çekilmek zorunda) — yalnızca **yeni** tutanak
oluşturma offline kuyruğa alınır.

## 9. PDF/Excel Dışa Aktarma (Faz 6)

- **Tek tutanak → PDF**: Tutanak Detayı ekranının sağ üstündeki PDF ikonu
  (`lib/core/export/tutanak_pdf_olusturucu.dart`), tüm alanları ve fotoğrafları resmi bir
  rapor formatında PDF'e döker; `printing` paketiyle paylaşım/yazdırma sayfası açılır.
  Türkçe karakterler (ğ, ş, ı, ö, ü, ç) standart PDF fontlarında eksik olduğundan Google
  Fonts'tan Noto Sans çalışma anında indirilip gömülür (bu adım internet gerektirir).
- **Tutanak listesi → Excel**: Tutanaklar ekranının sağ üstündeki tablo ikonu
  (`lib/core/export/tutanak_excel_olusturucu.dart`), o an filtrelenmiş listeyi bir
  `.xlsx` dosyasına döker ve `share_plus` ile paylaşım sayfası açar.

## 10. Yol Haritası

Kalan iş (Teknik Analiz Bölüm 16): mağaza yayını (Play Store/App Store hesabı, imzalama
sertifikaları, mağaza listeleme metinleri/görselleri — bu adımlar geliştirme ortamı
dışında, sizin tarafınızda tamamlanmalıdır).
