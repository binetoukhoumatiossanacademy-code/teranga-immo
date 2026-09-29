-- Teranga Immo - schéma MVP compatible avec l'existant.
-- Ne supprime aucune ligne et ne renomme aucune colonne existante.
-- À exécuter seulement après validation du fichier preflight.

begin;

do $$
declare
  v_statut_type text;
begin
  if to_regclass('public.annonces') is null then
    raise exception 'Précondition manquante : public.annonces doit déjà exister';
  end if;

  select data_type into v_statut_type
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'annonces'
    and column_name = 'statut';

  if v_statut_type not in ('text', 'character varying', 'character') then
    raise exception 'Le type actuel de annonces.statut (%) doit être examiné avant migration', v_statut_type;
  end if;
end
$$;

create extension if not exists pgcrypto;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Profils : création si le script historique n'a jamais été appliqué,
-- puis extension sans renommer les colonnes déjà utilisées par Flutter.
-- ---------------------------------------------------------------------------

create table if not exists public.profils (
  id uuid primary key references auth.users(id) on delete cascade,
  type_compte text not null,
  nom text not null,
  nom_agence text,
  created_at timestamptz not null default now()
);

alter table public.profils
  add column if not exists telephone_whatsapp text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.profils
  drop constraint if exists profils_type_compte_check,
  drop constraint if exists agence_nom_valide,
  add constraint profils_type_compte_mvp_check
    check (type_compte in ('locataire', 'proprietaire', 'agence', 'admin'))
    not valid,
  add constraint profils_nom_mvp_check
    check (char_length(trim(nom)) between 1 and 120)
    not valid,
  add constraint profils_agence_nom_mvp_check
    check (
      (type_compte = 'agence'
        and nom_agence is not null
        and char_length(trim(nom_agence)) between 1 and 160)
      or
      (type_compte <> 'agence' and nom_agence is null)
    ) not valid;

-- ---------------------------------------------------------------------------
-- Annonces : workflow_id devient la clé stable du nouveau modèle sans imposer
-- un changement de type à la colonne id historique.
-- ---------------------------------------------------------------------------

alter table public.annonces
  add column if not exists workflow_id uuid,
  add column if not exists annonceur_id uuid,
  add column if not exists region text,
  add column if not exists nombre_chambres smallint,
  add column if not exists est_meuble boolean,
  add column if not exists description text,
  add column if not exists mode_disponibilite text,
  add column if not exists disponible_a_partir date,
  add column if not exists niveau_controle text not null default 'declaree',
  add column if not exists publication_autorisee boolean not null default false,
  add column if not exists version_soumise integer not null default 0,
  add column if not exists derniere_soumission_at timestamptz,
  add column if not exists published_at timestamptz,
  add column if not exists retired_at timestamptz,
  add column if not exists premium_actif boolean not null default false,
  add column if not exists premium_debut_at timestamptz,
  add column if not exists premium_fin_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

update public.annonces
set workflow_id = gen_random_uuid()
where workflow_id is null;

alter table public.annonces
  alter column workflow_id set default gen_random_uuid(),
  alter column workflow_id set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.annonces'::regclass
      and conname = 'annonces_workflow_id_key'
  ) then
    alter table public.annonces
      add constraint annonces_workflow_id_key unique (workflow_id);
  end if;
end
$$;

alter table public.annonces
  drop constraint if exists annonces_annonceur_id_fkey,
  add constraint annonces_annonceur_id_fkey
    foreign key (annonceur_id) references public.profils(id)
    on delete restrict not valid,
  drop constraint if exists annonces_type_logement_mvp_check,
  add constraint annonces_type_logement_mvp_check
    check (type_logement is null or type_logement in ('Appartement', 'Studio', 'Maison'))
    not valid,
  drop constraint if exists annonces_loyer_mvp_check,
  add constraint annonces_loyer_mvp_check
    check (loyer_mensuel is null or loyer_mensuel >= 0)
    not valid,
  drop constraint if exists annonces_chambres_mvp_check,
  add constraint annonces_chambres_mvp_check
    check (nombre_chambres is null or nombre_chambres >= 0)
    not valid,
  drop constraint if exists annonces_disponibilite_mvp_check,
  add constraint annonces_disponibilite_mvp_check
    check (
      mode_disponibilite is null
      or (mode_disponibilite = 'maintenant' and disponible_a_partir is null)
      or (mode_disponibilite = 'date' and disponible_a_partir is not null)
    ) not valid,
  drop constraint if exists annonces_niveau_controle_mvp_check,
  add constraint annonces_niveau_controle_mvp_check
    check (niveau_controle in ('declaree', 'informations_controlees', 'verifiee_teranga'))
    not valid,
  drop constraint if exists annonces_statut_mvp_check,
  add constraint annonces_statut_mvp_check
    check (statut in (
      'approuvee', 'en_attente',
      'brouillon', 'en_attente_controle', 'correction_demandee',
      'publiee', 'retrait_demande', 'retiree', 'refusee'
    )) not valid,
  drop constraint if exists annonces_premium_dates_check,
  add constraint annonces_premium_dates_check
    check (
      premium_fin_at is null
      or premium_debut_at is null
      or premium_fin_at > premium_debut_at
    ) not valid;

