-- Yerel geliştirme için örnek veri (yalnızca `supabase db reset` ile yüklenir).
-- Kaynak: "Uygunsuzluk Tespit Tutanağı – Yerel Yapı" excel şablonu.

insert into public.osgblar (ad) values
  ('ÖRNEK OSGB LTD. ŞTİ.')
on conflict do nothing;

insert into public.projeler (ad, yuklenici_adi, adres, aktif, osgb_id) values
  (
    'LEVENT', 'PASİFİK İNŞAAT', 'İstanbul / Levent', true,
    (select id from public.osgblar where ad = 'ÖRNEK OSGB LTD. ŞTİ.' limit 1)
  ),
  (
    'ATAŞEHİR', 'PASİFİK İNŞAAT', 'İstanbul / Ataşehir', true,
    (select id from public.osgblar where ad = 'ÖRNEK OSGB LTD. ŞTİ.' limit 1)
  )
on conflict do nothing;

insert into public.firmalar (ad, proje_id) values
  ('YEREL YAPI', (select id from public.projeler where ad = 'LEVENT' limit 1)),
  ('ÖRNEK TAŞERON A.Ş.', (select id from public.projeler where ad = 'ATAŞEHİR' limit 1))
on conflict do nothing;
