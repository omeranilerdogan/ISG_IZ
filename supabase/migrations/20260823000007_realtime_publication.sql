-- Flutter tarafında `.stream()` (Supabase Realtime / postgres_changes) ile
-- izlenen tablolar `supabase_realtime` publication'ına eklenmelidir, aksi halde
-- "RealtimeSubscribeException: Unable to subscribe to changes" hatası alınır.
-- Kullanım yerleri: ProfileRepository.watchById/watchAll, ProjeRepository.watchAll,
-- FirmaRepository.watchAll (Bölüm 5.7) ve ileride tutanaklar/bildirimler (Bölüm 7, 8).

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.projeler;
alter publication supabase_realtime add table public.firmalar;
alter publication supabase_realtime add table public.tutanaklar;
alter publication supabase_realtime add table public.bildirimler;
