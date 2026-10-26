import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/main.dart';
import 'package:teranga_immo/owner_flow.dart';
import 'package:teranga_immo/account_service.dart';
import 'account_test.dart' show FakeAccountGateway, testUser, profile;

Future<void> tap(WidgetTester tester, String text) async {
  // Attendre aussi le repositionnement automatique du champ après la saisie.
  await tester.pumpAndSettle();
  final target = find.textContaining(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String text) async {
  final target = find.byKey(ValueKey('owner-$key'));
  await tester.ensureVisible(target);
  await tester.enterText(target, text);
  await tester.pump();
}

void main() {
  setUpAll(() async {
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
  for (final width in [320.0, 390.0, 768.0, 1100.0, 1440.0]) {
    testWidgets('Propriétaire : huit écrans sans faux envoi à $width pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const TerangaApp());
      await tester.pumpAndSettle();
      await tap(tester, 'Commencer');
      await tap(tester, 'Propriétaire');
      await tap(tester, 'Continuer');
      await tap(tester, 'Continuer');
      expect(find.byType(OwnerFlow), findsOneWidget);
      expect(
        find.text('Bienvenue dans votre espace propriétaire'),
        findsOneWidget,
      );
      final login = find.widgetWithText(FilledButton, 'Se connecter');
      expect(tester.widget<FilledButton>(login).onPressed, isNull);
      await tap(tester, 'S’inscrire');
      expect(find.byKey(const ValueKey('owner-name')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Créer mon compte'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'Consulter les écrans sans connexion');
      expect(find.text('Espace Propriétaire'), findsOneWidget);
      expect(
        find.byType(NavigationRail),
        width >= 900 ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(NavigationBar),
        width >= 900 ? findsNothing : findsOneWidget,
      );
      if (width >= 900) {
        final card = tester.getRect(
          find.widgetWithText(Card, 'Proposer un logement'),
        );
        final recent = tester.getRect(find.text('Mes annonces récentes'));
        expect(card.right, lessThan(recent.left));
      }
      await tap(tester, 'Proposer un logement');
      await enter(tester, 'region', 'Région saisie');
      await enter(tester, 'city', 'Ville saisie');
      await enter(tester, 'district', 'Quartier saisi');
      if (width >= 900) {
        final region = tester.getRect(
          find.byKey(const ValueKey('owner-region')),
        );
        final rent = tester.getRect(find.byKey(const ValueKey('owner-rent')));
        expect(region.right, lessThan(rent.left));
      }
      await enter(tester, 'rent', '-1');
      await enter(
        tester,
        'description',
        'Description saisie uniquement dans le test',
      );
      await tap(tester, 'Continuer');
      expect(find.text('Indiquez un montant entier positif'), findsOneWidget);
      await enter(tester, 'rent', '123456');
      await tap(tester, 'Continuer');
      expect(find.text('Vérifiez votre annonce'), findsOneWidget);
      expect(find.text('123456 FCFA / mois'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Envoyer à Teranga Immo'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'Modifier');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('owner-rent')))
            .controller!
            .text,
        '123456',
      );
      await tap(tester, 'Continuer');
      await tap(tester, 'Consulter l’état de l’envoi');
      expect(find.text('Aucun envoi confirmé'), findsOneWidget);
      expect(find.text('Annonce envoyée !'), findsNothing);
      await tap(tester, 'Voir mes annonces');
      expect(find.text('Aucune annonce chargée'), findsOneWidget);
      await tap(tester, 'Correction demandée : état indisponible');
      expect(find.text('Correction demandée'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Corriger mon annonce'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'Retour à mes annonces');
      await tap(tester, 'Gérer mon annonce : état indisponible');
      expect(find.text('Gérer mon annonce'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Demander le retrait'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, 'Profil');
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.text('Aucun compte connecté'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Connexion propriétaire : erreur serveur sans faux accès au compte',
    (tester) async {
      final gateway = FakeAccountGateway()..failLogin = true;
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(account: account, onAgency: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await enter(tester, 'email', 'a@example.com');
      await enter(tester, 'password', 'password123');
      await tap(tester, 'Se connecter');
      expect(
        find.text(
          'Impossible de terminer la demande. Vérifiez vos informations et votre connexion.',
        ),
        findsOneWidget,
      );
      expect(find.text('Gérez vos logements simplement.'), findsNothing);
    },
  );
  testWidgets(
    'Inscription propriétaire : rôle transmis et confirmation sans session fictive',
    (tester) async {
      final gateway = FakeAccountGateway();
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(account: account, onAgency: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'S’inscrire');
      await enter(tester, 'name', 'Compte de test');
      await enter(tester, 'phone', '000000000');
      await enter(tester, 'email', 'a@example.com');
      await enter(tester, 'password', 'password123');
      await enter(tester, 'confirm', 'password123');
      await tap(tester, 'Créer mon compte');
      expect(gateway.registeredRole?.name, 'proprietaire');
      expect(gateway.registeredName, 'Compte de test');
      expect(account.user, isNull);
      expect(find.text('Gérez vos logements simplement.'), findsNothing);
      expect(
        find.text(
          'Demande traitée par le serveur. Vérifiez votre e-mail pour confirmer votre inscription.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('Récupération propriétaire : demande via le service existant', (
    tester,
  ) async {
    final gateway = FakeAccountGateway();
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: OwnerFlow(account: account, onAgency: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'Mot de passe oublié ?');
    await enter(tester, 'email', 'a@example.com');
    await tap(tester, 'Envoyer le lien de récupération');
    expect(gateway.resetEmail, 'a@example.com');
    await tap(tester, 'Retour');
    expect(
      find.text('Bienvenue dans votre espace propriétaire'),
      findsOneWidget,
    );
  });
  testWidgets(
    'Profil réel et mot de passe : réutilisation du contrôleur existant',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile();
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(account: account, onAgency: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bonjour Awa'), findsOneWidget);
      await tap(tester, 'Profil');
      await tap(tester, 'Changer mon mot de passe');
      await enter(tester, 'password', 'newpassword123');
      await enter(tester, 'confirm', 'newpassword123');
      await tap(tester, 'Enregistrer le mot de passe');
      expect(gateway.newPassword, 'newpassword123');
      expect(find.text('Votre mot de passe a été modifié.'), findsOneWidget);
    },
  );
}
