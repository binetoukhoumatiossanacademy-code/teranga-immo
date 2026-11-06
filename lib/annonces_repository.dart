import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';
import 'models/announcement_contact.dart';

class AnnouncementFilters {
  const AnnouncementFilters({
    this.city = '',
    this.district = '',
    this.type = 'Tous',
    this.maxRent,
  });
  final String city, district, type;
  final num? maxRent;
}

abstract class AnnoncesRepository {
  Future<List<Home>> search(AnnouncementFilters filters);

  /// Le contact (propriétaire ou agence) d'une annonce publiée. La RLS
  /// Supabase réserve cette information aux locataires connectés : un
  /// visiteur non authentifié reçoit toujours `null`, sans appel réseau.
  Future<AnnouncementContact?> fetchContact(String announcementWorkflowId);
}

class SupabaseAnnoncesRepository implements AnnoncesRepository {
  SupabaseAnnoncesRepository(this.client);
  final SupabaseClient client;

  static String _literal(String value) => value
      .trim()
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  @override
  Future<List<Home>> search(AnnouncementFilters filters) async {
    var query = client
        .schema('public')
        .from('annonces')
        .select(
          'id,created_at,type_logement,ville,quartier,loyer_mensuel,statut,workflow_id',
        )
        .eq('statut', 'approuvee');
    if (filters.city.trim().isNotEmpty) {
      query = query.ilike('ville', _literal(filters.city));
    }
    if (filters.district.trim().isNotEmpty) {
      query = query.ilike('quartier', '%${_literal(filters.district)}%');
    }
    if (filters.type != 'Tous') {
      query = query.ilike('type_logement', _literal(filters.type));
    }
    if (filters.maxRent != null) {
      query = query.lte('loyer_mensuel', filters.maxRent!);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .limit(100)
        .timeout(const Duration(seconds: 15));
    return rows
        .where((row) => row['statut'] == 'approuvee')
        .map(Home.fromAnnouncement)
        .toList();
  }

  @override
  Future<AnnouncementContact?> fetchContact(
    String announcementWorkflowId,
  ) async {
    if (client.auth.currentUser == null) return null;
    final rows = await client
        .schema('public')
        .from('contacts_annonces')
        .select(
          'version_id,annonce_id,nom_contact,type_contact,'
          'telephone_whatsapp,email_contact,appel_autorise,'
          'whatsapp_autorise,updated_at',
        )
        .eq('annonce_id', announcementWorkflowId)
        .limit(1);
    if (rows.isEmpty) return null;
    return AnnouncementContact.fromJson(rows.first);
  }
}
