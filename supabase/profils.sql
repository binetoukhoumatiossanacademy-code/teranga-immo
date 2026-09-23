-- À examiner puis exécuter dans le SQL Editor avec le rôle postgres.
-- Non exécuté par l'application. Création initiale : s'arrête si profils existe.
begin;

create table public.profils (
  id uuid primary key references auth.users(id) on delete cascade,
  type_compte text not null check (type_compte in ('proprietaire', 'agence')),
  nom text not null check (char_length(trim(nom)) between 1 and 120),
  nom_agence text,
  created_at timestamptz not null default now(),
  constraint agence_nom_valide check (
    (type_compte = 'proprietaire' and nom_agence is null)
    or (type_compte = 'agence' and
        nom_agence is not null and char_length(trim(nom_agence)) between 1 and 160)
  )
);

alter table public.profils enable row level security;
revoke all on table public.profils from public, anon, authenticated;
grant select on table public.profils to authenticated;
grant insert (id, type_compte, nom, nom_agence)
  on public.profils to authenticated;
-- L'upsert envoie id ; RLS interdit tout changement de propriétaire.
grant update (id, type_compte, nom, nom_agence)
  on public.profils to authenticated;

create policy profils_lecture_personnelle on public.profils
  for select to authenticated using ((select auth.uid()) = id);
create policy profils_creation_personnelle on public.profils
  for insert to authenticated with check ((select auth.uid()) = id);
create policy profils_modification_personnelle on public.profils
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Aucun rôle administrateur dans cette table. Le type de compte
-- est descriptif et n'accorde aucun privilège sur les annonces.
-- Aucune politique DELETE, aucun droit de suppression utilisateur.
-- Les droits des rôles administratifs et public.annonces restent inchangés.
commit;

-- Contrôles : trois politiques personnelles ; aucun droit pour anon.
select policyname, roles, cmd, qual, with_check from pg_policies
where schemaname = 'public' and tablename = 'profils';
select
  has_table_privilege('anon', 'public.profils', 'SELECT') as anon_lecture,
  has_any_column_privilege('anon', 'public.profils', 'INSERT') as anon_ajout,
  has_any_column_privilege('anon', 'public.profils', 'UPDATE') as anon_modification,
  has_table_privilege('anon', 'public.profils', 'DELETE') as anon_suppression;
