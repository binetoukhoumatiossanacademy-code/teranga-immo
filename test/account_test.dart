import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teranga_immo/account_service.dart';
import 'package:teranga_immo/account_page.dart';
import 'package:teranga_immo/main.dart';

final testUser = User(
  id: 'user-a',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-21T00:00:00Z',
  email: 'a@example.com',
);
Session session(User user) =>
    Session(accessToken: 'test', tokenType: 'bearer', user: user);

class FakeAccountGateway implements AccountGateway {
  @override
  User? user;
  final events = StreamController<AuthState>.broadcast(sync: true);
  @override
  Stream<AuthState> get changes => events.stream;
  AccountProfile? stored, registered;
  String? resetEmail, resentEmail, newPassword;
  bool failLoad = false, failLogin = false;
  Completer<AccountProfile?>? pending;
  void emit(AuthChangeEvent event, User? next) {
    user = next;
    events.add(AuthState(event, next == null ? null : session(next)));
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    AccountProfile profile,
  ) async {
    registered = profile; // Confirmation nécessaire : pas de session.
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
  Future<AccountProfile?> loadProfile(String id) async {
    if (failLoad) throw StateError('table unavailable');
    return pending == null ? stored : await pending!.future;
  }

  @override
  Future<void> saveProfile(String id, AccountProfile profile) async {
    stored = profile;
  }
}

void main() {
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
    gateway.stored = const AccountProfile(name: 'Awa', type: 'proprietaire');
    account = AccountController(gateway);
    await Future<void>.delayed(Duration.zero);
    expect(account.user?.id, 'user-a');
    expect(account.profile?.name, 'Awa');
  });

  test('Déconnexion ignore une ancienne réponse de profil', () async {
    gateway.user = testUser;
    gateway.pending = Completer<AccountProfile?>();
    account = AccountController(gateway);
    await gateway.signOut();
    gateway.pending!.complete(
      const AccountProfile(name: 'Privé', type: 'agence'),
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
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agence').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Nom de l’agence'), 'Agence Awa');
    await tap(tester, 'Créer mon compte');
    expect(gateway.registered?.type, 'agence');
    expect(gateway.registered?.agency, 'Agence Awa');
    expect(account.user, isNull);
    expect(find.text('Confirmez votre email'), findsOneWidget);
    await tap(tester, 'Renvoyer l’email');
    expect(gateway.resentEmail, 'agence@example.com');
    expect(tester.takeException(), isNull);
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
    await tester.enterText(field('Nom'), 'Awa');
    await tap(tester, 'Enregistrer mon profil');
    expect(gateway.stored?.type, 'proprietaire');
    expect(gateway.stored?.name, 'Awa');
    await tap(tester, 'Se déconnecter');
    expect(account.user, isNull);
    expect(find.text('Mon profil'), findsNothing);
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
    expect(account.user?.id, 'user-a');
  });

  testWidgets(
    'Accueil accessible sans compte et récupération dirigée vers Profil',
    (tester) async {
      account = AccountController(gateway);
      await tester.pumpWidget(TerangaApp(account: account));
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
                      'nom': 'Awa',
                      'type_compte': 'agence',
                      'nom_agence': 'Awa Immo',
                    },
                  ])
                : '',
            request.method == 'GET' ? 200 : 201,
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
      final profile = await real.loadProfile('user-a');
      expect(profile?.type, 'agence');
      expect(requests.first.url.path, '/rest/v1/profils');
      expect(requests.first.url.queryParameters['id'], 'eq.user-a');
      expect(requests.first.headers['accept-profile'], 'public');
      await real.saveProfile('user-a', profile!);
      expect(requests.last.headers['content-profile'], 'public');
      expect(jsonDecode(requests.last.body), {
        'id': 'user-a',
        'nom': 'Awa',
        'type_compte': 'agence',
        'nom_agence': 'Awa Immo',
      });
    },
  );
}
