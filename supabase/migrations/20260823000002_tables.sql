-- İSG Uygunsuzluk Tespit Tutanağı — Tablo Şeması
-- Teknik Analiz Bölüm 9 (Veritabanı Şeması)

-- =========================================================
-- firmalar (Taşeron / ilgili firma tanımları)
-- =========================================================
create table public.firmalar (
  id uuid primary key default gen_random_uuid(),
  ad text not null,
  tur public.firma_turu not null default 'taseron',
  created_at timestamptz not null default now()
);

comment on table public.firmalar is 'Taşeron / ilgili firma tanımları (Bölüm 9)';

-- =========================================================
-- projeler
-- =========================================================
create table public.projeler (
  id uuid primary key default gen_random_uuid(),
  ad text not null,
  yuklenici_adi text,
  adres text,
  aktif boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table public.projeler is 'Şantiye/proje tanımları (Bölüm 9)';

-- =========================================================
-- profiles (auth.users ile bire bir)
-- =========================================================
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  ad_soyad text not null,
  telefon text,
  rol public.kullanici_rolu not null default 'personel',
  firma_id uuid references public.firmalar (id) on delete set null,
  -- Kayıt sırasında seçilen "birincil" proje; tutanak formunu ön doldurmak için kullanılır.
  -- Görüntüleme/onay yetkisi bundan değil, kullanici_proje_atamalari ve rol'den gelir (Bölüm 10).
  varsayilan_proje_id uuid references public.projeler (id) on delete set null,
  aktif boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.profiles is 'Kullanıcı profili; auth.users ile bire bir (Bölüm 9). aktif=false => admin onayı bekliyor (Bölüm 5.2).';

-- =========================================================
-- kullanici_proje_atamalari (çoka çok)
-- =========================================================
create table public.kullanici_proje_atamalari (
  id uuid primary key default gen_random_uuid(),
  kullanici_id uuid not null references public.profiles (id) on delete cascade,
  proje_id uuid not null references public.projeler (id) on delete cascade,
  ceza_tutari_gorebilir boolean not null default false,
  created_at timestamptz not null default now(),
  unique (kullanici_id, proje_id)
);

comment on table public.kullanici_proje_atamalari is 'İSG Uzmanı/Şantiye Şefi - proje ataması; ceza_tutari_gorebilir proje bazlı istisnai yetki (Bölüm 4 dipnot).';

-- =========================================================
-- tutanaklar (ana tablo)
-- =========================================================
create table public.tutanaklar (
  id uuid primary key default gen_random_uuid(),
  utt_no text unique,
  proje_id uuid not null references public.projeler (id),
  firma_id uuid not null references public.firmalar (id),
  raporlayan_id uuid not null references public.profiles (id),
  tespit_tarihi date not null default current_date,
  tehlike_sinifi public.tehlike_sinifi not null,
  aciklama text not null,
  tavsiye_oneri text,
  termin_tarihi text,
  ceza_tutari numeric(12, 2),
  durum public.tutanak_durumu not null default 'taslak',
  onaylayan_id uuid references public.profiles (id),
  red_revizyon_notu text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.tutanaklar is 'Uygunsuzluk Tespit Tutanağı ana kaydı (Bölüm 6, 9).';
comment on column public.tutanaklar.ceza_tutari is 'Yalnızca yetkili rollerce okunur/yazılır; RPC/view üzerinden erişim önerilir (Bölüm 10).';

create index tutanaklar_proje_id_idx on public.tutanaklar (proje_id);
create index tutanaklar_raporlayan_id_idx on public.tutanaklar (raporlayan_id);
create index tutanaklar_durum_idx on public.tutanaklar (durum);

-- =========================================================
-- tutanak_fotograflari
-- =========================================================
create table public.tutanak_fotograflari (
  id uuid primary key default gen_random_uuid(),
  tutanak_id uuid not null references public.tutanaklar (id) on delete cascade,
  storage_path text not null,
  sira_no int not null default 0,
  yuklenen_id uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create index tutanak_fotograflari_tutanak_id_idx on public.tutanak_fotograflari (tutanak_id);

-- =========================================================
-- tutanak_gecmisi (audit log)
-- =========================================================
create table public.tutanak_gecmisi (
  id uuid primary key default gen_random_uuid(),
  tutanak_id uuid not null references public.tutanaklar (id) on delete cascade,
  eski_durum public.tutanak_durumu,
  yeni_durum public.tutanak_durumu not null,
  islemi_yapan_id uuid references public.profiles (id),
  not_metni text,
  created_at timestamptz not null default now()
);

create index tutanak_gecmisi_tutanak_id_idx on public.tutanak_gecmisi (tutanak_id);

-- =========================================================
-- bildirimler
-- =========================================================
create table public.bildirimler (
  id uuid primary key default gen_random_uuid(),
  alici_id uuid not null references public.profiles (id) on delete cascade,
  tutanak_id uuid references public.tutanaklar (id) on delete cascade,
  baslik text not null,
  icerik text,
  okundu boolean not null default false,
  created_at timestamptz not null default now()
);

create index bildirimler_alici_id_idx on public.bildirimler (alici_id, okundu);

-- =========================================================
-- push_tokens
-- =========================================================
create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  kullanici_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform public.cihaz_platformu not null,
  created_at timestamptz not null default now(),
  unique (kullanici_id, token)
);
