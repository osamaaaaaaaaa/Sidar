-- SIDAR privacy hardening: analysis images must never be publicly readable.
-- Run after production_schema.sql. Existing public URLs remain in old records,
-- but new uploads are private and can only be read through short-lived signed URLs.

update storage.buckets
set public = false
where id = 'scan-images';

drop policy if exists "Public can read scan images" on storage.objects;
drop policy if exists "Authenticated users can upload scan images" on storage.objects;
drop policy if exists "Authenticated users can update scan images" on storage.objects;
drop policy if exists "Authenticated users can delete scan images" on storage.objects;
drop policy if exists "Users can upload only to their scan-image folder" on storage.objects;
drop policy if exists "Users can read only their scan-image folder" on storage.objects;
drop policy if exists "Users can update only their scan-image folder" on storage.objects;
drop policy if exists "Users can delete only their scan-image folder" on storage.objects;

create policy "Users can upload only to their scan-image folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'scan-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can read only their scan-image folder"
on storage.objects for select to authenticated
using (
  bucket_id = 'scan-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update only their scan-image folder"
on storage.objects for update to authenticated
using (
  bucket_id = 'scan-images'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'scan-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete only their scan-image folder"
on storage.objects for delete to authenticated
using (
  bucket_id = 'scan-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
