-- Teranga Immo - audit préalable en lecture seule.
-- Exécuter séparément et conserver les résultats AVANT toute migration.
-- Ce fichier ne modifie aucune donnée ni aucun objet de la base.

select current_database() as base,
       current_user as utilisateur_sql,
       current_setting('server_version') as version_postgresql;

select table_schema, table_name
from information_schema.tables
where table_schema in ('public', 'storage')
  and table_name in (
    'annonces', 'profils', 'contacts_annonces', 'photos_annonces',
    'favoris', 'moderations_annonces', 'controles_annonces',
    'elements_controles', 'demandes_retrait', 'annonces_versions',
    'annonces_versions_photos'
  )
order by table_schema, table_name;

select table_name, ordinal_position, column_name, data_type,
       udt_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('annonces', 'profils')
order by table_name, ordinal_position;

select conrelid::regclass as table_concernee,
       conname as contrainte,
       pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid in (
  to_regclass('public.annonces'),
  to_regclass('public.profils')
)
order by conrelid::regclass::text, conname;

select c.oid::regclass as table_concernee,
       c.relrowsecurity as rls_active,
       c.relforcerowsecurity as rls_forcee
from pg_class c
where c.oid in (
  to_regclass('public.annonces'),
  to_regclass('public.profils')
);

select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname in ('public', 'storage')
  and tablename in ('annonces', 'profils', 'objects')
order by schemaname, tablename, policyname;

select statut, count(*) as nombre
from public.annonces
group by statut
order by statut;

select count(*) as nombre_total_annonces from public.annonces;

select grantee, table_schema, table_name, privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in ('annonces', 'profils')
  and grantee in ('anon', 'authenticated', 'public')
order by table_name, grantee, privilege_type;

