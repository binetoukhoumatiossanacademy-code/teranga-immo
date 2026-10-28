import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'home.dart';

const tenantDemoPhotos = [
  'assets/homes/tenant_reference_living.png',
  'assets/homes/tenant_reference_bedroom.png',
  'assets/homes/tenant_reference_kitchen.png',
];

class TenantHeader extends StatelessWidget {
  const TenantHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const TerangaLogo(variant: TerangaLogoVariant.compact),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: TerangaColors.beige,
          borderRadius: BorderRadius.circular(TerangaRadius.badge + 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.user, size: 16, color: TerangaColors.gold),
            const SizedBox(width: 6),
            Text(
              'Locataire',
              style: TerangaTypography.meta.copyWith(
                color: TerangaColors.deepBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class TenantNotice extends StatelessWidget {
  const TenantNotice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(TerangaSpacing.md),
    decoration: BoxDecoration(
      color: warning ? TerangaColors.warningSurface : TerangaColors.beige,
      borderRadius: BorderRadius.circular(TerangaRadius.field),
      border: Border.all(
        color: warning ? TerangaColors.warning.withValues(alpha: 0.4) : TerangaColors.border,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? LucideIcons.triangle_alert : LucideIcons.info,
          size: 16,
          color: warning ? TerangaColors.warning : TerangaColors.taupe,
        ),
        const SizedBox(width: TerangaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TerangaTypography.meta.copyWith(color: TerangaColors.deepBrown),
          ),
        ),
      ],
    ),
  );
}

class TenantPhoto extends StatelessWidget {
  const TenantPhoto({
    super.key,
    required this.home,
    this.index = 0,
    this.height = 180,
  });
  final Home home;
  final int index;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(TerangaRadius.card),
    child: home.isDemo
        ? Image.asset(
            tenantDemoPhotos[index],
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            semanticLabel:
                'Illustration de maquette, sans lien avec un logement réel',
          )
        : Container(
            height: height,
            width: double.infinity,
            color: TerangaColors.beige,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.image_off,
                  size: 36,
                  color: TerangaColors.lightBrown,
                ),
                const SizedBox(height: TerangaSpacing.sm),
                Text(
                  'Photo non renseignée',
                  style: TerangaTypography.meta,
                ),
              ],
            ),
          ),
  );
}

class TenantListingCard extends StatelessWidget {
  const TenantListingCard({
    super.key,
    required this.home,
    required this.favorite,
    required this.onOpen,
    required this.onFavorite,
  });
  final Home home;
  final bool favorite;
  final VoidCallback onOpen, onFavorite;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: TerangaSpacing.lg),
    decoration: BoxDecoration(
      color: TerangaColors.white,
      borderRadius: BorderRadius.circular(TerangaRadius.card),
      border: Border.all(color: TerangaColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(TerangaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TenantPhoto(home: home, height: 175),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Material(
                    color: TerangaColors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: favorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite ? LucideIcons.heart : LucideIcons.heart,
                        color: favorite ? TerangaColors.gold : TerangaColors.deepBrown,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, TerangaSpacing.sm, 6, TerangaSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    home.monthlyPrice,
                    style: TerangaTypography.bodyStrong.copyWith(
                      color: TerangaColors.gold,
                      fontSize: 18,
                    ),
                  ),
                  Text(home.location, style: TerangaTypography.cardTitle),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.building_complex, size: 14, color: TerangaColors.lightBrown),
                      const SizedBox(width: 4),
                      Text(
                        '${home.type} · ${home.roomsLabel}',
                        style: TerangaTypography.meta,
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: TerangaColors.border),
                  Row(
                    children: [
                      Icon(LucideIcons.circle, size: 12, color: TerangaColors.border),
                      const SizedBox(width: TerangaSpacing.sm),
                      Expanded(
                        child: Text(
                          'Niveau de contrôle non renseigné',
                          style: TerangaTypography.meta,
                        ),
                      ),
                    ],
                  ),
                  if (home.isDemo)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Exemple fictif · illustration de maquette',
                        style: TerangaTypography.meta.copyWith(fontSize: 11),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onOpen,
                      child: const Text('Voir l’annonce'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

ButtonStyle tenantPrimaryStyle() => FilledButton.styleFrom(
  backgroundColor: TerangaColors.gold,
  foregroundColor: TerangaColors.white,
  minimumSize: const Size.fromHeight(50),
  padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.md, vertical: TerangaSpacing.md),
  textStyle: TerangaTypography.button,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TerangaRadius.button)),
);

Future<void> showTenantControlInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Niveau de contrôle Teranga Immo'),
    content: Text(
      'Niveau de contrôle non renseigné. Une approbation de publication ne constitue pas une vérification sur place.\n\nPremium = visibilité payante. Le paiement ne donne jamais le statut Vérifié.',
      style: TerangaTypography.body,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Compris'),
      ),
    ],
  ),
);

Future<void> showTenantContact(
  BuildContext context,
  Home home,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: TerangaColors.ivory,
  constraints: BoxConstraints(
    maxWidth: MediaQuery.sizeOf(context).width < 700 ? 440 : 720,
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(TerangaRadius.modal + 8)),
  ),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fermer le contact',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ),
            Text(
              'Contacter l’annonceur',
              textAlign: TextAlign.center,
              style: TerangaTypography.sectionTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: TerangaSpacing.lg),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: TerangaColors.beige,
                  child: Icon(LucideIcons.user, color: TerangaColors.gold),
                ),
                const SizedBox(width: TerangaSpacing.md),
                Expanded(
                  child: Text(
                    'Annonceur non renseigné',
                    style: TerangaTypography.bodyStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.lg),
            TenantNotice(
              home.isDemo
                  ? 'Ce logement est fictif : aucun propriétaire ne peut être contacté.'
                  : 'Coordonnées de contact non renseignées pour cette annonce.',
              warning: true,
            ),
            const SizedBox(height: TerangaSpacing.lg),
            Row(
              children: [
                const Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.phone, size: 18),
                        SizedBox(width: 6),
                        Flexible(child: Text('Appeler')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: TerangaSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: null,
                    style: tenantPrimaryStyle(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.message_circle, size: 18),
                        SizedBox(width: 6),
                        Flexible(child: Text('WhatsApp')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.md),
            Text(
              'Les appels et WhatsApp seront accessibles lorsque des coordonnées réelles et autorisées seront disponibles.',
              style: TerangaTypography.meta,
            ),
          ],
        ),
      ),
    ),
  ),
);
