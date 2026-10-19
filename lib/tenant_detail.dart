import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'tenant_widgets.dart';

class TenantDetail extends StatefulWidget {
  const TenantDetail({
    super.key,
    required this.home,
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
  });
  final Home home;
  final bool favorite;
  final VoidCallback onBack, onFavorite;
  @override
  State<TenantDetail> createState() => _TenantDetailState();
}

class _TenantDetailState extends State<TenantDetail> {
  int photo = 0;
  @override
  Widget build(BuildContext context) {
    final home = widget.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (home.isDemo)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: TenantNotice(
              'DÉMONSTRATION · Annonce fictive existante. Images de maquette, sans lien avec un logement réel.',
              warning: true,
            ),
          ),
        ResponsiveSections(
          first: [
            Stack(
              children: [
                TenantPhoto(
                  home: home,
                  index: photo,
                  height: MediaQuery.sizeOf(context).width >= 900 ? 320 : 225,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: FilledButton.tonalIcon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Résultats'),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: widget.favorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      onPressed: widget.onFavorite,
                      icon: Icon(
                        widget.favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.favorite ? Colors.red : tenantInk,
                      ),
                    ),
                  ),
                ),
                if (home.isDemo)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${photo + 1}/${tenantDemoPhotos.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            if (home.isDemo)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < tenantDemoPhotos.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                          child: Semantics(
                            button: true,
                            selected: photo == i,
                            label: 'Voir l’illustration ${i + 1}',
                            child: InkWell(
                              onTap: () => setState(() => photo = i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: photo == i
                                        ? tenantGreen
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TenantPhoto(
                                  home: home,
                                  index: i,
                                  height: 67,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          second: [
            const SizedBox(height: 18),
            Text(
              home.monthlyPrice,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: tenantGreen,
              ),
            ),
            Text(
              home.location,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: tenantInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${home.type} · ${home.roomsLabel}',
              style: const TextStyle(color: tenantInk, fontSize: 14),
            ),
            const Text(
              'Ameublement et salles de bain : non renseignés.',
              style: TextStyle(fontSize: 12, color: tenantInk),
            ),
            const SizedBox(height: 8),
            const TenantNotice('Disponibilité non renseignée.'),
            const Divider(height: 30),
            const Text(
              'À propos de ce logement',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: tenantInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              home.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: tenantInk,
              ),
            ),
            const Divider(height: 30),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Niveau de contrôle Teranga Immo',
                    style: TextStyle(
                      color: tenantInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Niveau de contrôle non renseigné',
                    style: TextStyle(color: tenantInk, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => showTenantControlInfo(context),
                    child: const Text(
                      'Voir ce qui a été contrôlé →',
                      style: TextStyle(color: tenantGreen),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),
            const Text(
              'Annonce publiée par',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: tenantInk,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFE3E7EA),
                  child: Icon(Icons.person_outline, color: tenantInk),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Annonceur non renseigné',
                    style: TextStyle(color: tenantInk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => showTenantContact(context, home),
              style: tenantPrimaryStyle(),
              child: const Text('Contacter →'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onFavorite,
              icon: Icon(
                widget.favorite ? Icons.favorite : Icons.favorite_border,
              ),
              label: Text(
                widget.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Favoris conservés uniquement pour cette session, sans sauvegarde de compte.',
              style: TextStyle(fontSize: 11, color: tenantInk),
            ),
            const Divider(height: 30),
            const TextButton(
              onPressed: null,
              child: Text('⚑ Signaler un problème avec cette annonce'),
            ),
            const Text(
              'Signalement non disponible actuellement. Aucun signalement n’est envoyé.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: tenantInk),
            ),
          ],
        ),
      ],
    );
  }
}
