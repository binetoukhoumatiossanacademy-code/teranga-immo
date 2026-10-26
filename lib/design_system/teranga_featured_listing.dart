/// Modèle d'affichage pour la section « Biens en vedette » de l'accueil.
///
/// Distinct du modèle `Home` (lib/home.dart) utilisé par la recherche et
/// le détail connectés à Supabase : ce type ne sert qu'à présenter des
/// visuels fictifs sur l'accueil, sans toucher au chemin de données réel.
/// Aucune de ces entrées n'est, ni ne deviendra, une annonce réelle.
class TerangaFeaturedListing {
  const TerangaFeaturedListing({
    required this.title,
    required this.district,
    required this.city,
    required this.monthlyRent,
    required this.type,
    required this.rooms,
    required this.bathrooms,
    required this.surfaceSqm,
    this.photoAsset,
  });

  final String title;
  final String district;
  final String city;
  final int monthlyRent;
  final String type;
  final int rooms;
  final int bathrooms;
  final int surfaceSqm;

  /// Chemin d'asset d'illustration. Si absent, la carte affiche un
  /// panneau illustré sobre plutôt qu'une fausse photographie.
  final String? photoAsset;

  String get formattedRent {
    final text = monthlyRent.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$text FCFA / mois';
  }

  String get location => '$district, $city';
}

/// Trois exemples illustratifs pour la page d'accueil. Des logements
/// fictifs, non liés à des annonces réelles.
const List<TerangaFeaturedListing> terangaFeaturedListings = [
  TerangaFeaturedListing(
    title: 'Appartement lumineux',
    district: 'Almadies',
    city: 'Dakar',
    monthlyRent: 250000,
    type: 'Appartement',
    rooms: 3,
    bathrooms: 2,
    surfaceSqm: 120,
    photoAsset: 'assets/homes/salon_demo.png',
  ),
  TerangaFeaturedListing(
    title: 'Studio cosy',
    district: 'Plateau',
    city: 'Dakar',
    monthlyRent: 120000,
    type: 'Studio',
    rooms: 1,
    bathrooms: 1,
    surfaceSqm: 38,
  ),
  TerangaFeaturedListing(
    title: 'Villa familiale',
    district: 'Ngor',
    city: 'Dakar',
    monthlyRent: 450000,
    type: 'Maison',
    rooms: 4,
    bathrooms: 3,
    surfaceSqm: 210,
  ),
];
