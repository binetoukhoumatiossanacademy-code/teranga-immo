-- Teranga Immo - validation différée des contraintes.
-- Exécuter seulement lorsque les requêtes de vérification ne retournent plus
-- aucune ancienne donnée incompatible et que les annonceurs ont été rattachés.

begin;

alter table public.profils validate constraint profils_type_compte_mvp_check;
alter table public.profils validate constraint profils_nom_mvp_check;
alter table public.profils validate constraint profils_agence_nom_mvp_check;

alter table public.annonces validate constraint annonces_annonceur_id_fkey;
alter table public.annonces validate constraint annonces_type_logement_mvp_check;
alter table public.annonces validate constraint annonces_loyer_mvp_check;
alter table public.annonces validate constraint annonces_chambres_mvp_check;
alter table public.annonces validate constraint annonces_disponibilite_mvp_check;
alter table public.annonces validate constraint annonces_niveau_controle_mvp_check;
alter table public.annonces validate constraint annonces_statut_mvp_check;
alter table public.annonces validate constraint annonces_premium_dates_check;
alter table public.annonces validate constraint annonces_version_publiee_id_fkey;
alter table public.annonces validate constraint annonces_version_travail_id_fkey;

commit;

