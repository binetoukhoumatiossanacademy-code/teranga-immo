import 'package:flutter/material.dart';

import 'teranga_colors.dart';

/// Système typographique — section 4 du prompt de direction artistique.
///
/// Deux polices, deux rôles stricts :
/// - [editorial] (Cormorant Garamond) : grands titres, accroches, phrases
///   de marque. Jamais pour un corps de texte ou un petit libellé.
/// - [interface] (DM Sans) : navigation, boutons, formulaires,
///   descriptions, métadonnées — tout ce qui doit rester lisible à
///   petite taille.
///
/// Les tailles ci-dessous correspondent à la référence mobile (390 px).
/// [TerangaTypography.scaled] adapte la taille pour tablette/ordinateur.
abstract final class TerangaTypography {
  static const String editorial = 'Cormorant Garamond';
  static const String interface = 'DM Sans';

  // -- Éditorial (Cormorant Garamond) ------------------------------------

  /// Grand titre éditorial — accroche d'accueil. 34 px sur mobile.
  static const TextStyle heroTitle = TextStyle(
    fontFamily: editorial,
    fontSize: 34,
    height: 1.14,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
    letterSpacing: 0,
  );

  /// Variante italique du grand titre, pour le second segment d'une
  /// accroche à deux lignes (« Trouvez le lieu / qui vous ressemble. »).
  static const TextStyle heroTitleItalic = TextStyle(
    fontFamily: editorial,
    fontSize: 34,
    height: 1.14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: TerangaColors.deepBrown,
  );

  /// Titre de section — 27 px.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: editorial,
    fontSize: 27,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
  );

  /// Titre éditorial de carte mise en avant (collection, sélection).
  static const TextStyle editorialCardTitle = TextStyle(
    fontFamily: editorial,
    fontSize: 22,
    height: 1.22,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
  );

  /// Prix mis en évidence sur la page de détail.
  static const TextStyle priceDisplay = TextStyle(
    fontFamily: editorial,
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
  );

  // -- Interface (DM Sans) -------------------------------------------------

  /// Titre de carte fonctionnelle (carte logement standard) — 19 px.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: interface,
    fontSize: 17,
    height: 1.28,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
  );

  /// Texte courant — 15 px.
  static const TextStyle body = TextStyle(
    fontFamily: interface,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: TerangaColors.deepBrown,
  );

  /// Texte courant, graisse medium (emphase légère, prix secondaires).
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: interface,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w600,
    color: TerangaColors.deepBrown,
  );

  /// Métadonnées — quartier, surface, date. 13 px, taupe par défaut.
  static const TextStyle meta = TextStyle(
    fontFamily: interface,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: TerangaColors.taupe,
  );

  /// Signature de marque courte, capitales espacées
  /// (« LE SÉNÉGAL, À VOTRE ADRESSE »).
  static const TextStyle eyebrow = TextStyle(
    fontFamily: interface,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: TerangaColors.gold,
  );

  /// Libellé de bouton — 15 px, semi-gras.
  static const TextStyle button = TextStyle(
    fontFamily: interface,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: TerangaColors.white,
  );

  /// Libellé de navigation inférieure — 11 px.
  static const TextStyle navLabel = TextStyle(
    fontFamily: interface,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: TerangaColors.taupe,
  );

  /// Lien textuel (ex. « Voir tout », « Se connecter »).
  static const TextStyle link = TextStyle(
    fontFamily: interface,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: TerangaColors.gold,
  );

  /// Texte du logo (« TERANGA IMMO ») — capitales espacées en éditorial.
  static const TextStyle wordmark = TextStyle(
    fontFamily: editorial,
    fontSize: 19,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.2,
    color: TerangaColors.gold,
  );

  /// Version compacte du texte du logo (en-tête mobile).
  static const TextStyle wordmarkCompact = TextStyle(
    fontFamily: editorial,
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
    color: TerangaColors.gold,
  );

  /// Adapte une taille de texte pour tablette/ordinateur. À utiliser
  /// avec [TextStyle.copyWith] plutôt que de dupliquer des styles.
  /// ex. `TerangaTypography.heroTitle.copyWith(fontSize:
  /// TerangaTypography.scaled(34, width))`
  static double scaled(double mobileSize, double width) {
    if (width >= 1280) return mobileSize * 1.35;
    if (width >= 768) return mobileSize * 1.18;
    return mobileSize;
  }
}
