# Teranga Immo — accueil en cours de validation

Prototype Flutter en français pour BK Technologies. Logements à louer à Dakar, données et visuels fictifs.

## Travail réalisé

- Logo original reçu et copié sans modification dans assets/brand/logo_original.png.
- Accueil adapté aux maquettes : vert foncé, doré, fond clair, Poppins, recherche et carte arrondie.
- Illustration fictive ImageGen : voir assets/homes/PROVENANCE.md pour la provenance et le prompt.
- Disposition mobile et ordinateur prévue dans le code.
- Autres pages esquissées avant la demande de validation de l’accueil, sans développement supplémentaire.
- Tests de navigation, recherche, détail et absence de débordement mobile préparés.

## État réel des vérifications — 19 septembre 2026

Le formatage Dart des trois fichiers réussit. Les commandes d’analyse et de test de l’outil Flutter ont été tentées mais échouent pendant son initialisation : CreateFile failed 5, puis ProcessException: Accès refusé, lorsque Dart crée les canaux Windows nécessaires au lancement de Git. Voir les journaux dans verification/.

Le SDK officiel Flutter 3.47.5 est préparé dans ../../work/f à partir des sources du tag GitHub et du moteur Dart officiel. Un instantané Git local permet son initialisation. Ce SDK est un outil de travail et ne fait pas partie du dépôt de l’application. Les dépendances de l’outil ont été téléchargées, mais l’environnement restreint empêche ses sous-processus. L’outil de permissions ne prend pas en charge les chemins de canaux Windows.

**Analyse, tests et démarrage Web non validés. Aucune capture de l’application exécutée. Aucun commit créé.**

## Vérifier et lancer depuis PowerShell

Depuis une fenêtre PowerShell normale, ouvrir ce dossier puis exécuter :

```powershell
& .\Verifier-et-lancer.ps1
```

Le script installe les dépendances officielles, exécute flutter analyze puis flutter test et lance Edge uniquement si les vérifications réussissent. Il s’arrête à la première erreur. Il peut télécharger les composants Flutter manquants. Conserver la fenêtre ouverte pendant la démonstration.

Si un SDK Flutter complet est installé ailleurs :

```powershell
& .\Verifier-et-lancer.ps1 -SdkPath 'C:\chemin\vers\flutter'
```

Sur un environnement Flutter configuré :

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d edge --web-port 8765
```

## Prochaine validation

Après lancement, capturer l’accueil et obtenir son retour visuel avant de développer les autres pages. Web est la cible actuelle ; Android n’est pas préparé. Aucune connexion Supabase ni donnée de production.

Le dépôt Git local est sur main, sans dépôt distant confirmé. L’identité Git reste à renseigner avant le premier commit.
