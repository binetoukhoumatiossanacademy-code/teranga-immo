import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'teranga_colors.dart';
import 'teranga_typography.dart';

/// Les présentations du logo prévues par la direction artistique
/// (section 5.3). Une seule source — le monogramme vectoriel — alimente
/// toutes les variantes : il n'y a pas de fichier dupliqué par couleur.
enum TerangaLogoVariant {
  /// Monogramme + séparateur + « TERANGA IMMO » sur une ligne.
  /// Version principale, utilisée en-tête d'écran large et onboarding.
  horizontal,

  /// Monogramme + nom, en taille réduite pour l'en-tête mobile compact.
  compact,

  /// Monogramme seul (favicon, splash, vignette).
  markOnly,
}

/// Logo officiel de Teranga Immo.
///
/// Le monogramme (toit, « T » et « i » aux empattements évasés, socle)
/// est un SVG vectoriel (`assets/brand/teranga_mark.svg`). Le nom
/// « TERANGA IMMO » est rendu en texte réel (Cormorant Garamond), jamais
/// en image, pour garantir une orthographe exacte à toute taille.
///
/// La couleur est appliquée par teinte (ColorFilter) sur le SVG source,
/// ce qui fournit les variantes « monochrome », « sur fond ivoire » et
/// « sur fond blanc » sans dupliquer le fichier vectoriel.
class TerangaLogo extends StatelessWidget {
  const TerangaLogo({
    super.key,
    this.variant = TerangaLogoVariant.horizontal,
    this.color = TerangaColors.gold,
    this.textColor,
    this.markSize,
  });

  /// Variante de composition (voir [TerangaLogoVariant]).
  final TerangaLogoVariant variant;

  /// Couleur appliquée au monogramme.
  final Color color;

  /// Couleur du texte « TERANGA IMMO ». Par défaut, identique à [color].
  final Color? textColor;

  /// Hauteur du monogramme. Valeurs par défaut cohérentes avec la
  /// variante choisie si non renseigné.
  final double? markSize;

  static const String _asset = 'assets/brand/teranga_mark.svg';

  @override
  Widget build(BuildContext context) {
    final wordColor = textColor ?? color;
    final mark = SvgPicture.asset(
      _asset,
      height: markSize ?? (variant == TerangaLogoVariant.compact ? 34 : 44),
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: 'Monogramme Teranga Immo',
    );

    if (variant == TerangaLogoVariant.markOnly) return mark;

    final wordmarkStyle = variant == TerangaLogoVariant.compact
        ? TerangaTypography.wordmarkCompact
        : TerangaTypography.wordmark;

    return Semantics(
      label: 'Teranga Immo',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: variant == TerangaLogoVariant.compact ? 10 : 14),
          Container(
            width: 1.2,
            height: (markSize ?? 44) * 0.7,
            color: color.withValues(alpha: 0.55),
          ),
          SizedBox(width: variant == TerangaLogoVariant.compact ? 10 : 14),
          Text(
            'TERANGA IMMO',
            style: wordmarkStyle.copyWith(color: wordColor),
          ),
        ],
      ),
    );
  }
}
