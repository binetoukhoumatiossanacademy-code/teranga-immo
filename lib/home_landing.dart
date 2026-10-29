import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'home.dart';

/// Accueil de Teranga Immo — conçu mobile-first (référence 390 px),
/// section 10 de la direction artistique.
///
/// En mode connecté (Supabase configuré), la section « vedette » montre
/// la dernière annonce réellement approuvée si elle est disponible, ou
/// l'état de chargement/erreur existant ([status]). En mode prototype
/// (aucune configuration), elle montre des exemples fictifs, jamais
/// mélangés à de vraies données.
class HomeLanding extends StatefulWidget {
  const HomeLanding({
    super.key,
    required this.onSearch,
    required this.onDetail,
    required this.onPublish,
    required this.onFavorites,
    required this.onProfile,
    this.connected = false,
    this.announcement,
    this.status,
  });

  final VoidCallback onSearch;
  final VoidCallback onDetail;
  final VoidCallback onPublish;
  final VoidCallback onFavorites;
  final VoidCallback onProfile;
  final bool connected;
  final Home? announcement;
  final Widget? status;

  @override
  State<HomeLanding> createState() => _HomeLandingState();
}

class _HomeLandingState extends State<HomeLanding> {
  final Set<String> _favorites = {};

  void _toggleFavorite(String key) => setState(() {
    if (!_favorites.remove(key)) _favorites.add(key);
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= TerangaBreakpoints.tablet;
    final maxContentWidth = width >= TerangaBreakpoints.desktop ? 1120.0 : double.infinity;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onFavorites: widget.onFavorites, onProfile: widget.onProfile),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : TerangaSpacing.lg,
                  TerangaSpacing.sm,
                  wide ? 40 : TerangaSpacing.lg,
                  0,
                ),
                child: wide
                    ? _WideHero(onSearch: widget.onSearch)
                    : _MobileHero(onSearch: widget.onSearch),
              ),
              SizedBox(height: wide ? TerangaSpacing.xxxl : TerangaSpacing.huge),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : TerangaSpacing.lg),
                child: _ExploreByNeed(
                  wide: wide,
                  onSearch: widget.onSearch,
                  onPublish: widget.onPublish,
                  onFavorites: widget.onFavorites,
                ),
              ),
              SizedBox(height: wide ? TerangaSpacing.xxxl : TerangaSpacing.xxl),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : TerangaSpacing.lg),
                child: _FeaturedSection(
                  wide: wide,
                  connected: widget.connected,
                  announcement: widget.announcement,
                  status: widget.status,
                  favorites: _favorites,
                  onToggleFavorite: _toggleFavorite,
                  onSeeAll: widget.onSearch,
                  onOpen: widget.onDetail,
                ),
              ),
              SizedBox(height: wide ? TerangaSpacing.xxxl : TerangaSpacing.xxl),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : TerangaSpacing.lg),
                child: _OwnerPanel(onPublish: widget.onPublish),
              ),
              const SizedBox(height: TerangaSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// En-tête
// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.onFavorites, required this.onProfile});
  final VoidCallback onFavorites;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TerangaSpacing.lg,
      TerangaSpacing.md,
      TerangaSpacing.lg,
      TerangaSpacing.md,
    ),
    child: Row(
      children: [
        const TerangaLogo(variant: TerangaLogoVariant.compact),
        const Spacer(),
        _HeaderIconButton(
          icon: LucideIcons.heart,
          tooltip: 'Favoris',
          onTap: onFavorites,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: LucideIcons.user,
          tooltip: 'Profil',
          onTap: onProfile,
        ),
      ],
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: TerangaColors.beige,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 19, color: TerangaColors.deepBrown),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------
// Bloc d'accroche + recherche — mobile
// ---------------------------------------------------------------------

