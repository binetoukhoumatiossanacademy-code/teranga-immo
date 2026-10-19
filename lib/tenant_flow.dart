import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'account_page.dart';
import 'account_service.dart';
import 'annonces_repository.dart';
import 'home.dart';
import 'models/account_role.dart';
import 'tenant_detail.dart';
import 'tenant_introduction_page.dart';
import 'tenant_widgets.dart';

enum TenantScreen { introduction, search, results, detail, favorites, profile }

class TenantFlow extends StatefulWidget {
  const TenantFlow({
    super.key,
    this.repository,
    this.configurationError,
    this.account,
  });
  final AnnoncesRepository? repository;
  final String? configurationError;
  final AccountController? account;
  @override
  State<TenantFlow> createState() => _TenantFlowState();
}

class _TenantFlowState extends State<TenantFlow> {
  TenantScreen screen = TenantScreen.introduction;
  TenantScreen detailOrigin = TenantScreen.results;
  final keyword = TextEditingController(),
      city = TextEditingController(),
      district = TextEditingController(),
      rent = TextEditingController();
  final scroll = ScrollController();
  final Map<String, Home> favorites = {};
  String type = 'Tous';
  int? rooms;
  List<Home> results = [];
  Home? selectedHome;
  bool loading = false;
  String? error, rentError;
  int requestId = 0;
  Map<String, String> appliedLabels = {};
  bool get connected =>
      widget.repository != null || widget.configurationError != null;

  @override
  void dispose() {
    requestId++;
    keyword.dispose();
    city.dispose();
    district.dispose();
    rent.dispose();
    scroll.dispose();
    super.dispose();
  }

