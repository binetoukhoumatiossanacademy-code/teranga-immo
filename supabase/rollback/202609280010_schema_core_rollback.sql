-- Teranga Immo - rollback manuel de 202609280010_schema_core.sql.
-- NE PAS placer ce fichier dans supabase/migrations.
-- NE PAS exécuter après une migration ultérieure ni après ajout de données.
-- Ce rollback restaure la structure publique connue avant schema_core :
-- public.annonces avec ses sept colonnes historiques et sans public.profils.

begin;

do $$
declare
  v_table text;
  v_count bigint;
  v_objets text;
begin
  if to_regclass('public.annonces') is null then
    raise exception 'Rollback interrompu : public.annonces est absente';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'annonces'
      and column_name = 'workflow_id'
  ) then
    raise exception 'Rollback interrompu : schema_core ne semble pas appliquée';
  end if;

  if to_regprocedure('private.role_courant()') is not null
     or to_regprocedure('public.creer_annonce_brouillon(text,text,text,text,bigint,smallint,boolean,text,text,date)') is not null then
    raise exception 'Rollback interrompu : une migration ultérieure semble appliquée';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
  ) then
    raise exception 'Rollback interrompu : le schéma private contient une ou plusieurs fonctions';
  end if;

  select string_agg(c.relname, ', ' order by c.relname)
  into v_objets
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'private'
    and c.relname not in (
      'notes_moderation_internes',
      'notes_moderation_internes_pkey'
    );

  if v_objets is not null then
    raise exception 'Rollback interrompu : objets inattendus dans private : %', v_objets;
  end if;

  if to_regclass('private.notes_moderation_internes') is not null then
    select count(*) into v_count from private.notes_moderation_internes;
    if v_count <> 0 then
      raise exception 'Rollback interrompu : private.notes_moderation_internes contient % ligne(s)', v_count;
    end if;
  end if;

  select count(*) into v_count from public.annonces;
  if v_count <> 0 then
    raise exception 'Rollback interrompu : public.annonces contient % ligne(s)', v_count;
  end if;

  foreach v_table in array array[
    'profils',
    'annonces_versions',
    'contacts_annonces',
    'photos_annonces',
    'annonces_versions_photos',
    'favoris',
    'moderations_annonces',
    'controles_annonces',
    'elements_controles',
    'demandes_retrait'
  ]
  loop
    if to_regclass('public.' || v_table) is not null then
      execute format('select count(*) from public.%I', v_table) into v_count;
      if v_count <> 0 then
        raise exception 'Rollback interrompu : public.% contient % ligne(s)',
          v_table, v_count;
      end if;
    end if;
  end loop;
end
$$;

drop table if exists private.notes_moderation_internes;
drop table if exists public.elements_controles;
drop table if exists public.demandes_retrait;
drop table if exists public.moderations_annonces;
drop table if exists public.controles_annonces;
drop table if exists public.favoris;
drop table if exists public.annonces_versions_photos;
drop table if exists public.photos_annonces;
drop table if exists public.contacts_annonces;

alter table public.annonces
  drop constraint if exists annonces_version_publiee_id_fkey,
  drop constraint if exists annonces_version_travail_id_fkey;

alter table public.annonces
  drop column if exists version_publiee_id,
  drop column if exists version_travail_id;

drop table if exists public.annonces_versions;

drop index if exists public.annonces_statut_created_idx;
drop index if exists public.annonces_annonceur_statut_idx;
drop index if exists public.annonces_localisation_idx;
drop index if exists public.annonces_type_loyer_idx;

alter table public.annonces
  drop constraint if exists annonces_annonceur_id_fkey,
  drop constraint if exists annonces_type_logement_mvp_check,
  drop constraint if exists annonces_loyer_mvp_check,
  drop constraint if exists annonces_chambres_mvp_check,
  drop constraint if exists annonces_disponibilite_mvp_check,
  drop constraint if exists annonces_niveau_controle_mvp_check,
  drop constraint if exists annonces_statut_mvp_check,
  drop constraint if exists annonces_premium_dates_check,
  drop constraint if exists annonces_workflow_id_key;

alter table public.annonces
  drop column if exists workflow_id,
  drop column if exists annonceur_id,
  drop column if exists region,
  drop column if exists nombre_chambres,
  drop column if exists est_meuble,
  drop column if exists description,
  drop column if exists mode_disponibilite,
  drop column if exists disponible_a_partir,
  drop column if exists niveau_controle,
  drop column if exists publication_autorisee,
  drop column if exists version_soumise,
  drop column if exists derniere_soumission_at,
  drop column if exists published_at,
  drop column if exists retired_at,
  drop column if exists premium_actif,
  drop column if exists premium_debut_at,
  drop column if exists premium_fin_at,
  drop column if exists updated_at;

drop table if exists public.profils;

-- Le préflight a confirmé que private n'existait pas avant schema_core.
-- RESTRICT interdit sa suppression si une fonction, une table, un type ou tout
-- autre objet inattendu y subsiste. L'échec annule alors tout ce rollback.
drop schema private restrict;

-- pgcrypto existait avant schema_core : elle est volontairement conservée.

commit;

