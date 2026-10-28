import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'home.dart';

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
            home.type == 'Maison' ? LucideIcons.house : LucideIcons.building_complex,
            size: 96,
            color: TerangaColors.deepBrown.withValues(alpha: .5),
          ),
        ),
        if (home.isDemo)
          Positioned(
            left: 12,
            top: 12,
            child: Chip(
              label: const Text('Exemple fictif'),
              backgroundColor: TerangaColors.white.withValues(alpha: 0.85),
              labelStyle: TerangaTypography.meta.copyWith(fontSize: 11),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 8,
          child: Text(
            home.isDemo ? 'Illustration' : 'Photo non renseignée',
            style: TerangaTypography.meta,
          ),
        ),
      ],
    ),
  );
}
