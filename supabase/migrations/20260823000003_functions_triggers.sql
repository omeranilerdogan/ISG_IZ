-- İSG Uygunsuzluk Tespit Tutanağı — Yardımcı Fonksiyonlar ve Trigger'lar
-- Teknik Analiz Bölüm 7, 8, 9, 10

-- =========================================================
-- Yardımcı yetki fonksiyonları (RLS politikalarında kullanılır)
-- security definer + sabit search_path: profiles/atama tablolarında
-- RLS'e takılmadan (recursion olmadan) okuma yapabilmek için.
-- =========================================================
create or replace function public.current_rol()
returns public.kullanici_rolu
language sql
security definer
stable
set search_path = public
as $$
  select rol from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and rol = 'admin' and aktif = true
  );
$$;

create or replace function public.is_aktif_kullanici()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and aktif = true);
$$;

create or replace function public.is_assigned_to_proje(p_proje_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.kullanici_proje_atamalari
    where kullanici_id = auth.uid() and proje_id = p_proje_id
  );
$$;

create or replace function public.can_see_ceza_tutari(p_proje_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select public.is_admin() or exists (
    select 1 from public.kullanici_proje_atamalari
    where kullanici_id = auth.uid()
      and proje_id = p_proje_id
      and ceza_tutari_gorebilir = true
  );
$$;

-- =========================================================
-- Yeni auth.users kaydı oluşunca profiles satırı otomatik açılır
-- Varsayılan rol: personel, aktif: false (admin onayı bekler, Bölüm 5.2)
-- =========================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, ad_soyad, telefon, firma_id, varsayilan_proje_id, rol, aktif)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'ad_soyad', ''),
    new.raw_user_meta_data ->> 'telefon',
    nullif(new.raw_user_meta_data ->> 'firma_id', '')::uuid,
    nullif(new.raw_user_meta_data ->> 'proje_id', '')::uuid,
    'personel',
    false
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================
-- updated_at otomatik güncelleme
-- =========================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tutanaklar_set_updated_at on public.tutanaklar;
create trigger tutanaklar_set_updated_at
  before update on public.tutanaklar
  for each row execute function public.set_updated_at();

-- =========================================================
-- UTT No üretimi (proje bazlı sıra, format: YY/sira — Bölüm 6, 15)
-- =========================================================
create table public.proje_utt_sayaclari (
  proje_id uuid not null references public.projeler (id) on delete cascade,
  yil int not null,
  son_sira int not null default 0,
  primary key (proje_id, yil)
);

create or replace function public.generate_utt_no(p_proje_id uuid, p_tarih date)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_yil int := extract(year from p_tarih);
  v_sira int;
begin
  insert into public.proje_utt_sayaclari (proje_id, yil, son_sira)
  values (p_proje_id, v_yil, 1)
  on conflict (proje_id, yil)
  do update set son_sira = public.proje_utt_sayaclari.son_sira + 1
  returning son_sira into v_sira;

  return lpad((v_yil % 100)::text, 2, '0') || '/' || v_sira::text;
end;
$$;

create or replace function public.tutanaklar_assign_utt_no()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.durum = 'gonderildi' and new.utt_no is null then
    new.utt_no := public.generate_utt_no(new.proje_id, new.tespit_tarihi);
  end if;
  return new;
end;
$$;

drop trigger if exists tutanaklar_before_upsert_utt_no on public.tutanaklar;
create trigger tutanaklar_before_upsert_utt_no
  before insert or update on public.tutanaklar
  for each row execute function public.tutanaklar_assign_utt_no();

-- =========================================================
-- Durum değişikliği denetim kaydı (tutanak_gecmisi) — Bölüm 7
-- =========================================================
create or replace function public.tutanaklar_log_durum()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.tutanak_gecmisi (tutanak_id, eski_durum, yeni_durum, islemi_yapan_id, not_metni)
    values (new.id, null, new.durum, coalesce(auth.uid(), new.raporlayan_id), null);
  elsif tg_op = 'UPDATE' and old.durum is distinct from new.durum then
    insert into public.tutanak_gecmisi (tutanak_id, eski_durum, yeni_durum, islemi_yapan_id, not_metni)
    values (new.id, old.durum, new.durum, auth.uid(), new.red_revizyon_notu);
  end if;
  return new;
end;
$$;

drop trigger if exists tutanaklar_after_upsert_log on public.tutanaklar;
create trigger tutanaklar_after_upsert_log
  after insert or update on public.tutanaklar
  for each row execute function public.tutanaklar_log_durum();

-- =========================================================
-- Bildirimler — Bölüm 8
-- Tutanak "gonderildi" olduğunda: projeye atanmış Admin + İSG Uzmanı'na bildirim.
-- Tutanak durumu incelemede/revizyon/onay/red/kapatıldı olduğunda: raporlayan'a bildirim.
-- (Bildirim satırı eklenmesi; FCM push gönderimi Faz 5'te Edge Function ile eklenecektir — Bölüm 8, 16.)
-- =========================================================
create or replace function public.tutanaklar_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proje_adi text;
begin
  if (tg_op = 'INSERT' and new.durum = 'gonderildi')
     or (tg_op = 'UPDATE' and old.durum is distinct from new.durum and new.durum = 'gonderildi') then

    select ad into v_proje_adi from public.projeler where id = new.proje_id;

    insert into public.bildirimler (alici_id, tutanak_id, baslik, icerik)
    select p.id, new.id, 'Yeni Uygunsuzluk Tutanağı',
           coalesce(v_proje_adi, '') || ' — ' || new.tehlike_sinifi::text || ' sınıfı'
    from public.profiles p
    where p.aktif = true
      and (
        p.rol = 'admin'
        or (p.rol = 'isg_uzmani' and public.is_assigned_to_proje_for(p.id, new.proje_id))
      );

  elsif tg_op = 'UPDATE' and old.durum is distinct from new.durum
        and new.durum in ('incelemede', 'revizyon_istendi', 'onaylandi', 'reddedildi', 'kapatildi') then

    insert into public.bildirimler (alici_id, tutanak_id, baslik, icerik)
    values (
      new.raporlayan_id,
      new.id,
      'Tutanak Durumu Güncellendi',
      'UTT No ' || coalesce(new.utt_no, '-') || ' — yeni durum: ' || new.durum::text
    );
  end if;

  return new;
end;
$$;

-- is_assigned_to_proje() auth.uid() bağımlı; trigger içinde başka kullanıcı_id ile
-- kontrol edebilmek için parametreli bir yardımcı gerekir.
create or replace function public.is_assigned_to_proje_for(p_kullanici_id uuid, p_proje_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.kullanici_proje_atamalari
    where kullanici_id = p_kullanici_id and proje_id = p_proje_id
  );
$$;

drop trigger if exists tutanaklar_after_upsert_notify on public.tutanaklar;
create trigger tutanaklar_after_upsert_notify
  after insert or update on public.tutanaklar
  for each row execute function public.tutanaklar_notify();
