import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/account_role.dart';
import 'models/user_profile.dart';

abstract class AccountGateway {
  User? get user;
  Stream<AuthState> get changes;
  Future<void> signUp(
    String email,
    String password, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  });
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resend(String email);
  Future<void> reset(String email);
  Future<void> updatePassword(String password);
  Future<UserProfile?> loadProfile(String id);
  Future<UserProfile> createProfile(
    String id, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  });
  Future<UserProfile> updateProfile(
    UserProfile current, {
    required String name,
    String? agencyName,
    String? phoneWhatsApp,
  });
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
    String password, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: UserProfile.publicFields(
        name: name,
        role: role,
        agencyName: agencyName,
        phoneWhatsApp: phoneWhatsApp,
      ),
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
  Future<UserProfile?> loadProfile(String id) async {
    final row = await client
        .schema('public')
        .from('profils')
        .select(
          'id,type_compte,nom,nom_agence,telephone_whatsapp,created_at,updated_at',
        )
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  @override
  Future<UserProfile> createProfile(
    String id, {
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    final row = await client
        .schema('public')
        .from('profils')
        .insert({
          'id': id,
          ...UserProfile.publicFields(
            name: name,
            role: role,
            agencyName: agencyName,
            phoneWhatsApp: phoneWhatsApp,
          ),
        })
        .select(
          'id,type_compte,nom,nom_agence,telephone_whatsapp,created_at,updated_at',
        )
        .single();
    return UserProfile.fromJson(row);
  }

  @override
  Future<UserProfile> updateProfile(
    UserProfile current, {
    required String name,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    final row = await client
        .schema('public')
        .from('profils')
        .update(
          current.mutableFields(
            name: name,
            agencyName: agencyName,
            phoneWhatsApp: phoneWhatsApp,
          ),
        )
        .eq('id', current.id)
        .select(
          'id,type_compte,nom,nom_agence,telephone_whatsapp,created_at,updated_at',
        )
        .single();
    return UserProfile.fromJson(row);
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
  UserProfile? profile;
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

  Future<void> save({
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) async {
    final id = user?.id;
    if (id == null) throw StateError('Connexion requise');
    final current = profile;
    if (current != null && role != current.role) {
      throw StateError('Le rôle du profil ne peut pas être modifié');
    }
    final saved = current == null
        ? await gateway.createProfile(
            id,
            name: name,
            role: role,
            agencyName: agencyName,
            phoneWhatsApp: phoneWhatsApp,
          )
        : await gateway.updateProfile(
            current,
            name: name,
            agencyName: agencyName,
            phoneWhatsApp: phoneWhatsApp,
          );
    if (!_disposed && user?.id == id) {
      profile = saved;
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
