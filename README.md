# Teranga Immo — connexion Supabase

Application Flutter en français pour BK Technologies. La configuration Supabase active la lecture des annonces approuvées. Sans configuration, le prototype de démonstration reste disponible.

## Configuration locale

`config/supabase.local.json` contient uniquement l’URL du projet et sa clé publique publishable. Ce fichier est exclu de Git par `config/*.local.json` et ne figure pas dans les assets Flutter. Le modèle partageable est `config/supabase.example.json`.

```sh
flutter pub get
flutter analyze
flutter test --dart-define-from-file=config/supabase.local.json
flutter run -d edge --web-port 8765 --dart-define-from-file=config/supabase.local.json
```

Les paramètres sont lus avec `String.fromEnvironment`. Le fichier est chargé à la compilation, pas au démarrage depuis les assets. Après modification, relancer complètement l’application. Une clé publique embarquée reste accessible dans l’application ; ne jamais utiliser de clé secrète ou service_role.

## Lecture des annonces

- Source : `public.annonces`, uniquement les sept colonnes existantes.
- Filtre obligatoire côté requête : `statut = 'approuvee'`, également vérifié avant affichage.
- Filtres de ville, quartier, type et loyer maximum ; jusqu’à 100 annonces, des plus récentes aux plus anciennes.
- Messages de chargement, absence de résultats et erreur avec nouvelle tentative. Les réponses périmées d’une précédente recherche sont ignorées.
- Accueil, résultats et détail utilisent les données reçues. Aucune annonce, photo ou caractéristique fictive n’est utilisée en mode connecté, y compris après une erreur ou une configuration partielle.
- Photos, chambres, description, disponibilité et contact : non renseignés tant que ces données ne figurent pas dans la table. Le filtre chambres est désactivé en mode connecté.
- Le statut approuvé autorise la publication ; il n’est pas présenté comme une vérification sur place.

Le filtre de l’application ne remplace pas la sécurité RLS de Supabase. Les règles de la base doivent réserver la lecture publique aux annonces approuvées. Aucune migration, écriture ou modification des règles Supabase n’a été effectuée.

## Travail réalisé

- Logo original reçu et copié sans modification dans assets/brand/logo_original.png.
- Accueil adapté aux maquettes : vert foncé, doré, fond clair, Poppins, recherche et carte arrondie.
- Illustration fictive ImageGen : voir assets/homes/PROVENANCE.md pour la provenance et le prompt.
- Disposition mobile et ordinateur prévue dans le code.
- Autres pages esquissées avant la demande de validation de l’accueil, sans développement supplémentaire.
- Tests de navigation, recherche, détail et absence de débordement mobile préparés.

## Vérifications

Avant cette intégration, les journaux du 20 septembre confirment quatre tests réussis et une analyse sans anomalie. La suite a été étendue pour vérifier les requêtes filtrées, les champs manquants, les erreurs API et les états connectés sans repli vers les données fictives. Ces tests utilisent des réponses contrôlées, sans écrire dans Supabase.

Le SDK officiel Flutter 3.47.5 est préparé dans ../../work/f à partir des sources du tag GitHub et du moteur Dart officiel. Un instantané Git local permet son initialisation. Ce SDK est un outil de travail et ne fait pas partie du dépôt de l’application. Les dépendances de l’outil ont été téléchargées, mais l’environnement restreint empêche ses sous-processus. L’outil de permissions ne prend pas en charge les chemins de canaux Windows.

Les nouvelles commandes et leurs résultats sont consignés dans `verification/`. Ne pas confondre les anciens journaux réussis avec la vérification de cette intégration. Aucun nouveau commit n’est créé.

## Vérifier et lancer depuis PowerShell

Depuis une fenêtre PowerShell normale, ouvrir ce dossier puis exécuter :

```powershell
& .\Verifier-et-lancer.ps1
```

Le script installe les dépendances officielles, exécute flutter analyze puis flutter test et lance Edge uniquement si les vérifications réussissent. Il s’arrête à la première erreur. Il peut télécharger les composants Flutter manquants. Conserver la fenêtre ouverte pendant la démonstration.

Il transmet automatiquement `--dart-define-from-file` aux tests et au lancement Web. Pour vérifier sans lancer Edge : `& .\Verifier-et-lancer.ps1 -VerificationSeulement`. Les journaux datés sont écrits en UTF-8, y compris sous Windows PowerShell 5.

Si un SDK Flutter complet est installé ailleurs :

```powershell
& .\Verifier-et-lancer.ps1 -SdkPath 'C:\chemin\vers\flutter'
```

Sur un environnement Flutter configuré :

```sh
flutter pub get
flutter analyze
flutter test --dart-define-from-file=config/supabase.local.json
flutter run -d edge --web-port 8765 --dart-define-from-file=config/supabase.local.json
```

## Prochaine validation

Web est la cible actuelle ; Android n’est pas préparé. L’authentification, la publication et la modération ne sont pas implémentées à cette étape.

Le dépôt Git local est conservé en l’état, sans nouveau commit pour cette intégration.
