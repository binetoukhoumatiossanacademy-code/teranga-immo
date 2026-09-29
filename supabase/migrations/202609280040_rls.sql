-- Teranga Immo - privilèges SQL et politiques RLS.
-- Les opérations sensibles restent interdites en accès direct et passeront
-- par les fonctions métier de la migration suivante.

begin;

alter table public.profils enable row level security;
alter table public.annonces enable row level security;
alter table public.annonces_versions enable row level security;
alter table public.contacts_annonces enable row level security;
alter table public.photos_annonces enable row level security;
alter table public.annonces_versions_photos enable row level security;
alter table public.favoris enable row level security;
alter table public.moderations_annonces enable row level security;
alter table public.controles_annonces enable row level security;
alter table public.elements_controles enable row level security;
alter table public.demandes_retrait enable row level security;

revoke all on table public.profils from public, anon, authenticated;
revoke all on table public.annonces from public, anon, authenticated;
revoke all on table public.annonces_versions from public, anon, authenticated;
revoke all on table public.contacts_annonces from public, anon, authenticated;
revoke all on table public.photos_annonces from public, anon, authenticated;
revoke all on table public.annonces_versions_photos from public, anon, authenticated;
revoke all on table public.favoris from public, anon, authenticated;
revoke all on table public.moderations_annonces from public, anon, authenticated;
revoke all on table public.controles_annonces from public, anon, authenticated;
revoke all on table public.elements_controles from public, anon, authenticated;
revoke all on table public.demandes_retrait from public, anon, authenticated;
revoke all on table private.notes_moderation_internes from public, anon, authenticated;

-- REVOKE ALL sur une table ne retire pas nécessairement d'anciens droits
-- accordés colonne par colonne. Nettoyer explicitement tous les ACL de
-- colonnes avant de réattribuer la liste minimale ci-dessous.
do $$
declare
  v_table record;
begin
  for v_table in
    select n.nspname as schema_name,
           c.relname as table_name,
           string_agg(format('%I', a.attname), ', ' order by a.attnum) as columns_list
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid
    where c.oid in (
      'public.profils'::regclass,
      'public.annonces'::regclass,
      'public.annonces_versions'::regclass,
      'public.contacts_annonces'::regclass,
      'public.photos_annonces'::regclass,
      'public.annonces_versions_photos'::regclass,
      'public.favoris'::regclass,
      'public.moderations_annonces'::regclass,
      'public.controles_annonces'::regclass,
      'public.elements_controles'::regclass,
      'public.demandes_retrait'::regclass,
      'private.notes_moderation_internes'::regclass
    )
      and a.attnum > 0
      and not a.attisdropped
    group by n.nspname, c.relname
  loop
    execute format(
      'revoke all privileges (%s) on table %I.%I from public, anon, authenticated',
      v_table.columns_list,
      v_table.schema_name,
      v_table.table_name
    );
  end loop;
end
$$;

-- La création et la suppression des annonces passent par les fonctions
-- métier. Aucun rôle client n'a besoin d'accéder à la séquence historique.
do $$
declare
  v_sequence text;
begin
  v_sequence := pg_get_serial_sequence('public.annonces', 'id');
  if v_sequence is not null then
    execute format(
      'revoke all privileges on sequence %s from public, anon, authenticated',
      to_regclass(v_sequence)
    );
  end if;
end
$$;

grant select (
  id, created_at, type_logement, ville, quartier, loyer_mensuel, statut,
  workflow_id, region, nombre_chambres, est_meuble, description,
  mode_disponibilite, disponible_a_partir, niveau_controle,
  premium_actif, premium_debut_at, premium_fin_at, published_at
) on public.annonces to anon;
grant select on table public.annonces to authenticated;
grant select on table public.profils to authenticated;
grant insert (id, type_compte, nom, nom_agence, telephone_whatsapp)
  on public.profils to authenticated;
-- type_compte reste présent pour que l'upsert Flutter actuel fonctionne si sa
-- valeur ne change pas. Le trigger bloque tout changement de rôle.
grant update (id, type_compte, nom, nom_agence, telephone_whatsapp)
  on public.profils to authenticated;

