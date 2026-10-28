import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'home.dart';
import 'home_art.dart';

/// Détail d'un logement de démonstration (parcours non connecté), repris
/// avec le système graphique — section 11 de la direction artistique.
class DetailPage extends StatelessWidget {
  final Home home;
  const DetailPage({super.key, required this.home});

  void explain(BuildContext context, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(home.isDemo ? 'Mode démonstration' : 'Information'),
      content: Text(text, style: TerangaTypography.body),
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
    backgroundColor: TerangaColors.ivory,
    appBar: AppBar(title: const Text('Détail du logement')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(TerangaSpacing.lg),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(TerangaRadius.card + 6),
              child: AspectRatio(aspectRatio: 4 / 3, child: HomeArt(home: home)),
            ),
            const SizedBox(height: TerangaSpacing.lg),
            Row(
              children: [
                Icon(
                  home.isDemo ? LucideIcons.info : LucideIcons.shield_check,
                  size: 16,
                  color: TerangaColors.taupe,
                ),
                const SizedBox(width: 6),
                Text(
                  home.isDemo
                      ? 'DÉMONSTRATION · Aucune annonce réelle'
                      : 'Annonce approuvée',
                  style: TerangaTypography.meta.copyWith(
                    color: TerangaColors.taupe,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.sm),
            Text(home.title, style: TerangaTypography.sectionTitle),
            const SizedBox(height: TerangaSpacing.xs),
            Text(
              home.monthlyPrice,
              style: TerangaTypography.editorialCardTitle.copyWith(
                color: TerangaColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.map_pin, size: 16, color: TerangaColors.lightBrown),
                const SizedBox(width: 6),
                Text(
                  '${home.location} · ${home.roomsLabel}',
                  style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.xl),
            Text('Le logement', style: TerangaTypography.cardTitle),
            const SizedBox(height: TerangaSpacing.sm),
            Text(
              home.description,
              style: TerangaTypography.body.copyWith(color: TerangaColors.deepBrown),
            ),
            const SizedBox(height: TerangaSpacing.md),
            Text(
              home.isDemo
                  ? 'Disponibilité : fictive\nÉquipements et conditions : non renseignés dans cet exemple.'
                  : 'Disponibilité, équipements et conditions : non renseignés.',
              style: TerangaTypography.meta.copyWith(color: TerangaColors.taupe),
            ),
            const SizedBox(height: TerangaSpacing.xl),
            if (!home.isDemo)
              _InfoCard(
                child: Text(
                  'Niveau de contrôle non renseigné. Une approbation de publication ne constitue pas une vérification sur place.',
                  style: TerangaTypography.body,
                ),
              )
            else
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shield_check,
                          size: 18,
                          color: TerangaColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Comprendre le niveau de contrôle',
                            style: TerangaTypography.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TerangaSpacing.sm),
                    Text(
                      'Cet exemple n’a fait l’objet d’aucun contrôle.\n\nDéclarée par le propriétaire : informations fournies par l’annonceur.\nInformations contrôlées : les éléments réellement examinés seront précisés.\nVérifiée par Teranga Immo : le périmètre et la date de vérification seront explicités.\n\nUne mise en avant Premium ne constitue jamais une vérification.',
                      style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: TerangaSpacing.xl),
            Wrap(
              spacing: TerangaSpacing.sm,
              runSpacing: TerangaSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () => explain(
                    context,
                    'Les favoris et la connexion ne sont pas encore disponibles. Aucun favori n’est enregistré.',
                  ),
                  icon: const Icon(LucideIcons.heart, size: 18),
                  label: const Text('Ajouter aux favoris'),
                ),
                OutlinedButton.icon(
                  onPressed: () => explain(
                    context,
                    home.isDemo
                        ? 'Ce logement est fictif : aucun propriétaire ne peut être contacté.'
                        : 'Coordonnées de contact non renseignées pour cette annonce.',
                  ),
                  icon: const Icon(LucideIcons.message_circle, size: 18),
                  label: const Text('Contacter'),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.lg),
          ],
        ),
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(TerangaSpacing.lg),
    decoration: BoxDecoration(
      color: TerangaColors.beige,
      borderRadius: BorderRadius.circular(TerangaRadius.card),
      border: Border.all(color: TerangaColors.border),
    ),
    child: child,
  );
}
