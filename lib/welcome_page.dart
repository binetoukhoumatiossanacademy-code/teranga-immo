import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'design_system/design_system.dart';
import 'models/account_role.dart';

/// Choix de profil — référence « 2. Connexion / Inscription » (section
/// 11.1 de la direction artistique). Étape 1 sur 3 du parcours
/// d'orientation (onboarding → profil → confirmation).
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.onContinue, this.onBack});
  final ValueChanged<AccountRole> onContinue;
  final VoidCallback? onBack;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  AccountRole selected = AccountRole.locataire;

  static const _descriptions = {
    AccountRole.locataire: 'Je recherche un logement',
    AccountRole.proprietaire: 'Je souhaite publier un bien',
    AccountRole.agence: 'Je gère plusieurs logements',
  };

  static const _icons = {
    AccountRole.locataire: LucideIcons.house,
    AccountRole.proprietaire: LucideIcons.key_round,
    AccountRole.agence: LucideIcons.building_complex,
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
            child: SingleChildScrollView(
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
                      if (widget.onBack != null)
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(LucideIcons.arrow_left),
                          color: TerangaColors.deepBrown,
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      const TerangaLogo(
                        variant: TerangaLogoVariant.stacked,
                        markSize: 28,
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: TerangaSpacing.xl),
                  const _StepProgress(step: 1, of: 3),
                  const SizedBox(height: TerangaSpacing.lg),
                  const Text('VOUS ÊTES\u202f?', style: TerangaTypography.eyebrow),
                  const SizedBox(height: TerangaSpacing.sm),
                  Text('Choisissez votre profil', style: TerangaTypography.sectionTitle),
                  const SizedBox(height: 6),
                  Text(
                    'Cela nous permettra de vous proposer une expérience adaptée à vos besoins.',
                    style: TerangaTypography.body.copyWith(color: TerangaColors.taupe),
                  ),
                  const SizedBox(height: TerangaSpacing.xl),
                  for (final role in AccountRole.values) ...[
                    _ProfileCard(
                      role: role,
                      description: _descriptions[role]!,
                      icon: _icons[role]!,
                      selected: selected == role,
                      onTap: () => setState(() => selected = role),
                    ),
                    if (role != AccountRole.values.last)
                      const SizedBox(height: TerangaSpacing.md),
                  ],
                  const SizedBox(height: TerangaSpacing.xl),
                  FilledButton(
                    onPressed: () => widget.onContinue(selected),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Continuer  →'),
                  ),
                  const SizedBox(height: TerangaSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shield_check, size: 18, color: TerangaColors.taupe),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vos informations sont protégées et utilisées uniquement '
                          'pour vous offrir une meilleure expérience.',
                          style: TerangaTypography.meta,
                        ),
                      ),
                    ],
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

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.of});
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.role,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final AccountRole role;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? TerangaColors.beige : TerangaColors.white,
      borderRadius: BorderRadius.circular(TerangaRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(TerangaRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TerangaSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TerangaRadius.card),
            border: Border.all(
              color: selected ? TerangaColors.gold : TerangaColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: TerangaColors.ivory,
                  borderRadius: BorderRadius.circular(TerangaRadius.field),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: TerangaColors.gold, size: 24),
              ),
              const SizedBox(width: TerangaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label, style: TerangaTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TerangaTypography.meta,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TerangaSpacing.sm),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? TerangaColors.gold : Colors.transparent,
                  border: Border.all(
                    color: selected ? TerangaColors.gold : TerangaColors.border,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(LucideIcons.check, size: 15, color: TerangaColors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
