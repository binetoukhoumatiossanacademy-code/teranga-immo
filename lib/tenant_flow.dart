import 'responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'account_page.dart';
import 'account_service.dart';
import 'annonces_repository.dart';
import 'design_system/design_system.dart';
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
      backgroundColor: TerangaColors.ivory,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            SafeArea(
              child: NavigationRail(
                backgroundColor: TerangaColors.ivory,
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: navigate,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.house),
                    label: Text('Accueil'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.search),
                    label: Text('Rechercher'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.heart),
                    label: Text('Favoris'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.user),
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
                      icon: Icon(LucideIcons.house),
                      label: 'Accueil',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.search),
                      label: 'Rechercher',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.heart),
                      label: 'Favoris',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.user),
                      label: 'Profil',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget heading(String text, {double size = 26}) => Text(
    text,
    style: TerangaTypography.sectionTitle.copyWith(fontSize: size),
  );
  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: TerangaSpacing.sm, bottom: TerangaSpacing.xs),
    child: Text(
      text,
      style: TerangaTypography.meta.copyWith(
        color: TerangaColors.deepBrown,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    hintStyle: TerangaTypography.meta,
  );
  Widget section(String title, IconData icon, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.only(top: TerangaSpacing.md),
        padding: const EdgeInsets.all(TerangaSpacing.md),
        decoration: BoxDecoration(
          color: TerangaColors.white,
          borderRadius: BorderRadius.circular(TerangaRadius.card),
          border: Border.all(color: TerangaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: TerangaColors.gold),
                const SizedBox(width: TerangaSpacing.sm),
                Expanded(child: Text(title, style: TerangaTypography.cardTitle)),
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
      const SizedBox(height: TerangaSpacing.lg),
      ResponsiveSections(
        first: [
          TextField(
            controller: keyword,
            maxLines: 3,
            decoration: input('Décrivez le logement que vous recherchez…')
                .copyWith(
                  prefixIcon: const Icon(
                    LucideIcons.message_circle,
                    color: TerangaColors.gold,
                  ),
                  labelText: 'Votre recherche',
                ),
          ),
          const SizedBox(height: TerangaSpacing.xs),
          Text(
            'Exemple : Appartement meublé à Ngor, 4 chambres, maximum 400 000 FCFA/mois.',
            style: TerangaTypography.meta,
          ),
          const SizedBox(height: TerangaSpacing.xs),
          Text(
            'Recherche par mots-clés dans les informations disponibles. Les phrases ne sont pas converties automatiquement en critères.',
            style: TerangaTypography.meta,
          ),
          const Divider(height: TerangaSpacing.xxl, color: TerangaColors.border),
          heading('Ou précisez vos critères', size: 20),
          const SizedBox(height: TerangaSpacing.xs),
          Text(
            'Écrivez, choisissez vos critères ou combinez les deux.',
            style: TerangaTypography.meta,
          ),
          section('Localisation', LucideIcons.map_pin, [
            label('Région'),
            DropdownButtonFormField<String>(
              decoration: input('Choisir une région'),
              hint: Text('Choisir une région', style: TerangaTypography.meta),
              items: const [],
              onChanged: null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: TerangaSpacing.xs),
              child: Text(
                'Filtre région non disponible dans la source actuelle.',
                style: TerangaTypography.meta,
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TerangaSpacing.sm),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ],
        second: [
          section('Votre logement', LucideIcons.house, [
            label('Type de logement'),
            Wrap(
              spacing: TerangaSpacing.xs,
              runSpacing: TerangaSpacing.xs,
              children: [
                for (final value in ['Appartement', 'Studio', 'Maison'])
                  ChoiceChip(
                    label: Text(value),
                    selected: type == value,
                    onSelected: (selected) =>
                        setState(() => type = selected ? value : 'Tous'),
                    selectedColor: TerangaColors.gold.withValues(alpha: 0.2),
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
            ),
            label('Nombre de chambres'),
            Wrap(
              spacing: TerangaSpacing.xs,
              runSpacing: TerangaSpacing.xs,
              children: [
                for (final value in [1, 2, 3, 4, 5])
                  ChoiceChip(
                    label: Text(value == 5 ? '5+' : '$value'),
                    selected: rooms == value,
                    onSelected: connected
                        ? null
                        : (selected) =>
                              setState(() => rooms = selected ? value : null),
                    selectedColor: TerangaColors.gold.withValues(alpha: 0.2),
                  ),
              ],
            ),
            if (connected)
              Text(
                'Information non disponible dans ces annonces.',
                style: TerangaTypography.meta,
              ),
            label('Ameublement'),
            Wrap(
              spacing: TerangaSpacing.xs,
              runSpacing: TerangaSpacing.xs,
              children: const [
                ChoiceChip(label: Text('Meublé'), selected: false),
                ChoiceChip(label: Text('Non meublé'), selected: false),
                ChoiceChip(label: Text('Peu importe'), selected: true),
              ],
            ),
            Text(
              'Ameublement non renseigné : filtre désactivé.',
              style: TerangaTypography.meta,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: clear,
                child: const Text('Effacer les critères'),
              ),
            ),
          ]),
        ],
      ),
      const SizedBox(height: TerangaSpacing.lg),
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
              child: const Text('Trouver mon logement →'),
            ),
          ),
        ),
      ),
      const SizedBox(height: TerangaSpacing.md),
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
          icon: const Icon(LucideIcons.arrow_left, size: 17),
          label: const Text('Retour à la recherche'),
        ),
      ),
      heading('Logements trouvés'),
      if (appliedLabels.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TerangaSpacing.sm),
          child: Wrap(
            spacing: TerangaSpacing.xs,
            runSpacing: TerangaSpacing.xs,
            children: appliedLabels.entries
                .map(
                  (entry) => InputChip(
                    onDeleted: () => removeCriterion(entry.key),
                    deleteButtonTooltipMessage: 'Supprimer ${entry.value}',
                    label: Text(entry.value),
                    backgroundColor: TerangaColors.beige,
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
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Modifier la recherche'),
                ),
              ),
              const SizedBox(width: TerangaSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => go(TenantScreen.search),
                  icon: const Icon(LucideIcons.list_filter, size: 16),
                  label: const Text('Filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: TerangaSpacing.md),
      if (!connected)
        const Padding(
          padding: EdgeInsets.only(bottom: TerangaSpacing.md),
          child: TenantNotice(
            'DÉMONSTRATION · Annonces fictives existantes et illustrations extraites du PDF. Aucun logement réellement proposé.',
          ),
        ),
      if (loading)
        Padding(
          padding: const EdgeInsets.all(TerangaSpacing.xl),
          child: Column(
            children: [
              const CircularProgressIndicator(color: TerangaColors.gold),
              const SizedBox(height: TerangaSpacing.md),
              Text('Chargement des annonces…', style: TerangaTypography.body),
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
          style: TerangaTypography.meta,
        ),
        const SizedBox(height: TerangaSpacing.sm),
        if (results.isEmpty) ...[
          const TenantNotice(
            'Aucun logement ne correspond exactement à vos critères. Aucun résultat approchant n’est proposé automatiquement.',
            warning: true,
          ),
          const SizedBox(height: TerangaSpacing.md),
          Text(
            'Aucune annonce approuvée ne correspond à votre recherche.',
            style: TerangaTypography.body,
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
      const SizedBox(height: TerangaSpacing.md),
      Text(
        'Premium = visibilité payante. Le paiement ne donne jamais le statut Vérifié.',
        textAlign: TextAlign.center,
        style: TerangaTypography.meta,
      ),
    ],
  );

  Widget favoritesPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading('Mes favoris'),
      const SizedBox(height: TerangaSpacing.sm),
      const TenantNotice(
        'Favoris de cette session uniquement. Aucune sauvegarde dans un compte ou dans Supabase.',
      ),
      const SizedBox(height: TerangaSpacing.md),
      Text(
        'Touchez un logement pour le consulter.',
        style: TerangaTypography.meta.copyWith(
          color: TerangaColors.deepBrown,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text('Touchez le cœur pour le retirer.', style: TerangaTypography.meta),
      const SizedBox(height: TerangaSpacing.lg),
      if (favorites.isEmpty) ...[
        const SizedBox(height: TerangaSpacing.xxl),
        Center(
          child: Image.asset(
            'assets/homes/tenant_reference_empty_favorites.png',
            width: 165,
            height: 165,
            semanticLabel: 'Aucun logement dans les favoris',
          ),
        ),
        const SizedBox(height: TerangaSpacing.xl),
        Text(
          'Vous n’avez pas encore\najouté de logement\nà vos favoris.',
          textAlign: TextAlign.center,
          style: TerangaTypography.sectionTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: TerangaSpacing.xl),
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