grant select on table public.annonces_versions to authenticated;
grant update (
  region, ville, quartier, type_logement, loyer_mensuel,
  nombre_chambres, est_meuble, description,
  mode_disponibilite, disponible_a_partir
) on public.annonces_versions to authenticated;

grant select, insert, delete on table public.contacts_annonces to authenticated;
grant update (
  nom_contact, type_contact, telephone_whatsapp, email_contact,
  appel_autorise, whatsapp_autorise
) on public.contacts_annonces to authenticated;
grant select on table public.photos_annonces to anon, authenticated;
grant insert, delete on table public.photos_annonces to authenticated;
grant select on table public.annonces_versions_photos to anon, authenticated;
grant insert, update, delete on table public.annonces_versions_photos to authenticated;
grant select, insert, delete on table public.favoris to authenticated;
grant select on table public.moderations_annonces to authenticated;
grant select on table public.controles_annonces to anon, authenticated;
grant select on table public.elements_controles to anon, authenticated;
grant select on table public.demandes_retrait to authenticated;

-- Profils : retirer les politiques historiques connues puis appliquer le rôle
-- unique et interdire admin à l'inscription.
drop policy if exists profils_lecture_personnelle on public.profils;
drop policy if exists profils_creation_personnelle on public.profils;
drop policy if exists profils_modification_personnelle on public.profils;
drop policy if exists profils_select_mvp on public.profils;
drop policy if exists profils_insert_mvp on public.profils;
drop policy if exists profils_update_mvp on public.profils;
drop policy if exists profils_select_guard_mvp on public.profils;
drop policy if exists profils_insert_guard_mvp on public.profils;
drop policy if exists profils_update_guard_mvp on public.profils;

create policy profils_select_guard_mvp
on public.profils as restrictive
for select to authenticated
using (id = (select auth.uid()) or private.est_admin());

create policy profils_insert_guard_mvp
on public.profils as restrictive
for insert to authenticated
with check (
  id = (select auth.uid())
  and type_compte in ('locataire', 'proprietaire', 'agence')
);

create policy profils_update_guard_mvp
on public.profils as restrictive
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy profils_select_mvp on public.profils
for select to authenticated
using (id = (select auth.uid()) or private.est_admin());

create policy profils_insert_mvp on public.profils
for insert to authenticated
with check (
  id = (select auth.uid())
  and type_compte in ('locataire', 'proprietaire', 'agence')
);

create policy profils_update_mvp on public.profils
for update to authenticated
using (id = (select auth.uid()))
with check (
  id = (select auth.uid())
  and type_compte in ('locataire', 'proprietaire', 'agence', 'admin')
);

-- Annonces : la politique restrictive neutralise une éventuelle ancienne
-- politique permissive trop large sans la supprimer silencieusement.
drop policy if exists annonces_select_mvp on public.annonces;
drop policy if exists annonces_select_guard_mvp on public.annonces;

create policy annonces_select_guard_mvp
on public.annonces as restrictive
for select to anon, authenticated
using (
  private.annonce_est_publique(workflow_id)
  or annonceur_id = (select auth.uid())
  or private.est_admin()
);

create policy annonces_select_mvp on public.annonces
for select to anon, authenticated
using (
  private.annonce_est_publique(workflow_id)
  or annonceur_id = (select auth.uid())
  or private.est_admin()
);

drop policy if exists annonces_versions_select_mvp on public.annonces_versions;
drop policy if exists annonces_versions_update_mvp on public.annonces_versions;

create policy annonces_versions_select_mvp on public.annonces_versions
for select to authenticated
using (private.possede_annonce(annonce_id) or private.est_admin());

create policy annonces_versions_update_mvp on public.annonces_versions
for update to authenticated
using (private.peut_modifier_version(id))
with check (private.peut_modifier_version(id));

drop policy if exists contacts_select_mvp on public.contacts_annonces;
drop policy if exists contacts_insert_mvp on public.contacts_annonces;
drop policy if exists contacts_update_mvp on public.contacts_annonces;
drop policy if exists contacts_delete_mvp on public.contacts_annonces;

create policy contacts_select_mvp on public.contacts_annonces
for select to authenticated
using (
  private.possede_annonce(annonce_id)
  or private.est_admin()
  or (
    private.role_courant() = 'locataire'
    and private.version_est_publique(version_id)
  )
);

