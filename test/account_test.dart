import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teranga_immo/account_service.dart';
import 'package:teranga_immo/account_page.dart';
import 'package:teranga_immo/main.dart';
import 'package:teranga_immo/models/account_role.dart';
import 'package:teranga_immo/models/user_profile.dart';

final testUser = User(
  id: testUserId,
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-21T00:00:00Z',
  email: 'a@example.com',
);
final adminMetadataUser = User(
  id: testUserId,
  appMetadata: {},
  userMetadata: const {'type_compte': 'admin', 'nom': 'Administration'},
  aud: 'authenticated',
  createdAt: '2026-09-21T00:00:00Z',
  email: 'admin@example.com',
);
final locataireMetadataUser = User(
  id: testUserId,
  appMetadata: {},
  userMetadata: const {'type_compte': 'locataire', 'nom': 'Métadonnée'},
  aud: 'authenticated',
  createdAt: '2026-09-21T00:00:00Z',
  email: 'a@example.com',
);
const testUserId = '11111111-1111-4111-8111-111111111111';
final profileCreatedAt = DateTime.utc(2026, 9, 21);

UserProfile profile({
  String name = 'Awa',
  AccountRole role = AccountRole.proprietaire,
  String? agencyName,
  String? phoneWhatsApp,
}) => UserProfile(
  id: testUserId,
  name: name,
  role: role,
  agencyName: agencyName,
  phoneWhatsApp: phoneWhatsApp,
  createdAt: profileCreatedAt,
  updatedAt: profileCreatedAt,
);
Session session(User user) =>
    Session(accessToken: 'test', tokenType: 'bearer', user: user);

class FakeAccountGateway implements AccountGateway {
  @override
  User? user;
  final events = StreamController<AuthState>.broadcast(sync: true);
  @override
  Stream<AuthState> get changes => events.stream;
  UserProfile? stored;
  String? registeredName, registeredAgency, registeredPhone;
  AccountRole? registeredRole;
  int saveCalls = 0;
  String? resetEmail, resentEmail, newPassword;
  bool failLoad = false, failLogin = false;
  Completer<UserProfile?>? pending;
  void emit(AuthChangeEvent event, User? next) {
    user = next;
    events.add(AuthState(event, next == null ? null : session(next)));
  }

  @override
  Future<void> signUp(
    String email,
    String password, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    registeredName = name;
    registeredRole = role;
    registeredAgency = agencyName;
    registeredPhone = phoneWhatsApp;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (failLogin)
      throw const AuthException(
        'private server detail',
        code: 'invalid_credentials',
      );
    emit(AuthChangeEvent.signedIn, testUser);
  }

  @override
  Future<void> signOut() async => emit(AuthChangeEvent.signedOut, null);
  @override
  Future<void> resend(String email) async {
    resentEmail = email;
  }

