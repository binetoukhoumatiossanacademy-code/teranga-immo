-- Teranga Immo - fonctions internes, horodatage et garde-fous.

begin;

create or replace function private.role_courant()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select p.type_compte
  from public.profils p
  where p.id = (select auth.uid())
$$;

create or replace function private.est_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(private.role_courant() = 'admin', false)
$$;

create or replace function private.possede_annonce(p_annonce_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces a
    where a.workflow_id = p_annonce_id
      and a.annonceur_id = (select auth.uid())
  )
$$;

create or replace function private.peut_modifier_version(p_version_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces_versions v
    join public.annonces a on a.workflow_id = v.annonce_id
    where v.id = p_version_id
      and a.annonceur_id = (select auth.uid())
      and a.version_travail_id = v.id
      and v.statut_version in ('brouillon', 'correction_demandee')
  )
$$;

create or replace function private.version_est_publique(p_version_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces a
    where a.version_publiee_id = p_version_id
      and a.publication_autorisee
      and a.statut in ('approuvee', 'publiee', 'retrait_demande')
  )
$$;

create or replace function private.annonce_est_publique(p_annonce_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces a
    where a.workflow_id = p_annonce_id
      and a.annonceur_id is not null
      and a.version_publiee_id is not null
      and a.publication_autorisee
      and a.statut in ('approuvee', 'publiee', 'retrait_demande')
  )
$$;

create or replace function private.photo_est_publique(p_photo_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.annonces_versions_photos vp
    where vp.photo_id = p_photo_id
      and private.version_est_publique(vp.version_id)
  )
$$;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

drop trigger if exists profils_set_updated_at on public.profils;
create trigger profils_set_updated_at
before update on public.profils
for each row execute function private.set_updated_at();

drop trigger if exists annonces_set_updated_at on public.annonces;
create trigger annonces_set_updated_at
before update on public.annonces
for each row execute function private.set_updated_at();

drop trigger if exists annonces_versions_set_updated_at on public.annonces_versions;
create trigger annonces_versions_set_updated_at
before update on public.annonces_versions
for each row execute function private.set_updated_at();

drop trigger if exists contacts_annonces_set_updated_at on public.contacts_annonces;
create trigger contacts_annonces_set_updated_at
before update on public.contacts_annonces
for each row execute function private.set_updated_at();

-- Le rôle reste modifiable par une opération privilégiée, jamais par le client.
create or replace function private.proteger_role_profil()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id then
    raise exception 'L identifiant du profil est immuable';
  end if;

  if new.type_compte is distinct from old.type_compte
     and current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception 'Le rôle du compte ne peut pas être modifié depuis le client';
  end if;

  return new;
end
$$;

drop trigger if exists profils_proteger_role on public.profils;
create trigger profils_proteger_role
before update on public.profils
for each row execute function private.proteger_role_profil();

-- Limite à dix photos par version et interdit de rattacher une photo d'une
-- autre annonce.
create or replace function private.verifier_photo_version()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_annonce_version uuid;
  v_annonce_photo uuid;
  v_nombre integer;
begin
  select annonce_id into v_annonce_version
  from public.annonces_versions where id = new.version_id;

  select annonce_id into v_annonce_photo
  from public.photos_annonces where id = new.photo_id;

  if v_annonce_version is null or v_annonce_photo is null
     or v_annonce_version <> v_annonce_photo then
    raise exception 'La photo et la version doivent appartenir à la même annonce';
  end if;

  if tg_op = 'INSERT' then
    select count(*) into v_nombre
    from public.annonces_versions_photos
    where version_id = new.version_id;

    if v_nombre >= 10 then
      raise exception 'Une annonce ne peut pas contenir plus de 10 photos';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists annonces_versions_photos_verifier on public.annonces_versions_photos;
create trigger annonces_versions_photos_verifier
before insert or update on public.annonces_versions_photos
for each row execute function private.verifier_photo_version();

-- Le schéma private devient utilisable par les helpers RLS ci-dessous, mais
-- ses tables restent entièrement inaccessibles aux rôles clients.
revoke all on table private.notes_moderation_internes
  from public, anon, authenticated;
revoke all privileges (moderation_id, note_interne, created_at)
  on table private.notes_moderation_internes
  from public, anon, authenticated;

revoke all on all functions in schema private from public, anon, authenticated;
grant usage on schema private to anon, authenticated, service_role;
grant execute on function private.role_courant() to authenticated;
grant execute on function private.est_admin() to anon, authenticated;
grant execute on function private.possede_annonce(uuid) to anon, authenticated;
grant execute on function private.peut_modifier_version(uuid) to anon, authenticated;
grant execute on function private.version_est_publique(uuid) to anon, authenticated;
grant execute on function private.annonce_est_publique(uuid) to anon, authenticated;
grant execute on function private.photo_est_publique(uuid) to anon, authenticated;

commit;

