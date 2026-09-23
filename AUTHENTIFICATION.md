# Comptes Teranga Immo

## Code développé

Inscription email/mot de passe, choix propriétaire/agence, confirmation et renvoi
d'email, connexion/déconnexion, demande de récupération et nouveau mot de passe.
L'onglet Profil permet de compléter puis modifier ses propres informations.
Le thème Flutter existant est réutilisé ; la lecture des annonces reste publique.
Le SDK conserve et renouvelle la session dans son stockage local prévu pour le Web.
Les mots de passe ne sont ni stockés dans profils ni journalisés par l'application.

Le profil est créé lors de son premier enregistrement après connexion. Les champs
de l'inscription préremplissent ce formulaire via les métadonnées Auth ; ces
métadonnées ne confèrent aucun droit. Il n'existe aucun rôle administrateur dans
ce modèle. Le type agence est déclaratif, sans validation professionnelle implicite.

## Supabase : actions manuelles encore nécessaires

1. Examiner puis exécuter `supabase/profils.sql` dans le SQL Editor. Ce script
   crée une nouvelle table ; il échoue volontairement si elle existe déjà.
   Aucune requête SQL n'a été exécutée à distance pendant ce développement.
2. Activer les inscriptions email/mot de passe et la confirmation d'email dans
   Supabase Auth. Fixer une longueur minimale de 8 caractères ou plus.
3. Configurer Site URL et Redirect URLs. Pour le lancement local prévu :
   `http://localhost:8765/` et `http://localhost:8765/?auth=recovery`.
   Ajouter les équivalents HTTPS du futur domaine une fois choisi.
   L'application utilise son URL courante, sans query/fragment, pour le retour.
4. Configurer un expéditeur SMTP de production et vérifier les modèles et limites
   d'envoi. Les limites du service de test Supabase ne conviennent pas à tous
   les destinataires. Ne pas intégrer d'identifiants SMTP dans Flutter.
5. Vérifier les privilèges et politiques de `authenticated` sur `annonces` avant
   d'ouvrir les inscriptions au public. Le script profils n'accorde aucun droit
   sur annonces et ne touche pas aux droits administratifs existants.

Avec le flux PKCE du SDK, ouvrir les liens dans le navigateur ayant initié la
demande. Un lien expiré ou ouvert sans son contexte doit être redemandé.

## Vérifications

Ne pas confondre les 11 tests de consultation précédemment validés avec la suite
étendue d'authentification. Les nouveaux tests simulent Supabase sans créer de
compte, envoyer d'email ou modifier les données distantes.

```powershell
.\Verifier-et-lancer.ps1 -VerificationSeulement
```

Puis vérifier avec deux comptes réels distincts après configuration :

- Inscription propriétaire et agence, confirmation et renvoi d'email.
- Connexion, rechargement du navigateur, déconnexion.
- Récupération du mot de passe via email, changement, lien invalide/expiré.
- Création et modification du profil ; accès au profil d'autrui refusé.
- Lecture anonyme des profils refusée ; type administrateur rejeté.
- Lecture des annonces approuvées accessible connecté ou déconnecté.

L'outil Flutter de cet environnement échoue au lancement de sous-processus Windows
avec `CreateFile failed 5` (code 255). Les nouvelles vérifications complètes
doivent être confirmées sur la machine locale. Voir les journaux ignorés dans
`verification/`. Aucun commit ni déploiement n'a été effectué pour cette étape.

## Étapes suivantes

Publication d'annonces, rattachement à un propriétaire, photos, favoris,
modération et administration restent des fonctionnalités séparées à développer.
Les agences disposent ici d'un compte individuel, pas encore d'équipes multi-utilisateurs.
