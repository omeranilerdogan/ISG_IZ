-- İSG Uygunsuzluk Tespit Tutanağı — Yetki/OSGB Kapsam Güncellemesi (RLS/RPC)
-- 20260824000001'de eklenen enum değerleri/tablolar üzerine kurulur.
-- Değişen yetki matrisi:
--   - İSG Uzmanı artık yalnızca UTTS oluşturur; onay/red/revizyon-isteme yetkisi kalkar.
--   - Firma Yetkilisi/Firma Sorumlusu: kendi firmalarının tutanaklarını görüntüler.
--   - Firma Sorumlusu: tutanak içeriğini/durumunu değiştirmeyen not+fotoğraf yorumu ekleyebilir.
--   - Saha Personeli: yalnızca kendi firma+projesi eşleşen tutanak oluşturabilir.

-- =========================================================
-- osgblar — referans veri (register ekranı vb. için anon dahil okunabilir)
-- =========================================================
alter table public.osgblar enable row level security;

create policy osgblar_select_public on public.osgblar
  for select to anon, authenticated
  using (true);

create policy osgblar_admin_write on public.osgblar
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =========================================================
-- Yardımcı fonksiyonlar
-- =========================================================
create or replace function public.is_firma_uyesi(p_firma_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and firma_id = p_firma_id
      and rol in ('firma_yetkilisi', 'firma_sorumlusu')
  );
$$;

create or replace function public.is_personel_kapsam_uygun(p_firma_id uuid, p_proje_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and firma_id = p_firma_id
      and varsayilan_proje_id = p_proje_id
  );
$$;

-- =========================================================
-- guard_tutanaklar_update — İSG Uzmanı'nın inceleme/onay dalı kaldırıldı;
-- artık raporlayan_id=auth.uid() ise (Personel/İSG Uzmanı fark etmeksizin)
-- yalnızca kendi taslak/revizyon_istendi kaydını düzenleyebilir.
-- =========================================================
create or replace function public.guard_tutanaklar_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_admin boolean := public.is_admin();
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

  if v_is_owner then
    -- Personel/İSG Uzmanı yalnızca taslak/revizyon_istendi durumundayken düzenleyip
    -- tekrar "gonderildi" durumuna geçirebilir.
    if old.durum not in ('taslak', 'revizyon_istendi') then
      raise exception 'Bu tutanak artık düzenlenemez (durum: %).', old.durum;
    end if;
    if new.durum not in ('taslak', 'gonderildi') then
      raise exception 'Bu tutanağı yalnızca taslak/gönderildi durumuna alabilirsiniz.';
    end if;
    return new;
  end if;

  raise exception 'Bu tutanağı güncelleme yetkiniz yok.';
end;
$$;

-- =========================================================
-- tutanaklar_select / tutanaklar_insert — Firma Yetkilisi/Sorumlusu görünürlüğü
-- ve Saha Personeli firma+proje kapsaması eklenir.
-- =========================================================
drop policy if exists tutanaklar_select on public.tutanaklar;
create policy tutanaklar_select on public.tutanaklar
  for select to authenticated
  using (
    public.is_admin()
    or public.is_assigned_to_proje(proje_id)
    or raporlayan_id = auth.uid()
    or (public.current_rol() in ('firma_yetkilisi', 'firma_sorumlusu') and public.is_firma_uyesi(firma_id))
  );

drop policy if exists tutanaklar_insert on public.tutanaklar;
create policy tutanaklar_insert on public.tutanaklar
  for insert to authenticated
  with check (
    raporlayan_id = auth.uid()
    and (ceza_tutari is null or public.is_admin())
    and (public.current_rol() <> 'personel' or public.is_personel_kapsam_uygun(firma_id, proje_id))
  );

