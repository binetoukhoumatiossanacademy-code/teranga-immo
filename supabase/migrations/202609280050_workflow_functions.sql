-- Teranga Immo - fonctions métier atomiques.
-- Aucune fonction n'attribue Premium. Accepter une annonce ne change jamais
-- automatiquement son niveau de contrôle.

begin;

create table if not exists private.configuration_mvp (
  singleton boolean primary key default true check (singleton),
  statuts_v2_actifs boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into private.configuration_mvp(singleton, statuts_v2_actifs)
values (true, false)
on conflict (singleton) do nothing;

create table if not exists private.historique_roles (
  id uuid primary key default gen_random_uuid(),
  utilisateur_id uuid not null references public.profils(id) on delete restrict,
  ancien_role text,
  nouveau_role text not null,
  motif text not null,
  effectue_par uuid,
  created_at timestamptz not null default now()
);

-- Les tables privées ne sont jamais accessibles directement depuis Flutter.
-- Les fonctions SECURITY DEFINER ci-dessous sont leur seule porte d'entrée.
revoke all on table private.configuration_mvp
  from public, anon, authenticated;
revoke all on table private.historique_roles
  from public, anon, authenticated;
revoke all privileges (singleton, statuts_v2_actifs, updated_at)
  on table private.configuration_mvp
  from public, anon, authenticated;
revoke all privileges (
  id, utilisateur_id, ancien_role, nouveau_role, motif, effectue_par, created_at
) on table private.historique_roles
  from public, anon, authenticated;

create or replace function public.creer_annonce_brouillon(
  p_region text,
  p_ville text,
  p_quartier text,
  p_type_logement text,
  p_loyer_mensuel bigint,
  p_nombre_chambres smallint,
  p_est_meuble boolean,
  p_description text,
  p_mode_disponibilite text,
  p_disponible_a_partir date
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_role text := private.role_courant();
  v_annonce uuid := gen_random_uuid();
  v_version uuid := gen_random_uuid();
begin
  if v_user is null or v_role not in ('proprietaire', 'agence') then
    raise exception 'Un compte propriétaire ou agence est requis';
  end if;

  if p_type_logement not in ('Appartement', 'Studio', 'Maison') then
    raise exception 'Type de logement invalide';
  end if;
  if p_loyer_mensuel is null or p_loyer_mensuel < 0 then
    raise exception 'Prix mensuel invalide';
  end if;

  insert into public.annonces (
    workflow_id, annonceur_id, statut,
    region, ville, quartier, type_logement, loyer_mensuel,
    nombre_chambres, est_meuble, description,
    mode_disponibilite, disponible_a_partir,
    niveau_controle, publication_autorisee, premium_actif
  ) values (
    v_annonce, v_user, 'brouillon',
    nullif(trim(p_region), ''), nullif(trim(p_ville), ''), nullif(trim(p_quartier), ''),
    p_type_logement, p_loyer_mensuel,
    p_nombre_chambres, p_est_meuble, nullif(trim(p_description), ''),
    p_mode_disponibilite, p_disponible_a_partir,
    'declaree', false, false
  );

  insert into public.annonces_versions (
    id, annonce_id, numero_version, statut_version,
    region, ville, quartier, type_logement, loyer_mensuel,
    nombre_chambres, est_meuble, description,
    mode_disponibilite, disponible_a_partir, created_by
  ) values (
    v_version, v_annonce, 1, 'brouillon',
    nullif(trim(p_region), ''), nullif(trim(p_ville), ''), nullif(trim(p_quartier), ''),
    p_type_logement, p_loyer_mensuel,
    p_nombre_chambres, p_est_meuble, nullif(trim(p_description), ''),
    p_mode_disponibilite, p_disponible_a_partir, v_user
  );

  update public.annonces
  set version_travail_id = v_version
  where workflow_id = v_annonce;

  return v_annonce;
end
$$;

create or replace function public.supprimer_mon_brouillon(p_annonce_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_annonce public.annonces%rowtype;
begin
  select * into v_annonce
  from public.annonces
  where workflow_id = p_annonce_id
  for update;

  if v_user is null
     or not found
     or v_annonce.annonceur_id is distinct from v_user then
    raise exception 'Annonce introuvable ou non autorisée';
  end if;

  if v_annonce.version_publiee_id is not null or v_annonce.statut <> 'brouillon' then
    raise exception 'Seul un brouillon jamais publié peut être supprimé';
  end if;

  delete from public.annonces where workflow_id = p_annonce_id;
end
$$;

create or replace function public.commencer_modification_annonce(p_annonce_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_annonce public.annonces%rowtype;
  v_source public.annonces_versions%rowtype;
  v_version uuid := gen_random_uuid();
  v_numero integer;
begin
  select * into v_annonce
  from public.annonces
  where workflow_id = p_annonce_id
  for update;

  if v_user is null
     or not found
     or v_annonce.annonceur_id is distinct from v_user then
    raise exception 'Annonce introuvable ou non autorisée';
  end if;
  if v_annonce.version_publiee_id is null
     or v_annonce.statut not in ('approuvee', 'publiee', 'retrait_demande') then
    raise exception 'Aucune version publiée ne peut être modifiée';
  end if;
  if v_annonce.version_travail_id is not null then
    raise exception 'Une modification est déjà en cours';
  end if;

  select * into strict v_source
  from public.annonces_versions
  where id = v_annonce.version_publiee_id;

  select coalesce(max(numero_version), 0) + 1 into v_numero
  from public.annonces_versions
  where annonce_id = p_annonce_id;

  insert into public.annonces_versions (
    id, annonce_id, numero_version, statut_version,
    region, ville, quartier, type_logement, loyer_mensuel,
    nombre_chambres, est_meuble, description,
    mode_disponibilite, disponible_a_partir, created_by
  ) values (
    v_version, p_annonce_id, v_numero, 'brouillon',
    v_source.region, v_source.ville, v_source.quartier,
    v_source.type_logement, v_source.loyer_mensuel,
    v_source.nombre_chambres, v_source.est_meuble, v_source.description,
    v_source.mode_disponibilite, v_source.disponible_a_partir,
    (select auth.uid())
  );

  insert into public.contacts_annonces (
    version_id, annonce_id, nom_contact, type_contact,
    telephone_whatsapp, email_contact, appel_autorise, whatsapp_autorise
  )
  select v_version, annonce_id, nom_contact, type_contact,
         telephone_whatsapp, email_contact, appel_autorise, whatsapp_autorise
  from public.contacts_annonces
  where version_id = v_annonce.version_publiee_id;

  insert into public.annonces_versions_photos(version_id, photo_id, ordre, est_principale)
  select v_version, photo_id, ordre, est_principale
  from public.annonces_versions_photos
  where version_id = v_annonce.version_publiee_id;

  update public.annonces
  set version_travail_id = v_version
  where workflow_id = p_annonce_id;

  return v_version;
end
$$;

create or replace function public.soumettre_annonce(p_annonce_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_annonce public.annonces%rowtype;
  v_version public.annonces_versions%rowtype;
  v_photos integer;
begin
  select * into v_annonce
  from public.annonces
  where workflow_id = p_annonce_id
  for update;

  if v_user is null
     or not found
     or v_annonce.annonceur_id is distinct from v_user then
    raise exception 'Annonce introuvable ou non autorisée';
  end if;
  if v_annonce.version_travail_id is null then
    raise exception 'Aucune version à soumettre';
  end if;

  select * into strict v_version
  from public.annonces_versions
  where id = v_annonce.version_travail_id
  for update;

  if v_version.statut_version not in ('brouillon', 'correction_demandee') then
    raise exception 'Cette version ne peut pas être soumise';
  end if;

  if v_version.region is null or v_version.ville is null or v_version.quartier is null
     or v_version.type_logement is null or v_version.loyer_mensuel is null
     or v_version.nombre_chambres is null or v_version.est_meuble is null
     or v_version.description is null or v_version.mode_disponibilite is null then
    raise exception 'Les informations obligatoires du logement sont incomplètes';
  end if;

  if not exists (
    select 1 from public.contacts_annonces c where c.version_id = v_version.id
  ) then
    raise exception 'Le contact de l annonce est obligatoire';
  end if;

  select count(*) into v_photos
  from public.annonces_versions_photos vp
  where vp.version_id = v_version.id;

  if v_photos < 1 or v_photos > 10 then
    raise exception 'L annonce doit contenir entre 1 et 10 photos';
  end if;
  if not exists (
    select 1 from public.annonces_versions_photos vp
    where vp.version_id = v_version.id and vp.est_principale
  ) then
    raise exception 'Une photo principale est obligatoire';
  end if;

  update public.annonces_versions
  set statut_version = 'en_attente_controle', submitted_at = now()
  where id = v_version.id;

  update public.annonces
  set version_soumise = v_version.numero_version,
      derniere_soumission_at = now(),
      statut = case when version_publiee_id is null then 'en_attente_controle' else statut end,
      region = case when version_publiee_id is null then v_version.region else region end,
      ville = case when version_publiee_id is null then v_version.ville else ville end,
      quartier = case when version_publiee_id is null then v_version.quartier else quartier end,
      type_logement = case when version_publiee_id is null then v_version.type_logement else type_logement end,
      loyer_mensuel = case when version_publiee_id is null then v_version.loyer_mensuel else loyer_mensuel end,
      nombre_chambres = case when version_publiee_id is null then v_version.nombre_chambres else nombre_chambres end,
      est_meuble = case when version_publiee_id is null then v_version.est_meuble else est_meuble end,
      description = case when version_publiee_id is null then v_version.description else description end,
      mode_disponibilite = case when version_publiee_id is null then v_version.mode_disponibilite else mode_disponibilite end,
      disponible_a_partir = case when version_publiee_id is null then v_version.disponible_a_partir else disponible_a_partir end
  where workflow_id = p_annonce_id;
end
$$;

create or replace function public.moderer_annonce(
  p_version_id uuid,
  p_decision text,
  p_message_annonceur text default null,
  p_note_interne text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_version public.annonces_versions%rowtype;
  v_annonce public.annonces%rowtype;
  v_moderation uuid;
  v_statut_public text;
begin
  if not private.est_admin() then
    raise exception 'Accès administrateur requis';
  end if;
  if p_decision not in ('accepter', 'demander_correction', 'refuser') then
    raise exception 'Décision invalide';
  end if;
  if p_decision in ('demander_correction', 'refuser')
     and nullif(trim(p_message_annonceur), '') is null then
    raise exception 'Un motif visible par l annonceur est obligatoire';
  end if;

  select * into v_version
  from public.annonces_versions
  where id = p_version_id
  for update;
  if not found or v_version.statut_version <> 'en_attente_controle' then
    raise exception 'Cette version n est pas en attente de contrôle';
  end if;

  select * into strict v_annonce
  from public.annonces
  where workflow_id = v_version.annonce_id
  for update;

  if v_annonce.version_travail_id is distinct from v_version.id then
    raise exception 'Cette version n est plus la version de travail courante';
  end if;

  if v_annonce.annonceur_id = (select auth.uid()) then
    raise exception 'Un administrateur ne peut pas modérer sa propre annonce';
  end if;

  insert into public.moderations_annonces (
    annonce_id, version_id, administrateur_id, decision, message_annonceur
  ) values (
    v_annonce.workflow_id, v_version.id, (select auth.uid()),
    p_decision, nullif(trim(p_message_annonceur), '')
  ) returning id into v_moderation;

  if nullif(trim(p_note_interne), '') is not null then
    insert into private.notes_moderation_internes(moderation_id, note_interne)
    values (v_moderation, trim(p_note_interne));
  end if;

  if p_decision = 'accepter' then
    select case when statuts_v2_actifs then 'publiee' else 'approuvee' end
    into v_statut_public
    from private.configuration_mvp where singleton;

    if v_annonce.version_publiee_id is not null then
      update public.annonces_versions
      set statut_version = 'archivee'
      where id = v_annonce.version_publiee_id;
    end if;

    update public.annonces_versions
    set statut_version = 'publiee', published_at = now()
    where id = v_version.id;

    update public.annonces
    set version_publiee_id = v_version.id,
        version_travail_id = null,
        statut = v_statut_public,
        niveau_controle = 'declaree',
        publication_autorisee = true,
        published_at = coalesce(published_at, now()),
        retired_at = null,
        region = v_version.region,
        ville = v_version.ville,
        quartier = v_version.quartier,
        type_logement = v_version.type_logement,
        loyer_mensuel = v_version.loyer_mensuel,
        nombre_chambres = v_version.nombre_chambres,
        est_meuble = v_version.est_meuble,
        description = v_version.description,
        mode_disponibilite = v_version.mode_disponibilite,
        disponible_a_partir = v_version.disponible_a_partir
    where workflow_id = v_annonce.workflow_id;

  elsif p_decision = 'demander_correction' then
    update public.annonces_versions
    set statut_version = 'correction_demandee'
    where id = v_version.id;

    if v_annonce.version_publiee_id is null then
      update public.annonces set statut = 'correction_demandee'
      where workflow_id = v_annonce.workflow_id;
    end if;

  else
    update public.annonces_versions
    set statut_version = 'refusee'
    where id = v_version.id;

    if v_annonce.version_publiee_id is null then
      update public.annonces
      set statut = 'refusee', publication_autorisee = false
      where workflow_id = v_annonce.workflow_id;
    else
      update public.annonces
      set version_travail_id = null
      where workflow_id = v_annonce.workflow_id;
    end if;
  end if;
end
$$;

create or replace function public.demander_retrait_annonce(
  p_annonce_id uuid,
  p_motif text,
  p_logement_loue boolean,
  p_location_grace_teranga boolean default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_annonce public.annonces%rowtype;
  v_demande uuid;
  v_v2 boolean;
begin
  select * into v_annonce
  from public.annonces where workflow_id = p_annonce_id for update;

  if v_user is null
     or not found
     or v_annonce.annonceur_id is distinct from v_user then
    raise exception 'Annonce introuvable ou non autorisée';
  end if;
  if v_annonce.statut not in ('approuvee', 'publiee')
     or not v_annonce.publication_autorisee then
    raise exception 'Seule une annonce publiée peut faire l objet d un retrait';
  end if;
  if nullif(trim(p_motif), '') is null then
    raise exception 'Le motif est obligatoire';
  end if;
  if p_location_grace_teranga is true and not p_logement_loue then
    raise exception 'La déclaration de location est incohérente';
  end if;

  insert into public.demandes_retrait (
    annonce_id, demandeur_id, motif, logement_loue, location_grace_teranga
  ) values (
    p_annonce_id, (select auth.uid()), trim(p_motif),
    p_logement_loue, p_location_grace_teranga
  ) returning id into v_demande;

  select statuts_v2_actifs into v_v2
  from private.configuration_mvp where singleton;

  if v_v2 then
    update public.annonces set statut = 'retrait_demande'
    where workflow_id = p_annonce_id;
  end if;

  return v_demande;
end
$$;

create or replace function public.traiter_demande_retrait(
  p_demande_id uuid,
  p_decision text,
  p_commentaire text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_demande public.demandes_retrait%rowtype;
  v_statut_public text;
begin
  if not private.est_admin() then
    raise exception 'Accès administrateur requis';
  end if;
  if p_decision not in ('approuver', 'refuser') then
    raise exception 'Décision invalide';
  end if;

  select * into v_demande
  from public.demandes_retrait
  where id = p_demande_id
  for update;

  if not found or v_demande.statut <> 'en_attente' then
    raise exception 'Cette demande n est plus en attente';
  end if;

  if p_decision = 'approuver' then
    update public.demandes_retrait
    set statut = 'approuvee', decidee_par = (select auth.uid()),
        decidee_at = now(), commentaire_decision = nullif(trim(p_commentaire), '')
    where id = p_demande_id;

    update public.annonces
    set statut = 'retiree', publication_autorisee = false, retired_at = now()
    where workflow_id = v_demande.annonce_id;
  else
    select case when statuts_v2_actifs then 'publiee' else 'approuvee' end
    into v_statut_public
    from private.configuration_mvp where singleton;

    update public.demandes_retrait
    set statut = 'refusee', decidee_par = (select auth.uid()),
        decidee_at = now(), commentaire_decision = nullif(trim(p_commentaire), '')
    where id = p_demande_id;

    update public.annonces
    set statut = v_statut_public
    where workflow_id = v_demande.annonce_id;
  end if;
end
$$;

create or replace function public.enregistrer_controle_annonce(
  p_annonce_id uuid,
  p_niveau text,
  p_resume_public text,
  p_elements jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_annonce public.annonces%rowtype;
  v_controle uuid;
  v_element jsonb;
  v_code text;
  v_resultat text;
  v_explication text;
  v_verifie_at timestamptz;
  v_ordre integer := 0;
begin
  if not private.est_admin() then
    raise exception 'Accès administrateur requis';
  end if;
  if p_niveau not in ('informations_controlees', 'verifiee_teranga') then
    raise exception 'Niveau de contrôle invalide';
  end if;
  if nullif(trim(p_resume_public), '') is null then
    raise exception 'Un résumé public du contrôle est obligatoire';
  end if;
  if jsonb_typeof(p_elements) <> 'array' or jsonb_array_length(p_elements) = 0 then
    raise exception 'Au moins un élément contrôlé est obligatoire';
  end if;

  select * into v_annonce
  from public.annonces where workflow_id = p_annonce_id for update;

  if not found
     or v_annonce.version_publiee_id is null
     or not v_annonce.publication_autorisee
     or v_annonce.statut not in ('approuvee', 'publiee', 'retrait_demande') then
    raise exception 'Une annonce actuellement publiée est requise';
  end if;

  insert into public.controles_annonces (
    annonce_id, version_id, administrateur_id, niveau_attribue, resume_public
  ) values (
    p_annonce_id, v_annonce.version_publiee_id, (select auth.uid()),
    p_niveau, trim(p_resume_public)
  ) returning id into v_controle;

  for v_element in select value from jsonb_array_elements(p_elements)
  loop
    v_code := v_element->>'element_code';
    v_resultat := v_element->>'resultat';
    v_explication := v_element->>'explication_publique';
    v_verifie_at := coalesce((v_element->>'verifie_at')::timestamptz, now());

    if v_code not in (
      'identite_annonceur', 'existence_logement', 'localisation',
      'photos_correspondantes', 'prix_declare', 'caracteristiques',
      'disponibilite', 'droit_proposer_logement'
    ) or v_resultat not in ('confirme', 'non_confirme', 'non_applicable')
      or nullif(trim(v_explication), '') is null then
      raise exception 'Élément de contrôle invalide';
    end if;

    insert into public.elements_controles (
      controle_id, element_code, resultat,
      explication_publique, verifie_at, ordre
    ) values (
      v_controle, v_code, v_resultat,
      trim(v_explication), v_verifie_at, v_ordre
    );
    v_ordre := v_ordre + 1;
  end loop;

  if p_niveau = 'informations_controlees'
     and not exists (
       select 1 from public.elements_controles e
       where e.controle_id = v_controle and e.resultat = 'confirme'
     ) then
    raise exception 'Informations contrôlées exige au moins un élément confirmé';
  end if;

  if p_niveau = 'verifiee_teranga'
     and (
       select count(distinct e.element_code) <> 8
              or bool_or(e.resultat <> 'confirme')
       from public.elements_controles e
       where e.controle_id = v_controle
     ) then
    raise exception 'Vérifiée par Teranga Immo exige les huit éléments confirmés';
  end if;

  -- Cette mise à jour est volontairement indépendante de la publication.
  update public.annonces
  set niveau_controle = p_niveau
  where workflow_id = p_annonce_id;

  return v_controle;
end
$$;

-- Fonction privée : jamais accordée à anon/authenticated. L'opération est
-- réservée au service_role ou au SQL Editor administré.
create or replace function private.attribuer_role_admin(
  p_utilisateur_id uuid,
  p_motif text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ancien text;
begin
  if nullif(trim(p_motif), '') is null then
    raise exception 'Un motif est obligatoire';
  end if;

  select type_compte into v_ancien
  from public.profils where id = p_utilisateur_id for update;
  if not found then raise exception 'Profil introuvable'; end if;

  update public.profils set type_compte = 'admin'
  where id = p_utilisateur_id;

  insert into private.historique_roles (
    utilisateur_id, ancien_role, nouveau_role, motif, effectue_par
  ) values (
    p_utilisateur_id, v_ancien, 'admin', trim(p_motif), (select auth.uid())
  );
end
$$;

-- Rattachement explicite d'une annonce historique. Cette opération ne choisit
-- jamais automatiquement un propriétaire.
create or replace function private.rattacher_annonce_legacy(
  p_annonce_id uuid,
  p_annonceur_id uuid,
  p_confirmation text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_annonce public.annonces%rowtype;
begin
  if p_confirmation <> 'ANNONCEUR_IDENTIFIE_ET_VERIFIE' then
    raise exception 'Une confirmation explicite du rattachement est requise';
  end if;

  select type_compte into v_role
  from public.profils where id = p_annonceur_id;
  if v_role not in ('proprietaire', 'agence') then
    raise exception 'Le compte choisi doit être propriétaire ou agence';
  end if;

  select * into v_annonce
  from public.annonces where workflow_id = p_annonce_id for update;
  if not found then raise exception 'Annonce introuvable'; end if;
  if v_annonce.annonceur_id is not null
     and v_annonce.annonceur_id <> p_annonceur_id then
    raise exception 'Cette annonce est déjà rattachée à un autre compte';
  end if;

  update public.annonces
  set annonceur_id = p_annonceur_id,
      publication_autorisee = (
        statut in ('approuvee', 'publiee', 'retrait_demande')
        and version_publiee_id is not null
      )
  where workflow_id = p_annonce_id;

  update public.annonces_versions
  set created_by = p_annonceur_id
  where annonce_id = p_annonce_id and created_by is null;
end
$$;

-- Basculement final à appeler seulement après déploiement du repository Flutter
-- acceptant publiee/en_attente_controle. La phrase de confirmation est voulue.
create or replace function private.finaliser_statuts_v2(p_confirmation text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_confirmation <> 'FLUTTER_V2_DEPLOYE' then
    raise exception 'Le client Flutter compatible doit être déployé avant le basculement';
  end if;

  update public.annonces set statut = 'publiee' where statut = 'approuvee';
  update public.annonces set statut = 'en_attente_controle' where statut = 'en_attente';
  update private.configuration_mvp
  set statuts_v2_actifs = true, updated_at = now()
  where singleton;
end
$$;

revoke execute on function public.creer_annonce_brouillon(
  text,text,text,text,bigint,smallint,boolean,text,text,date
) from public, anon, authenticated;
revoke execute on function public.supprimer_mon_brouillon(uuid) from public, anon, authenticated;
revoke execute on function public.commencer_modification_annonce(uuid) from public, anon, authenticated;
revoke execute on function public.soumettre_annonce(uuid) from public, anon, authenticated;
revoke execute on function public.moderer_annonce(uuid,text,text,text) from public, anon, authenticated;
revoke execute on function public.demander_retrait_annonce(uuid,text,boolean,boolean) from public, anon, authenticated;
revoke execute on function public.traiter_demande_retrait(uuid,text,text) from public, anon, authenticated;
revoke execute on function public.enregistrer_controle_annonce(uuid,text,text,jsonb) from public, anon, authenticated;

grant execute on function public.creer_annonce_brouillon(
  text,text,text,text,bigint,smallint,boolean,text,text,date
) to authenticated;
grant execute on function public.supprimer_mon_brouillon(uuid) to authenticated;
grant execute on function public.commencer_modification_annonce(uuid) to authenticated;
grant execute on function public.soumettre_annonce(uuid) to authenticated;
grant execute on function public.moderer_annonce(uuid,text,text,text) to authenticated;
grant execute on function public.demander_retrait_annonce(uuid,text,boolean,boolean) to authenticated;
grant execute on function public.traiter_demande_retrait(uuid,text,text) to authenticated;
grant execute on function public.enregistrer_controle_annonce(uuid,text,text,jsonb) to authenticated;

revoke execute on function private.attribuer_role_admin(uuid,text)
  from public, anon, authenticated;
revoke execute on function private.finaliser_statuts_v2(text)
  from public, anon, authenticated;
revoke execute on function private.rattacher_annonce_legacy(uuid,uuid,text)
  from public, anon, authenticated;
grant execute on function private.attribuer_role_admin(uuid,text) to service_role;
grant execute on function private.finaliser_statuts_v2(text) to service_role;
grant execute on function private.rattacher_annonce_legacy(uuid,uuid,text) to service_role;

commit;

