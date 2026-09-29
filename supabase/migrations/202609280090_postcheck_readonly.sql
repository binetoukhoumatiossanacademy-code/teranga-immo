-- Teranga Immo - contrôle final strictement en lecture seule.
-- Ce fichier ne crée, ne modifie et ne supprime aucun objet ni aucune donnée.

-- 1. Présence des tables attendues.
with tables_attendues(schema_name, table_name) as (
  values
    ('public', 'profils'),
    ('public', 'annonces'),
    ('public', 'annonces_versions'),
    ('public', 'contacts_annonces'),
    ('public', 'photos_annonces'),
    ('public', 'annonces_versions_photos'),
    ('public', 'favoris'),
    ('public', 'moderations_annonces'),
    ('public', 'controles_annonces'),
    ('public', 'elements_controles'),
    ('public', 'demandes_retrait'),
    ('private', 'notes_moderation_internes'),
    ('private', 'configuration_mvp'),
    ('private', 'historique_roles')
)
select
  t.schema_name,
  t.table_name,
  to_regclass(format('%I.%I', t.schema_name, t.table_name)) is not null as existe
from tables_attendues t
order by t.schema_name, t.table_name;

-- 2. Colonnes réelles des tables métier.
select
  c.table_schema,
  c.table_name,
  c.ordinal_position,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default,
  c.is_identity
from information_schema.columns c
where c.table_schema in ('public', 'private')
  and c.table_name in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
order by c.table_schema, c.table_name, c.ordinal_position;

-- 3. Contraintes, définition et état de validation.
select
  n.nspname as schema_name,
  c.relname as table_name,
  con.conname as contrainte,
  case con.contype
    when 'p' then 'PRIMARY KEY'
    when 'f' then 'FOREIGN KEY'
    when 'u' then 'UNIQUE'
    when 'c' then 'CHECK'
    when 'x' then 'EXCLUSION'
    else con.contype::text
  end as type_contrainte,
  con.convalidated as validee,
  pg_get_constraintdef(con.oid, true) as definition
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public', 'private')
  and c.relname in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
order by n.nspname, c.relname, con.conname;

-- Ce résultat doit être vide après validate_after_backfill.
select
  n.nspname as schema_name,
  c.relname as table_name,
  con.conname as contrainte_non_validee
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public', 'private')
  and not con.convalidated
order by n.nspname, c.relname, con.conname;

-- 4. Index des tables métier.
select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname in ('public', 'private')
  and tablename in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
order by schemaname, tablename, indexname;

-- 5. État RLS. Toutes les tables public ci-dessous doivent avoir RLS actif.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_active,
  c.relforcerowsecurity as rls_forcee
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('r', 'p')
  and n.nspname in ('public', 'private')
  and c.relname in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
order by n.nspname, c.relname;

-- Ce résultat doit être vide.
select c.relname as table_public_sans_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
  and c.relname in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait'
  )
  and not c.relrowsecurity
order by c.relname;

-- 6. Politiques RLS métier et Storage.
select
  p.schemaname,
  p.tablename,
  p.policyname,
  p.permissive,
  p.roles,
  p.cmd,
  p.qual,
  p.with_check
from pg_policies p
where (p.schemaname = 'public' and p.tablename in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait'
  ))
  or (p.schemaname = 'storage' and p.tablename = 'objects'
      and p.policyname like 'teranga_photos_%')
order by p.schemaname, p.tablename, p.policyname;

-- 7. Privilèges de table effectivement accordés aux rôles clients.
select
  g.table_schema,
  g.table_name,
  g.grantee,
  string_agg(g.privilege_type, ', ' order by g.privilege_type) as privileges
from information_schema.role_table_grants g
where g.grantee in ('anon', 'authenticated')
  and g.table_schema in ('public', 'private')
  and g.table_name in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
group by g.table_schema, g.table_name, g.grantee
order by g.table_schema, g.table_name, g.grantee;

