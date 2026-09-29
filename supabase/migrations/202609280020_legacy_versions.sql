-- Teranga Immo - création d'une version de référence pour les lignes existantes.
-- Ne supprime et ne publie aucune donnée. Une ancienne annonce reste publique
-- seulement si un annonceur réel a déjà été identifié.

begin;

insert into public.annonces_versions (
  annonce_id, numero_version, statut_version,
  region, ville, quartier, type_logement, loyer_mensuel,
  nombre_chambres, est_meuble, description,
  mode_disponibilite, disponible_a_partir,
  created_by, created_at, updated_at, submitted_at, published_at
)
select
  a.workflow_id,
  1,
  case
    when a.statut in ('approuvee', 'publiee', 'retrait_demande') then 'publiee'
    when a.statut in ('en_attente', 'en_attente_controle') then 'en_attente_controle'
    when a.statut = 'correction_demandee' then 'correction_demandee'
    when a.statut = 'refusee' then 'refusee'
    else 'brouillon'
  end,
  a.region, a.ville, a.quartier, a.type_logement, a.loyer_mensuel,
  a.nombre_chambres, a.est_meuble, a.description,
  a.mode_disponibilite, a.disponible_a_partir,
  a.annonceur_id,
  coalesce(a.created_at, now()),
  coalesce(a.updated_at, a.created_at, now()),
  case when a.statut in ('en_attente', 'en_attente_controle') then now() end,
  case when a.statut in ('approuvee', 'publiee', 'retrait_demande')
       then coalesce(a.published_at, a.created_at, now()) end
from public.annonces a
where not exists (
  select 1 from public.annonces_versions v
  where v.annonce_id = a.workflow_id
);

update public.annonces a
set version_publiee_id = v.id,
    version_travail_id = null,
    version_soumise = greatest(a.version_soumise, v.numero_version)
from public.annonces_versions v
where v.annonce_id = a.workflow_id
  and v.numero_version = 1
  and v.statut_version = 'publiee'
  and a.version_publiee_id is null;

update public.annonces a
set version_travail_id = v.id,
    version_soumise = greatest(a.version_soumise, v.numero_version)
from public.annonces_versions v
where v.annonce_id = a.workflow_id
  and v.numero_version = 1
  and v.statut_version <> 'publiee'
  and a.version_travail_id is null;

-- Une ligne historique n'est autorisée publiquement que lorsqu'un annonceur
-- réel est déjà rattaché. Aucun propriétaire n'est inventé par la migration.
update public.annonces
set publication_autorisee = true
where annonceur_id is not null
  and statut in ('approuvee', 'publiee', 'retrait_demande')
  and version_publiee_id is not null;

commit;

