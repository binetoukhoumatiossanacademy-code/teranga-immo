-- Teranga Immo - bucket privé et politiques Storage.
-- Les fichiers restent privés par défaut. Seules les photos de la version
-- publiée sont lisibles publiquement via une requête autorisée par RLS.

begin;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'annonces-photos',
  'annonces-photos',
  false,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Chemin attendu : {auth.uid}/{annonce.workflow_id}/{uuid-fichier}.ext
create or replace function private.storage_annonce_id(p_name text)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parties text[];
begin
  v_parties := storage.foldername(p_name);
  if coalesce(array_length(v_parties, 1), 0) <> 2 then return null; end if;
  return v_parties[2]::uuid;
exception when invalid_text_representation then
  return null;
end
$$;

create or replace function private.storage_objet_appartient_utilisateur(p_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_parties text[];
  v_annonce uuid;
begin
  v_parties := storage.foldername(p_name);
  if coalesce(array_length(v_parties, 1), 0) <> 2 then return false; end if;
  if v_parties[1] <> (select auth.uid())::text then return false; end if;
  v_annonce := private.storage_annonce_id(p_name);
  return v_annonce is not null and private.possede_annonce(v_annonce);
end
$$;

create or replace function private.storage_objet_est_public(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.photos_annonces p
    where p.storage_path = p_name
      and private.photo_est_publique(p.id)
  )
$$;

-- Une photo ayant appartenu à une version publiée ou archivée reste conservée
-- dans l'historique, même lorsque l'annonce est ensuite retirée ou remplacée.
create or replace function private.photo_est_protegee(p_photo_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces_versions_photos vp
    join public.annonces_versions v on v.id = vp.version_id
    where vp.photo_id = p_photo_id
      and v.statut_version in ('publiee', 'archivee')
  )
$$;

create or replace function private.storage_objet_peut_etre_supprime(p_name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.storage_objet_appartient_utilisateur(p_name)
     and not exists (
       select 1
       from public.photos_annonces p
       where p.storage_path = p_name
         and private.photo_est_protegee(p.id)
     )
$$;

revoke all on function private.storage_annonce_id(text)
  from public, anon, authenticated;
revoke all on function private.storage_objet_appartient_utilisateur(text)
  from public, anon, authenticated;
revoke all on function private.storage_objet_est_public(text)
  from public, anon, authenticated;
revoke all on function private.photo_est_protegee(uuid)
  from public, anon, authenticated;
revoke all on function private.storage_objet_peut_etre_supprime(text)
  from public, anon, authenticated;

grant execute on function private.storage_objet_appartient_utilisateur(text)
  to anon, authenticated;
grant execute on function private.storage_objet_est_public(text)
  to anon, authenticated;
grant execute on function private.photo_est_protegee(uuid)
  to authenticated;
grant execute on function private.storage_objet_peut_etre_supprime(text)
  to authenticated;

-- Aligner la suppression des métadonnées avec la conservation physique : une
-- photo historiquement publiée ne peut plus être supprimée par l'annonceur.
drop policy if exists photos_delete_mvp on public.photos_annonces;
create policy photos_delete_mvp on public.photos_annonces
for delete to authenticated
using (
  private.possede_annonce(annonce_id)
  and not private.photo_est_protegee(id)
);

drop policy if exists teranga_photos_select_guard on storage.objects;
drop policy if exists teranga_photos_select on storage.objects;
drop policy if exists teranga_photos_insert_guard on storage.objects;
drop policy if exists teranga_photos_insert on storage.objects;
drop policy if exists teranga_photos_update_guard on storage.objects;
drop policy if exists teranga_photos_update on storage.objects;
drop policy if exists teranga_photos_delete_guard on storage.objects;
drop policy if exists teranga_photos_delete on storage.objects;

-- Les guards restrictifs empêchent une ancienne politique permissive de rendre
-- ce bucket plus ouvert que prévu, tout en laissant les autres buckets intacts.
create policy teranga_photos_select_guard
on storage.objects as restrictive
for select to anon, authenticated
using (
  bucket_id <> 'annonces-photos'
  or private.storage_objet_est_public(name)
  or private.storage_objet_appartient_utilisateur(name)
  or private.est_admin()
);

create policy teranga_photos_select
on storage.objects
for select to anon, authenticated
using (
  bucket_id = 'annonces-photos'
  and (
    private.storage_objet_est_public(name)
    or private.storage_objet_appartient_utilisateur(name)
    or private.est_admin()
  )
);

create policy teranga_photos_insert_guard
on storage.objects as restrictive
for insert to authenticated
with check (
  bucket_id <> 'annonces-photos'
  or private.storage_objet_appartient_utilisateur(name)
  or private.est_admin()
);

create policy teranga_photos_insert
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'annonces-photos'
  and (
    private.storage_objet_appartient_utilisateur(name)
    or private.est_admin()
  )
);

create policy teranga_photos_update_guard
on storage.objects as restrictive
for update to authenticated
using (
  bucket_id <> 'annonces-photos'
  or private.storage_objet_peut_etre_supprime(name)
  or private.est_admin()
)
with check (
  bucket_id <> 'annonces-photos'
  or private.storage_objet_appartient_utilisateur(name)
  or private.est_admin()
);

create policy teranga_photos_update
on storage.objects
for update to authenticated
using (
  bucket_id = 'annonces-photos'
  and (
    private.storage_objet_peut_etre_supprime(name)
    or private.est_admin()
  )
)
with check (
  bucket_id = 'annonces-photos'
  and (
    private.storage_objet_appartient_utilisateur(name)
    or private.est_admin()
  )
);

create policy teranga_photos_delete_guard
on storage.objects as restrictive
for delete to authenticated
using (
  bucket_id <> 'annonces-photos'
  or private.storage_objet_peut_etre_supprime(name)
  or private.est_admin()
);

create policy teranga_photos_delete
on storage.objects
for delete to authenticated
using (
  bucket_id = 'annonces-photos'
  and (
    private.storage_objet_peut_etre_supprime(name)
    or private.est_admin()
  )
);

commit;

