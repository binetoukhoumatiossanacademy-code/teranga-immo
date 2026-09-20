import 'package:flutter/material.dart';

const _green = Color(0xFF0D6B3D);
const _ink = Color(0xFF143C2B);
const _gold = Color(0xFFE8A315);

/// Accueil construit d'après les maquettes fournies. Aucun service distant.
class HomeLanding extends StatelessWidget {
  const HomeLanding({
    super.key,
    required this.onSearch,
    required this.onDetail,
  });
  final VoidCallback onSearch;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 650;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/brand/logo_original.png',
                      width: 80,
                      height: 80,
                      semanticLabel: 'Logo original Teranga Immo',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2E9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: _green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Dakar, Sénégal',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Trouvez votre logement\navec plus de confiance.',
                style: TextStyle(
                  fontSize: wide ? 40 : 28,
                  height: 1.2,
                  letterSpacing: -.7,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Un nouveau chez-vous commence ici.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B756F)),
              ),
              const SizedBox(height: 22),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCE4DD)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: _green, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Où cherchez-vous ?',
                            style: TextStyle(
                              color: Color(0xFF737B76),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          'Dakar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18, color: _green),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _filter(Icons.payments_outlined, 'Prix'),
                  const SizedBox(width: 10),
                  _filter(Icons.apartment_outlined, 'Type'),
                  const SizedBox(width: 10),
                  _filter(Icons.bed_outlined, 'Chambres'),
                  const SizedBox(width: 10),
                  _filter(Icons.tune, 'Filtres'),
                ],
              ),
              const SizedBox(height: 23),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5DF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: Color(0xFF98690C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode démo · annonces et visuels fictifs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C5A17),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'À découvrir à Dakar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onSearch,
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _listing(context)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _trustPanel()),
                  ],
                )
              else
                _listing(context),
              const SizedBox(height: 20),
              if (!wide) _trustPanel(),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'TERANGA IMMO  ·  BK TECHNOLOGIES',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: Color(0xFF7B867E),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );

  Widget _filter(IconData icon, String label) => Expanded(
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onSearch,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5EAE4)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: _green, size: 23),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _listing(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3E9E2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080D3A22),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.95,
              child: Image.asset(
                'assets/homes/salon_demo.png',
                fit: BoxFit.cover,
                semanticLabel: 'Illustration fictive : salon lumineux aux tons beige et vert',
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'EXEMPLE FICTIF',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w700,
                    color: _green,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '180 000 FCFA',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    TextSpan(
                      text: ' / mois',
                      style: TextStyle(fontSize: 12, color: Color(0xFF717A73)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Un appartement pour se sentir chez soi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: _green),
                  SizedBox(width: 5),
                  Text(
                    'Ouakam, Dakar',
                    style: TextStyle(fontSize: 12, color: Color(0xFF657267)),
                  ),
                  Spacer(),
                  Icon(Icons.bed_outlined, size: 16, color: _green),
                  SizedBox(width: 5),
                  Text(
                    '2 chambres',
                    style: TextStyle(fontSize: 12, color: Color(0xFF657267)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDetail,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Voir l’annonce'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _trustPanel() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF3EB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.fact_check_outlined, color: _green, size: 27),
        SizedBox(height: 12),
        Text(
          'La confiance commence\npar des informations claires.',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _ink,
            height: 1.3,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Quartier, loyer, chambres : les détails utiles pour préparer votre recherche.',
          style: TextStyle(fontSize: 13, color: Color(0xFF657267), height: 1.5),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.circle, color: _gold, size: 7),
            SizedBox(width: 8),
            Text(
              'Dakar, pour commencer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _green,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