-- =========================================================
-- get_tutanaklar — Firma Yetkilisi/Sorumlusu görünürlüğü eklenir.
-- (security definer olduğundan görünürlük burada, RLS'de değil.)
-- =========================================================
create or replace function public.get_tutanaklar(
  p_proje_id uuid default null,
  p_durum public.tutanak_durumu default null,
  p_id uuid default null
)
returns table (
  id uuid,
  utt_no text,
  proje_id uuid,
  proje_adi text,
  firma_id uuid,
  firma_adi text,
  raporlayan_id uuid,
  raporlayan_adi text,
  tespit_tarihi date,
  tehlike_sinifi public.tehlike_sinifi,
  aciklama text,
  tavsiye_oneri text,
  termin_tarihi text,
  ceza_tutari numeric,
  durum public.tutanak_durumu,
  onaylayan_id uuid,
  red_revizyon_notu text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
stable
set search_path = public
as $$
  select
    t.id, t.utt_no, t.proje_id, pr.ad, t.firma_id, f.ad,
    t.raporlayan_id, prof.ad_soyad, t.tespit_tarihi, t.tehlike_sinifi,
    t.aciklama, t.tavsiye_oneri, t.termin_tarihi,
    case when public.can_see_ceza_tutari(t.proje_id) then t.ceza_tutari else null end as ceza_tutari,
    t.durum, t.onaylayan_id, t.red_revizyon_notu, t.created_at, t.updated_at
  from public.tutanaklar t
  join public.projeler pr on pr.id = t.proje_id
  join public.firmalar f on f.id = t.firma_id
  join public.profiles prof on prof.id = t.raporlayan_id
  where (
      public.is_admin()
      or public.is_assigned_to_proje(t.proje_id)
      or t.raporlayan_id = auth.uid()
      or (public.current_rol() in ('firma_yetkilisi', 'firma_sorumlusu') and public.is_firma_uyesi(t.firma_id))
    )
    and (p_proje_id is null or t.proje_id = p_proje_id)
    and (p_durum is null or t.durum = p_durum)
    and (p_id is null or t.id = p_id)
  order by t.created_at desc;
$$;

revoke all on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) from public;
grant execute on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) to authenticated;

-- =========================================================
-- tutanak_durum_degistir — yetki artık yalnızca Admin'de; opsiyonel fotoğraf
-- yolları verilirse en son oluşan tutanak_gecmisi satırına eklenir.
-- =========================================================
drop function if exists public.tutanak_durum_degistir(uuid, public.tutanak_durumu, text);

create or replace function public.tutanak_durum_degistir(
  p_tutanak_id uuid,
  p_yeni_durum public.tutanak_durumu,
  p_not text default null,
  p_foto_yollari text[] default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proje_id uuid;
  v_gecmisi_id uuid;
  v_yol text;
  v_sira int := 0;
begin
  select proje_id into v_proje_id from public.tutanaklar where id = p_tutanak_id;

  if v_proje_id is null then
    raise exception 'Tutanak bulunamadı: %', p_tutanak_id;
  end if;

  if not public.is_admin() then
    raise exception 'Bu tutanağı onaylama/reddetme/revizyon isteme yetkiniz yok.';
  end if;

  if p_yeni_durum not in ('incelemede', 'revizyon_istendi', 'onaylandi', 'reddedildi', 'kapatildi') then
    raise exception 'Geçersiz durum: %', p_yeni_durum;
  end if;

  update public.tutanaklar
  set durum = p_yeni_durum,
      red_revizyon_notu = coalesce(p_not, red_revizyon_notu),
      onaylayan_id = case when p_yeni_durum = 'onaylandi' then auth.uid() else onaylayan_id end
  where id = p_tutanak_id;

  if p_foto_yollari is not null and array_length(p_foto_yollari, 1) > 0 then
    select id into v_gecmisi_id
    from public.tutanak_gecmisi
    where tutanak_id = p_tutanak_id
    order by created_at desc
    limit 1;

    foreach v_yol in array p_foto_yollari loop
      insert into public.tutanak_gecmisi_fotograflari (gecmisi_id, storage_path, sira_no)
      values (v_gecmisi_id, v_yol, v_sira);
      v_sira := v_sira + 1;
    end loop;
  end if;
end;
$$;

revoke all on function public.tutanak_durum_degistir(uuid, public.tutanak_durumu, text, text[]) from public;
grant execute on function public.tutanak_durum_degistir(uuid, public.tutanak_durumu, text, text[]) to authenticated;

-- =========================================================
-- tutanak_yorum_ekle — Firma Sorumlusu (ve Admin) için içerik/durum
-- değiştirmeyen not+fotoğraf yorumu.
-- =========================================================
create or replace function public.tutanak_yorum_ekle(
  p_tutanak_id uuid,
  p_not text,
  p_foto_yollari text[] default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_firma_id uuid;
  v_yorum_id uuid;
  v_yol text;
  v_sira int := 0;
begin
  select firma_id into v_firma_id from public.tutanaklar where id = p_tutanak_id;

  if v_firma_id is null then
    raise exception 'Tutanak bulunamadı: %', p_tutanak_id;
  end if;

  if not (public.is_admin() or (public.current_rol() = 'firma_sorumlusu' and public.is_firma_uyesi(v_firma_id))) then
    raise exception 'Bu tutanağa yorum ekleme yetkiniz yok.';
  end if;

  insert into public.tutanak_yorumlari (tutanak_id, yazan_id, not_metni)
  values (p_tutanak_id, auth.uid(), p_not)
  returning id into v_yorum_id;

  if p_foto_yollari is not null and array_length(p_foto_yollari, 1) > 0 then
    foreach v_yol in array p_foto_yollari loop
      insert into public.tutanak_yorum_fotograflari (yorum_id, storage_path, sira_no)
      values (v_yorum_id, v_yol, v_sira);
      v_sira := v_sira + 1;
    end loop;
  end if;

  return v_yorum_id;
end;
$$;

revoke all on function public.tutanak_yorum_ekle(uuid, text, text[]) from public;
grant execute on function public.tutanak_yorum_ekle(uuid, text, text[]) to authenticated;

-- =========================================================
-- Yeni tabloların RLS'i — yalnızca yukarıdaki RPC'ler (security definer) yazar,
-- kullanıcılar sadece kendi görebildikleri tutanaklara ait satırları okur.
-- =========================================================
alter table public.tutanak_gecmisi_fotograflari enable row level security;

create policy tutanak_gecmisi_fotograflari_select on public.tutanak_gecmisi_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanak_gecmisi g
      join public.tutanaklar t on t.id = g.tutanak_id
      where g.id = gecmisi_id
        and (
          public.is_admin()
          or public.is_assigned_to_proje(t.proje_id)
          or t.raporlayan_id = auth.uid()
          or public.is_firma_uyesi(t.firma_id)
        )
    )
  );

