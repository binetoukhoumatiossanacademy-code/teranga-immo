import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/main.dart';
import 'package:teranga_immo/annonces_repository.dart';
import 'package:teranga_immo/account_service.dart';
import 'package:teranga_immo/home.dart';
import 'package:teranga_immo/design_system/design_system.dart';
import 'account_test.dart' as account_test;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Les métriques d'Ahem, police de test par défaut, ne correspondent pas
    // à celles de Cormorant Garamond/DM Sans et peuvent provoquer des
    // débordements artificiels.
    final titleFonts = FontLoader('Cormorant Garamond')
      ..addFont(
        rootBundle.load(
          'assets/fonts/cormorant_garamond/CormorantGaramond-Variable.ttf',
        ),
      );
    await titleFonts.load();
    final bodyFonts = FontLoader('DM Sans')
      ..addFont(rootBundle.load('assets/fonts/dm_sans/DMSans-Variable.ttf'));
    await bodyFonts.load();
  });

  testWidgets(
    'Bienvenue : Locataire ouvre la présentation sans débordement mobile',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TerangaApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Trouvez le lieu'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tapVisible(tester, find.textContaining('Commencer'));
      expect(find.text('Locataire'), findsOneWidget);
      expect(find.text('Propriétaire'), findsOneWidget);
      expect(find.text('Agence immobilière'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tapVisible(tester, find.textContaining('Continuer'));
      await tapVisible(tester, find.textContaining('Continuer'));
      expect(
        find.text('Trouvez votre\nlogement plus\nsimplement'),
        findsOneWidget,
      );
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Bienvenue : Agence ouvre son authentification sans compte', (
    tester,
  ) async {
    await tester.pumpWidget(const TerangaApp());
    await tester.pumpAndSettle();
    await tapVisible(tester, find.textContaining('Commencer'));
    await tapVisible(tester, find.text('Agence immobilière'));
    await tapVisible(tester, find.textContaining('Continuer'));
    await tapVisible(tester, find.textContaining('Continuer'));
    expect(find.text('Bienvenue dans votre\nespace agence'), findsOneWidget);
    expect(
      find.text(
        'Supabase n’est pas configuré. Connexion, photos, envoi et gestion des annonces indisponibles.',
      ),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Présentation Locataire : parcours et recherche à ${width.toInt()} pixels',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const TerangaApp());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('Commencer'));
        await tester.tap(find.textContaining('Commencer'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('Continuer'));
        await tester.tap(find.textContaining('Continuer'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('Continuer'));
        await tester.tap(find.textContaining('Continuer'));
        await tester.pumpAndSettle();
        expect(
          find.text('Trouvez votre\nlogement plus\nsimplement'),
          findsOneWidget,
        );
        expect(find.text('Comment ça marche ?'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/homes/locataire_illustration.png',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('En savoir plus →'));
        await tester.tap(find.text('En savoir plus →'));
        await tester.pumpAndSettle();
        expect(find.text('Comprendre le niveau de contrôle'), findsOneWidget);
        await tester.tap(find.text('Compris'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Chercher votre logement'));
        await tester.tap(find.text('Chercher votre logement'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(
          find.text('Trouvez le logement qui\nvous convient'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Supabase : chargement puis liste vide, sans démonstration', (
    tester,
  ) async {
    final pending = Completer<List<Home>>();
    await pumpLegacyHome(
      tester,
      repository: TestAnnoncesRepository((_) => pending.future),
    );
    await tester.pump();
    expect(find.text('Chargement des annonces…'), findsOneWidget);
    expect(find.text('EXEMPLE FICTIF'), findsNothing);
    expect(find.text('Un appartement pour se sentir chez soi'), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Rechercher'),
      ),
    );
    await tester.pump();
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune annonce approuvée ne correspond à votre recherche.'),
      findsOneWidget,
    );
    expect(find.text('0 résultat(s)'), findsOneWidget);
    expect(find.text('Voir l’annonce'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Supabase : erreur, nouvelle tentative et détail sans données fictives',
    (tester) async {
      var calls = 0;
      final repository = TestAnnoncesRepository((_) async {
        if (++calls == 1) throw StateError('Connexion indisponible');
        return [
          Home.fromAnnouncement({
            'id': 'live',
            'ville': 'Thiès',
            'quartier': 'Centre',
            'type_logement': 'Maison',
            'loyer_mensuel': 220000,
          }),
        ];
      });
      await pumpLegacyHome(tester, repository: repository);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Impossible de charger les annonces. Vérifiez votre connexion et réessayez.',
        ),
        findsOneWidget,
      );
      expect(find.text('EXEMPLE FICTIF'), findsNothing);
      await tapVisible(tester, find.text('Réessayer'));
      expect(find.text('Maison à Thiès'), findsOneWidget);
      expect(find.text('Photo non renseignée'), findsOneWidget);
      expect(find.text('2 chambres'), findsNothing);
      await tapVisible(tester, find.byType(TerangaPropertyCard));
      expect(find.text('Maison à Thiès'), findsOneWidget);
      expect(find.text('Description non renseignée.'), findsOneWidget);
      expect(find.text('DÉMONSTRATION · Aucune annonce réelle'), findsNothing);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Configuration invalide : aucun repli vers la démonstration', (
    tester,
  ) async {
    await pumpLegacyHome(tester, configurationError: 'Configuration invalide.');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Configuration invalide.'), findsOneWidget);
    expect(find.text('EXEMPLE FICTIF'), findsNothing);
    expect(find.text('Voir l’annonce'), findsNothing);
  });

  testWidgets('Accueil mobile sans débordement et logo original chargé', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpLegacyHome(tester);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Teranga Immo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      // Flutter vérifie les handles avant les callbacks addTearDown.
      semantics.dispose();
    }
  });

  testWidgets('La navigation permet de visiter les cinq rubriques', (
    tester,
  ) async {
    await pumpLegacyHome(tester);
    await tester.pump();
    for (final label in [
      'Favoris',
      'Publier',
      'Profil',
      'Rechercher',
      'Accueil',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.textContaining('Trouvez le lieu'), findsOneWidget);
  });

  testWidgets('Un budget sans résultat peut être effacé', (tester) async {
    await pumpLegacyHome(tester);
    await tester.pump();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Où cherchez-vous ?'));
    await tester.enterText(find.byType(TextField).at(1), '1');
    final search = find.widgetWithText(FilledButton, 'Rechercher');
    await tapVisible(tester, search);
    expect(find.text('0 résultat(s) de démonstration'), findsOneWidget);
    await tapVisible(tester, find.text('Effacer les filtres'));
    expect(find.text('3 résultat(s) de démonstration'), findsOneWidget);
  });

  testWidgets('La fiche explique que le contact est fictif', (tester) async {
    await pumpLegacyHome(tester);
    await tester.pump();
    await tester.pumpAndSettle();
    final card = find.byType(TerangaPropertyCard).first;
    await tapVisible(tester, card);
    expect(find.text('Détail du logement'), findsOneWidget);
    final detail = find.byType(DetailPage);
    final contact = find.descendant(
      of: detail,
      matching: find.text('Contacter'),
    );
    final detailScroll = find.descendant(
      of: detail,
      matching: find.byType(Scrollable),
    );
    // Le bouton est créé à la demande par la ListView du détail.
    await tester.scrollUntilVisible(contact, 300, scrollable: detailScroll);
    await tapVisible(tester, contact);
    expect(
      find.text(
        'Ce logement est fictif : aucun propriétaire ne peut être contacté.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    // pageBack() cherche "Back" en anglais ; utiliser le libellé localisé.
    final backTooltip = MaterialLocalizations.of(
      tester.element(detail),
    ).backButtonTooltip;
    final backButton = find.descendant(
      of: detail,
      matching: find.byTooltip(backTooltip),
    );
    await tapVisible(tester, backButton);
    expect(find.byType(DetailPage), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  // ensureVisible peut modifier la position sans avoir rendu la nouvelle frame.
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}

class TestAnnoncesRepository implements AnnoncesRepository {
  TestAnnoncesRepository(this.fetch);
  final Future<List<Home>> Function(AnnouncementFilters) fetch;
  @override
  Future<List<Home>> search(AnnouncementFilters filters) => fetch(filters);
}

// Les contrôles historiques du catalogue public restent couverts par une
// session de récupération, sans détourner le parcours Agence vers cet écran.
Future<void> pumpLegacyHome(
  WidgetTester tester, {
  AnnoncesRepository? repository,
  String? configurationError,
}) async {
  final gateway = account_test.FakeAccountGateway();
  final account = AccountController(gateway, recovering: true);
  addTearDown(account.dispose);
  addTearDown(gateway.events.close);
  await tester.pumpWidget(
    TerangaApp(
      account: account,
      repository: repository,
      configurationError: configurationError,
    ),
  );
  // Une recherche réseau peut volontairement rester en attente dans les tests.
  // Ne pas attendre son achèvement avant d'ouvrir le catalogue public.
  await tester.pump();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Accueil'),
    ),
  );
  await tester.pump();
}