-- Privilèges de colonnes : permet de vérifier les listes blanches UPDATE/INSERT.
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type,
  string_agg(g.column_name, ', ' order by c.ordinal_position) as colonnes
from information_schema.column_privileges g
join information_schema.columns c
  on c.table_schema = g.table_schema
 and c.table_name = g.table_name
 and c.column_name = g.column_name
where g.grantee in ('anon', 'authenticated')
  and g.table_schema in ('public', 'private')
  and g.table_name in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
group by g.table_schema, g.table_name, g.grantee, g.privilege_type
order by g.table_schema, g.table_name, g.grantee, g.privilege_type;

-- Privilèges sensibles effectifs, y compris ceux hérités de PUBLIC.
-- Toute ligne est une anomalie à corriger.
with tables_controlees(schema_name, table_name) as (
  values
    ('public', 'profils'), ('public', 'annonces'),
    ('public', 'annonces_versions'), ('public', 'contacts_annonces'),
    ('public', 'photos_annonces'), ('public', 'annonces_versions_photos'),
    ('public', 'favoris'), ('public', 'moderations_annonces'),
    ('public', 'controles_annonces'), ('public', 'elements_controles'),
    ('public', 'demandes_retrait'),
    ('private', 'notes_moderation_internes'),
    ('private', 'configuration_mvp'), ('private', 'historique_roles')
), roles_controles(role_name) as (
  values ('anon'), ('authenticated')
), privileges_controles(privilege_name) as (
  values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')
), droits_effectifs as (
  select
    t.schema_name,
    t.table_name,
    r.role_name,
    p.privilege_name,
    has_table_privilege(
      r.role_name,
      format('%I.%I', t.schema_name, t.table_name),
      p.privilege_name
    ) as possede
  from tables_controlees t
  cross join roles_controles r
  cross join privileges_controles p
  where to_regclass(format('%I.%I', t.schema_name, t.table_name)) is not null
)
select schema_name, table_name, role_name, privilege_name
from droits_effectifs
where possede
  and (
    privilege_name in ('TRUNCATE', 'REFERENCES', 'TRIGGER')
    or role_name = 'anon'
    or schema_name = 'private'
    or (table_name in (
      'annonces', 'moderations_annonces', 'controles_annonces',
      'elements_controles', 'demandes_retrait'
    ) and privilege_name in ('INSERT', 'UPDATE', 'DELETE'))
  )
order by schema_name, table_name, role_name, privilege_name;

-- Toute ligne est une anomalie sensible à analyser avant de continuer.
select
  g.table_schema,
  g.table_name,
  g.grantee,
  g.privilege_type as privilege_inattendu
from information_schema.role_table_grants g
where g.grantee in ('anon', 'authenticated')
  and g.table_schema in ('public', 'private')
  and g.table_name in (
    'profils', 'annonces', 'annonces_versions', 'contacts_annonces',
    'photos_annonces', 'annonces_versions_photos', 'favoris',
    'moderations_annonces', 'controles_annonces', 'elements_controles',
    'demandes_retrait', 'notes_moderation_internes',
    'configuration_mvp', 'historique_roles'
  )
  and (
    g.privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')
    or (g.grantee = 'anon' and g.privilege_type <> 'SELECT')
    or (g.table_schema = 'private')
    or (g.table_name in (
      'annonces', 'moderations_annonces', 'controles_annonces',
      'elements_controles', 'demandes_retrait'
    ) and g.privilege_type in ('INSERT', 'UPDATE', 'DELETE'))
  )
order by g.table_schema, g.table_name, g.grantee, g.privilege_type;

-- Aucun rôle client ne doit utiliser directement la séquence bigint historique.
select
  r.rolname as role_name,
  has_sequence_privilege(r.rolname, 'public.annonces_id_seq', 'USAGE') as usage,
  has_sequence_privilege(r.rolname, 'public.annonces_id_seq', 'SELECT') as select_sequence,
  has_sequence_privilege(r.rolname, 'public.annonces_id_seq', 'UPDATE') as update_sequence
