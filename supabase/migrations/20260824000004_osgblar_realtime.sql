-- osgblar tablosu 20260824000001'de eklendi ama supabase_realtime publication'ına
-- dahil edilmemişti — bu yüzden OsgbRepository.watchAll() (Proje/Firma Tanımları
-- ekranındaki OSGB sekmesi) ekleme/silme sonrası kendiliğinden yenilenmiyordu.

alter publication supabase_realtime add table public.osgblar;
