import 'package:flutter/material.dart';

/// Palette officielle de Teranga Immo — ivoire, blanc, or mat, brun.
///
/// Chaque couleur documente son rôle fonctionnel. Les noms décrivent
/// l'usage plutôt que la teinte, pour que le code reste lisible même si
/// une valeur est légèrement ajustée plus tard (contraste, rendu photo).
///
/// Référence : prompt de direction artistique « Refonte complète de
/// Teranga Immo », section 3.2. Aucun vert ni charbon n'est utilisé comme
/// couleur de marque.
abstract final class TerangaColors {
  // ---------------------------------------------------------------------
  // Fonds et surfaces
  // ---------------------------------------------------------------------

  /// Blanc cassé lumineux — #FFFCF7. Fond principal des surfaces claires
  /// (cartes, champs, modales) posées sur l'ivoire.
  static const Color white = Color(0xFFFFFCF7);

  /// Ivoire chaud — #F6F0E6. Fond principal de l'application.
  static const Color ivory = Color(0xFFF6F0E6);

  /// Beige clair — #EDE1D0. Sections secondaires, bandeaux, surfaces
  /// légèrement distinguées du fond principal.
  static const Color beige = Color(0xFFEDE1D0);

  // ---------------------------------------------------------------------
  // Accents dorés
  // ---------------------------------------------------------------------

  /// Or mat — #B18A43. Logo, accents, éléments actifs, icônes de marque.
  /// Toujours un accent : ne jamais couvrir de grandes surfaces.
  static const Color gold = Color(0xFFB18A43);

  /// Or doux (Champagne) — #C6A36B. Accents secondaires, décorations
  /// fines, bordures mises en valeur.
  static const Color champagne = Color(0xFFC6A36B);

  // ---------------------------------------------------------------------
  // Bruns fonctionnels
  // ---------------------------------------------------------------------

  /// Marron clair — #A98565. Icônes, bordures renforcées, détails.
  static const Color lightBrown = Color(0xFFA98565);

  /// Taupe doux — #8C7A69. Textes secondaires et métadonnées
  /// (quartier, surface, date). Contraste suffisant sur ivoire pour du
  /// texte de taille courante, à éviter sous 14 px.
  static const Color taupe = Color(0xFF8C7A69);

  /// Brun profond — #4A382B. Textes principaux, titres fonctionnels.
  /// C'est la couleur de texte par défaut : elle seule garantit un
  /// contraste AA sur l'ivoire pour les petits corps de texte.
  static const Color deepBrown = Color(0xFF4A382B);

  // ---------------------------------------------------------------------
  // Bordures
  // ---------------------------------------------------------------------

  /// Bordure discrète beige clair — séparations entre image et contenu,
  /// cadres de cartes.
  static const Color border = Color(0xFFE4D6C1);

  /// Bordure champagne, plus affirmée — champs actifs, cartes
  /// sélectionnées.
  static const Color borderStrong = Color(0xFFC6A36B);

  // ---------------------------------------------------------------------
  // États fonctionnels
  // ---------------------------------------------------------------------
  // Restent dans une famille chaude pour ne pas introduire de nouvelle
  // couleur dominante ; seule la fonction (succès / attention / erreur)
  // change de teinte, jamais la température de la palette.

  /// Succès / confirmation. Vert olive sourd, jamais le vert de l'ancien
  /// thème : utilisé uniquement en petites touches (icône, liseré).
  static const Color success = Color(0xFF5B7049);
  static const Color successSurface = Color(0xFFE8ECDD);

  /// Attention / information à vérifier.
  static const Color warning = Color(0xFF9A6A2B);
  static const Color warningSurface = Color(0xFFF2E3C8);

  /// Erreur / action bloquante.
  static const Color error = Color(0xFFA4442E);
  static const Color errorSurface = Color(0xFFF3DCD4);

  // ---------------------------------------------------------------------
  // Overlays & ombres
  // ---------------------------------------------------------------------

  /// Ombre très légère, pour les rares composants qui en ont besoin
  /// (modales, carte au survol). Ne jamais utiliser noir pur.
  static const Color shadow = Color(0x1A4A382B);

  /// Voile sombre sur photographie, pour la lisibilité d'un texte ou
  /// badge posé sur une image (ex. bandeau prix sur photo de bien).
  static const Color scrimOnPhoto = Color(0x992A1F16);
}