class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(TerangaRadius.card + 6),
        child: Stack(
          children: [
            Image.asset(
              'assets/homes/salon_demo.png',
              height: 430,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      TerangaColors.ivory,
                      TerangaColors.ivory.withValues(alpha: 0.78),
                      TerangaColors.ivory.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.34, 0.62],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TerangaSpacing.lg,
            TerangaSpacing.lg,
            TerangaSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LE SÉNÉGAL, À VOTRE ADRESSE', style: TerangaTypography.eyebrow),
              const SizedBox(height: TerangaSpacing.sm),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'Trouvez le lieu\n', style: TerangaTypography.heroTitle),
                    TextSpan(
                      text: 'qui vous ressemble.',
                      style: TerangaTypography.heroTitleItalic,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TerangaSpacing.md),
              Text(
                'Louez votre prochain logement ou publiez votre bien, en toute simplicité.',
                style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: TerangaSpacing.lg,
        right: TerangaSpacing.lg,
        bottom: -28,
        child: _SearchField(onTap: onSearch),
      ),
    ],
  );
}

class _WideHero extends StatelessWidget {
  const _WideHero({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LE SÉNÉGAL, À VOTRE ADRESSE', style: TerangaTypography.eyebrow),
              const SizedBox(height: TerangaSpacing.md),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Trouvez le lieu\n',
                      style: TerangaTypography.heroTitle.copyWith(
                        fontSize: TerangaTypography.scaled(34, width),
                      ),
                    ),
                    TextSpan(
                      text: 'qui vous ressemble.',
                      style: TerangaTypography.heroTitleItalic.copyWith(
                        fontSize: TerangaTypography.scaled(34, width),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TerangaSpacing.lg),
              Text(
                'Louez votre prochain logement ou publiez votre bien, en toute simplicité.',
                style: TerangaTypography.body.copyWith(
                  color: TerangaColors.taupe,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: TerangaSpacing.xxl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _SearchField(onTap: onSearch),
              ),
            ],
          ),
        ),
        const SizedBox(width: TerangaSpacing.xxxl),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TerangaRadius.card),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset('assets/homes/salon_demo.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TerangaColors.white,
    borderRadius: BorderRadius.circular(TerangaRadius.field + 3),
    elevation: 6,
    shadowColor: TerangaColors.deepBrown.withValues(alpha: 0.22),
    child: InkWell(
      borderRadius: BorderRadius.circular(TerangaRadius.field + 3),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TerangaRadius.field + 3),
          border: Border.all(color: TerangaColors.border),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.map_pin, size: 18, color: TerangaColors.lightBrown),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Où cherchez-vous ?', style: TerangaTypography.bodyStrong),
                  Text(
                    'Dakar, Ngor, Almadies…',
                    style: TerangaTypography.meta,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: TerangaColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.search, size: 18, color: TerangaColors.white),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------
// Explorer par besoin — composition asymétrique (pas 4 cartes identiques)
// ---------------------------------------------------------------------

