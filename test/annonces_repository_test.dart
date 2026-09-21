import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teranga_immo/annonces_repository.dart';
import 'package:teranga_immo/app_config.dart';
import 'package:teranga_immo/home.dart';

void main() {
  test('Requête publique filtrée, triée et sans colonnes inventées', () async {
    final transport = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/annonces');
      expect(request.headers['accept-profile'], 'public');
      expect(request.url.queryParameters['statut'], 'eq.approuvee');
      expect(request.url.queryParameters['ville'], 'ilike.Dakar');
      expect(request.url.queryParameters['quartier'], r'ilike.%100\%%');
      expect(request.url.queryParameters['type_logement'], 'ilike.Appartement');
      expect(request.url.queryParameters['loyer_mensuel'], 'lte.200000');
      expect(request.url.queryParameters['order'], 'created_at.desc.nullslast');
      expect(request.url.queryParameters['limit'], '100');
      expect(
        request.url.queryParameters['select'],
        'id,created_at,type_logement,ville,quartier,loyer_mensuel,statut',
      );
      return http.Response(
        jsonEncode([
          {
            'id': 'approved',
            'statut': 'approuvee',
            'ville': 'Dakar',
            'quartier': 'Ouakam',
            'type_logement': 'Appartement',
            'loyer_mensuel': '180000',
          },
          {'id': 'pending', 'statut': 'en_attente', 'loyer_mensuel': 150000},
        ]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test',
      httpClient: transport,
    );
    addTearDown(client.dispose);
    final results = await SupabaseAnnoncesRepository(client).search(
      const AnnouncementFilters(
        city: 'Dakar',
        district: '100%',
        type: 'Appartement',
        maxRent: 200000,
      ),
    );
    expect(results.map((home) => home.id), ['approved']);
    expect(results.single.isDemo, isFalse);
    expect(results.single.monthlyPrice, '180 000 FCFA / mois');
    expect(results.single.rooms, isNull);
  });

  test('Les informations manquantes restent non renseignées', () {
    final home = Home.fromAnnouncement({'id': 42, 'statut': 'approuvee'});
    expect(home.city, 'Ville non renseignée');
    expect(home.monthlyPrice, 'Loyer non renseigné');
    expect(home.roomsLabel, 'Chambres non renseignées');
    expect(home.description, 'Description non renseignée.');
    expect(home.isDemo, isFalse);
    expect(
      Home.fromAnnouncement({'loyer_mensuel': 150000.5}).price,
      '150 000,50',
    );
  });

  test('Une erreur API est propagée sans annonces de secours', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'sb_publishable_test',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'message': 'permission denied', 'code': '42501'}),
          403,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseAnnoncesRepository(client).search(const AnnouncementFilters()),
      throwsA(
        isA<PostgrestException>()
            .having((error) => error.code, 'code', '42501')
            .having((error) => error.message, 'message', 'permission denied'),
      ),
    );
  });

  test('Configuration absente, partielle et clé secrète distinguées', () {
    expect(const AppConfig(url: '', publishableKey: '').isProvided, isFalse);
    const partial = AppConfig(
      url: 'https://example.supabase.co',
      publishableKey: '',
    );
    expect(partial.isProvided, isTrue);
    expect(partial.isValid, isFalse);
    expect(
      const AppConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_secret_test',
      ).isValid,
      isFalse,
    );
    expect(
      const AppConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_test',
      ).isValid,
      isTrue,
    );
  });
}
