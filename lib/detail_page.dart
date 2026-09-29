import 'package:flutter/material.dart';

import 'home.dart';
import 'home_art.dart';
import 'teranga_theme.dart';

class DetailPage extends StatelessWidget {
  final Home home;
  const DetailPage({super.key, required this.home});
  void explain(BuildContext context, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(home.isDemo ? 'Mode démonstration' : 'Information'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Détail du logement')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              home.isDemo
                  ? 'DÉMONSTRATION · Aucune annonce réelle'
                  : 'Annonce approuvée',
              style: const TextStyle(fontWeight: FontWeight.bold, color: green),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: HomeArt(home: home),
            ),
            const SizedBox(height: 24),
            Text(
              home.title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              home.monthlyPrice,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 12),
            Text('${home.location} · ${home.roomsLabel}'),
            const SizedBox(height: 24),
            const Text(
              'Le logement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(home.description),
            const SizedBox(height: 16),
            Text(
              home.isDemo
                  ? 'Disponibilité : fictive\nÉquipements et conditions : non renseignés dans cet exemple.'
                  : 'Disponibilité, équipements et conditions : non renseignés.',
            ),
            const SizedBox(height: 24),
            if (!home.isDemo)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Niveau de contrôle non renseigné. Une approbation de publication ne constitue pas une vérification sur place.',
                  ),
                ),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprendre le niveau de contrôle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cet exemple n’a fait l’objet d’aucun contrôle.\n\nDéclarée par le propriétaire : informations fournies par l’annonceur.\nInformations contrôlées : les éléments réellement examinés seront précisés.\nVérifiée par Teranga Immo : le périmètre et la date de vérification seront explicités.\n\nUne mise en avant Premium ne constitue jamais une vérification.',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => explain(
                    context,
                    'Les favoris et la connexion ne sont pas encore disponibles. Aucun favori n’est enregistré.',
                  ),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Ajouter aux favoris'),
                ),
                OutlinedButton.icon(
                  onPressed: () => explain(
                    context,
                    home.isDemo
                        ? 'Ce logement est fictif : aucun propriétaire ne peut être contacté.'
                        : 'Coordonnées de contact non renseignées pour cette annonce.',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
