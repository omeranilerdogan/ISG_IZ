-- İSG Uygunsuzluk Tespit Tutanağı — Yetki/OSGB Kapsam Güncellemesi (Şema)
-- Yeni roller (firma_yetkilisi, firma_sorumlusu), OSGB kavramı, firma<->proje bağı,
-- ve revizyon notu / yorum fotoğrafları için tablo değişiklikleri.
-- Not: enum'a eklenen yeni değerler bu migration'ın transaction'ı commit olmadan
-- kullanılamaz — bu yüzden RLS/RPC güncellemeleri ayrı bir sonraki migration'da yapılır.

alter type public.kullanici_rolu add value if not exists 'firma_yetkilisi';
alter type public.kullanici_rolu add value if not exists 'firma_sorumlusu';

-- =========================================================
-- osgblar (İş Sağlığı ve Güvenliği Birimi / danışmanlık firmaları)
-- =========================================================
create table public.osgblar (
  id uuid primary key default gen_random_uuid(),
  ad text not null,
  created_at timestamptz not null default now()
);

comment on table public.osgblar is 'OSGB (iş sağlığı-güvenliği danışmanlık) firma tanımları; projelere atanır.';

-- =========================================================
-- projeler — OSGB ataması
-- =========================================================
alter table public.projeler
  add column osgb_id uuid references public.osgblar (id) on delete set null;

-- =========================================================
-- firmalar — artık türü değil, bağlı olduğu inşaatı (proje) taşır;
-- OSGB proje üzerinden devralınır.
-- =========================================================
alter table public.firmalar
  add column proje_id uuid references public.projeler (id) on delete set null;

alter table public.firmalar drop column tur;
drop type public.firma_turu;

-- =========================================================
-- profiles — OSGB ataması (Firma ataması zaten mevcut)
-- =========================================================
alter table public.profiles
  add column osgb_id uuid references public.osgblar (id) on delete set null;

-- =========================================================
-- tutanak_gecmisi_fotograflari — Admin'in onay/red/revizyon notuna
-- ekleyebileceği fotoğraflar.
-- =========================================================
create table public.tutanak_gecmisi_fotograflari (
  id uuid primary key default gen_random_uuid(),
  gecmisi_id uuid not null references public.tutanak_gecmisi (id) on delete cascade,
  storage_path text not null,
  sira_no int not null default 0,
  created_at timestamptz not null default now()
);

create index tutanak_gecmisi_fotograflari_gecmisi_id_idx
  on public.tutanak_gecmisi_fotograflari (gecmisi_id);

-- =========================================================
-- tutanak_yorumlari — Firma Sorumlusu'nun tutanak içeriğini/durumunu
-- değiştirmeden bırakabildiği not+fotoğraf yorumları.
-- =========================================================
create table public.tutanak_yorumlari (
  id uuid primary key default gen_random_uuid(),
  tutanak_id uuid not null references public.tutanaklar (id) on delete cascade,
  yazan_id uuid references public.profiles (id),
  not_metni text not null,
  created_at timestamptz not null default now()
);

create index tutanak_yorumlari_tutanak_id_idx on public.tutanak_yorumlari (tutanak_id);

create table public.tutanak_yorum_fotograflari (
  id uuid primary key default gen_random_uuid(),
  yorum_id uuid not null references public.tutanak_yorumlari (id) on delete cascade,
  storage_path text not null,
  sira_no int not null default 0,
  created_at timestamptz not null default now()
);

create index tutanak_yorum_fotograflari_yorum_id_idx
  on public.tutanak_yorum_fotograflari (yorum_id);