  @override
  Future<void> reset(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> updatePassword(String password) async {
    newPassword = password;
  }

  @override
  Future<UserProfile?> loadProfile(String id) async {
    if (failLoad) throw StateError('table unavailable');
    return pending == null ? stored : await pending!.future;
  }

  @override
  Future<UserProfile> createProfile(
    String id, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    saveCalls++;
    stored = profile(
      name: name,
      role: role,
      agencyName: agencyName,
      phoneWhatsApp: phoneWhatsApp,
    );
    return stored!;
  }

  @override
  Future<UserProfile> updateProfile(
    UserProfile current, {
    required String name,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    saveCalls++;
    stored = profile(
      name: name,
      role: current.role,
      agencyName: agencyName,
      phoneWhatsApp: phoneWhatsApp,
    );
    return stored!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Utiliser les métriques de Poppins, comme l’application et widget_test.dart.
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
  late FakeAccountGateway gateway;
  late AccountController account;
  setUp(() {
    gateway = FakeAccountGateway();
  });
  tearDown(() async {
    account.dispose();
    await gateway.events.close();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AccountPage(account: account)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  test('Session restaurée et profil personnel chargés', () async {
    gateway.user = testUser;
    gateway.stored = profile();
    account = AccountController(gateway);
    await Future<void>.delayed(Duration.zero);
    expect(account.user?.id, testUserId);
    expect(account.profile?.name, 'Awa');
  });

  test('Déconnexion ignore une ancienne réponse de profil', () async {
    gateway.user = testUser;
    gateway.pending = Completer<UserProfile?>();
    account = AccountController(gateway);
    await gateway.signOut();
    gateway.pending!.complete(
      profile(
        name: 'Privé',
        role: AccountRole.agence,
        agencyName: 'Privé Immo',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(account.user, isNull);
    expect(account.profile, isNull);
    expect(account.loading, isFalse);
  });

  testWidgets('Inscription agence, confirmation et renvoi sans session', (
    tester,
  ) async {
    account = AccountController(gateway);
    await show(tester);
    await tap(tester, 'Créer un compte');
    await tester.enterText(field('Email'), 'agence@example.com');
    await tester.enterText(field('Mot de passe'), 'password123');
    await tester.enterText(field('Confirmer le mot de passe'), 'password123');
    await tester.enterText(field('Nom'), 'Awa');
    await tester.enterText(field('Téléphone / WhatsApp'), '77 000 00 00');
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<AccountRole>),
    );
    await tester.tap(find.byType(DropdownButtonFormField<AccountRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AccountRole.agence.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Nom de l’agence'), 'Agence Awa');
    await tap(tester, 'Créer mon compte');
    expect(gateway.registeredRole, AccountRole.agence);
    expect(gateway.registeredAgency, 'Agence Awa');
    expect(gateway.registeredPhone, '77 000 00 00');
    expect(account.user, isNull);
    expect(find.text('Confirmez votre email'), findsOneWidget);
    await tap(tester, 'Renvoyer l’email');
    expect(gateway.resentEmail, 'agence@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inscription locataire et rôle admin absent', (tester) async {
    account = AccountController(gateway);
    await show(tester);
    await tap(tester, 'Créer un compte');
    await tester.enterText(field('Email'), 'locataire@example.com');
    await tester.enterText(field('Mot de passe'), 'password123');
    await tester.enterText(field('Confirmer le mot de passe'), 'password123');
    await tester.enterText(field('Nom'), 'Moussa');
    await tester.enterText(field('Téléphone / WhatsApp'), '76 000 00 00');
    final roleField = find.byType(DropdownButtonFormField<AccountRole>);
    await tester.ensureVisible(roleField);
    await tester.tap(roleField);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DropdownMenuItem<AccountRole>>(
            find.byType(DropdownMenuItem<AccountRole>),
          )
          .map((item) => item.value)
          .whereType<AccountRole>()
          .toSet(),
      AccountRole.values.toSet(),
    );
    expect(find.text('Administrateur'), findsNothing);
    await tester.tap(find.text('Locataire').last);
    await tester.pumpAndSettle();
    await tap(tester, 'Créer mon compte');
    expect(gateway.registeredRole, AccountRole.locataire);
    expect(gateway.registeredName, 'Moussa');
    expect(gateway.registeredPhone, '76 000 00 00');
  });

  testWidgets('Connexion, création du profil propriétaire puis déconnexion', (
    tester,
  ) async {
    account = AccountController(gateway);
    await show(tester);
    await tester.enterText(field('Email'), 'a@example.com');
    await tester.enterText(field('Mot de passe'), 'password123');
    await tap(tester, 'Se connecter');
    expect(find.text('Mon profil'), findsOneWidget);
    expect(account.profile, isNull);
    expect(
      find.text('Complétez votre profil pour terminer votre inscription.'),
      findsOneWidget,
    );
    await tester.enterText(field('Nom'), 'Awa');
    await tester.enterText(field('Téléphone / WhatsApp'), '78 000 00 00');
    await tap(tester, 'Enregistrer mon profil');
    expect(gateway.stored?.role, AccountRole.proprietaire);
    expect(gateway.stored?.name, 'Awa');
    expect(gateway.stored?.phoneWhatsApp, '78 000 00 00');
    expect(find.text('Le rôle ne peut plus être modifié.'), findsOneWidget);
    await tap(tester, 'Se déconnecter');
    expect(account.user, isNull);
    expect(find.text('Mon profil'), findsNothing);
  });

  test('Le rôle enregistré est immuable dans le contrôleur', () async {
    gateway.user = testUser;
    gateway.stored = profile(role: AccountRole.proprietaire);
    account = AccountController(gateway);
    await Future<void>.delayed(Duration.zero);
    expect(account.profile?.role, AccountRole.proprietaire);
    await expectLater(
      account.save(
        name: 'Awa',
        role: AccountRole.agence,
        agencyName: 'Changement interdit',
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.saveCalls, 0);
    expect(account.profile?.role, AccountRole.proprietaire);
  });

  testWidgets('Une métadonnée admin ne devient jamais un rôle public', (
    tester,
  ) async {
    gateway.user = adminMetadataUser;
    account = AccountController(gateway);
    await show(tester);
    expect(account.profile, isNull);
    expect(
      find.text(
        'Ce compte ne peut pas créer un profil depuis l’application publique.',
      ),
      findsOneWidget,
    );
    expect(find.text('Enregistrer mon profil'), findsNothing);
    expect(gateway.saveCalls, 0);
  });

  testWidgets('Le profil Supabase prime sur les métadonnées Auth', (
    tester,
  ) async {
    gateway.user = locataireMetadataUser;
    gateway.stored = profile(
      role: AccountRole.agence,
      agencyName: 'Profil officiel',
    );
    account = AccountController(gateway);
    await show(tester);
    final roleField = tester.widget<DropdownButtonFormField<AccountRole>>(
      find.byType(DropdownButtonFormField<AccountRole>),
    );
    expect(roleField.initialValue, AccountRole.agence);
    final roleDropdown = tester.widget<DropdownButton<AccountRole>>(
      find.byType(DropdownButton<AccountRole>),
    );
    expect(roleDropdown.onChanged, isNull);
    expect(account.profile?.agencyName, 'Profil officiel');
    expect(find.text('Le rôle ne peut plus être modifié.'), findsOneWidget);
  });

  testWidgets('Mot de passe oublié puis récupération et nouveau mot de passe', (
    tester,
  ) async {
    account = AccountController(gateway);
    await show(tester);
    await tap(tester, 'Mot de passe oublié ?');
    await tester.enterText(field('Email'), 'a@example.com');
    await tap(tester, 'Envoyer le lien');
    expect(gateway.resetEmail, 'a@example.com');
    gateway.emit(AuthChangeEvent.passwordRecovery, testUser);
    await tester.pumpAndSettle();
    await tester.enterText(field('Nouveau mot de passe'), 'newpassword123');
    await tester.enterText(
      field('Confirmer le mot de passe'),
      'newpassword123',
    );
    await tap(tester, 'Enregistrer le mot de passe');
    expect(gateway.newPassword, 'newpassword123');
    expect(account.recovering, isFalse);
  });

  testWidgets('Validation et erreurs de connexion sans détail technique', (
    tester,
  ) async {
    account = AccountController(gateway);
    gateway.failLogin = true;
    await show(tester);
    await tap(tester, 'Se connecter');
    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    await tester.enterText(field('Email'), 'a@example.com');
    await tester.enterText(field('Mot de passe'), 'password123');
    await tap(tester, 'Se connecter');
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.textContaining('private server detail'), findsNothing);
  });

  testWidgets('Profil indisponible : réessayer sans perdre la session', (
    tester,
  ) async {
    gateway.user = testUser;
    gateway.failLoad = true;
    account = AccountController(gateway);
    await show(tester);
    expect(find.text('Réessayer le chargement'), findsOneWidget);
    gateway.failLoad = false;
    await tap(tester, 'Réessayer le chargement');
    expect(find.text('Enregistrer mon profil'), findsOneWidget);
    expect(account.user?.id, testUserId);
  });

  testWidgets(
    'Accueil accessible sans compte et récupération dirigée vers Profil',
    (tester) async {
      account = AccountController(gateway);
      await tester.pumpWidget(TerangaApp(account: account));
      await tester.ensureVisible(find.text('Continuer'));
      await tester.tap(find.text('Continuer'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.text('Trouvez votre logement\navec plus de confiance.'),
        findsOneWidget,
      );
      gateway.emit(AuthChangeEvent.passwordRecovery, testUser);
      await tester.pumpAndSettle();
      expect(find.text('Nouveau mot de passe'), findsNWidgets(2));
    },
  );

  test(
    'Requêtes profils publiques limitées à un identifiant et sans rôle admin',
    () async {
      account = AccountController(gateway);
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_test',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            request.method == 'GET'
                ? jsonEncode([
                    {
                      'id': testUserId,
                      'nom': 'Awa',
                      'type_compte': 'agence',
                      'nom_agence': 'Awa Immo',
                      'telephone_whatsapp': '77 000 00 00',
                      'created_at': '2026-09-21T00:00:00Z',
                      'updated_at': '2026-09-21T00:00:00Z',
                    },
                  ])
                : jsonEncode({
                    'id': testUserId,
                    'nom': 'Awa',
                    'type_compte': 'agence',
                    'nom_agence': 'Awa Immo',
                    'telephone_whatsapp': '77 000 00 00',
                    'created_at': '2026-09-21T00:00:00Z',
                    'updated_at': '2026-09-21T00:00:00Z',
                  }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final real = SupabaseAccountGateway(
        client,
        redirectUrl: 'https://example.com/',
      );
      final loaded = await real.loadProfile(testUserId);
      expect(loaded?.role, AccountRole.agence);
      expect(requests.first.url.path, '/rest/v1/profils');
      expect(requests.first.url.queryParameters['id'], 'eq.$testUserId');
      expect(requests.first.headers['accept-profile'], 'public');
      await real.updateProfile(
        loaded!,
        name: loaded.name,
        agencyName: loaded.agencyName,
        phoneWhatsApp: loaded.phoneWhatsApp,
      );
      expect(requests.last.headers['content-profile'], 'public');
      expect(jsonDecode(requests.last.body), {
        'nom': 'Awa',
        'nom_agence': 'Awa Immo',
        'telephone_whatsapp': '77 000 00 00',
      });
      expect(requests.last.method, 'PATCH');
      expect(jsonDecode(requests.last.body), isNot(contains('type_compte')));
      await real.createProfile(
        testUserId,
        name: 'Awa',
        role: AccountRole.agence,
        agencyName: 'Awa Immo',
        phoneWhatsApp: '77 000 00 00',
      );
      expect(requests.last.method, 'POST');
      expect(jsonDecode(requests.last.body), {
        'id': testUserId,
        'nom': 'Awa',
        'type_compte': 'agence',
        'nom_agence': 'Awa Immo',
        'telephone_whatsapp': '77 000 00 00',
      });
    },
  );
}
