import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'models/account_role.dart';

const _welcomeGreen = Color(0xFF00664B);
const _welcomeGold = Color(0xFFF0AA0C);

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.onContinue});
  final ValueChanged<AccountRole> onContinue;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  AccountRole selected = AccountRole.locataire;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFCFAF5),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width < 700 ? 440 : 1180,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResponsiveSections(
                    first: [
                      Center(
                        child: Image.asset(
                          'assets/brand/logo_original.png',
                          width: 190,
                          height: 190,
                          semanticLabel: 'Logo original Teranga Immo',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Bienvenue sur\nTeranga Immo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.18,
                          fontWeight: FontWeight.w700,
                          color: _welcomeGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Une façon plus simple de chercher, publier et gérer un logement au Sénégal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4E5261),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    second: [
                      const Text(
                        'Vous êtes ?',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: _welcomeGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      profileCard(
                        AccountRole.locataire,
                        'Je cherche un logement',
                        Icons.home_outlined,
                      ),
                      if (selected == AccountRole.locataire) ...[
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E1),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(color: _welcomeGold, width: 4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: _welcomeGold, size: 23),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Trouvez votre logement plus simplement et consultez les informations importantes avant de vous déplacer.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.45,
                                    color: Color(0xFF4E5261),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      profileCard(
                        AccountRole.proprietaire,
                        'Je veux proposer un logement',
                        Icons.key_outlined,
                      ),
                      const SizedBox(height: 12),
                      profileCard(
                        AccountRole.agence,
                        'Je gère plusieurs logements',
                        Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 28),
                      ResponsiveAction(
                        child: FilledButton(
                          onPressed: () => widget.onContinue(selected),
                          style: FilledButton.styleFrom(
                            backgroundColor: _welcomeGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 23),
                            ],
                          ),
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
    ),
  );

  Widget profileCard(AccountRole role, String description, IconData icon) {
    final active = selected == role;
    return Semantics(
      selected: active,
      child: Material(
        color: active ? const Color(0xFFEDF7F0) : Colors.white,
        elevation: 2,
        shadowColor: const Color(0x18000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: active ? _welcomeGreen : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => selected = role),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F0E6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _welcomeGreen, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _welcomeGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4E5261),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  active ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: active ? _welcomeGreen : const Color(0xFFB9B9B9),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
