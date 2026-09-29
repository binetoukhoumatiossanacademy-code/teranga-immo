import 'package:flutter/material.dart';

import 'home.dart';
import 'teranga_theme.dart';

class HomeArt extends StatelessWidget {
  final Home home;
  const HomeArt({super.key, required this.home});
  @override
  Widget build(BuildContext context) => Container(
    height: 165,
    color: home.color,
    width: double.infinity,
    child: Stack(
      children: [
        Center(
          child: Icon(
            home.type == 'Maison' ? Icons.cottage_outlined : Icons.apartment,
            size: 106,
            color: green.withValues(alpha: .65),
          ),
        ),
        if (home.isDemo)
          const Positioned(
            left: 12,
            top: 12,
            child: Chip(
              label: Text('Exemple fictif', style: TextStyle(fontSize: 11)),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 8,
          child: Text(
            home.isDemo ? 'Illustration' : 'Photo non renseignée',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );
}
