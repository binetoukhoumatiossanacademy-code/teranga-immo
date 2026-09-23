import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountProfile {
  const AccountProfile({
    required this.name,
    required this.type,
    this.agency = '',
  });
  final String name, type, agency;
  Map<String, dynamic> toJson() => {
    'nom': name.trim(),
    'type_compte': type,
    'nom_agence': type == 'agence' ? agency.trim() : null,
  };
  factory AccountProfile.fromJson(Map<String, dynamic> data) => AccountProfile(
    name: data['nom'] as String? ?? '',
    type: data['type_compte'] == 'agence' ? 'agence' : 'proprietaire',
    agency: data['nom_agence'] as String? ?? '',
  );
}

abstract class AccountGateway {
  User? get user;
  Stream<AuthState> get changes;
  Future<void> signUp(String email, String password, AccountProfile profile);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resend(String email);
  Future<void> reset(String email);
  Future<void> updatePassword(String password);
  Future<AccountProfile?> loadProfile(String id);
  Future<void> saveProfile(String id, AccountProfile profile);
}

class SupabaseAccountGateway implements AccountGateway {
  SupabaseAccountGateway(this.client, {required this.redirectUrl});
  final SupabaseClient client;
  final String redirectUrl;
  @override
  User? get user => client.auth.currentUser;
  @override
  Stream<AuthState> get changes => client.auth.onAuthStateChange;
  @override
  Future<void> signUp(
    String email,
    String password,
    AccountProfile profile,
  ) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: profile.toJson(),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => client.auth.signOut();
  @override
  Future<void> resend(String email) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<void> reset(String email) => client.auth.resetPasswordForEmail(
    email,
    redirectTo: '$redirectUrl?auth=recovery',
  );
  @override
  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<AccountProfile?> loadProfile(String id) async {
    final row = await client
        .schema('public')
        .from('profils')
        .select('nom,type_compte,nom_agence')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : AccountProfile.fromJson(row);
  }

  @override
  Future<void> saveProfile(String id, AccountProfile profile) async {
    await client.schema('public').from('profils').upsert({
      'id': id,
      ...profile.toJson(),
    }, onConflict: 'id');
  }
}

class AccountController extends ChangeNotifier {
  AccountController(this.gateway, {this.recovering = false}) {
    user = gateway.user;
    _subscription = gateway.changes.listen(
      (state) {
        final oldId = user?.id;
        user = state.session?.user;
        if (state.event == AuthChangeEvent.passwordRecovery) recovering = true;
        if (state.event == AuthChangeEvent.signedOut) recovering = false;
        if (oldId != user?.id ||
            state.event == AuthChangeEvent.initialSession) {
          unawaited(refreshProfile());
        }
        _notify();
      },
      onError: (Object error) {
        message = 'Le lien est invalide ou expiré. Demandez un nouvel email.';
        _notify();
      },
    );
    unawaited(refreshProfile());
  }
  final AccountGateway gateway;
  late final StreamSubscription<AuthState> _subscription;
  User? user;
  AccountProfile? profile;
  bool recovering, loading = false;
  String? message;
  int _request = 0;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshProfile() async {
    final request = ++_request;
    final id = user?.id;
    profile = null;
    message = null;
    loading = id != null;
    _notify();
    if (id == null) return;
    try {
      final result = await gateway.loadProfile(id);
      if (_disposed || request != _request) return;
      profile = result;
    } catch (_) {
      if (_disposed || request != _request) return;
      message = 'Impossible de charger le profil. Veuillez réessayer.';
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> save(AccountProfile value) async {
    final id = user?.id;
    if (id == null) throw StateError('Connexion requise');
    await gateway.saveProfile(id, value);
    if (!_disposed && user?.id == id) {
      profile = value;
      message = null;
      _notify();
    }
  }

  Future<void> changePassword(String value) async {
    await gateway.updatePassword(value);
    recovering = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
