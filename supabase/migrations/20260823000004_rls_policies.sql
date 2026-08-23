-- İSG Uygunsuzluk Tespit Tutanağı — Row Level Security Politikaları
-- Teknik Analiz Bölüm 4, 10, 14
-- Not: Kolon seviyesinde kısıtlama (özellikle ceza_tutari) RLS ile değil,
-- aşağıdaki guard trigger'lar ve Bölüm 10.2'deki get_tutanaklar()/RPC katmanıyla sağlanır.

alter table public.profiles enable row level security;
alter table public.firmalar enable row level security;
alter table public.projeler enable row level security;
alter table public.kullanici_proje_atamalari enable row level security;
alter table public.tutanaklar enable row level security;
alter table public.tutanak_fotograflari enable row level security;
alter table public.tutanak_gecmisi enable row level security;
alter table public.bildirimler enable row level security;
alter table public.push_tokens enable row level security;
alter table public.proje_utt_sayaclari enable row level security;

-- =========================================================
-- profiles
-- =========================================================
-- Aktif kullanıcılar birbirinin temel profil bilgisini görebilir
-- (raporlayan/onaylayan adı, admin personel listesi vb. için gereklidir).
create policy profiles_select on public.profiles
  for select to authenticated
  using (auth.uid() = id or public.is_admin() or public.is_aktif_kullanici());

create policy profiles_update on public.profiles
  for update to authenticated
  using (auth.uid() = id or public.is_admin())
  with check (auth.uid() = id or public.is_admin());

-- profiles insert: yalnızca handle_new_user() trigger'ı (security definer) yazar.
-- Doğrudan client insert politikası tanımlanmaz (varsayılan: reddedilir).

-- Kullanıcının kendi rol/aktif/firma alanlarını yükselterek kendine yetki
-- vermesini engelleyen koruma trigger'ı (RLS satır bazlı olduğundan yetmez).
create or replace function public.guard_profiles_self_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    if new.rol is distinct from old.rol
       or new.aktif is distinct from old.aktif
       or new.firma_id is distinct from old.firma_id then
      raise exception 'Bu alanları yalnızca yönetici değiştirebilir (rol, aktif, firma_id).';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_self_update on public.profiles;
create trigger profiles_guard_self_update
  before update on public.profiles
  for each row execute function public.guard_profiles_self_update();

-- =========================================================
-- firmalar / projeler — referans veriler
-- Kayıt (register) ekranı oturum açmadan bu listeleri okuyabilmeli (Bölüm 5.2).
-- =========================================================
create policy firmalar_select_public on public.firmalar
  for select to anon, authenticated
  using (true);

create policy firmalar_admin_write on public.firmalar
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy projeler_select_public on public.projeler
  for select to anon, authenticated
  using (true);

create policy projeler_admin_write on public.projeler
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =========================================================
-- kullanici_proje_atamalari
-- =========================================================
create policy kpa_select on public.kullanici_proje_atamalari
  for select to authenticated
  using (public.is_admin() or kullanici_id = auth.uid());

create policy kpa_admin_write on public.kullanici_proje_atamalari
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =========================================================
-- tutanaklar
-- Görünürlük: Admin tümü, İSG Uzmanı/Şantiye Şefi atanan proje(ler),
-- Personel yalnızca kendi oluşturduğu (Bölüm 4 Yetki Matrisi).
-- =========================================================
create policy tutanaklar_select on public.tutanaklar
  for select to authenticated
  using (
    public.is_admin()
    or public.is_assigned_to_proje(proje_id)
    or raporlayan_id = auth.uid()
  );

create policy tutanaklar_insert on public.tutanaklar
  for insert to authenticated
  with check (
    raporlayan_id = auth.uid()
    and (ceza_tutari is null or public.is_admin())
  );

create policy tutanaklar_update on public.tutanaklar
  for update to authenticated
  using (
    public.is_admin()
    or public.is_assigned_to_proje(proje_id)
    or raporlayan_id = auth.uid()
  )
  with check (
    public.is_admin()
    or public.is_assigned_to_proje(proje_id)
    or raporlayan_id = auth.uid()
  );

