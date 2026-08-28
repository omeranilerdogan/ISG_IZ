-- Düzeltme: (1) PostgREST şema önbelleğini yeniler — CLI üzerinden uygulanan
-- DDL değişiklikleri (20260824000001/2) bazen otomatik NOTIFY tetiklemeyebilir,
-- bu da "Could not find the table 'public.osgblar' in the schema cache" (PGRST205)
-- hatasına yol açar.
-- (2) proje_utt_sayaclari sayaç tablosunu, tutanaklar.utt_no içindeki gerçek en
-- yüksek sıra numarasının GERİSİNDE kalmışsa senkronize eder — bu senkron
-- bozukluğu "duplicate key value violates unique constraint tutanaklar_utt_no_key"
-- hatasına yol açar. Yalnızca sayacı yükseltir, hiçbir veri silmez/değiştirmez.

insert into public.proje_utt_sayaclari (proje_id, yil, son_sira)
select
  t.proje_id,
  2000 + split_part(t.utt_no, '/', 1)::int,
  max(split_part(t.utt_no, '/', 2)::int)
from public.tutanaklar t
where t.utt_no is not null
  and t.utt_no ~ '^[0-9]{2}/[0-9]+$'
group by t.proje_id, split_part(t.utt_no, '/', 1)::int
on conflict (proje_id, yil)
do update set son_sira = greatest(
  public.proje_utt_sayaclari.son_sira,
  excluded.son_sira
);

notify pgrst, 'reload schema';