from pg_roles r
where r.rolname in ('anon', 'authenticated')
  and to_regclass('public.annonces_id_seq') is not null
order by r.rolname;

-- 8. Fonctions installées, type de sécurité et search_path.
select
  n.nspname as schema_name,
  p.proname as fonction,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_userbyid(p.proowner) as proprietaire,
  p.prosecdef as security_definer,
  p.provolatile as volatilite,
  p.proconfig as configuration
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where (n.nspname = 'private' and p.proname in (
    'role_courant', 'est_admin', 'possede_annonce',
    'peut_modifier_version', 'version_est_publique',
    'annonce_est_publique', 'photo_est_publique', 'photo_est_protegee',
    'set_updated_at', 'proteger_role_profil', 'verifier_photo_version',
    'attribuer_role_admin', 'rattacher_annonce_legacy',
    'finaliser_statuts_v2', 'storage_annonce_id',
    'storage_objet_appartient_utilisateur', 'storage_objet_est_public',
    'storage_objet_peut_etre_supprime'
  ))
  or (n.nspname = 'public' and p.proname in (
    'creer_annonce_brouillon', 'supprimer_mon_brouillon',
    'commencer_modification_annonce', 'soumettre_annonce',
    'moderer_annonce', 'demander_retrait_annonce',
    'traiter_demande_retrait', 'enregistrer_controle_annonce'
  ))
order by n.nspname, p.proname, pg_get_function_identity_arguments(p.oid);

-- Matrice attendue des droits EXECUTE.
with fonctions_attendues(signature, anon_execute, authenticated_execute, service_execute) as (
  values
    ('private.role_courant()', false, true, null::boolean),
    ('private.est_admin()', true, true, null::boolean),
    ('private.possede_annonce(uuid)', true, true, null::boolean),
    ('private.peut_modifier_version(uuid)', true, true, null::boolean),
    ('private.version_est_publique(uuid)', true, true, null::boolean),
    ('private.annonce_est_publique(uuid)', true, true, null::boolean),
    ('private.photo_est_publique(uuid)', true, true, null::boolean),
    ('private.photo_est_protegee(uuid)', false, true, null::boolean),
    ('private.set_updated_at()', false, false, null::boolean),
    ('private.proteger_role_profil()', false, false, null::boolean),
    ('private.verifier_photo_version()', false, false, null::boolean),
    ('private.storage_annonce_id(text)', false, false, null::boolean),
    ('private.storage_objet_appartient_utilisateur(text)', true, true, null::boolean),
    ('private.storage_objet_est_public(text)', true, true, null::boolean),
    ('private.storage_objet_peut_etre_supprime(text)', false, true, null::boolean),
    ('public.creer_annonce_brouillon(text,text,text,text,bigint,smallint,boolean,text,text,date)', false, true, null::boolean),
    ('public.supprimer_mon_brouillon(uuid)', false, true, null::boolean),
    ('public.commencer_modification_annonce(uuid)', false, true, null::boolean),
    ('public.soumettre_annonce(uuid)', false, true, null::boolean),
    ('public.moderer_annonce(uuid,text,text,text)', false, true, null::boolean),
    ('public.demander_retrait_annonce(uuid,text,boolean,boolean)', false, true, null::boolean),
    ('public.traiter_demande_retrait(uuid,text,text)', false, true, null::boolean),
    ('public.enregistrer_controle_annonce(uuid,text,text,jsonb)', false, true, null::boolean),
    ('private.attribuer_role_admin(uuid,text)', false, false, true),
    ('private.rattacher_annonce_legacy(uuid,uuid,text)', false, false, true),
    ('private.finaliser_statuts_v2(text)', false, false, true)
), droits as (
  select
    f.*,
    to_regprocedure(f.signature) as fonction_oid
  from fonctions_attendues f
)
select
  d.signature,
  d.fonction_oid is not null as existe,
  d.anon_execute as anon_attendu,
  case when d.fonction_oid is null then null
       else has_function_privilege('anon', d.fonction_oid, 'EXECUTE') end as anon_reel,
  d.authenticated_execute as authenticated_attendu,
  case when d.fonction_oid is null then null
       else has_function_privilege('authenticated', d.fonction_oid, 'EXECUTE') end as authenticated_reel,
  d.service_execute as service_attendu,
  case when d.fonction_oid is null or d.service_execute is null then null
       else has_function_privilege('service_role', d.fonction_oid, 'EXECUTE') end as service_reel