class _ExploreByNeed extends StatelessWidget {
  const _ExploreByNeed({
    required this.wide,
    required this.onSearch,
    required this.onPublish,
    required this.onFavorites,
  });
  final bool wide;
  final VoidCallback onSearch;
  final VoidCallback onPublish;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    final sectionTitle = Text('Explorer par besoin', style: TerangaTypography.sectionTitle);
    final primary = _NeedCard(
      icon: LucideIcons.house,
      title: 'Louer',
      description: 'Trouvez votre prochain chez-vous parmi les annonces disponibles.',
      onTap: onSearch,
      emphasized: true,
    );
    final secondary = [
      _NeedCard(
        icon: LucideIcons.building_complex,
        title: 'Publier',
        description: 'Annoncez votre bien en quelques minutes.',
        onTap: onPublish,
      ),
      _NeedCard(
        icon: LucideIcons.heart,
        title: 'Favoris',
        description: 'Retrouvez les logements que vous avez aimés.',
        onTap: onFavorites,
      ),
    ];

    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle,
          const SizedBox(height: TerangaSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: primary),
              const SizedBox(width: TerangaSpacing.lg),
              Expanded(child: secondary[0]),
              const SizedBox(width: TerangaSpacing.lg),
              Expanded(child: secondary[1]),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle,
        const SizedBox(height: TerangaSpacing.md),
        primary,
        const SizedBox(height: TerangaSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: secondary[0]),
            const SizedBox(width: TerangaSpacing.md),
            Expanded(child: secondary[1]),
          ],
        ),
      ],
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.emphasized = false,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Material(
    color: emphasized ? TerangaColors.gold : TerangaColors.white,
    borderRadius: BorderRadius.circular(TerangaRadius.card),
    child: InkWell(
      borderRadius: BorderRadius.circular(TerangaRadius.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TerangaSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TerangaRadius.card),
          border: emphasized ? null : Border.all(color: TerangaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: emphasized ? TerangaColors.white : TerangaColors.gold,
            ),
            const SizedBox(height: TerangaSpacing.md),
            Text(
              title,
              style: TerangaTypography.cardTitle.copyWith(
                color: emphasized ? TerangaColors.white : TerangaColors.deepBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TerangaTypography.meta.copyWith(
                color: emphasized
                    ? TerangaColors.white.withValues(alpha: 0.88)
                    : TerangaColors.taupe,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------
// Biens en vedette
// ---------------------------------------------------------------------

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.wide,
    required this.connected,
    required this.announcement,
    required this.status,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onSeeAll,
    required this.onOpen,
  });

  final bool wide;
  final bool connected;
  final Home? announcement;
  final Widget? status;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  final VoidCallback onSeeAll;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Text('Biens en vedette', style: TerangaTypography.sectionTitle),
        const Spacer(),
        TextButton(onPressed: onSeeAll, child: const Text('Voir tout →')),
      ],
    );

    if (connected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: TerangaSpacing.md),
          if (announcement == null)
            status ?? const SizedBox.shrink()
          else
            TerangaPropertyCard(
              listing: TerangaFeaturedListing(
                title: announcement!.title,
                district: announcement!.district,
                city: announcement!.city,
                monthlyRent: (announcement!.rent ?? 0).round(),
                type: announcement!.type,
                rooms: announcement!.rooms ?? 0,
                bathrooms: 0,
                surfaceSqm: 0,
              ),
              isFavorite: favorites.contains(announcement!.title),
              onToggleFavorite: () => onToggleFavorite(announcement!.title),
              onTap: onOpen,
            ),
        ],
      );
    }

    final cards = terangaFeaturedListings
        .map(
          (listing) => TerangaPropertyCard(
            listing: listing,
            isFavorite: favorites.contains(listing.title),
            onToggleFavorite: () => onToggleFavorite(listing.title),
            onTap: onOpen,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: TerangaSpacing.md),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final card in cards) ...[
                Expanded(child: card),
                if (card != cards.last) const SizedBox(width: TerangaSpacing.lg),
              ],
            ],
          )
        else
          Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: TerangaSpacing.lg),
              ],
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Bloc propriétaires
// ---------------------------------------------------------------------

class _OwnerPanel extends StatelessWidget {
  const _OwnerPanel({required this.onPublish});
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(TerangaSpacing.xl),
    decoration: BoxDecoration(
      color: TerangaColors.deepBrown,
      borderRadius: BorderRadius.circular(TerangaRadius.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POUR LES PROPRIÉTAIRES',
          style: TerangaTypography.eyebrow.copyWith(color: TerangaColors.champagne),
        ),
        const SizedBox(height: TerangaSpacing.sm),
        Text(
          'Votre bien mérite\nla bonne visibilité.',
          style: TerangaTypography.sectionTitle.copyWith(
            color: TerangaColors.white,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: TerangaSpacing.sm),
        Text(
          'Publiez votre annonce et facilitez la recherche de votre futur locataire.',
          style: TerangaTypography.body.copyWith(
            color: TerangaColors.white.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(height: TerangaSpacing.lg),
        FilledButton(
          onPressed: onPublish,
          style: FilledButton.styleFrom(
            backgroundColor: TerangaColors.gold,
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.xl),
          ),
          child: const Text('Publier une annonce'),
        ),
      ],
    ),
  );
}
