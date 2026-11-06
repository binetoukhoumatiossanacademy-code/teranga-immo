import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/account_service.dart';
import 'package:teranga_immo/announcement_service.dart';
import 'package:teranga_immo/models/account_role.dart';
import 'package:teranga_immo/models/announcement.dart';
import 'package:teranga_immo/owner_flow.dart';
import 'account_test.dart' show FakeAccountGateway, testUser, profile;

Future<void> tap(WidgetTester tester, String text) async {
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

class FakeAnnouncementGateway implements AnnouncementGateway {
  bool failSubmit = false;
  String refusalMessage = 'L’annonce doit contenir entre 1 et 10 photos';
  int createDraftCalls = 0, setContactCalls = 0, submitCalls = 0;
  AccountRole? receivedContactRole;

  @override
  Future<AnnouncementWorkflowId> createDraft({
    String? region,
    required String city,
    required String district,
    required HousingType housingType,
    required int monthlyRent,
    required int bedroomCount,
    required bool furnished,
    required String description,
    required AvailabilityMode availabilityMode,
    DateTime? availableFrom,
  }) async {
    createDraftCalls++;
    return AnnouncementWorkflowId.fromJson(
      '11111111-1111-4111-8111-111111111111',
    );
  }

  @override
  Future<void> setContact({
    required AnnouncementWorkflowId announcementId,
    required AccountRole accountRole,
    required String contactName,
    required String phoneWhatsApp,
    String? email,
  }) async {
    setContactCalls++;
    receivedContactRole = accountRole;
  }

  int uploadPhotoCalls = 0;

  @override
  Future<void> uploadPhoto({
    required AnnouncementWorkflowId announcementId,
    required Uint8List bytes,
    required String mimeType,
    required int order,
    required bool principal,
  }) async {
    uploadPhotoCalls++;
  }

  @override
  Future<void> submit(AnnouncementWorkflowId announcementId) async {
    submitCalls++;
    if (failSubmit) throw AnnouncementSubmissionRefused(refusalMessage);
  }

  List<Announcement> mine = [];

  @override
  Future<List<Announcement>> listMine() async => mine;

  int withdrawCalls = 0;

  @override
  Future<void> withdraw({
    required AnnouncementWorkflowId announcementId,
    required String reason,
    required bool rentedOut,
  }) async {
    withdrawCalls++;
  }

  int startCorrectionCalls = 0;
  int updateDraftCalls = 0;
  String correctionVersionId = '33333333-3333-4333-8333-333333333333';

  @override
  Future<String> startCorrection(AnnouncementWorkflowId announcementId) async {
    startCorrectionCalls++;
    return correctionVersionId;
  }

  @override
  Future<void> updateDraft({
    required String versionId,
    String? region,
    required String city,
    required String district,
    required HousingType housingType,
    required int monthlyRent,
    required int bedroomCount,
    required bool furnished,
    required String description,
    required AvailabilityMode availabilityMode,
    DateTime? availableFrom,
  }) async {
    updateDraftCalls++;
  }
}

Announcement fixtureAnnouncement({required String status}) =>
    Announcement.fromJson({
      'id': 1,
      'workflow_id': '11111111-1111-4111-8111-111111111111',
      'statut': status,
      'region': 'Dakar',
      'ville': 'Dakar',
      'quartier': 'Mermoz',
      'type_logement': 'Appartement',
      'loyer_mensuel': 150000,
      'niveau_controle': 'declaree',
      'publication_autorisee': status == 'approuvee' || status == 'publiee',
      'version_soumise': 1,
      'premium_actif': false,
      'updated_at': '2026-09-28T10:00:00Z',
    });

Future<void> fillDraft(WidgetTester tester) async {
  await tap(tester, 'Proposer un logement');
  await enter(tester, 'region', 'Dakar');
  await enter(tester, 'city', 'Dakar');
  await enter(tester, 'district', 'Mermoz');
  await enter(tester, 'rent', '150000');
  await enter(tester, 'description', 'Appartement lumineux proche de la mer');
  await tap(tester, 'Continuer');
  expect(find.text('Vérifiez votre annonce'), findsOneWidget);
}

void main() {
  testWidgets('Envoi réussi : brouillon, contact et soumission au contrôle', (
    tester,
  ) async {
    final gateway = FakeAccountGateway()
      ..user = testUser
      ..stored = profile(phoneWhatsApp: '+221770000000');
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await account.refreshProfile();
    final announcements = FakeAnnouncementGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: OwnerFlow(
          account: account,
          announcements: announcements,
          onAgency: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await fillDraft(tester);
    await tap(tester, 'Envoyer à Teranga Immo');
    expect(announcements.createDraftCalls, 1);
    expect(announcements.setContactCalls, 1);
    expect(announcements.receivedContactRole, AccountRole.proprietaire);
    expect(announcements.submitCalls, 1);
    expect(find.text('Annonce envoyée au contrôle'), findsOneWidget);
    expect(
      find.text('Votre annonce est en attente de contrôle par Teranga Immo.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Envoi refusé par le serveur : brouillon conservé, motif affiché',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(phoneWhatsApp: '+221770000000');
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      final announcements = FakeAnnouncementGateway()..failSubmit = true;
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(
            account: account,
            announcements: announcements,
            onAgency: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await fillDraft(tester);
      await tap(tester, 'Envoyer à Teranga Immo');
      expect(announcements.createDraftCalls, 1);
      expect(announcements.setContactCalls, 1);
      expect(find.text('Brouillon enregistré'), findsOneWidget);
      expect(find.textContaining(announcements.refusalMessage), findsOneWidget);
    },
  );

  testWidgets(
    'Téléphone manquant : aucun appel réseau, message local affiché',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(phoneWhatsApp: null);
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      final announcements = FakeAnnouncementGateway();
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(
            account: account,
            announcements: announcements,
            onAgency: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await fillDraft(tester);
      await tap(tester, 'Envoyer à Teranga Immo');
      expect(announcements.createDraftCalls, 0);
      expect(
        find.textContaining('numéro de téléphone/WhatsApp'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Mes annonces affiche les annonces chargées depuis Supabase', (
    tester,
  ) async {
    final gateway = FakeAccountGateway()
      ..user = testUser
      ..stored = profile(phoneWhatsApp: '+221770000000');
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await account.refreshProfile();
    final announcements = FakeAnnouncementGateway()
      ..mine = [
        fixtureAnnouncement(status: 'en_attente_controle'),
        fixtureAnnouncement(status: 'approuvee'),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: OwnerFlow(
          account: account,
          announcements: announcements,
          onAgency: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'Mes annonces');
    expect(find.text('Appartement'), findsNWidgets(2));
    expect(find.textContaining('En attente de contrôle'), findsOneWidget);
    expect(find.textContaining('Publiée'), findsOneWidget);
  });

  testWidgets(
    'Demander le retrait appelle le serveur et affiche la confirmation',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(phoneWhatsApp: '+221770000000');
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      final announcements = FakeAnnouncementGateway()
        ..mine = [fixtureAnnouncement(status: 'approuvee')];
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(
            account: account,
            announcements: announcements,
            onAgency: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Mes annonces');
      await tap(tester, 'Appartement');
      expect(find.text('Gérer mon annonce'), findsOneWidget);
      await tap(tester, 'Demander le retrait');
      await tester.enterText(
        find.byType(TextField),
        'Le logement ne correspond plus à mon offre',
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Confirmer');
      expect(announcements.withdrawCalls, 1);
      expect(find.textContaining('transmise à Teranga Immo'), findsOneWidget);
    },
  );

  testWidgets(
    'Correction : renvoi au contrôle met à jour la version existante',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(phoneWhatsApp: '+221770000000');
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      final announcements = FakeAnnouncementGateway()
        ..mine = [fixtureAnnouncement(status: 'correction_demandee')];
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerFlow(
            account: account,
            announcements: announcements,
            onAgency: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Mes annonces');
      await tap(tester, 'Appartement');
      expect(find.text('Correction demandée'), findsOneWidget);
      await tap(tester, 'Corriger mon annonce');
      expect(find.text('Corriger mon annonce'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('owner-city')))
            .controller!
            .text,
        'Dakar',
      );
      await enter(tester, 'description', 'Description corrigée après refus');
      await tap(tester, 'Continuer');
      expect(find.text('Vérifiez votre correction'), findsOneWidget);
      await tap(tester, 'Renvoyer au contrôle');
      expect(announcements.startCorrectionCalls, 1);
      expect(announcements.updateDraftCalls, 1);
      expect(announcements.submitCalls, 1);
      expect(announcements.createDraftCalls, 0);
      expect(announcements.setContactCalls, 0);
      expect(announcements.uploadPhotoCalls, 0);
      expect(find.text('Annonce envoyée au contrôle'), findsOneWidget);
    },
  );
}
