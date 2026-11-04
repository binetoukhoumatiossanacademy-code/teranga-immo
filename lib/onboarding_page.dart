import 'package:flutter/material.dart';

import 'design_system/design_system.dart';

/// Teinte crème claire utilisée pour le texte posé sur la photo, une fois
/// le dégradé sombre appliqué en bas d'écran.
const Color _onPhotoText = Color(0xFFFAF6EF);

/// Doré clair pour le lien « Se connecter », contraste AA garanti sur le
/// dégradé sombre du bas d'écran.
const Color _linkGold = Color(0xFFD4A855);

/// Carrousel d'accueil avant le choix de profil — section 11.1 et
/// référence « 1. Accueil » de la direction artistique.
///
/// La photo du salon sert de fond plein écran, avec un dégradé sombre
/// sur les 55 % inférieurs pour garder le texte (en blanc/crème) lisible
/// quelle que soit la zone de la photo derrière lui. Titre, sous-titre,
/// points du carrousel, bouton et lien de connexion sont regroupés dans
/// un même bloc ancré en bas d'écran ; le haut reste dégagé pour la photo
/// et le logo.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onGetStarted, required this.onSignIn});

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      title: 'Trouvez le lieu',
      titleItalic: 'qui vous ressemble.',
      description: 'Louez votre prochain logement au Sénégal, en toute simplicité.',
    ),
    _Slide(
      title: 'Publiez votre bien',
      titleItalic: 'en toute confiance.',
      description: 'Chaque annonce est pensée pour rassurer un futur locataire.',
    ),
    _Slide(
      title: 'Une expérience pensée',
      titleItalic: 'pour le Sénégal.',
      description: 'Dakar et ses quartiers, avec une attention portée aux détails locaux.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= TerangaBreakpoints.tablet;
    final textBlockHeight = wide ? 220.0 : 180.0;

    return Scaffold(
      backgroundColor: TerangaColors.ivory,
      body: Stack(
        children: [
          // Photo plein écran — object-fit: cover. L'image couvre déjà
          // exactement la hauteur de l'écran avec `cover` (aucune marge
          // verticale), donc un leger zoom est necessaire pour pouvoir
          // masquer la suspension lumineuse du haut de la photo.
          Positioned.fill(
            child: ClipRect(
              child: Transform.scale(
                scale: 1.35,
                alignment: Alignment.bottomCenter,
                child: const Image(
                  image: AssetImage('assets/homes/salon_demo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Dégradé sombre sur les 55 % inférieurs, pour la lisibilité du
          // texte quelle que soit la zone de la photo derrière lui.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00140E08), Color(0xBF140E08)],
                  stops: [0.45, 1],
                ),
              ),
            ),
          ),
          // Léger voile localisé tout en haut, derrière le logo
          // uniquement — le reste du haut de la photo reste dégagé.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66140E08), Color(0x00140E08)],
                  stops: [0, 0.22],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 560 : double.infinity),
                child: Column(
                  children: [
                    // Logo en haut, centré — le haut de la photo reste
                    // dégagé. L'ombre portée (voir TerangaLogo) assure le
                    // contraste sur une photo claire.
                    Padding(
                      padding: const EdgeInsets.only(top: TerangaSpacing.xl),
                      child: TerangaLogo(
                        variant: TerangaLogoVariant.stacked,
                        markSize: wide ? 160 : 110,
                        color: _onPhotoText,
                      ),
                    ),
                    const Spacer(),
                    // Bloc unique ancré en bas : titre, sous-titre, points,
                    // bouton, lien — espacement régulier de 16 à 24 px.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: textBlockHeight,
                            child: PageView.builder(
                              controller: _controller,
                              itemCount: _slides.length,
                              onPageChanged: (value) => setState(() => _index = value),
                              itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                            ),
                          ),
                          const SizedBox(height: TerangaSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _slides.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _index
                                        ? TerangaColors.gold
                                        : _onPhotoText.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: TerangaSpacing.xl),
                          FilledButton(
                            onPressed: widget.onGetStarted,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: const Text('Commencer  →'),
                          ),
                          const SizedBox(height: TerangaSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Déjà un compte ? ',
                                style: TerangaTypography.body.copyWith(
                                  color: _onPhotoText.withValues(alpha: 0.8),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onSignIn,
                                style: TextButton.styleFrom(
                                  foregroundColor: _linkGold,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                child: const Text('Se connecter'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.titleItalic, required this.description});
  final String title;
  final String titleItalic;
  final String description;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = TerangaTypography.scaled(32, width);
    final bodySize = TerangaTypography.scaled(16, width);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${slide.title}\n',
                style: TerangaTypography.heroTitle.copyWith(
                  fontSize: titleSize,
                  color: _onPhotoText,
                ),
              ),
              TextSpan(
                text: slide.titleItalic,
                style: TerangaTypography.heroTitleItalic.copyWith(
                  fontSize: titleSize,
                  color: _onPhotoText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TerangaSpacing.sm),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: TerangaTypography.body.copyWith(
            color: _onPhotoText.withValues(alpha: 0.92),
            fontSize: bodySize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
