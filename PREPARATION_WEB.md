# Préparation Web — proposition, non appliquée

Aucune publication ni modification Supabase effectuée.

## Constat

Les lectures anonymes de public.annonces répondent HTTP 200. Les requêtes
statut = approuvee et statut différent de approuvee (ou NULL) ne renvoient
aucune ligne visible. Ce résultat ne prouve ni l'activation RLS ni le refus
des écritures. Aucun POST, PATCH ou DELETE n'a été envoyé.

La clé publique seule ne permet pas d'inspecter les politiques administratives.
Les requêtes ci-dessous sont à exécuter dans le SQL Editor Supabase pour
transmettre leurs résultats, sans fournir de clé secrète.

## 1. Audit en lecture seule

```sql
select relrowsecurity as rls_active, relforcerowsecurity as rls_forcee
from pg_class where oid = 'public.annonces'::regclass;

select policyname, permissive, roles, cmd, qual, with_check
from pg_policies where schemaname = 'public' and tablename = 'annonces';

select
  has_table_privilege('anon', 'public.annonces', 'SELECT') as lecture,
  has_table_privilege('anon', 'public.annonces', 'INSERT') as ajout_table,
  has_any_column_privilege('anon', 'public.annonces', 'INSERT') as ajout_colonnes,
  has_table_privilege('anon', 'public.annonces', 'UPDATE') as modification_table,
  has_any_column_privilege('anon', 'public.annonces', 'UPDATE') as modification_colonnes,
  has_table_privilege('anon', 'public.annonces', 'DELETE') as suppression;
```

Les droits SQL et les politiques RLS doivent être examinés ensemble. Vérifier
aussi les vues et fonctions exposées qui pourraient donner un accès indirect
à annonces, notamment les fonctions SECURITY DEFINER. La proposition suivante
protège l'accès direct à la table pour les visiteurs non connectés (rôle anon).
Les futurs utilisateurs connectés (authenticated) nécessiteront un audit distinct.

## 2. Règles proposées — attendre validation de l'audit avant exécution

```sql
begin;

alter table public.annonces enable row level security;
grant select on table public.annonces to anon;
revoke insert, update, delete, truncate, references, trigger
  on table public.annonces from anon;

create policy teranga_anon_read_approved
  on public.annonces for select to anon
  using (statut = 'approuvee');

-- Empêche une ancienne règle permissive d'élargir la lecture publique.
create policy teranga_anon_read_guard
  on public.annonces as restrictive for select to anon
  using (statut = 'approuvee');

-- Bloque aussi les écritures si des droits sont hérités d'un autre rôle
-- ou accordés sur des colonnes. Aucune ancienne politique n'est supprimée.
create policy teranga_anon_no_insert
  on public.annonces as restrictive for insert to anon
  with check (false);
create policy teranga_anon_no_update
  on public.annonces as restrictive for update to anon
  using (false) with check (false);
create policy teranga_anon_no_delete
  on public.annonces as restrictive for delete to anon
  using (false);

commit;
```

Après l'audit, retirer également les éventuels droits d'écriture hérités de
PUBLIC et les droits accordés par colonne, en évaluant l'effet sur les autres
rôles. Vérifier l'absence de collisions avec les noms de politiques proposés.
Une ancienne politique restrictive peut continuer à limiter la lecture :
elle doit être examinée avant application. Ne pas supprimer globalement les
politiques existantes.

## 3. Validation après approbation

Appliquer uniquement le script validé, puis refaire l'audit. Tester sous le rôle
anon, avec des données contrôlées dans un environnement de test : annonce
approuvée visible, annonce en attente et statut NULL invisibles. Vérifier le
refus d'INSERT et l'impossibilité de modifier ou supprimer des lignes par
UPDATE/DELETE (ces opérations peuvent répondre sans erreur mais affecter zéro
ligne). Ne pas tester les écritures sur des annonces réelles en production.

## 4. Compilation et contrôle du contenu

Le fichier config/supabase.local.json contient uniquement SUPABASE_URL et
SUPABASE_PUBLISHABLE_KEY. Il est ignoré par Git, tout comme verification/.
Il n'est pas déclaré dans les assets Flutter. Aucune clé secrète détectée dans
lib/, web/, assets/ et le modèle de configuration.

La clé publique et l'URL sont volontairement intégrées au JavaScript compilé.
Le fichier JSON lui-même ne doit pas être publié. Ne jamais utiliser une clé
sb_secret ou service_role, un mot de passe de base ou un jeton administratif.
L'exclusion Git ne remplace pas le contrôle des fichiers effectivement déployés.

Après validation des règles :

```powershell
flutter analyze
flutter test --dart-define-from-file=config/supabase.local.json
flutter build web --release --dart-define-from-file=config/supabase.local.json
```

Inspecter le dossier build/web généré avant tout envoi : absence du JSON local,
de .env, de journaux, de .git et de clés secrètes. Cet artefact n'existe pas encore
et son audit reste donc à faire. Tester localement cette version compilée avec
Supabase configuré, sans repli vers les logements fictifs.

## 5. Publication ultérieure

Choisir l'hébergeur et le domaine avec le propriétaire. Présenter la version
compilée et le résultat des contrôles avant autorisation de publication.
Publier uniquement le contenu validé de build/web via HTTPS, jamais le dossier
du projet entier. Tester accueil, résultats, filtres et rechargement après
publication. Aucun hébergeur n'est configuré à ce stade.

Référence : https://supabase.com/docs/guides/database/postgres/row-level-security
