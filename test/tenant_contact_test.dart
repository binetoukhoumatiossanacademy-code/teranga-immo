import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/annonces_repository.dart';
import 'package:teranga_immo/home.dart';
import 'package:teranga_immo/models/announcement_contact.dart';
import 'package:teranga_immo/tenant_detail.dart';

const _workflowId = '11111111-1111-4111-8111-111111111111';

const _home = Home(
  'Appartement à Dakar',
  'Mermoz',
  'Appartement',
  '150 000',
  150000,
  2,
  'Appartement lumineux proche de la mer.',
  Color(0xFFD9E3D5),
  id: '1',
  workflowId: _workflowId,
  isDemo: false,
);

AnnouncementContact _contact({
  bool callAllowed = true,
  bool whatsAppAllowed = true,
}) => AnnouncementContact.fromJson({
  'version_id': '22222222-2222-4222-8222-222222222222',
  'annonce_id': _workflowId,
  'nom_contact': 'Awa Diop',
  'type_contact': 'proprietaire',
  'telephone_whatsapp': '+221770000000',
  'email_contact': null,
  'appel_autorise': callAllowed,
  'whatsapp_autorise': whatsAppAllowed,
  'updated_at': '2026-09-28T10:00:00Z',
});

class FakeRepository implements AnnoncesRepository {
  FakeRepository(this.contact);
  final AnnouncementContact? contact;
  int fetchContactCalls = 0;
  @override
  Future<List<Home>> search(AnnouncementFilters filters) async => [];
  @override
  Future<AnnouncementContact?> fetchContact(
    String announcementWorkflowId,
  ) async {
    fetchContactCalls++;
    return contact;
  }
}

Future<void> pumpDetail(
  WidgetTester tester, {
  required AnnoncesRepository? repository,
  required bool authenticated,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TenantDetail(
          home: _home,
          favorite: false,
          repository: repository,
          authenticated: authenticated,
          onBack: () {},
          onFavorite: () {},
        ),
      ),
    ),
  ),
);

Future<void> openContact(WidgetTester tester) async {
  final target = find.text('Contacter →');
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Locataire connecté avec coordonnées : nom réel et boutons actifs',
    (tester) async {
      final repository = FakeRepository(_contact());
      await pumpDetail(tester, repository: repository, authenticated: true);
      await tester.pumpAndSettle();
      expect(repository.fetchContactCalls, 1);
      expect(find.text('Awa Diop'), findsOneWidget);
      await openContact(tester);
      expect(find.text('Awa Diop'), findsNWidgets(2));
      expect(
        find.text('Coordonnées transmises par l’annonceur.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byType(OutlinedButton).last)
            .onPressed,
        isNotNull,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Coordonnées non autorisées : boutons désactivés malgré le contact',
    (tester) async {
      final repository = FakeRepository(
        _contact(callAllowed: false, whatsAppAllowed: false),
      );
      await pumpDetail(tester, repository: repository, authenticated: true);
      await tester.pumpAndSettle();
      await openContact(tester);
      expect(
        tester
            .widget<OutlinedButton>(find.byType(OutlinedButton).last)
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Locataire non connecté : invitation à se connecter, aucun appel réseau',
    (tester) async {
      final repository = FakeRepository(_contact());
      await pumpDetail(tester, repository: repository, authenticated: false);
      await tester.pumpAndSettle();
      expect(repository.fetchContactCalls, 0);
      expect(find.text('Annonceur non renseigné'), findsOneWidget);
      await openContact(tester);
      expect(
        find.text('Connectez-vous pour voir les coordonnées de contact.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Annonce sans contact enregistré : message honnête, rien d’inventé',
    (tester) async {
      final repository = FakeRepository(null);
      await pumpDetail(tester, repository: repository, authenticated: true);
      await tester.pumpAndSettle();
      await openContact(tester);
      expect(
        find.text('Coordonnées de contact non renseignées pour cette annonce.'),
        findsOneWidget,
      );
    },
  );
}
