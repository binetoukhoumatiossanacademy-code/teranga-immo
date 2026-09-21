import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_landing.dart';
import 'home.dart';
import 'app_config.dart';
import 'annonces_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  if (!config.isProvided) {
    runApp(const TerangaApp());
    return;
  }
  if (!config.isValid) {
    runApp(
      const TerangaApp(
        configurationError: 'Configuration Supabase incomplète ou invalide.',
      ),
    );
    return;
  }
  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    runApp(
      TerangaApp(
        repository: SupabaseAnnoncesRepository(Supabase.instance.client),
      ),
    );
  } catch (_) {
    runApp(
      const TerangaApp(
        configurationError:
            'Impossible de démarrer la connexion. Veuillez relancer l’application.',
      ),
    );
  }
}

const green = Color(0xFF0D6B3D);
const sand = Color(0xFFFAFBF8);

class TerangaApp extends StatelessWidget {
  const TerangaApp({super.key, this.repository, this.configurationError});
  final AnnoncesRepository? repository;
  final String? configurationError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Teranga Immo',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      fontFamily: 'Poppins',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
      scaffoldBackgroundColor: sand,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    ),
    home: HomeShell(
      repository: repository,
      configurationError: configurationError,
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.repository, this.configurationError});
  final AnnoncesRepository? repository;
  final String? configurationError;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int page = 0;
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
    if (connected) {
      loadAnnouncements();
    } else {
      results = homes;
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
      placeholder(
        Icons.person_outline,
        'Bienvenue chez Teranga Immo',
        'Un projet BK Technologies. Les comptes seront disponibles au jalon 4.',
        'Découvrir les logements',
      ),
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
            home.type == 'Maison' ? Icons.cottage_outlined : Icons.apartment,
            size: 106,
            color: green.withValues(alpha: .65),
          ),
        ),
        if (home.isDemo)
          const Positioned(
            left: 12,
            top: 12,
            child: Chip(
              label: Text('Exemple fictif', style: TextStyle(fontSize: 11)),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 8,
          child: Text(
            home.isDemo ? 'Illustration' : 'Photo non renseignée',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class DetailPage extends StatelessWidget {
  final Home home;
  const DetailPage({super.key, required this.home});
  void explain(BuildContext context, String text) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(home.isDemo ? 'Mode démonstration' : 'Information'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Détail du logement')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              home.isDemo
                  ? 'DÉMONSTRATION · Aucune annonce réelle'
                  : 'Annonce approuvée',
              style: const TextStyle(fontWeight: FontWeight.bold, color: green),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: HomeArt(home: home),
            ),
            const SizedBox(height: 24),
            Text(
              home.title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              home.monthlyPrice,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 12),
            Text('${home.location} · ${home.roomsLabel}'),
            const SizedBox(height: 24),
            const Text(
              'Le logement',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(home.description),
            const SizedBox(height: 16),
            Text(
              home.isDemo
                  ? 'Disponibilité : fictive\nÉquipements et conditions : non renseignés dans cet exemple.'
                  : 'Disponibilité, équipements et conditions : non renseignés.',
            ),
            const SizedBox(height: 24),
            if (!home.isDemo)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Niveau de contrôle non renseigné. Une approbation de publication ne constitue pas une vérification sur place.',
                  ),
                ),
              )
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprendre le niveau de contrôle',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cet exemple n’a fait l’objet d’aucun contrôle.\n\nDéclarée par le propriétaire : informations fournies par l’annonceur.\nInformations contrôlées : les éléments réellement examinés seront précisés.\nVérifiée par Teranga Immo : le périmètre et la date de vérification seront explicités.\n\nUne mise en avant Premium ne constitue jamais une vérification.',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => explain(
                    context,
                    'Les favoris et la connexion ne sont pas encore disponibles. Aucun favori n’est enregistré.',
                  ),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Ajouter aux favoris'),
                ),
                OutlinedButton.icon(
                  onPressed: () => explain(
                    context,
                    home.isDemo
                        ? 'Ce logement est fictif : aucun propriétaire ne peut être contacté.'
                        : 'Coordonnées de contact non renseignées pour cette annonce.',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
