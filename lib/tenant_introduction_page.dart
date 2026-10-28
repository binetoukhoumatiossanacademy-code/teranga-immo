import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'tenant_widgets.dart';

class TenantIntroductionPage extends StatelessWidget {
  const TenantIntroductionPage({super.key, required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TerangaColors.ivory,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width < 700 ? 440 : 1180,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TenantHeader(),
                  const SizedBox(height: TerangaSpacing.lg),
                  ResponsiveSections(
                    first: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Trouvez votre\nlogement plus\n',
                              style: TerangaTypography.heroTitle,
                            ),
                            TextSpan(
                              text: 'simplement',
                              style: TerangaTypography.heroTitleItalic,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: TerangaSpacing.md),
                      Text(
                        'Recherchez selon vos besoins, consultez les informations importantes et le niveau de contrôle des annonces avant de vous déplacer.',
                        style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                      ),
                      const SizedBox(height: TerangaSpacing.lg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TerangaRadius.card + 8),
                        child: Image.asset(
                          'assets/homes/locataire_illustration.png',
                          fit: BoxFit.contain,
                          height: MediaQuery.sizeOf(context).width >= 900
                              ? 320
                              : null,
                          semanticLabel:
                              'Une main tient les clés d’un logement lumineux au Sénégal',
                        ),
                      ),
                      const SizedBox(height: TerangaSpacing.lg),
                    ],
                    second: [
                      Text('Comment ça marche ?', style: TerangaTypography.sectionTitle),
                      const SizedBox(height: TerangaSpacing.lg),
                      step(
                        '1',
                        'Recherchez',
                        'Indiquez où et quel logement vous recherchez.',
                        LucideIcons.search,
                      ),
                      const SizedBox(height: TerangaSpacing.lg),
                      step(
                        '2',
                        'Comparez',
                        'Consultez le prix, les photos, les caractéristiques et le niveau de contrôle.',
                        LucideIcons.copy,
                      ),
                      const SizedBox(height: TerangaSpacing.lg),
                      step(
                        '3',
                        'Contactez',
                        'Contactez le propriétaire ou l’agence si le logement vous intéresse.',
                        LucideIcons.message_circle,
                      ),
                      const SizedBox(height: TerangaSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(TerangaSpacing.md),
                        decoration: BoxDecoration(
                          color: TerangaColors.beige,
                          border: Border.all(color: TerangaColors.border),
                          borderRadius: BorderRadius.circular(TerangaRadius.card),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.shield_check,
                              color: TerangaColors.gold,
                              size: 24,
                            ),
                            const SizedBox(width: TerangaSpacing.sm),
                            Expanded(
                              child: Text(
                                'Chaque annonce indique clairement son niveau de contrôle.',
                                style: TerangaTypography.meta,
                              ),
                            ),
                            const SizedBox(width: TerangaSpacing.xs),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Comprendre le niveau de contrôle',
                                  ),
                                  content: Text(
                                    'Déclarée par le propriétaire : informations fournies par l’annonceur.\n\nInformations contrôlées : les éléments réellement examinés seront précisés.\n\nVérifiée par Teranga Immo : le périmètre et la date de vérification seront explicités.\n\nUne mise en avant Premium ne constitue jamais une vérification.',
                                    style: TerangaTypography.body,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Compris'),
                                    ),
                                  ],
                                ),
                              ),
                              child: const Text('En savoir plus →'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: TerangaSpacing.lg),
                      ResponsiveAction(
                        child: FilledButton(
                          onPressed: onSearch,
                          style: tenantPrimaryStyle(),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text('Chercher votre logement')),
                              SizedBox(width: 8),
                              Icon(LucideIcons.arrow_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget step(String number, String title, String description, IconData icon) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: TerangaColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TerangaColors.gold, size: 26),
          ),
          const SizedBox(width: TerangaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$number — ',
                        style: const TextStyle(color: TerangaColors.gold),
                      ),
                      TextSpan(text: title),
                    ],
                  ),
                  style: TerangaTypography.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TerangaTypography.meta,
                ),
              ],
            ),
          ),
        ],
      );
}
