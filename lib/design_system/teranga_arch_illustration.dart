import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'teranga_colors.dart';

/// Illustration légère en traits — une arche, un palmier et une maison —
/// utilisée sur les écrans d'onboarding et de confirmation quand aucune
/// photographie n'est disponible. Construite avec les composants du
/// design system plutôt qu'une image, pour rester cohérente avec
/// n'importe quelle couleur d'accent et ne dépendre d'aucun asset.
class TerangaArchIllustration extends StatelessWidget {
  const TerangaArchIllustration({super.key, this.size = 140, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? TerangaColors.gold;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArchPainter(color: tint),
        child: Padding(
          padding: EdgeInsets.only(top: size * 0.22),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: size * 0.08,
                bottom: size * 0.14,
                child: Icon(LucideIcons.tree_palm, color: tint, size: size * 0.34),
              ),
              Positioned(
                bottom: size * 0.12,
                child: Icon(LucideIcons.house, color: tint, size: size * 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.06,
      size.width * 0.88,
      size.height * 0.88,
    );
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + rect.width / 2)
      ..arcToPoint(
        Offset(rect.right, rect.top + rect.width / 2),
        radius: Radius.circular(rect.width / 2),
        clockwise: true,
      )
      ..lineTo(rect.right, rect.bottom);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) =>
      oldDelegate.color != color;
}
