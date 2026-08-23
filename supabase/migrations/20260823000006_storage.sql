-- İSG Uygunsuzluk Tespit Tutanağı — Storage Bucket'ları ve Politikaları
-- Teknik Analiz Bölüm 3, 11, 14 — private bucket + signed URL / RLS

insert into storage.buckets (id, name, public)
values ('tutanak-fotograflari', 'tutanak-fotograflari', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('profil-resimleri', 'profil-resimleri', false)
on conflict (id) do nothing;

-- =========================================================
-- tutanak-fotograflari
-- Yol şeması: {proje_id}/{tutanak_id}/{sira}.jpg (Bölüm 11)
-- =========================================================
create policy tutanak_fotograflari_storage_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'tutanak-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[2]
        and (public.is_admin() or public.is_assigned_to_proje(t.proje_id) or t.raporlayan_id = auth.uid())
    )
  );

create policy tutanak_fotograflari_storage_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'tutanak-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[2]
        and (public.is_admin() or t.raporlayan_id = auth.uid())
    )
  );

create policy tutanak_fotograflari_storage_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'tutanak-fotograflari'
    and exists (
      select 1 from public.tutanaklar t
      where t.id::text = (storage.foldername(name))[2]
        and (public.is_admin() or (t.raporlayan_id = auth.uid() and t.durum in ('taslak', 'revizyon_istendi')))
    )
  );

-- =========================================================
-- profil-resimleri
-- Yol şeması: {kullanici_id}/{dosya_adi}
-- =========================================================
create policy profil_resmi_storage_select on storage.objects
  for select to authenticated
  using (bucket_id = 'profil-resimleri');

create policy profil_resmi_storage_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'profil-resimleri' and (storage.foldername(name))[1] = auth.uid()::text);

create policy profil_resmi_storage_update on storage.objects
  for update to authenticated
  using (bucket_id = 'profil-resimleri' and (storage.foldername(name))[1] = auth.uid()::text);

create policy profil_resmi_storage_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'profil-resimleri' and (storage.foldername(name))[1] = auth.uid()::text);
