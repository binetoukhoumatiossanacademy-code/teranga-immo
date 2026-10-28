import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'design_system/design_system.dart';
import 'home.dart';
import 'tenant_widgets.dart';

class TenantDetail extends StatefulWidget {
  const TenantDetail({
    super.key,
    required this.home,
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
  });
  final Home home;
  final bool favorite;
  final VoidCallback onBack, onFavorite;
  @override
  State<TenantDetail> createState() => _TenantDetailState();
}

class _TenantDetailState extends State<TenantDetail> {
  int photo = 0;
  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (home.isDemo)
          const Padding(
            padding: EdgeInsets.only(bottom: TerangaSpacing.md),
            child: TenantNotice(
              'DÉMONSTRATION · Annonce fictive existante. Images de maquette, sans lien avec un logement réel.',
              warning: true,
            ),
          ),
        ResponsiveSections(
          first: [
            Stack(
              children: [
                TenantPhoto(
                  home: home,
                  index: photo,
                  height: MediaQuery.sizeOf(context).width >= 900 ? 320 : 225,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: widget.onBack,
                    icon: const Icon(LucideIcons.chevron_left),
                    label: const Text('Résultats'),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: TerangaColors.white.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: widget.favorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      onPressed: widget.onFavorite,
                      icon: Icon(
                        LucideIcons.heart,
                        color: widget.favorite
                            ? TerangaColors.gold
                            : TerangaColors.deepBrown,
                      ),
                    ),
                  ),
                ),
                if (home.isDemo)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TerangaColors.scrimOnPhoto,
                        borderRadius: BorderRadius.circular(TerangaRadius.badge + 10),
                      ),
                      child: Text(
                        '${photo + 1}/${tenantDemoPhotos.length}',
                        style: TerangaTypography.meta.copyWith(color: TerangaColors.white),
                      ),
                    ),
                  ),
              ],
            ),
            if (home.isDemo)
              Padding(
                padding: const EdgeInsets.only(top: TerangaSpacing.sm),
                child: Row(
                  children: [
                    for (var i = 0; i < tenantDemoPhotos.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                          child: Semantics(
                            button: true,
                            selected: photo == i,
                            label: 'Voir l’illustration ${i + 1}',
                            child: InkWell(
                              onTap: () => setState(() => photo = i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: photo == i
                                        ? TerangaColors.gold
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(TerangaRadius.card + 2),
                                ),
                                child: TenantPhoto(
                                  home: home,
                                  index: i,
                                  height: 67,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          second: [
            const SizedBox(height: TerangaSpacing.lg),
            Text(
              home.monthlyPrice,
              style: TerangaTypography.priceDisplay.copyWith(color: TerangaColors.gold),
            ),
            Text(home.location, style: TerangaTypography.cardTitle.copyWith(fontSize: 19)),
            const SizedBox(height: TerangaSpacing.sm),
            Row(
              children: [
                const Icon(LucideIcons.building_complex, size: 16, color: TerangaColors.lightBrown),
                const SizedBox(width: 6),
                Text('${home.type} · ${home.roomsLabel}', style: TerangaTypography.body),
              ],
            ),
            Text(
              'Ameublement et salles de bain : non renseignés.',
              style: TerangaTypography.meta,
            ),
            const SizedBox(height: TerangaSpacing.sm),
            const TenantNotice('Disponibilité non renseignée.'),
            const Divider(height: TerangaSpacing.xxl, color: TerangaColors.border),
            Text('À propos de ce logement', style: TerangaTypography.sectionTitle.copyWith(fontSize: 20)),
            const SizedBox(height: TerangaSpacing.sm),
            Text(home.description, style: TerangaTypography.body),
            const Divider(height: TerangaSpacing.xxl, color: TerangaColors.border),
            Container(
              padding: const EdgeInsets.all(TerangaSpacing.md),
              decoration: BoxDecoration(
                color: TerangaColors.beige,
                borderRadius: BorderRadius.circular(TerangaRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Niveau de contrôle Teranga Immo', style: TerangaTypography.cardTitle),
                  const SizedBox(height: TerangaSpacing.sm),
                  Text('Niveau de contrôle non renseigné', style: TerangaTypography.meta),
                  TextButton(
                    onPressed: () => showTenantControlInfo(context),
                    child: const Text('Voir ce qui a été contrôlé →'),
                  ),
                ],
              ),
            ),
            const Divider(height: TerangaSpacing.xxl, color: TerangaColors.border),
            Text('Annonce publiée par', style: TerangaTypography.sectionTitle.copyWith(fontSize: 19)),
            const SizedBox(height: TerangaSpacing.md),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: TerangaColors.beige,
                  child: Icon(LucideIcons.user, color: TerangaColors.gold),
                ),
                const SizedBox(width: TerangaSpacing.md),
                Expanded(
                  child: Text('Annonceur non renseigné', style: TerangaTypography.bodyStrong),
                ),
              ],
            ),
            const SizedBox(height: TerangaSpacing.lg),
            FilledButton(
              onPressed: () => showTenantContact(context, home),
              style: tenantPrimaryStyle(),
              child: const Text('Contacter →'),
            ),
            const SizedBox(height: TerangaSpacing.sm),
            OutlinedButton.icon(
              onPressed: widget.onFavorite,
              icon: const Icon(LucideIcons.heart),
              label: Text(
                widget.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              ),
            ),
            const SizedBox(height: TerangaSpacing.sm),
            Text(
              'Favoris conservés uniquement pour cette session, sans sauvegarde de compte.',
              style: TerangaTypography.meta,
            ),
            const Divider(height: TerangaSpacing.xxl, color: TerangaColors.border),
            const TextButton(
              onPressed: null,
              child: Text('⚑ Signaler un problème avec cette annonce'),
            ),
            Text(
              'Signalement non disponible actuellement. Aucun signalement n’est envoyé.',
              textAlign: TextAlign.center,
              style: TerangaTypography.meta,
            ),
          ],
        ),
      ],
    );
  }
}
