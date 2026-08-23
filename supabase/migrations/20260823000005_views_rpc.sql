-- İSG Uygunsuzluk Tespit Tutanağı — Kolon Seviyesi Güvenlik (RPC)
-- Teknik Analiz Bölüm 10.2 — ceza_tutari alanı doğrudan tabloya değil
-- get_tutanaklar()/set_ceza_tutari() üzerinden okunur/yazılır.

create or replace function public.get_tutanaklar(
  p_proje_id uuid default null,
  p_durum public.tutanak_durumu default null
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
  where (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid())
    and (p_proje_id is null or t.proje_id = p_proje_id)
    and (p_durum is null or t.durum = p_durum)
  order by t.created_at desc;
$$;

revoke all on function public.get_tutanaklar(uuid, public.tutanak_durumu) from public;
grant execute on function public.get_tutanaklar(uuid, public.tutanak_durumu) to authenticated;

-- Ceza tutarının yazılması yalnızca bu RPC üzerinden yapılır (Bölüm 10.2).
-- Not: tutanaklar tablosunda ayrıca guard_tutanaklar_update trigger'ı da
-- admin olmayan bir UPDATE ile ceza_tutari değişmesini reddeder (çift katman).
create or replace function public.set_ceza_tutari(p_tutanak_id uuid, p_tutar numeric)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Yalnızca yönetici (Admin) ceza tutarı girebilir/düzenleyebilir.';
  end if;

  update public.tutanaklar
  set ceza_tutari = p_tutar
  where id = p_tutanak_id;

  if not found then
    raise exception 'Tutanak bulunamadı: %', p_tutanak_id;
  end if;
end;
$$;

revoke all on function public.set_ceza_tutari(uuid, numeric) from public;
grant execute on function public.set_ceza_tutari(uuid, numeric) to authenticated;

-- Tutanağı onaylama/reddetme/revizyon isteme (Admin, İSG Uzmanı) — Bölüm 7.
create or replace function public.tutanak_durum_degistir(
  p_tutanak_id uuid,
  p_yeni_durum public.tutanak_durumu,
  p_not text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proje_id uuid;
  v_rol public.kullanici_rolu := public.current_rol();
begin
  select proje_id into v_proje_id from public.tutanaklar where id = p_tutanak_id;

  if v_proje_id is null then
    raise exception 'Tutanak bulunamadı: %', p_tutanak_id;
  end if;

  if not (public.is_admin() or (v_rol = 'isg_uzmani' and public.is_assigned_to_proje(v_proje_id))) then
    raise exception 'Bu tutanağı onaylama/reddetme yetkiniz yok.';
  end if;

  if p_yeni_durum not in ('incelemede', 'revizyon_istendi', 'onaylandi', 'reddedildi', 'kapatildi') then
    raise exception 'Geçersiz durum: %', p_yeni_durum;
  end if;

  update public.tutanaklar
  set durum = p_yeni_durum,
      red_revizyon_notu = coalesce(p_not, red_revizyon_notu),
      onaylayan_id = case when p_yeni_durum = 'onaylandi' then auth.uid() else onaylayan_id end
  where id = p_tutanak_id;
end;
$$;

revoke all on function public.tutanak_durum_degistir(uuid, public.tutanak_durumu, text) from public;
grant execute on function public.tutanak_durum_degistir(uuid, public.tutanak_durumu, text) to authenticated;
