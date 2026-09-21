import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

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
          'id,created_at,type_logement,ville,quartier,loyer_mensuel,statut',
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
}
