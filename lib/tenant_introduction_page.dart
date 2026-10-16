import 'package:flutter/material.dart';

const _green = Color(0xFF00664B);
const _gold = Color(0xFFF0AA0C);

class TenantIntroductionPage extends StatelessWidget {
  const TenantIntroductionPage({super.key, required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFCFAF5),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/brand/logo_original.png',
                        width: 90,
                        height: 90,
                        semanticLabel: 'Logo original Teranga Immo',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F1E7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 19, color: _green),
                            SizedBox(width: 7),
                            Text(
                              'Locataire',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trouvez votre\nlogement plus\nsimplement',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.08,
                      letterSpacing: -.9,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Recherchez selon vos besoins, consultez les informations importantes et le niveau de contrôle des annonces avant de vous déplacer.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF4E5261),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/homes/locataire_illustration.png',
                      fit: BoxFit.contain,
                      semanticLabel:
                          'Une main tient les clés d’un logement lumineux au Sénégal',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Comment ça marche ?',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 14),
                  step(
                    '1',
                    'Recherchez',
                    'Indiquez où et quel logement vous recherchez.',
                    Icons.search,
                  ),
                  const SizedBox(height: 16),
                  step(
                    '2',
                    'Comparez',
                    'Consultez le prix, les photos, les caractéristiques et le niveau de contrôle.',
                    Icons.copy_outlined,
                  ),
                  const SizedBox(height: 16),
                  step(
                    '3',
                    'Contactez',
                    'Contactez le propriétaire ou l’agence si le logement vous intéresse.',
                    Icons.chat_bubble_outline,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFDF9D)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: _gold,
                          size: 29,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Chaque annonce indique clairement son niveau de contrôle.',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.45,
                              color: Color(0xFF4E5261),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 44),
                            foregroundColor: _green,
                          ),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Comprendre le niveau de contrôle',
                              ),
                              content: const Text(
                                'Déclarée par le propriétaire : informations fournies par l’annonceur.\n\nInformations contrôlées : les éléments réellement examinés seront précisés.\n\nVérifiée par Teranga Immo : le périmètre et la date de vérification seront explicités.\n\nUne mise en avant Premium ne constitue jamais une vérification.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Compris'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text(
                            'En savoir plus →',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: onSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Chercher votre logement',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget step(String number, String title, String description, IconData icon) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F1E7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _green, size: 34),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$number — ',
                        style: const TextStyle(color: _gold),
                      ),
                      TextSpan(text: title),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF4E5261),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