from droits d
order by d.signature;

-- Toute ligne signale une fonction SECURITY DEFINER sans search_path vide.
select
  n.nspname as schema_name,
  p.proname as fonction,
  pg_get_function_identity_arguments(p.oid) as arguments,
  p.proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where p.prosecdef
  and n.nspname in ('public', 'private')
  and p.proname in (
    'role_courant', 'est_admin', 'possede_annonce', 'peut_modifier_version',
    'version_est_publique', 'annonce_est_publique', 'photo_est_publique',
    'photo_est_protegee', 'verifier_photo_version', 'attribuer_role_admin',
    'rattacher_annonce_legacy', 'finaliser_statuts_v2', 'storage_annonce_id',
    'storage_objet_appartient_utilisateur', 'storage_objet_est_public',
    'storage_objet_peut_etre_supprime', 'creer_annonce_brouillon',
    'supprimer_mon_brouillon', 'commencer_modification_annonce',
    'soumettre_annonce', 'moderer_annonce', 'demander_retrait_annonce',
    'traiter_demande_retrait', 'enregistrer_controle_annonce'
  )
  and not (coalesce(p.proconfig, array[]::text[]) @> array['search_path=""']::text[])
order by n.nspname, p.proname;

-- 9. Bucket privé : 8 Mo et formats autorisés.
select
  b.id,
  b.name,
  b.public,
  b.file_size_limit,
  b.allowed_mime_types,
  b.id = 'annonces-photos'
    and b.name = 'annonces-photos'
    and not b.public
    and b.file_size_limit = 8388608
    and b.allowed_mime_types @> array['image/jpeg', 'image/png', 'image/webp']::text[]
    and cardinality(b.allowed_mime_types) = 3 as configuration_attendue
from storage.buckets b
where b.id = 'annonces-photos';

-- Les huit politiques Teranga Storage attendues.
with politiques_attendues(policyname) as (
  values
    ('teranga_photos_select_guard'), ('teranga_photos_select'),
    ('teranga_photos_insert_guard'), ('teranga_photos_insert'),
    ('teranga_photos_update_guard'), ('teranga_photos_update'),
    ('teranga_photos_delete_guard'), ('teranga_photos_delete')
)
select
  a.policyname,
  p.policyname is not null as existe,
  p.permissive,
  p.roles,
  p.cmd,
  p.qual,
  p.with_check
from politiques_attendues a
left join pg_policies p
  on p.schemaname = 'storage'
 and p.tablename = 'objects'
 and p.policyname = a.policyname
order by a.policyname;

-- 10. État du basculement des statuts. Doit rester false avant finaliser_statuts_v2.
select singleton, statuts_v2_actifs, updated_at
from private.configuration_mvp
where singleton;

-- 11. Valeurs réellement présentes dans les statuts et niveaux de contrôle.
select 'annonces.statut' as champ, statut as valeur, count(*) as nombre
from public.annonces group by statut
union all
select 'annonces.niveau_controle', niveau_controle, count(*)
from public.annonces group by niveau_controle
union all
select 'annonces_versions.statut_version', statut_version, count(*)
from public.annonces_versions group by statut_version
union all
select 'moderations_annonces.decision', decision, count(*)
from public.moderations_annonces group by decision
union all
select 'demandes_retrait.statut', statut, count(*)
from public.demandes_retrait group by statut
union all
select 'controles_annonces.niveau_attribue', niveau_attribue, count(*)
from public.controles_annonces group by niveau_attribue
union all
select 'elements_controles.element_code', element_code, count(*)
from public.elements_controles group by element_code
union all
select 'elements_controles.resultat', resultat, count(*)
from public.elements_controles group by resultat
order by champ, valeur;

