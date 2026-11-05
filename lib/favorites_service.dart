import 'package:supabase_flutter/supabase_flutter.dart';

import 'home.dart';

/// Persiste les favoris du locataire connecté dans la table Supabase
/// `favoris`, identifiés par le `workflow_id` (uuid) de l'annonce.
abstract class FavoritesGateway {
  /// Identifiants des annonces mises en favori par l'utilisateur connecté.
  Future<Set<String>> listIds();

  /// Les annonces favorites, avec leurs informations d'affichage.
  Future<List<Home>> listHomes();

  Future<void> add(String announcementWorkflowId);

  Future<void> remove(String announcementWorkflowId);
}

class SupabaseFavoritesGateway implements FavoritesGateway {
  SupabaseFavoritesGateway(this.client);
  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Connexion requise');
    return id;
  }

  @override
  Future<Set<String>> listIds() async {
    final rows = await client
        .schema('public')
        .from('favoris')
        .select('annonce_id')
        .eq('utilisateur_id', _userId);
    return rows.map((row) => row['annonce_id'] as String).toSet();
  }

  @override
  Future<List<Home>> listHomes() async {
    final ids = await listIds();
    if (ids.isEmpty) return [];
    final rows = await client
        .schema('public')
        .from('annonces')
        .select(
          'id,created_at,type_logement,ville,quartier,loyer_mensuel,statut,workflow_id',
        )
        .inFilter('workflow_id', ids.toList());
    return rows.map(Home.fromAnnouncement).toList();
  }

  @override
  Future<void> add(String announcementWorkflowId) async {
    await client.schema('public').from('favoris').insert({
      'utilisateur_id': _userId,
      'annonce_id': announcementWorkflowId,
    });
  }

  @override
  Future<void> remove(String announcementWorkflowId) async {
    await client
        .schema('public')
        .from('favoris')
        .delete()
        .eq('utilisateur_id', _userId)
        .eq('annonce_id', announcementWorkflowId);
  }
}
