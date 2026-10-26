import 'package:flutter/material.dart';

import 'design_system/design_system.dart';

/// Carrousel d'accueil avant le choix de profil — section 11.1 et
/// référence « 1. Accueil » de la direction artistique.
///
/// Trois écrans : une photo pour le premier (seul visuel disponible côté
/// projet), une illustration en traits pour les deux suivants — plutôt
/// que de répéter la même photographie, ce qui aurait été trompeur sur
/// le nombre réel de visuels disponibles.
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
      photo: 'assets/homes/salon_demo.png',
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

    return Scaffold(
      backgroundColor: TerangaColors.ivory,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 480 : double.infinity),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: TerangaSpacing.xxl),
                  child: TerangaLogo(),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: TerangaSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index ? TerangaColors.gold : TerangaColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TerangaSpacing.xl,
                    0,
                    TerangaSpacing.xl,
                    TerangaSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: widget.onGetStarted,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        child: const Text('Commencer  →'),
                      ),
                      const SizedBox(height: TerangaSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Déjà un compte\u202f? ',
                            style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                          ),
                          TextButton(
                            onPressed: widget.onSignIn,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    );
  }
}

class _Slide {
  const _Slide({
    required this.title,
    required this.titleItalic,
    required this.description,
    this.photo,
  });
  final String title;
  final String titleItalic;
  final String description;
  final String? photo;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${slide.title}\n', style: TerangaTypography.heroTitle),
                  TextSpan(
                    text: slide.titleItalic,
                    style: TerangaTypography.heroTitleItalic,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TerangaSpacing.md),
            Text(
              slide.description,
              style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
            ),
          ],
        ),
      ),
      const SizedBox(height: TerangaSpacing.xl),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TerangaSpacing.xl),
          child: slide.photo != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Image.asset(
                    slide.photo!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TerangaColors.beige,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const TerangaArchIllustration(size: 150),
                ),
        ),
      ),
    ],
  );
}
