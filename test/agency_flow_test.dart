import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fonts = FontLoader('Poppins');
    for (final asset in [
      'assets/fonts/Poppins-Regular.ttf',
      'assets/fonts/Poppins-SemiBold.ttf',
      'assets/fonts/Poppins-Bold.ttf',
    ]) {
      fonts.addFont(rootBundle.load(asset));
    }
    await fonts.load();
  });

  testWidgets('Agence : connexion, inscription et conditions indisponibles', (
    tester,
  ) async {
    await openAgency(tester);
    expect(find.text('Bienvenue dans votre\nespace agence'), findsOneWidget);
    expect(find.text('Trouvez. Valorisez. Ensemble.'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tapVisible(tester, find.text('S’inscrire'));
    expect(find.text('Nom de l’agence'), findsOneWidget);
    expect(find.text('Nom et prénom du responsable'), findsOneWidget);
    expect(find.text('Téléphone / WhatsApp'), findsOneWidget);
    expect(
      find.text(
        'Les conditions d’utilisation officielles ne sont pas encore fournies. Leur acceptation et l’inscription Agence sont indisponibles.',
      ),
      findsOneWidget,
    );
    final create = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Créer le compte de l’agence'),
    );
    expect(create.onPressed, isNull);
    await tapVisible(tester, find.text('conditions d’utilisation'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tapVisible(tester, find.text('Fermer'));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1100.0, 1440.0]) {
    testWidgets('Agence : écrans sans débordement à ${width.toInt()} pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openAgency(tester);
      await tapVisible(
        tester,
        find.text('Consulter les écrans sans connexion'),
      );
      expect(find.text('Gérez vos logements\nsimplement'), findsOneWidget);
      expect(find.text('Aucune annonce chargée'), findsNothing);
      expect(find.text('Agence Teranga Habitat'), findsNothing);

      await tapVisible(tester, find.text('Proposer un logement'));
      expect(find.text('Proposer un logement'), findsOneWidget);
      expect(find.text('Ajout de photos indisponible'), findsOneWidget);

      await goToAgencySection(tester, 'Mes annonces');
      expect(find.text('Aucune annonce chargée'), findsOneWidget);
      expect(find.text('Publiée'), findsNothing);
      expect(find.text('Administration'), findsNothing);

      await goToAgencySection(tester, 'Profil');
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Aucune agence connectée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> openAgency(WidgetTester tester) async {
  await tester.pumpWidget(const TerangaApp());
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('Agence immobilière'));
  await tapVisible(tester, find.text('Continuer'));
}

Future<void> goToAgencySection(WidgetTester tester, String label) async {
  final rail = find.byType(NavigationRail);
  if (rail.evaluate().isNotEmpty) {
    await tapVisible(
      tester,
      find.descendant(of: rail, matching: find.text(label)),
    );
    return;
  }
  await tapVisible(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target.hitTestable());
  await tester.pumpAndSettle();
}
