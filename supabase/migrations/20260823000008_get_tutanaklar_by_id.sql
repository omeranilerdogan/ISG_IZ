-- get_tutanaklar()'a tekil kayıt (detay ekranı) sorgusu için p_id parametresi eklenir.
-- Eski 2 parametreli imza kaldırılıp yerine 3 parametreli (proje/durum/id) sürüm konur.

drop function if exists public.get_tutanaklar(uuid, public.tutanak_durumu);

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
  where (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid())
    and (p_proje_id is null or t.proje_id = p_proje_id)
    and (p_durum is null or t.durum = p_durum)
    and (p_id is null or t.id = p_id)
  order by t.created_at desc;
$$;

revoke all on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) from public;
grant execute on function public.get_tutanaklar(uuid, public.tutanak_durumu, uuid) to authenticated;