-- Alan/durum bazlı ince kontrol: RLS satır bazlı olduğundan yetmiyor (Bölüm 10.2).
create or replace function public.guard_tutanaklar_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean := public.is_admin();
  v_is_reviewer boolean := public.is_assigned_to_proje(new.proje_id)
    and public.current_rol() in ('isg_uzmani', 'santiye_sefi');
  v_is_owner boolean := old.raporlayan_id = auth.uid();
begin
  if v_is_admin then
    return new;
  end if;

  -- Ceza tutarını yalnızca admin girebilir/değiştirebilir.
  if new.ceza_tutari is distinct from old.ceza_tutari then
    raise exception 'Ceza tutarını yalnızca yönetici (Admin) girebilir/düzenleyebilir.';
  end if;

  if public.current_rol() = 'santiye_sefi' then
    raise exception 'Şantiye Şefi rolü tutanak üzerinde onay/düzenleme yapamaz.';
  end if;

  if v_is_reviewer then
    -- İSG Uzmanı yalnızca inceleme/onay/red/revizyon akışını yürütebilir.
    if new.durum not in ('incelemede', 'revizyon_istendi', 'onaylandi', 'reddedildi') then
      raise exception 'İSG Uzmanı bu duruma geçiş yapamaz: %', new.durum;
    end if;
    if new.aciklama is distinct from old.aciklama
       or new.tavsiye_oneri is distinct from old.tavsiye_oneri
       or new.tehlike_sinifi is distinct from old.tehlike_sinifi then
      raise exception 'İSG Uzmanı tutanağın içerik alanlarını değiştiremez.';
    end if;
    return new;
  end if;

  if v_is_owner then
    -- Personel yalnızca taslak/revizyon_istendi durumundayken düzenleyip
    -- tekrar "gonderildi" durumuna geçirebilir.
    if old.durum not in ('taslak', 'revizyon_istendi') then
      raise exception 'Bu tutanak artık düzenlenemez (durum: %).', old.durum;
    end if;
    if new.durum not in ('taslak', 'gonderildi') then
      raise exception 'Personel tutanağı yalnızca taslak/gönderildi durumuna alabilir.';
    end if;
    return new;
  end if;

  raise exception 'Bu tutanağı güncelleme yetkiniz yok.';
end;
$$;

drop trigger if exists tutanaklar_guard_update on public.tutanaklar;
create trigger tutanaklar_guard_update
  before update on public.tutanaklar
  for each row execute function public.guard_tutanaklar_update();

-- =========================================================
-- tutanak_fotograflari
-- =========================================================
create policy tutanak_fotograflari_select on public.tutanak_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid())
    )
  );

create policy tutanak_fotograflari_insert on public.tutanak_fotograflari
  for insert to authenticated
  with check (
    public.is_admin()
    or exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id and t.raporlayan_id = auth.uid()
    )
  );

create policy tutanak_fotograflari_delete on public.tutanak_fotograflari
  for delete to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id and t.raporlayan_id = auth.uid() and t.durum in ('taslak', 'revizyon_istendi')
    )
  );

-- =========================================================
-- tutanak_gecmisi — yalnızca trigger yazar, kullanıcılar okur
-- =========================================================
create policy tutanak_gecmisi_select on public.tutanak_gecmisi
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid())
    )
  );

-- =========================================================
-- bildirimler
-- =========================================================
create policy bildirimler_select on public.bildirimler
  for select to authenticated
  using (alici_id = auth.uid());

create policy bildirimler_update_own on public.bildirimler
  for update to authenticated
  using (alici_id = auth.uid())
  with check (alici_id = auth.uid());

-- insert: yalnızca trigger/servis rolü (Edge Function) yazar.

-- =========================================================
-- push_tokens — kullanıcı yalnızca kendi cihaz token'larını yönetir
-- =========================================================
create policy push_tokens_all_own on public.push_tokens
  for all to authenticated
  using (kullanici_id = auth.uid())
  with check (kullanici_id = auth.uid());

-- proje_utt_sayaclari: hiçbir client politikası yok; yalnızca
-- generate_utt_no() (security definer) tarafından erişilir.
