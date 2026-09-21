import 'package:flutter/material.dart';

class Home {
  final String title, district, type, price, description;
  final num? rent;
  final int? rooms;
  final Color color;
  final String? id;
  final String city;
  final bool isDemo;
  const Home(
    this.title,
    this.district,
    this.type,
    this.price,
    this.rent,
    this.rooms,
    this.description,
    this.color, {
    this.id,
    this.city = 'Dakar',
    this.isDemo = true,
  });

  String get location => '$city · $district';
  String get monthlyPrice =>
      rent == null ? 'Loyer non renseigné' : '$price FCFA / mois';
  String get roomsLabel => rooms == null
      ? 'Chambres non renseignées'
      : '$rooms chambre${rooms! > 1 ? 's' : ''}';

  factory Home.fromAnnouncement(Map<String, dynamic> row) {
    String value(String key, String fallback) {
      final text = row[key]?.toString().trim();
      return text == null || text.isEmpty ? fallback : text;
    }

    final rawRent = row['loyer_mensuel'];
    final rent = rawRent == null ? null : num.parse(rawRent.toString());
    if (rent != null && (!rent.isFinite || rent < 0)) {
      throw const FormatException('Loyer invalide');
    }
    final type = value('type_logement', 'Type non renseigné');
    final city = value('ville', 'Ville non renseignée');
    final parts = rent == null
        ? null
        : rent.toStringAsFixed(rent == rent.roundToDouble() ? 0 : 2).split('.');
    final price = parts == null
        ? ''
        : parts.first.replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]} ',
              ) +
              (parts.length > 1 ? ',${parts.last}' : '');
    return Home(
      '$type à $city',
      value('quartier', 'Quartier non renseigné'),
      type,
      price,
      rent,
      null,
      'Description non renseignée.',
      const Color(0xFFEAF2E9),
      id: row['id']?.toString(),
      city: city,
      isDemo: false,
    );
  }
}

const homes = [
  Home(
    'Un appartement pour se sentir chez soi',
    'Ouakam',
    'Appartement',
    '180 000',
    180000,
    2,
    'Un séjour lumineux, deux chambres et un balcon. Exemple fictif pour découvrir le parcours de recherche.',
    Color(0xFFD9E3D5),
  ),
  Home(
    'Un studio, votre nouveau départ',
    'Sacré-Cœur',
    'Studio',
    '95 000',
    95000,
    1,
    'Un espace compact avec coin cuisine et salle d’eau. Exemple fictif, aucun logement réellement proposé.',
    Color(0xFFE8D8C2),
  ),
  Home(
    'De la place pour toute la famille',
    'Yoff',
    'Maison',
    '300 000',
    300000,
    3,
    'Une maison avec séjour, trois chambres et cour. Exemple fictif pour la démonstration.',
    Color(0xFFD3DFE4),
  ),
];