-- 12. Anomalies de workflow. Tous les compteurs doivent être à zéro.
select 'annonce publiée sans autorisation/version/annonceur' as controle, count(*) as anomalies
from public.annonces
where statut in ('approuvee', 'publiee', 'retrait_demande')
  and (not publication_autorisee or version_publiee_id is null or annonceur_id is null)
union all
select 'publication autorisée sur statut non public', count(*)
from public.annonces
where publication_autorisee
  and statut not in ('approuvee', 'publiee', 'retrait_demande')
union all
select 'premium incohérent', count(*)
from public.annonces
where (premium_actif and premium_fin_at is null)
   or (not premium_actif and premium_fin_at is not null)
   or (premium_debut_at is not null and premium_fin_at is not null
       and premium_fin_at <= premium_debut_at)
union all
select 'niveau contrôlé sans contrôle correspondant', count(*)
from public.annonces a
where a.niveau_controle in ('informations_controlees', 'verifiee_teranga')
  and not exists (
    select 1 from public.controles_annonces c
    where c.annonce_id = a.workflow_id
      and c.version_id = a.version_publiee_id
      and c.niveau_attribue = a.niveau_controle
  )
union all
select 'version de travail rattachée à une autre annonce', count(*)
from public.annonces a
join public.annonces_versions v on v.id = a.version_travail_id
where v.annonce_id <> a.workflow_id
union all
select 'version publiée rattachée à une autre annonce', count(*)
from public.annonces a
join public.annonces_versions v on v.id = a.version_publiee_id
where v.annonce_id <> a.workflow_id
union all
select 'photo rattachée à une version d une autre annonce', count(*)
from public.annonces_versions_photos vp
join public.annonces_versions v on v.id = vp.version_id
join public.photos_annonces p on p.id = vp.photo_id
where v.annonce_id <> p.annonce_id
union all
select 'photo principale multiple par version', count(*)
from (
  select version_id
  from public.annonces_versions_photos
  where est_principale
  group by version_id
  having count(*) > 1
) x
union all
select 'plus de dix photos par version', count(*)
from (
  select version_id
  from public.annonces_versions_photos
  group by version_id
  having count(*) > 10
) x
union all
select 'chemin Storage non conforme au propriétaire et à l annonce', count(*)
from public.photos_annonces p
join public.annonces a on a.workflow_id = p.annonce_id
where a.annonceur_id is not null
  and p.storage_path not like a.annonceur_id::text || '/' || a.workflow_id::text || '/%';

-- 13. Contrôle détaillé des niveaux Vérifiée par Teranga Immo.
-- Toute ligne indique un contrôle verifiee_teranga qui ne comporte pas
-- exactement les huit éléments attendus, tous confirmés.
select
  c.id as controle_id,
  c.annonce_id,
  count(distinct e.element_code) as elements_distincts,
  count(*) filter (where e.resultat = 'confirme') as elements_confirmes
from public.controles_annonces c
left join public.elements_controles e on e.controle_id = c.id
where c.niveau_attribue = 'verifiee_teranga'
group by c.id, c.annonce_id
having count(distinct e.element_code) <> 8
    or count(*) filter (where e.resultat = 'confirme') <> 8
order by c.id;

-- 14. Résumé des volumes après migration.
select 'profils' as objet, count(*) as nombre from public.profils
union all select 'annonces', count(*) from public.annonces
union all select 'annonces_versions', count(*) from public.annonces_versions
union all select 'contacts_annonces', count(*) from public.contacts_annonces
union all select 'photos_annonces', count(*) from public.photos_annonces
union all select 'favoris', count(*) from public.favoris
union all select 'moderations_annonces', count(*) from public.moderations_annonces
union all select 'controles_annonces', count(*) from public.controles_annonces
union all select 'demandes_retrait', count(*) from public.demandes_retrait
order by objet;
