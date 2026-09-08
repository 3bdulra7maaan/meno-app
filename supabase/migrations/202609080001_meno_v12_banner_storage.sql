-- Additive Meno v1.2 banner targeting and public image storage.
alter table public.home_banners
  add column if not exists target_type text not null default 'none';

-- Preserve v1.1 URL banners when the new discriminator is introduced.
update public.home_banners
set target_type = 'external'
where target_url is not null and target_type = 'none';

alter table public.home_banners
  drop constraint if exists home_banners_target_type_check;
alter table public.home_banners
  add constraint home_banners_target_type_check
  check (target_type in ('none', 'internal', 'external'));

alter table public.home_banners
  drop constraint if exists home_banners_target_consistency_check;
alter table public.home_banners
  add constraint home_banners_target_consistency_check check (
    (target_type = 'external' and target_url ~ '^https://')
    or (target_type in ('none', 'internal') and target_url is null)
  );

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'home-banners',
  'home-banners',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Admins upload home banner images" on storage.objects;
create policy "Admins upload home banner images" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'home-banners'
  and public.is_meno_admin()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Admins update home banner images" on storage.objects;
create policy "Admins update home banner images" on storage.objects
for update to authenticated
using (bucket_id = 'home-banners' and public.is_meno_admin())
with check (
  bucket_id = 'home-banners'
  and public.is_meno_admin()
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Admins delete home banner images" on storage.objects;
create policy "Admins delete home banner images" on storage.objects
for delete to authenticated
using (bucket_id = 'home-banners' and public.is_meno_admin());