alter table public.tutanak_yorumlari enable row level security;

create policy tutanak_yorumlari_select on public.tutanak_yorumlari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and (
          public.is_admin()
          or public.is_assigned_to_proje(t.proje_id)
          or t.raporlayan_id = auth.uid()
          or public.is_firma_uyesi(t.firma_id)
        )
    )
  );

alter table public.tutanak_yorum_fotograflari enable row level security;

create policy tutanak_yorum_fotograflari_select on public.tutanak_yorum_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanak_yorumlari y
      join public.tutanaklar t on t.id = y.tutanak_id
      where y.id = yorum_id
        and (
          public.is_admin()
          or public.is_assigned_to_proje(t.proje_id)
          or t.raporlayan_id = auth.uid()
          or public.is_firma_uyesi(t.firma_id)
        )
    )
  );

-- =========================================================
-- Mevcut tutanak_fotograflari / tutanak_gecmisi görünürlüğüne Firma
-- Yetkilisi/Sorumlusu eklenir.
-- =========================================================
drop policy if exists tutanak_fotograflari_select on public.tutanak_fotograflari;
create policy tutanak_fotograflari_select on public.tutanak_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid() or public.is_firma_uyesi(t.firma_id))
    )
  );

drop policy if exists tutanak_gecmisi_select on public.tutanak_gecmisi;
create policy tutanak_gecmisi_select on public.tutanak_gecmisi
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid() or public.is_firma_uyesi(t.firma_id))
    )
  );

-- =========================================================
-- Storage — tutanak-fotograflari select'e Firma Yetkilisi/Sorumlusu eklenir;
-- yeni tutanak-ek-fotograflari bucket'ı (revizyon notu + yorum fotoğrafları).
-- =========================================================
drop policy if exists tutanak_fotograflari_storage_select on storage.objects;
create policy tutanak_fotograflari_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'tutanak-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[2]
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid() or public.is_firma_uyesi(t.firma_id))
    )
  );

insert into storage.buckets (id, name, public)
values ('tutanak-ek-fotograflari', 'tutanak-ek-fotograflari', false)
on conflict (id) do nothing;

-- Yol şeması: {tutanak_id}/{dosya_adi}
create policy tutanak_ek_fotograflari_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'tutanak-ek-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[1]
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid() or public.is_firma_uyesi(t.firma_id))
    )
  );

create policy tutanak_ek_fotograflari_storage_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'tutanak-ek-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[1]
        and (public.is_admin() or (public.current_rol() = 'firma_sorumlusu' and public.is_firma_uyesi(t.firma_id)))
    )
  );
