import 'package:flutter/material.dart';
import 'home.dart';

const tenantGreen = Color(0xFF00664B);
const tenantGold = Color(0xFFF0AA0C);
const tenantBackground = Color(0xFFFCFAF5);
const tenantInk = Color(0xFF20364C);
const tenantDemoPhotos = [
  'assets/homes/tenant_reference_living.png',
  'assets/homes/tenant_reference_bedroom.png',
  'assets/homes/tenant_reference_kitchen.png',
];

class TenantHeader extends StatelessWidget {
  const TenantHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Image.asset(
        'assets/brand/logo_original.png',
        width: 82,
        height: 82,
        semanticLabel: 'Logo original Teranga Immo',
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F1E7),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 18, color: tenantGreen),
            SizedBox(width: 6),
            Text(
              'Locataire',
              style: TextStyle(
                color: tenantGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class TenantNotice extends StatelessWidget {
  const TenantNotice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF7E1) : const Color(0xFFF1F3F5),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: warning ? const Color(0xFFFFDF9D) : const Color(0xFFE3E7EA),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 17,
          color: warning ? const Color(0xFFAA7400) : tenantInk,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: tenantInk,
            ),
          ),
        ),
      ],
    ),
  );
}

class TenantPhoto extends StatelessWidget {
  const TenantPhoto({
    super.key,
    required this.home,
    this.index = 0,
    this.height = 180,
  });
  final Home home;
  final int index;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: home.isDemo
        ? Image.asset(
            tenantDemoPhotos[index],
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            semanticLabel:
                'Illustration de maquette, sans lien avec un logement réel',
          )
        : Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFFEAF2E9),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: tenantGreen,
                ),
                SizedBox(height: 8),
                Text(
                  'Photo non renseignée',
                  style: TextStyle(color: tenantInk, fontSize: 12),
                ),
              ],
            ),
          ),
  );
}

class TenantListingCard extends StatelessWidget {
  const TenantListingCard({
    super.key,
    required this.home,
    required this.favorite,
    required this.onOpen,
    required this.onFavorite,
  });
  final Home home;
  final bool favorite;
  final VoidCallback onOpen, onFavorite;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE3E8E3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TenantPhoto(home: home, height: 175),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: favorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      onPressed: onFavorite,
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                        color: favorite ? Colors.red : tenantInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    home.monthlyPrice,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: tenantGreen,
                    ),
                  ),
                  Text(
                    home.location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tenantInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${home.type} · ${home.roomsLabel}',
                    style: const TextStyle(fontSize: 12, color: tenantInk),
                  ),
                  const Divider(height: 18),
                  const Row(
                    children: [
                      Icon(Icons.circle, size: 14, color: Color(0xFF9CA3AF)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Niveau de contrôle non renseigné',
                          style: TextStyle(fontSize: 11, color: tenantInk),
                        ),
                      ),
                    ],
                  ),
                  if (home.isDemo)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Exemple fictif · illustration de maquette',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF657267),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onOpen,
                      child: const Text('Voir l’annonce'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

ButtonStyle tenantPrimaryStyle() => FilledButton.styleFrom(
  backgroundColor: tenantGreen,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(50),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
);

Future<void> showTenantControlInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Niveau de contrôle Teranga Immo'),
    content: const Text(
      'Niveau de contrôle non renseigné. Une approbation de publication ne constitue pas une vérification sur place.\n\nPremium = visibilité payante. Le paiement ne donne jamais le statut Vérifié.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Compris'),
      ),
    ],
  ),
);

Future<void> showTenantContact(
  BuildContext context,
  Home home,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: tenantBackground,
  constraints: const BoxConstraints(maxWidth: 440),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fermer le contact',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            const Text(
              'Contacter l’annonceur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tenantGreen,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFD9EEE3),
                  child: Icon(Icons.person_outline, color: tenantGreen),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Annonceur non renseigné',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tenantInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TenantNotice(
              home.isDemo
                  ? 'Ce logement est fictif : aucun propriétaire ne peut être contacté.'
                  : 'Coordonnées de contact non renseignées pour cette annonce.',
              warning: true,
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call_outlined, size: 18),
                        SizedBox(width: 6),
                        Flexible(child: Text('Appeler')),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 18),
                        SizedBox(width: 6),
                        Flexible(child: Text('WhatsApp')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Les appels et WhatsApp seront accessibles lorsque des coordonnées réelles et autorisées seront disponibles.',
              style: TextStyle(fontSize: 12, color: tenantInk),
            ),
          ],
        ),
      ),
    ),
  ),
);
