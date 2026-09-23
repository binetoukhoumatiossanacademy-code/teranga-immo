# Compilation Web sur GitHub, sans publication

Le workflow `.github/workflows/web-preview.yml` s'exécute manuellement sur Linux.
Il analyse le code, lance les tests et compile uniquement si ces vérifications
réussissent. Il ne déploie rien et ne modifie pas Supabase.

## Préparation

Les changements locaux, y compris l'authentification et le workflow, doivent être
enregistrés dans un commit et envoyés au dépôt avant de pouvoir compiler cette version. Aucun
commit ni push n'a été réalisé pendant la préparation de ce workflow.

Dans le dépôt GitHub, ouvrir Settings > Secrets and variables > Actions > Variables.
Créer deux variables de dépôt à partir du fichier local, sans envoyer ce fichier :

- SUPABASE_URL
- SUPABASE_PUBLISHABLE_KEY (uniquement la clé publique sb_publishable_)

Le workflow refuse une configuration absente ou une clé non publique. Ne jamais
ajouter de clé secrète ou de mot de passe de base. Les paramètres temporaires
restent hors du dossier téléchargé. La clé publique reste visible dans le Web.

## Compiler et récupérer

Ouvrir Actions > Compiler Teranga Immo Web > Run workflow, sélectionner main.
Après réussite, télécharger l'artefact `teranga-immo-web` puis extraire son ZIP.
Si un test échoue, corriger le code avant de relancer ; aucun ZIP n'est produit.
Les nouveaux tests d'authentification n'ont pas encore été validés en exécution.

## Voir la version dans Edge

Depuis le dossier extrait contenant index.html, lancer un serveur statique :

```powershell
& 'C:\Users\HPI\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -m http.server 8765 --bind 127.0.0.1
```

Ouvrir http://127.0.0.1:8765 dans Edge et conserver le terminal ouvert.
Cette étape ne nécessite pas le compilateur Dart. Ne pas ouvrir index.html
directement avec file://. Le serveur est limité à l'ordinateur local.

Pour l'authentification, configurer aussi dans Supabase les retours
http://127.0.0.1:8765/ et http://127.0.0.1:8765/?auth=recovery,
et terminer la configuration décrite dans AUTHENTIFICATION.md.

Le téléchargement d'un artefact GitHub n'est pas une publication du site.
