-- Yerel geliştirme için örnek veri (yalnızca `supabase db reset` ile yüklenir).
-- Kaynak: "Uygunsuzluk Tespit Tutanağı – Yerel Yapı" excel şablonu.

insert into public.firmalar (ad, tur) values
  ('YEREL YAPI', 'ana_yuklenici'),
  ('ÖRNEK TAŞERON A.Ş.', 'taseron')
on conflict do nothing;

insert into public.projeler (ad, yuklenici_adi, adres, aktif) values
  ('LEVENT', 'PASİFİK İNŞAAT', 'İstanbul / Levent', true),
  ('ATAŞEHİR', 'PASİFİK İNŞAAT', 'İstanbul / Ataşehir', true)
on conflict do nothing;