create policy contacts_insert_mvp on public.contacts_annonces
for insert to authenticated
with check (
  private.possede_annonce(annonce_id)
  and private.peut_modifier_version(version_id)
  and type_contact = private.role_courant()
);

create policy contacts_update_mvp on public.contacts_annonces
for update to authenticated
using (private.peut_modifier_version(version_id))
with check (
  private.peut_modifier_version(version_id)
  and type_contact = private.role_courant()
);

create policy contacts_delete_mvp on public.contacts_annonces
for delete to authenticated
using (private.peut_modifier_version(version_id));

drop policy if exists photos_select_mvp on public.photos_annonces;
drop policy if exists photos_insert_mvp on public.photos_annonces;
drop policy if exists photos_delete_mvp on public.photos_annonces;

create policy photos_select_mvp on public.photos_annonces
for select to anon, authenticated
using (
  private.photo_est_publique(id)
  or private.possede_annonce(annonce_id)
  or private.est_admin()
);

create policy photos_insert_mvp on public.photos_annonces
for insert to authenticated
with check (
  created_by = (select auth.uid())
  and private.possede_annonce(annonce_id)
  and split_part(storage_path, '/', 1) = (select auth.uid())::text
  and split_part(storage_path, '/', 2) = annonce_id::text
);

create policy photos_delete_mvp on public.photos_annonces
for delete to authenticated
using (
  private.possede_annonce(annonce_id)
  and not private.photo_est_publique(id)
);

drop policy if exists versions_photos_select_mvp on public.annonces_versions_photos;
drop policy if exists versions_photos_insert_mvp on public.annonces_versions_photos;
drop policy if exists versions_photos_update_mvp on public.annonces_versions_photos;
drop policy if exists versions_photos_delete_mvp on public.annonces_versions_photos;

create policy versions_photos_select_mvp on public.annonces_versions_photos
for select to anon, authenticated
using (
  private.version_est_publique(version_id)
  or private.peut_modifier_version(version_id)
  or private.est_admin()
);

create policy versions_photos_insert_mvp on public.annonces_versions_photos
for insert to authenticated
with check (private.peut_modifier_version(version_id));

create policy versions_photos_update_mvp on public.annonces_versions_photos
for update to authenticated
using (private.peut_modifier_version(version_id))
with check (private.peut_modifier_version(version_id));

create policy versions_photos_delete_mvp on public.annonces_versions_photos
for delete to authenticated
using (private.peut_modifier_version(version_id));

drop policy if exists favoris_select_mvp on public.favoris;
drop policy if exists favoris_insert_mvp on public.favoris;
drop policy if exists favoris_delete_mvp on public.favoris;

create policy favoris_select_mvp on public.favoris
for select to authenticated
using (utilisateur_id = (select auth.uid()));

create policy favoris_insert_mvp on public.favoris
for insert to authenticated
with check (
  utilisateur_id = (select auth.uid())
  and private.role_courant() = 'locataire'
  and private.annonce_est_publique(annonce_id)
);

create policy favoris_delete_mvp on public.favoris
for delete to authenticated
using (utilisateur_id = (select auth.uid()));

drop policy if exists moderations_select_mvp on public.moderations_annonces;
create policy moderations_select_mvp on public.moderations_annonces
for select to authenticated
using (private.possede_annonce(annonce_id) or private.est_admin());

drop policy if exists controles_select_mvp on public.controles_annonces;
create policy controles_select_mvp on public.controles_annonces
for select to anon, authenticated
using (
  private.version_est_publique(version_id)
  or private.possede_annonce(annonce_id)
  or private.est_admin()
);

drop policy if exists elements_controles_select_mvp on public.elements_controles;
create policy elements_controles_select_mvp on public.elements_controles
for select to anon, authenticated
using (
  exists (
    select 1
    from public.controles_annonces c
    where c.id = elements_controles.controle_id
      and (
        private.version_est_publique(c.version_id)
        or private.possede_annonce(c.annonce_id)
        or private.est_admin()
      )
  )
);

drop policy if exists demandes_retrait_select_mvp on public.demandes_retrait;
create policy demandes_retrait_select_mvp on public.demandes_retrait
for select to authenticated
using (demandeur_id = (select auth.uid()) or private.est_admin());

commit;

