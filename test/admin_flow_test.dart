import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/account_service.dart';
import 'package:teranga_immo/admin_flow.dart';
import 'package:teranga_immo/home_shell.dart';
import 'package:teranga_immo/models/account_role.dart';
import 'package:teranga_immo/moderation_service.dart';
import 'account_test.dart' show FakeAccountGateway, testUser, profile;

class FakeModerationGateway implements ModerationGateway {
  List<PendingModeration> moderation = [];
  List<PendingWithdrawal> withdrawals = [];
  final decisions = <String>[];
  final withdrawalDecisions = <bool>[];
  String? lastMessage;

  @override
  Future<List<PendingModeration>> listPendingModeration() async => moderation;

  @override
  Future<void> moderate({
    required String versionId,
    required String decision,
    String? messageToOwner,
    String? internalNote,
  }) async {
    decisions.add(decision);
    lastMessage = messageToOwner;
    moderation = moderation
        .where((item) => item.versionId != versionId)
        .toList();
  }

  @override
  Future<List<PendingWithdrawal>> listPendingWithdrawals() async => withdrawals;

  @override
  Future<void> processWithdrawal({
    required String requestId,
    required bool approve,
    String? comment,
  }) async {
    withdrawalDecisions.add(approve);
    withdrawals = withdrawals.where((item) => item.id != requestId).toList();
  }

  List<PublishedAnnouncement> published = [];
  String? lastControlLevel;
  List<ControlElementInput>? lastControlElements;

  @override
  Future<List<PublishedAnnouncement>> listPublished() async => published;

  @override
  Future<void> recordControl({
    required String announcementWorkflowId,
    required String level,
    required String publicSummary,
    required List<ControlElementInput> elements,
  }) async {
    lastControlLevel = level;
    lastControlElements = elements;
  }
}

PendingModeration _moderationFixture() => PendingModeration.fromJson({
  'id': '33333333-3333-4333-8333-333333333333',
  'annonce_id': '11111111-1111-4111-8111-111111111111',
  'region': 'Dakar',
  'ville': 'Dakar',
  'quartier': 'Mermoz',
  'type_logement': 'Appartement',
  'loyer_mensuel': 150000,
  'description': 'Appartement lumineux proche de la mer.',
  'submitted_at': '2026-09-28T10:00:00Z',
});

PendingWithdrawal _withdrawalFixture() => PendingWithdrawal.fromJson({
  'id': '44444444-4444-4444-8444-444444444444',
  'annonce_id': '11111111-1111-4111-8111-111111111111',
  'motif': 'Le logement a été loué.',
  'logement_loue': true,
  'created_at': '2026-09-28T10:00:00Z',
});

void main() {
  testWidgets('Accepter une annonce ne demande aucun message', (tester) async {
    final gateway = FakeAccountGateway()
      ..user = testUser
      ..stored = profile(role: AccountRole.admin);
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await account.refreshProfile();
    final moderation = FakeModerationGateway()
      ..moderation = [_moderationFixture()];
    await tester.pumpWidget(
      MaterialApp(
        home: AdminFlow(account: account, moderation: moderation),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appartement'), findsOneWidget);
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    expect(moderation.decisions, ['accepter']);
    expect(find.text('Aucune annonce en attente.'), findsOneWidget);
  });

  testWidgets('Refuser exige un message avant d’envoyer la décision', (
    tester,
  ) async {
    final gateway = FakeAccountGateway()
      ..user = testUser
      ..stored = profile(role: AccountRole.admin);
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await account.refreshProfile();
    final moderation = FakeModerationGateway()
      ..moderation = [_moderationFixture()];
    await tester.pumpWidget(
      MaterialApp(
        home: AdminFlow(account: account, moderation: moderation),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(moderation.decisions, isEmpty);
    expect(find.text('Appartement'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Les photos ne correspondent pas au logement.',
    );
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(moderation.decisions, ['refuser']);
    expect(
      moderation.lastMessage,
      'Les photos ne correspondent pas au logement.',
    );
  });

  testWidgets('Approuver un retrait retire la demande de la liste', (
    tester,
  ) async {
    final gateway = FakeAccountGateway()
      ..user = testUser
      ..stored = profile(role: AccountRole.admin);
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    addTearDown(gateway.events.close);
    await account.refreshProfile();
    final moderation = FakeModerationGateway()
      ..withdrawals = [_withdrawalFixture()];
    await tester.pumpWidget(
      MaterialApp(
        home: AdminFlow(account: account, moderation: moderation),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Motif'), findsOneWidget);
    await tester.tap(find.text('Approuver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(moderation.withdrawalDecisions, [true]);
    expect(find.text('Aucune demande en attente.'), findsOneWidget);
  });

  testWidgets(
    'Un compte administrateur est routé vers le back-office de modération',
    (tester) async {
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(role: AccountRole.admin);
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      await tester.pumpWidget(MaterialApp(home: HomeShell(account: account)));
      await tester.pumpAndSettle();
      expect(find.text('Modération Teranga Immo'), findsOneWidget);
    },
  );

  testWidgets(
    'Contrôler une annonce exige un résumé et une explication par élément',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = FakeAccountGateway()
        ..user = testUser
        ..stored = profile(role: AccountRole.admin);
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      addTearDown(gateway.events.close);
      await account.refreshProfile();
      final moderation = FakeModerationGateway()
        ..published = [
          PublishedAnnouncement.fromJson({
            'workflow_id': '11111111-1111-4111-8111-111111111111',
            'region': 'Dakar',
            'ville': 'Dakar',
            'quartier': 'Mermoz',
            'type_logement': 'Appartement',
            'loyer_mensuel': 150000,
            'niveau_controle': 'declaree',
          }),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: AdminFlow(account: account, moderation: moderation),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Contrôler'));
      await tester.tap(find.text('Contrôler'));
      await tester.pumpAndSettle();
      expect(find.text('Contrôler l’annonce'), findsOneWidget);

      final submit = find.text('Enregistrer le contrôle');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Le résumé public est obligatoire.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Résumé public du contrôle'),
        'Logement visité et conforme à l’annonce.',
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Une explication est requise pour chaque élément.'),
        findsOneWidget,
      );

      final explanationFields = find.widgetWithText(
        TextField,
        'Explication publique',
      );
      final explanationCount = explanationFields.evaluate().length;
      for (var i = 0; i < explanationCount; i++) {
        await tester.enterText(explanationFields.at(i), 'Vérifié sur place.');
      }
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Contrôler l’annonce'), findsNothing);
      expect(moderation.lastControlLevel, 'informations_controlees');
      expect(moderation.lastControlElements, hasLength(8));
      expect(
        moderation.lastControlElements!.every(
          (element) => element.explanation == 'Vérifié sur place.',
        ),
        isTrue,
      );
    },
  );
}
