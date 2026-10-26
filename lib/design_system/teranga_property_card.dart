import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'teranga_colors.dart';
import 'teranga_featured_listing.dart';
import 'teranga_geometry.dart';
import 'teranga_typography.dart';

/// Carte de logement — section 10.4 et 12.4 du prompt de direction
/// artistique. Photo (ou panneau illustré sobre si aucune photo n'est
/// fournie), statut, prix, type, localisation, caractéristiques et
/// favori.
class TerangaPropertyCard extends StatelessWidget {
  const TerangaPropertyCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final TerangaFeaturedListing listing;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TerangaRadius.card),
      child: Container(
        decoration: BoxDecoration(
          color: TerangaColors.white,
          borderRadius: BorderRadius.circular(TerangaRadius.card),
          border: Border.all(color: TerangaColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Visual(
              listing: listing,
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TerangaSpacing.lg,
                TerangaSpacing.md,
                TerangaSpacing.lg,
                TerangaSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.formattedRent,
                    style: TerangaTypography.bodyStrong.copyWith(
                      color: TerangaColors.gold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(listing.title, style: TerangaTypography.cardTitle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.map_pin,
                        size: 14,
                        color: TerangaColors.taupe,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.location,
                          style: TerangaTypography.meta,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Feature(icon: LucideIcons.bed_double, label: '${listing.rooms} ch'),
                      const SizedBox(width: 14),
                      _Feature(icon: LucideIcons.bath, label: '${listing.bathrooms} sdb'),
                      const SizedBox(width: 14),
                      _Feature(icon: LucideIcons.maximize, label: '${listing.surfaceSqm} m²'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Visual extends StatelessWidget {
  const _Visual({
    required this.listing,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final TerangaFeaturedListing listing;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final photo = listing.photoAsset;
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image.asset(photo, fit: BoxFit.cover)
          else
            Container(
              color: TerangaColors.beige,
              alignment: Alignment.center,
              child: Icon(
                listing.type == 'Maison'
                    ? LucideIcons.house
                    : LucideIcons.building_complex,
                size: 56,
                color: TerangaColors.lightBrown.withValues(alpha: 0.55),
              ),
            ),
          Positioned(
            left: TerangaSpacing.sm,
            top: TerangaSpacing.sm,
            child: _StatusBadge(label: 'À louer'),
          ),
          Positioned(
            right: TerangaSpacing.sm,
            top: TerangaSpacing.sm,
            child: _FavoriteButton(
              isFavorite: isFavorite,
              onTap: onToggleFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: TerangaColors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(TerangaRadius.badge),
    ),
    child: Text(
      label,
      style: TerangaTypography.meta.copyWith(
        color: TerangaColors.deepBrown,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        height: 1,
      ),
    ),
  );
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    // Le fond change de teinte en plus de la couleur de l'icône : l'état
    // favori ne repose pas sur la seule couleur (accessibilité).
    color: isFavorite
        ? TerangaColors.gold.withValues(alpha: 0.18)
        : TerangaColors.white.withValues(alpha: 0.92),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          LucideIcons.heart,
          size: 17,
          color: isFavorite ? TerangaColors.gold : TerangaColors.deepBrown,
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: TerangaColors.lightBrown),
      const SizedBox(width: 4),
      Text(
        label,
        style: TerangaTypography.meta.copyWith(color: TerangaColors.deepBrown),
      ),
    ],
  );
}
