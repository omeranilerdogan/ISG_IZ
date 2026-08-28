-- İSG Uygunsuzluk Tespit Tutanağı — Firma Bazlı Görünürlük ve Bildirim Düzeltmesi
--
-- Sorun 1: tutanaklar_notify() yalnızca admin + o projeye atanmış İSG Uzmanı'na
-- bildirim ekliyordu; tutanağın firma_id'sine sahip profillere (örn. Aksoy'a UTT
-- girildiğinde Aksoy'un kendi personeli/yetkilileri) hiç bildirim gitmiyordu.
--
-- Sorun 2: Admin dışındaki tüm roller (İSG Uzmanı, Şantiye Şefi, Personel,
-- Firma Yetkilisi, Firma Sorumlusu) artık, profillerinde bir firma_id
-- atanmışsa YALNIZCA o firmanın tutanaklarını görebilir. firma_id atanmamış
-- (proje geneli görevli) İSG Uzmanı/Şantiye Şefi için eski proje-bazlı geniş
-- görünürlük korunur.

-- =========================================================
-- Yardımcı fonksiyonlar
-- =========================================================
create or replace function public.current_firma_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select firma_id from public.profiles where id = auth.uid();
$$;

-- Admin dışında bir kullanıcının bir tutanağı görüp göremeyeceğinin tek yeri:
-- kendi raporladığı, kendi firmasına ait (firma_id atanmışsa) ya da (firma_id
-- atanmamışsa) atandığı projeye ait tutanaklar.
create or replace function public.can_see_tutanak(
  p_proje_id uuid,
  p_firma_id uuid,
  p_raporlayan_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select
    public.is_admin()
    or p_raporlayan_id = auth.uid()
    or (public.current_firma_id() is not null and public.current_firma_id() = p_firma_id)
    or (public.current_firma_id() is null and public.is_assigned_to_proje(p_proje_id));
$$;

-- =========================================================
-- tutanaklar_select — firma bazlı kısıtlama
-- =========================================================
drop policy if exists tutanaklar_select on public.tutanaklar;
create policy tutanaklar_select on public.tutanaklar
  for select to authenticated
  using (public.can_see_tutanak(proje_id, firma_id, raporlayan_id));

-- =========================================================
-- get_tutanaklar — aynı kural (security definer RPC)
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
  where public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    and (p_proje_id is null or t.proje_id = p_proje_id)
    and (p_durum is null or t.durum = p_durum)
    and (p_id is null or t.id = p_id)
  order by t.created_at desc;
$$;

revoke all on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) from public;
grant execute on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) to authenticated;

-- =========================================================
-- Bağımlı select politikaları — aynı görünürlük kuralına geçirilir
-- =========================================================
drop policy if exists tutanak_fotograflari_select on public.tutanak_fotograflari;
create policy tutanak_fotograflari_select on public.tutanak_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

drop policy if exists tutanak_gecmisi_select on public.tutanak_gecmisi;
create policy tutanak_gecmisi_select on public.tutanak_gecmisi
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

drop policy if exists tutanak_gecmisi_fotograflari_select on public.tutanak_gecmisi_fotograflari;
create policy tutanak_gecmisi_fotograflari_select on public.tutanak_gecmisi_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanak_gecmisi g
      join public.tutanaklar t on t.id = g.tutanak_id
      where g.id = gecmisi_id
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

drop policy if exists tutanak_yorumlari_select on public.tutanak_yorumlari;
create policy tutanak_yorumlari_select on public.tutanak_yorumlari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanaklar t
      where t.id = tutanak_id
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

drop policy if exists tutanak_yorum_fotograflari_select on public.tutanak_yorum_fotograflari;
create policy tutanak_yorum_fotograflari_select on public.tutanak_yorum_fotograflari
  for select to authenticated
  using (
    exists (
      select 1 from public.tutanak_yorumlari y
      join public.tutanaklar t on t.id = y.tutanak_id
      where y.id = yorum_id
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

-- =========================================================
-- Storage — tutanak-fotograflari / tutanak-ek-fotograflari select
-- =========================================================
drop policy if exists tutanak_fotograflari_storage_select on storage.objects;
create policy tutanak_fotograflari_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'tutanak-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[2]
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

drop policy if exists tutanak_ek_fotograflari_storage_select on storage.objects;
create policy tutanak_ek_fotograflari_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'tutanak-ek-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[1]
        and public.can_see_tutanak(t.proje_id, t.firma_id, t.raporlayan_id)
    )
  );

-- =========================================================
-- tutanaklar_notify — Sorun 1: tutanağın firma_id'sine sahip her aktif
-- profile (rolden bağımsız) bildirim eklenir. İSG Uzmanı'nın proje bazlı
-- bildirimi yalnızca kendisine firma atanmamışsa (proje geneli görevliyse)
-- geçerli kalır — aksi halde artık göremeyeceği bir tutanak için bildirim
-- almaz.
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
        or p.firma_id = new.firma_id
        or (p.rol = 'isg_uzmani' and p.firma_id is null and public.is_assigned_to_proje_for(p.id, new.proje_id))
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
