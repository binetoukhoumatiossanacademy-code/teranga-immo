import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'models/account_role.dart';

/// Écran de confirmation après le choix de profil — référence
/// « Parfait ! » (section 11.1). Étape 2 sur 3.
class RoleConfirmationPage extends StatelessWidget {
  const RoleConfirmationPage({
    super.key,
    required this.role,
    required this.onContinue,
    required this.onBack,
  });

  final AccountRole role;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  static const _subtitles = {
    AccountRole.locataire:
        'Nous vous proposerons des logements qui correspondent à vos critères.',
    AccountRole.proprietaire:
        'Vous pourrez publier votre bien et le gérer en toute simplicité.',
    AccountRole.agence:
        'Vous pourrez centraliser et gérer toutes vos annonces.',
  };

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TerangaSpacing.xl,
                TerangaSpacing.md,
                TerangaSpacing.xl,
                TerangaSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(LucideIcons.arrow_left),
                        color: TerangaColors.deepBrown,
                      ),
                      const Spacer(),
                      const TerangaLogo(variant: TerangaLogoVariant.compact),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: TerangaSpacing.xl),
                  const _StepProgressBar(step: 2, of: 3),
                  const SizedBox(height: TerangaSpacing.giant),
                  const Center(child: TerangaArchIllustration(size: 150)),
                  const SizedBox(height: TerangaSpacing.xxl),
                  Text(
                    'Parfait\u00a0!',
                    textAlign: TextAlign.center,
                    style: TerangaTypography.sectionTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: TerangaSpacing.sm),
                  Text(
                    'Vous êtes ${role.label.toLowerCase()}.',
                    textAlign: TextAlign.center,
                    style: TerangaTypography.bodyStrong,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitles[role]!,
                    textAlign: TextAlign.center,
                    style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                  ),
                  const SizedBox(height: TerangaSpacing.giant),
                  FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Continuer  →'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step, required this.of});
  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: step / of,
            minHeight: 4,
            backgroundColor: TerangaColors.border,
            valueColor: const AlwaysStoppedAnimation(TerangaColors.gold),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('$step / $of', style: TerangaTypography.meta),
    ],
  );
}