  void go(TenantScreen target) {
    FocusScope.of(context).unfocus();
    setState(() => screen = target);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  String keyFor(Home home) =>
      home.id ?? '${home.title}|${home.city}|${home.district}|${home.rent}';
  void toggleFavorite(Home home) => setState(() {
    final key = keyFor(home);
    if (favorites.containsKey(key)) {
      favorites.remove(key);
    } else {
      favorites[key] = home;
    }
  });

  void open(Home home) {
    detailOrigin = screen;
    selectedHome = home;
    go(TenantScreen.detail);
  }

  Future<void> search() async {
    FocusScope.of(context).unfocus();
    final value = rent.text.replaceAll(RegExp(r'\s'), '');
    final budget = value.isEmpty ? null : int.tryParse(value);
    if (value.isNotEmpty && (budget == null || budget < 0)) {
      setState(() => rentError = 'Saisissez un loyer positif en FCFA.');
      return;
    }
    // Snapshot des critères : une réponse périmée ne remplace pas une recherche plus récente.
    final filters = AnnouncementFilters(
      city: city.text.trim(),
      district: district.text.trim(),
      type: type,
      maxRent: budget,
    );
    final bedroomCount = rooms;
    final words = keyword.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final current = ++requestId;
    setState(() {
      rentError = null;
      loading = true;
      error = null;
      results = [];
      screen = TenantScreen.results;
      appliedLabels = {
        if (filters.city.isNotEmpty) 'city': filters.city,
        if (filters.district.isNotEmpty) 'district': filters.district,
        if (type != 'Tous') 'type': type,
        if (bedroomCount != null)
          'rooms': '${bedroomCount == 5 ? '5+' : bedroomCount} chambres',
        if (budget != null) 'rent': '≤ $budget FCFA',
        if (words.isNotEmpty) 'keyword': keyword.text.trim(),
      };
    });
    if (scroll.hasClients) scroll.jumpTo(0);
    try {
      if (widget.configurationError != null)
        throw StateError(widget.configurationError!);
      final data = widget.repository != null
          ? await widget.repository!.search(filters)
          : homes;
      final filtered = data.where((home) {
        final text =
            '${home.title} ${home.city} ${home.district} ${home.type} ${home.description}'
                .toLowerCase();
        return (!connected || !home.isDemo) &&
            home.city.toLowerCase().contains(filters.city.toLowerCase()) &&
            home.district.toLowerCase().contains(
              filters.district.toLowerCase(),
            ) &&
            (filters.type == 'Tous' ||
                home.type.toLowerCase() == filters.type.toLowerCase()) &&
            (budget == null || home.rent != null && home.rent! <= budget) &&
            (bedroomCount == null ||
                home.rooms != null &&
                    (bedroomCount == 5
                        ? home.rooms! >= 5
                        : home.rooms == bedroomCount)) &&
            words.every(text.contains);
      }).toList();
      if (!mounted || current != requestId) return;
      setState(() {
        results = filtered;
        loading = false;
      });
    } catch (_) {
      if (!mounted || current != requestId) return;
      setState(() {
        loading = false;
        error =
            widget.configurationError ??
            'Impossible de charger les annonces. Vérifiez votre connexion et réessayez.';
      });
    }
  }

  void clear() => setState(() {
    keyword.clear();
    city.clear();
    district.clear();
    rent.clear();
    type = 'Tous';
    rooms = null;
    rentError = null;
  });

  void removeCriterion(String key) {
    switch (key) {
      case 'city':
        city.clear();
      case 'district':
        district.clear();
      case 'keyword':
        keyword.clear();
      case 'rent':
        rent.clear();
      case 'type':
        type = 'Tous';
      case 'rooms':
        rooms = null;
    }
    search();
  }

  @override
  Widget build(BuildContext context) {
    if (screen == TenantScreen.introduction) {
      return TenantIntroductionPage(onSearch: () => go(TenantScreen.search));
    }
    final content = switch (screen) {
      TenantScreen.search => searchPage(),
      TenantScreen.results => resultsPage(),
      TenantScreen.favorites => favoritesPage(),
      TenantScreen.detail => TenantDetail(
        home: selectedHome!,
        favorite: favorites.containsKey(keyFor(selectedHome!)),
        onBack: () => go(detailOrigin),
        onFavorite: () => toggleFavorite(selectedHome!),
      ),
      TenantScreen.profile => AccountPage(
        account: widget.account,
        initialRole: AccountRole.locataire,
      ),
      TenantScreen.introduction => const SizedBox.shrink(),
    };
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final selectedIndex = screen == TenantScreen.favorites
        ? 2
        : screen == TenantScreen.profile
        ? 3
        : 1;
    void navigate(int index) => go(
      [
        TenantScreen.introduction,
        TenantScreen.search,
        TenantScreen.favorites,
        TenantScreen.profile,
      ][index],
    );
    return Scaffold(
      backgroundColor: tenantBackground,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            SafeArea(
              child: NavigationRail(
                backgroundColor: tenantBackground,
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: navigate,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    label: Text('Accueil'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.search),
                    label: Text('Rechercher'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite_border),
                    label: Text('Favoris'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    label: Text('Profil'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: scroll,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width < 700
                          ? 440
                          : 1240,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (screen != TenantScreen.detail)
                            const TenantHeader(),
                          content,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width < 700 ? 440 : 1240,
                ),
                child: NavigationBar(
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFE1F0E5),
                  height: 68,
                  selectedIndex: screen == TenantScreen.favorites
                      ? 2
                      : screen == TenantScreen.profile
                      ? 3
                      : 1,
                  onDestinationSelected: (index) => go(
                    [
                      TenantScreen.introduction,
                      TenantScreen.search,
                      TenantScreen.favorites,
                      TenantScreen.profile,
                    ][index],
                  ),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'Accueil',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search),
                      label: 'Rechercher',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      label: 'Favoris',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget heading(String text, {double size = 28}) => Text(
    text,
    style: TextStyle(
      color: tenantGreen,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
  );
  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        color: tenantInk,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    hintStyle: const TextStyle(fontSize: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
  Widget section(String title, IconData icon, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2EAE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: tenantGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: tenantGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      );

  Widget searchPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading('Trouvez le logement qui\nvous convient'),
      const SizedBox(height: 18),
      ResponsiveSections(
        first: [
          TextField(
            controller: keyword,
            maxLines: 3,
            decoration: input('Décrivez le logement que vous recherchez…')
                .copyWith(
                  prefixIcon: const Icon(
                    Icons.chat_bubble_outline,
                    color: tenantGreen,
                  ),
                  labelText: 'Votre recherche',
                ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Exemple : Appartement meublé à Ngor, 4 chambres, maximum 400 000 FCFA/mois.',
            style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 7),
          const Text(
            'Recherche par mots-clés dans les informations disponibles. Les phrases ne sont pas converties automatiquement en critères.',
            style: TextStyle(fontSize: 10, color: tenantInk),
          ),
          const Divider(height: 28),
          heading('Ou précisez vos critères', size: 21),
          const SizedBox(height: 5),
          const Text(
            'Écrivez, choisissez vos critères ou combinez les deux.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          section('Localisation', Icons.location_on, [
            label('Région'),
            DropdownButtonFormField<String>(
              decoration: input('Choisir une région'),
              hint: const Text(
                'Choisir une région',
                style: TextStyle(fontSize: 12),
              ),
              items: const [],
              onChanged: null,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Filtre région non disponible dans la source actuelle.',
                style: TextStyle(fontSize: 10, color: tenantInk),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label('Ville'),
                      TextField(
                        controller: city,
                        decoration: input(
                          'Choisir une ville',
                        ).copyWith(labelText: 'Ville'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label('Quartier'),
                      TextField(
                        controller: district,
                        decoration: input(
                          'Choisir un quartier',
                        ).copyWith(labelText: 'Quartier'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ],
        second: [
          section('Votre logement', Icons.home, [
            label('Type de logement'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in ['Appartement', 'Studio', 'Maison'])
                  ChoiceChip(
                    label: Text(value, style: const TextStyle(fontSize: 11)),
                    selected: type == value,
                    onSelected: (selected) =>
                        setState(() => type = selected ? value : 'Tous'),
                    selectedColor: const Color(0xFFE2F1E5),
                  ),
              ],
            ),
            label('Prix maximum'),
            TextField(
              controller: rent,
              keyboardType: TextInputType.number,
              decoration: input('Votre budget maximum').copyWith(
                labelText: 'Loyer maximum (FCFA)',
                suffixText: 'FCFA/mois',
                errorText: rentError,
              ),
              style: const TextStyle(fontSize: 12),
            ),
            label('Nombre de chambres'),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final value in [1, 2, 3, 4, 5])
                  ChoiceChip(
                    label: Text(value == 5 ? '5+' : '$value'),
                    selected: rooms == value,
                    onSelected: connected
                        ? null
                        : (selected) =>
                              setState(() => rooms = selected ? value : null),
                    selectedColor: const Color(0xFFE2F1E5),
                  ),
              ],
            ),
            if (connected)
              const Text(
                'Information non disponible dans ces annonces.',
                style: TextStyle(fontSize: 10, color: tenantInk),
              ),
            label('Ameublement'),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: const [
                ChoiceChip(
                  label: Text('Meublé', style: TextStyle(fontSize: 11)),
                  selected: false,
                ),
                ChoiceChip(
                  label: Text('Non meublé', style: TextStyle(fontSize: 11)),
                  selected: false,
                ),
                ChoiceChip(
                  label: Text('Peu importe', style: TextStyle(fontSize: 11)),
                  selected: true,
                ),
              ],
            ),
            const Text(
              'Ameublement non renseigné : filtre désactivé.',
              style: TextStyle(fontSize: 10, color: tenantInk),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: clear,
                child: const Text(
                  'Effacer les critères',
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
      const SizedBox(height: 18),
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width >= 700
                ? 420
                : double.infinity,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: search,
              style: tenantPrimaryStyle(),
              child: const Text(
                'Trouver mon logement →',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (!connected)
        const TenantNotice(
          'Mode démonstration : recherche dans les trois exemples fictifs déjà présents dans le projet.',
        ),
    ],
  );

  Widget resultsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => go(TenantScreen.search),
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Retour à la recherche'),
        ),
      ),
      heading('Logements trouvés'),
      if (appliedLabels.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: appliedLabels.entries
                .map(
                  (entry) => InputChip(
                    onDeleted: () => removeCriterion(entry.key),
                    deleteButtonTooltipMessage: 'Supprimer ${entry.value}',
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: const Color(0xFFE7F3EB),
                  ),
                )
                .toList(),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => go(TenantScreen.search),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Modifier la recherche',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => go(TenantScreen.search),
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Filtres', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (!connected)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: TenantNotice(
            'DÉMONSTRATION · Annonces fictives existantes et illustrations extraites du PDF. Aucun logement réellement proposé.',
          ),
        ),
      if (loading)
        const Padding(
          padding: EdgeInsets.all(26),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Chargement des annonces…'),
            ],
          ),
        )
      else if (error != null) ...[
        TenantNotice(error!, warning: true),
        if (widget.repository != null)
          TextButton(onPressed: search, child: const Text('Réessayer')),
      ] else ...[
        Text(
          '${results.length} résultat(s)',
          style: const TextStyle(fontSize: 12, color: tenantInk),
        ),
        const SizedBox(height: 10),
        if (results.isEmpty) ...[
          const TenantNotice(
            'Aucun logement ne correspond exactement à vos critères. Aucun résultat approchant n’est proposé automatiquement.',
            warning: true,
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune annonce approuvée ne correspond à votre recherche.',
            style: TextStyle(fontSize: 13, color: tenantInk),
          ),
        ] else
          ResponsiveListingGrid(
            children: [
              for (final home in results)
                TenantListingCard(
                  home: home,
                  favorite: favorites.containsKey(keyFor(home)),
                  onOpen: () => open(home),
                  onFavorite: () => toggleFavorite(home),
                ),
            ],
          ),
      ],
      const SizedBox(height: 12),
      const Text(
        'Premium = visibilité payante. Le paiement ne donne jamais le statut Vérifié.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: tenantInk),
      ),
    ],
  );

  Widget favoritesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading('Mes favoris'),
      const SizedBox(height: 10),
      const TenantNotice(
        'Favoris de cette session uniquement. Aucune sauvegarde dans un compte ou dans Supabase.',
      ),
      const SizedBox(height: 14),
      const Text(
        'Touchez un logement pour le consulter.',
        style: TextStyle(
          fontSize: 12,
          color: tenantInk,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Text(
        'Touchez le cœur pour le retirer.',
        style: TextStyle(fontSize: 12, color: tenantInk),
      ),
      const SizedBox(height: 16),
      if (favorites.isEmpty) ...[
        const SizedBox(height: 30),
        Center(
          child: Image.asset(
            'assets/homes/tenant_reference_empty_favorites.png',
            width: 165,
            height: 165,
            semanticLabel: 'Aucun logement dans les favoris',
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Vous n’avez pas encore\najouté de logement\nà vos favoris.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: tenantGreen,
          ),
        ),
        const SizedBox(height: 24),
        ResponsiveAction(
          child: FilledButton(
            onPressed: () => go(TenantScreen.search),
            style: tenantPrimaryStyle(),
            child: const Text('Chercher un logement →'),
          ),
        ),
      ] else
        ResponsiveListingGrid(
          children: [
            for (final home in favorites.values.toList())
              TenantListingCard(
                home: home,
                favorite: true,
                onOpen: () => open(home),
                onFavorite: () => toggleFavorite(home),
              ),
          ],
        ),
    ],
  );
}
