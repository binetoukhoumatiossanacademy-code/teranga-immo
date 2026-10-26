/// Tokens d'espacement et de géométrie — section 6 et 12.3 du prompt de
/// direction artistique. Échelle en multiples de 4 px, et rayons de
/// bordure réduits pour un langage graphique éditorial plutôt que
/// « capsule ».
abstract final class TerangaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 64;
}

/// Rayons de bordure. Les grandes surfaces restent sobres (8–12 px), les
/// badges presque droits (3–5 px) : aucun composant ne doit prendre une
/// apparence de capsule.
abstract final class TerangaRadius {
  static const double badge = 4;
  static const double field = 7;
  static const double button = 8;
  static const double card = 10;
  static const double modal = 12;
}

/// Points de rupture responsive — section 9.3 du prompt.
abstract final class TerangaBreakpoints {
  static const double smallPhone = 480;
  static const double tablet = 768;
  static const double smallDesktop = 1024;
  static const double desktop = 1280;

  static bool isTablet(double width) => width >= tablet && width < smallDesktop;
  static bool isDesktop(double width) => width >= smallDesktop;
  static bool isMobile(double width) => width < tablet;
}
