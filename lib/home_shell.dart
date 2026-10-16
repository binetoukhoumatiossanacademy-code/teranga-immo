import 'package:flutter/material.dart';

import 'account_page.dart';
import 'account_service.dart';
import 'annonces_repository.dart';
import 'detail_page.dart';
import 'home.dart';
import 'models/account_role.dart';
import 'welcome_page.dart';
import 'tenant_flow.dart';
import 'home_art.dart';
import 'home_landing.dart';
import 'teranga_theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.repository,
    this.configurationError,
    this.account,
  });
  final AccountController? account;
  final AnnoncesRepository? repository;
  final String? configurationError;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int page = 0;
  bool profileChosen = false;
  bool tenantFlowActive = false;
  AccountRole selectedRole = AccountRole.locataire;
  String district = '', type = 'Tous';
  int? budget, rooms;
  List<Home> results = [];
  bool loading = false;
  String? loadError;
  int requestId = 0;
  bool get connected =>
      widget.repository != null || widget.configurationError != null;
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.account?.addListener(accountChanged);
    if (widget.account?.recovering == true) {
      profileChosen = true;
      tenantFlowActive = false;
      page = 4;
    }
    if (connected && widget.account?.recovering == true) {
      loadAnnouncements();
    } else {
      results = homes;
    }
  }

  void accountChanged() {
    if (mounted && widget.account?.recovering == true) {
      setState(() {
        profileChosen = true;
        tenantFlowActive = false;
        page = 4;
      });
    }
  }

  Future<void> loadAnnouncements() async {
    final current = ++requestId;
    setState(() {
      loading = true;
      loadError = null;
      results = [];
    });
    if (widget.repository == null) {
      setState(() {
        loading = false;
        loadError = widget.configurationError;
      });
      return;
    }
    try {
      final data = await widget.repository!.search(
        AnnouncementFilters(
          city: cityController.text,
          district: district,
          type: type,
          maxRent: budget,
        ),
      );
      if (!mounted || current != requestId) return;
      setState(() {
        results = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted || current != requestId) return;
      setState(() {
        loading = false;
        loadError =
            'Impossible de charger les annonces. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  Widget remoteStatus() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: CircularProgressIndicator(),
          ),
        Text(
          loading
              ? 'Chargement des annonces…'
              : loadError ??
                    'Aucune annonce approuvée ne correspond à votre recherche.',
          textAlign: TextAlign.center,
        ),
        if (loadError != null && widget.repository != null)
          TextButton(
            onPressed: loadAnnouncements,
            child: const Text('Réessayer'),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    widget.account?.removeListener(accountChanged);
    cityController.dispose();
    districtController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  void detail(Home home) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => DetailPage(home: home)));

  @override
  Widget build(BuildContext context) {
    if (!profileChosen) {
      return WelcomePage(
        onContinue: (role) {
          setState(() {
            selectedRole = role;
            profileChosen = true;
            tenantFlowActive = role == AccountRole.locataire;
            page = role == AccountRole.locataire ? 0 : 4;
          });
          if (role != AccountRole.locataire && connected) loadAnnouncements();
        },
      );
    }
    if (tenantFlowActive) {
      return TenantFlow(
        repository: widget.repository,
        configurationError: widget.configurationError,
        account: widget.account,
      );
    }
    final pages = [
      HomeLanding(
        onSearch: () => setState(() => page = 1),
        onDetail: () {
          if (!connected) {
            detail(homes.first);
          } else if (results.isNotEmpty) {
            detail(results.first);
          }
        },
        connected: connected,
        announcement: connected && results.isNotEmpty ? results.first : null,
        status: remoteStatus(),
      ),
      search(),
      placeholder(
        Icons.favorite_border,
        'Vos coups de cœur, au même endroit',
        'La connexion et la sauvegarde des favoris seront disponibles au jalon 4.',
        'Explorer les logements',
      ),
      placeholder(
        Icons.add_home_outlined,
        'Proposez votre logement en confiance',
        'La publication sera disponible au jalon 5. Chaque annonce sera examinée avant son affichage public.',
        'Voir les exemples',
      ),
      AccountPage(account: widget.account, initialRole: selectedRole),
    ];
    return Scaffold(
      appBar: page == 0
          ? null
          : AppBar(
              backgroundColor: sand,
              title: const Row(
                children: [
                  Icon(Icons.roofing, color: green, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Teranga Immo',
                    style: TextStyle(fontWeight: FontWeight.w800, color: green),
                  ),
                ],
              ),
            ),
      body: Column(
        children: [
          if (page != 0 && !connected)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE9B2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'DÉMONSTRATION • Logements fictifs • Aucun contact réel',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(page == 0 ? 0 : 20),
                  child: pages[page],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5F1E8),
        height: 72,
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Rechercher'),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Publier',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget listing(List<Home> items) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth > 850
          ? 3
          : constraints.maxWidth > 560
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items
            .map(
              (h) => SizedBox(
                width: (constraints.maxWidth - (count - 1) * 16) / count,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeArt(home: h),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.monthlyPrice,
                              style: const TextStyle(
                                color: green,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              h.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(h.location),
                            Text('${h.type} · ${h.roomsLabel}'),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: () => detail(h),
                              child: const Text("Voir l’annonce"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Widget search() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Votre recherche, à votre rythme',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        connected
            ? 'Annonces approuvées · jusqu’à 100 résultats récents.'
            : 'Filtres appliqués uniquement aux exemples fictifs de Dakar.',
      ),
      const SizedBox(height: 24),
      if (connected)
        TextField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'Ville',
            hintText: 'Toutes les villes',
          ),
        )
      else
        const Text('Ville : Dakar'),
      const SizedBox(height: 12),
      TextField(
        controller: districtController,
        decoration: const InputDecoration(
          labelText: 'Quartier',
          hintText: 'Ex. Ouakam',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: budgetController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Loyer maximum (FCFA)',
          hintText: 'Ex. 200000',
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: type,
        key: ValueKey('type-$type'),
        decoration: const InputDecoration(labelText: 'Type de logement'),
        items: [
          'Tous',
          'Appartement',
          'Studio',
          'Maison',
        ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => type = v!),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        initialValue: rooms ?? 0,
        key: ValueKey('rooms-$rooms'),
        decoration: InputDecoration(
          labelText: 'Nombre de chambres',
          helperText: connected
              ? 'Information non disponible dans ces annonces.'
              : null,
        ),
        items: [0, 1, 2, 3]
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v == 0 ? 'Tous' : '$v'),
              ),
            )
            .toList(),
        onChanged: connected
            ? null
            : (v) => setState(() => rooms = v == 0 ? null : v),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        children: [
          FilledButton(
            onPressed: () {
              final value = budgetController.text.replaceAll(RegExp(r'\s'), '');
              final parsed = int.tryParse(value);
              if (value.isNotEmpty && (parsed == null || parsed < 0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saisissez un loyer positif en FCFA.'),
                  ),
                );
                return;
              }
              setState(() {
                budget = parsed;
                district = districtController.text.trim().toLowerCase();
                if (connected) return;
                results = homes
                    .where(
                      (h) =>
                          h.district.toLowerCase().contains(district) &&
                          (budget == null ||
                              (h.rent != null && h.rent! <= budget!)) &&
                          (type == 'Tous' || h.type == type) &&
                          (rooms == null || h.rooms == rooms),
                    )
                    .toList();
              });
              if (connected) loadAnnouncements();
            },
            child: const Text('Rechercher'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                cityController.clear();
                districtController.clear();
                budgetController.clear();
                district = '';
                budget = null;
                rooms = null;
                type = 'Tous';
                results = connected ? [] : homes;
              });
              if (connected) loadAnnouncements();
            },
            child: const Text('Effacer les filtres'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        '${results.length} résultat(s)${connected ? '' : ' de démonstration'}',
      ),
      const SizedBox(height: 12),
      if (connected && (loading || loadError != null || results.isEmpty))
        remoteStatus()
      else if (results.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun exemple ne correspond. Essayez un autre quartier ou élargissez vos filtres.',
          ),
        )
      else
        listing(results),
    ],
  );

  Widget placeholder(IconData icon, String title, String text, String action) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 72, color: green),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() => page = 1),
                child: Text(action),
              ),
            ],
          ),
        ),
      );
}
