import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/annonces_repository.dart';
import 'package:teranga_immo/home.dart';
import 'package:teranga_immo/teranga_app.dart';

class TenantTestRepository implements AnnoncesRepository {
  TenantTestRepository(this.fetch);
  final Future<List<Home>> Function(AnnouncementFilters) fetch;
  @override
  Future<List<Home>> search(AnnouncementFilters filters) => fetch(filters);
}

Future<void> tapTenant(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterSearch(
  WidgetTester tester, {
  AnnoncesRepository? repository,
  String? configurationError,
}) async {
  await tester.pumpWidget(
    TerangaApp(repository: repository, configurationError: configurationError),
  );
  await tester.pumpAndSettle();
  if (tester.view.physicalSize.width / tester.view.devicePixelRatio >= 900) {
    expect(
      tester.getRect(find.byType(Image).first).right,
      lessThan(tester.getRect(find.text('Locataire')).left),
    );
  }
  expect(tester.takeException(), isNull);
  await tapTenant(tester, find.text('Continuer'));
  expect(find.text('Comment ça marche ?'), findsOneWidget);
  await tapTenant(tester, find.text('Chercher votre logement'));
}

Finder nav(String text) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  ),
  matching: find.text(text),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Poppins');
    for (final asset in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf',
    ]) {
      loader.addFont(rootBundle.load('assets/fonts/$asset'));
    }
    await loader.load();
  });

  for (final width in [320.0, 390.0, 768.0, 1100.0, 1440.0]) {
    testWidgets(
      'Locataire : six écrans, favoris, galerie et contact désactivé à $width pixels',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await enterSearch(tester);
        expect(
          find.text('Trouvez le logement qui\nvous convient'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(nav('Favoris'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Vous n’avez pas encore\najouté de logement\nà vos favoris.',
          ),
          findsOneWidget,
        );
        await tapTenant(tester, find.text('Chercher un logement →'));
        await tapTenant(tester, find.text('Trouver mon logement →'));
        expect(find.text('Logements trouvés'), findsOneWidget);
        expect(find.text('3 résultat(s)'), findsOneWidget);
        expect(
          find.byType(NavigationRail),
          width >= 900 ? findsOneWidget : findsNothing,
        );
        if (width >= 700) {
          final cards = find.byType(Card);
          expect(
            tester.getRect(cards.at(0)).top,
            tester.getRect(cards.at(1)).top,
          );
          expect(
            tester.getRect(cards.at(0)).right,
            lessThan(tester.getRect(cards.at(1)).left),
          );
        }
        await tapTenant(tester, find.byTooltip('Ajouter aux favoris').first);
        await tester.tap(nav('Favoris'));
        await tester.pumpAndSettle();
        expect(find.text('Mes favoris'), findsOneWidget);
        expect(find.text('Voir l’annonce'), findsOneWidget);
        await tapTenant(tester, find.text('Voir l’annonce'));
        expect(find.text('À propos de ce logement'), findsOneWidget);
        await tapTenant(tester, find.bySemanticsLabel('Voir l’illustration 2'));
        expect(find.text('2/3'), findsOneWidget);
        await tapTenant(tester, find.text('Contacter →'));
        expect(find.text('Contacter l’annonceur'), findsOneWidget);
        expect(
          find.text(
            'Ce logement est fictif : aucun propriétaire ne peut être contacté.',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Appeler'),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'WhatsApp'),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byTooltip('Fermer le contact'));
        await tester.pumpAndSettle();
        await tapTenant(
          tester,
          find.widgetWithText(OutlinedButton, 'Retirer des favoris'),
        );
        await tapTenant(tester, find.widgetWithText(FilledButton, 'Résultats'));
        expect(
          find.text(
            'Vous n’avez pas encore\najouté de logement\nà vos favoris.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Locataire : filtres, budget invalide, résultat vide et effacement',
    (tester) async {
      await enterSearch(tester);
      final budget = find.widgetWithText(TextField, 'Loyer maximum (FCFA)');
      await tester.ensureVisible(budget);
      await tester.enterText(budget, '-1');
      await tapTenant(tester, find.text('Trouver mon logement →'));
      expect(find.text('Saisissez un loyer positif en FCFA.'), findsOneWidget);
      await tester.enterText(budget, '90000');
      await tapTenant(tester, find.text('Trouver mon logement →'));
      expect(find.text('0 résultat(s)'), findsOneWidget);
      expect(find.text('Voir l’annonce'), findsNothing);
      await tapTenant(tester, find.byTooltip('Supprimer ≤ 90000 FCFA'));
      expect(find.text('3 résultat(s)'), findsOneWidget);
      await tapTenant(tester, find.text('Modifier la recherche'));
      await tapTenant(tester, find.text('Effacer les critères'));
      await tapTenant(tester, find.widgetWithText(ChoiceChip, 'Studio'));
      await tapTenant(tester, find.text('Trouver mon logement →'));
      expect(find.text('1 résultat(s)'), findsOneWidget);
      expect(find.text('95 000 FCFA / mois'), findsOneWidget);
    },
  );

  testWidgets(
    'Locataire connecté : requête existante et aucune photo ou contact inventé',
    (tester) async {
      AnnouncementFilters? sent;
      final repository = TenantTestRepository((filters) async {
        sent = filters;
        return [
          Home.fromAnnouncement({
            'id': 'live',
            'ville': 'Thiès',
            'quartier': 'Centre',
            'type_logement': 'Maison',
            'loyer_mensuel': 220000,
            'statut': 'approuvee',
          }),
        ];
      });
      await enterSearch(tester, repository: repository);
      await tester.ensureVisible(find.widgetWithText(TextField, 'Ville'));
      await tester.enterText(find.widgetWithText(TextField, 'Ville'), 'Thiès');
      await tapTenant(tester, find.text('Trouver mon logement →'));
      expect(sent!.city, 'Thiès');
      expect(find.text('1 résultat(s)'), findsOneWidget);
      expect(find.text('Photo non renseignée'), findsOneWidget);
      expect(
        find.text('Exemple fictif · illustration de maquette'),
        findsNothing,
      );
      expect(find.text('2 chambres'), findsNothing);
      await tapTenant(tester, find.text('Voir l’annonce'));
      expect(find.text('Description non renseignée.'), findsOneWidget);
      await tapTenant(tester, find.text('Contacter →'));
      expect(
        find.text('Coordonnées de contact non renseignées pour cette annonce.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'WhatsApp'))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Locataire : erreur puis nouvelle tentative sans repli vers la démonstration',
    (tester) async {
      var calls = 0;
      final repo = TenantTestRepository((_) async {
        if (++calls == 1) throw StateError('Hors ligne');
        return [];
      });
      await enterSearch(tester, repository: repo);
      await tapTenant(tester, find.text('Trouver mon logement →'));
      expect(
        find.text(
          'Impossible de charger les annonces. Vérifiez votre connexion et réessayez.',
        ),
        findsOneWidget,
      );
      expect(find.text('Voir l’annonce'), findsNothing);
      await tapTenant(tester, find.text('Réessayer'));
      expect(find.text('0 résultat(s)'), findsOneWidget);
      expect(calls, 2);
    },
  );

  testWidgets('Locataire : configuration invalide sans annonces fictives', (
    tester,
  ) async {
    await enterSearch(tester, configurationError: 'Configuration invalide.');
    await tapTenant(tester, find.text('Trouver mon logement →'));
    expect(find.text('Configuration invalide.'), findsOneWidget);
    expect(find.text('Voir l’annonce'), findsNothing);
    expect(find.text('DÉMONSTRATION'), findsNothing);
  });

  testWidgets(
    'Locataire : une réponse périmée ne remplace pas la dernière recherche',
    (tester) async {
      final first = Completer<List<Home>>();
      var calls = 0;
      final repo = TenantTestRepository(
        (_) => ++calls == 1 ? first.future : Future.value([]),
      );
      await enterSearch(tester, repository: repo);
      await tester.ensureVisible(find.text('Trouver mon logement →'));
      await tester.tap(find.text('Trouver mon logement →'));
      await tester.pump();
      expect(find.text('Chargement des annonces…'), findsOneWidget);
      await tester.tap(nav('Rechercher'));
      await tester.pump();
      await tester.ensureVisible(find.text('Trouver mon logement →'));
      await tester.tap(find.text('Trouver mon logement →'));
      await tester.pumpAndSettle();
      first.complete([
        Home.fromAnnouncement({
          'id': 'old',
          'ville': 'Dakar',
          'loyer_mensuel': 1,
        }),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('0 résultat(s)'), findsOneWidget);
      expect(find.text('Voir l’annonce'), findsNothing);
    },
  );
}