-- ---------------------------------------------------------------------------
-- Versions privées. La ligne annonces conserve le cliché public accepté.
-- ---------------------------------------------------------------------------

create table if not exists public.annonces_versions (
  id uuid primary key default gen_random_uuid(),
  annonce_id uuid not null references public.annonces(workflow_id) on delete cascade,
  numero_version integer not null check (numero_version > 0),
  statut_version text not null check (statut_version in (
    'brouillon', 'en_attente_controle', 'correction_demandee',
    'publiee', 'refusee', 'archivee'
  )),
  region text,
  ville text,
  quartier text,
  type_logement text check (
    type_logement is null or type_logement in ('Appartement', 'Studio', 'Maison')
  ),
  loyer_mensuel bigint check (loyer_mensuel is null or loyer_mensuel >= 0),
  nombre_chambres smallint check (nombre_chambres is null or nombre_chambres >= 0),
  est_meuble boolean,
  description text,
  mode_disponibilite text,
  disponible_a_partir date,
  created_by uuid references public.profils(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  submitted_at timestamptz,
  published_at timestamptz,
  constraint annonces_versions_numero_unique unique (annonce_id, numero_version),
  constraint annonces_versions_id_annonce_unique unique (id, annonce_id),
  constraint annonces_versions_disponibilite_check check (
    mode_disponibilite is null
    or (mode_disponibilite = 'maintenant' and disponible_a_partir is null)
    or (mode_disponibilite = 'date' and disponible_a_partir is not null)
  )
);

alter table public.annonces
  add column if not exists version_publiee_id uuid,
  add column if not exists version_travail_id uuid;

alter table public.annonces
  drop constraint if exists annonces_version_publiee_id_fkey,
  add constraint annonces_version_publiee_id_fkey
    foreign key (version_publiee_id) references public.annonces_versions(id)
    on delete restrict not valid,
  drop constraint if exists annonces_version_travail_id_fkey,
  add constraint annonces_version_travail_id_fkey
    foreign key (version_travail_id) references public.annonces_versions(id)
    on delete restrict not valid;

-- Contact rattaché à une version : un nouveau numéro en attente ne remplace
-- pas le numéro de la version actuellement publiée.
create table if not exists public.contacts_annonces (
  version_id uuid primary key,
  annonce_id uuid not null references public.annonces(workflow_id) on delete cascade,
  nom_contact text not null check (char_length(trim(nom_contact)) between 1 and 160),
  type_contact text not null check (type_contact in ('proprietaire', 'agence')),
  telephone_whatsapp text not null,
  email_contact text,
  appel_autorise boolean not null default true,
  whatsapp_autorise boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint contacts_version_annonce_fkey
    foreign key (version_id, annonce_id)
    references public.annonces_versions(id, annonce_id)
    on delete cascade
);

-- Objet physique Storage. L'ordre et le statut principal appartiennent à une
-- version via annonces_versions_photos afin de pouvoir réutiliser une photo.
create table if not exists public.photos_annonces (
  id uuid primary key default gen_random_uuid(),
  annonce_id uuid not null references public.annonces(workflow_id) on delete cascade,
  storage_path text not null unique,
  created_by uuid not null references public.profils(id) on delete restrict,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp')),
  taille_octets bigint not null check (taille_octets > 0 and taille_octets <= 8388608),
  created_at timestamptz not null default now()
);

create table if not exists public.annonces_versions_photos (
  version_id uuid not null references public.annonces_versions(id) on delete cascade,
  photo_id uuid not null references public.photos_annonces(id) on delete restrict,
  ordre smallint not null check (ordre between 0 and 9),
  est_principale boolean not null default false,
  primary key (version_id, photo_id),
  unique (version_id, ordre)
);

create unique index if not exists annonces_versions_une_photo_principale_idx
  on public.annonces_versions_photos(version_id)
  where est_principale;

create table if not exists public.favoris (
  utilisateur_id uuid not null references public.profils(id) on delete cascade,
  annonce_id uuid not null references public.annonces(workflow_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (utilisateur_id, annonce_id)
);

create table if not exists public.moderations_annonces (
  id uuid primary key default gen_random_uuid(),
  annonce_id uuid not null references public.annonces(workflow_id) on delete restrict,
  version_id uuid not null references public.annonces_versions(id) on delete restrict,
  administrateur_id uuid not null references public.profils(id) on delete restrict,
  decision text not null check (decision in ('accepter', 'demander_correction', 'refuser')),
  message_annonceur text,
  created_at timestamptz not null default now()
);

create table if not exists private.notes_moderation_internes (
  moderation_id uuid primary key references public.moderations_annonces(id) on delete cascade,
  note_interne text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.controles_annonces (
  id uuid primary key default gen_random_uuid(),
  annonce_id uuid not null references public.annonces(workflow_id) on delete restrict,
  version_id uuid not null references public.annonces_versions(id) on delete restrict,
  administrateur_id uuid not null references public.profils(id) on delete restrict,
  niveau_attribue text not null check (
    niveau_attribue in ('informations_controlees', 'verifiee_teranga')
  ),
  resume_public text not null,
  effectue_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.elements_controles (
  id uuid primary key default gen_random_uuid(),
  controle_id uuid not null references public.controles_annonces(id) on delete cascade,
  element_code text not null check (element_code in (
    'identite_annonceur', 'existence_logement', 'localisation',
    'photos_correspondantes', 'prix_declare', 'caracteristiques',
    'disponibilite', 'droit_proposer_logement'
  )),
  resultat text not null check (resultat in ('confirme', 'non_confirme', 'non_applicable')),
  explication_publique text not null,
  verifie_at timestamptz not null default now(),
  ordre smallint not null default 0,
  unique (controle_id, element_code)
);

create table if not exists public.demandes_retrait (
  id uuid primary key default gen_random_uuid(),
  annonce_id uuid not null references public.annonces(workflow_id) on delete restrict,
  demandeur_id uuid not null references public.profils(id) on delete restrict,
  motif text not null check (char_length(trim(motif)) > 0),
  logement_loue boolean not null,
  location_grace_teranga boolean,
  statut text not null default 'en_attente'
    check (statut in ('en_attente', 'approuvee', 'refusee')),
  created_at timestamptz not null default now(),
  decidee_par uuid references public.profils(id) on delete restrict,
  decidee_at timestamptz,
  commentaire_decision text,
  constraint demandes_retrait_declaration_check check (
    location_grace_teranga is distinct from true or logement_loue = true
  ),
  constraint demandes_retrait_decision_check check (
    (statut = 'en_attente' and decidee_par is null and decidee_at is null)
    or
    (statut in ('approuvee', 'refusee') and decidee_par is not null and decidee_at is not null)
  )
);

create unique index if not exists demandes_retrait_une_en_attente_idx
  on public.demandes_retrait(annonce_id)
  where statut = 'en_attente';

-- Index applicatifs et RLS.
create index if not exists annonces_statut_created_idx
  on public.annonces(statut, created_at desc);
create index if not exists annonces_annonceur_statut_idx
  on public.annonces(annonceur_id, statut);
create index if not exists annonces_localisation_idx
  on public.annonces(region, ville, quartier);
create index if not exists annonces_type_loyer_idx
  on public.annonces(type_logement, loyer_mensuel);
create index if not exists annonces_versions_annonce_statut_idx
  on public.annonces_versions(annonce_id, statut_version, numero_version desc);
create index if not exists photos_annonces_annonce_idx
  on public.photos_annonces(annonce_id);
create index if not exists moderations_annonce_date_idx
  on public.moderations_annonces(annonce_id, created_at desc);
create index if not exists controles_annonce_date_idx
  on public.controles_annonces(annonce_id, effectue_at desc);
create index if not exists demandes_retrait_statut_date_idx
  on public.demandes_retrait(statut, created_at);

commit;

