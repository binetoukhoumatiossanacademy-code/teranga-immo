import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/account_role.dart';
import 'models/announcement.dart';

/// Levée quand le serveur refuse l'envoi au contrôle (ex. aucune photo
/// attachée). Le message vient directement de la fonction SQL
/// `soumettre_annonce` et peut être affiché tel quel à l'utilisateur.
class AnnouncementSubmissionRefused implements Exception {
  AnnouncementSubmissionRefused(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AnnouncementGateway {
  /// Crée l'annonce et sa première version en statut `brouillon`, via la
  /// fonction `creer_annonce_brouillon`.
  Future<AnnouncementWorkflowId> createDraft({
    String? region,
    required String city,
    required String district,
    required HousingType housingType,
    required int monthlyRent,
    required int bedroomCount,
    required bool furnished,
    required String description,
    required AvailabilityMode availabilityMode,
    DateTime? availableFrom,
  });

  /// Enregistre le contact de l'annonce (obligatoire avant tout envoi au
  /// contrôle).
  Future<void> setContact({
    required AnnouncementWorkflowId announcementId,
    required AccountRole accountRole,
    required String contactName,
    required String phoneWhatsApp,
    String? email,
  });

  /// Soumet la version de travail au contrôle Teranga Immo. Le serveur
  /// refuse si le contact ou les photos obligatoires manquent.
  Future<void> submit(AnnouncementWorkflowId announcementId);
}

class SupabaseAnnouncementGateway implements AnnouncementGateway {
  SupabaseAnnouncementGateway(this.client);
  final SupabaseClient client;

  @override
  Future<AnnouncementWorkflowId> createDraft({
    String? region,
    required String city,
    required String district,
    required HousingType housingType,
    required int monthlyRent,
    required int bedroomCount,
    required bool furnished,
    required String description,
    required AvailabilityMode availabilityMode,
    DateTime? availableFrom,
  }) async {
    final workflowId = await client
        .schema('public')
        .rpc(
          'creer_annonce_brouillon',
          params: {
            'p_region': region,
            'p_ville': city,
            'p_quartier': district,
            'p_type_logement': housingType.databaseValue,
            'p_loyer_mensuel': monthlyRent,
            'p_nombre_chambres': bedroomCount,
            'p_est_meuble': furnished,
            'p_description': description,
            'p_mode_disponibilite': availabilityMode.databaseValue,
            'p_disponible_a_partir': availableFrom
                ?.toIso8601String()
                .split('T')
                .first,
          },
        );
    return AnnouncementWorkflowId.fromJson(workflowId);
  }

  @override
  Future<void> setContact({
    required AnnouncementWorkflowId announcementId,
    required AccountRole accountRole,
    required String contactName,
    required String phoneWhatsApp,
    String? email,
  }) async {
    final annonce = await client
        .schema('public')
        .from('annonces')
        .select('version_travail_id')
        .eq('workflow_id', announcementId.value)
        .single();
    final versionId = annonce['version_travail_id'] as String?;
    if (versionId == null) {
      throw StateError('Aucune version de travail pour cette annonce');
    }
    await client.schema('public').from('contacts_annonces').insert({
      'version_id': versionId,
      'annonce_id': announcementId.value,
      'nom_contact': contactName,
      'type_contact': accountRole.databaseValue,
      'telephone_whatsapp': phoneWhatsApp,
      'email_contact': email,
      'appel_autorise': true,
      'whatsapp_autorise': true,
    });
  }

  @override
  Future<void> submit(AnnouncementWorkflowId announcementId) async {
    try {
      await client
          .schema('public')
          .rpc(
            'soumettre_annonce',
            params: {'p_annonce_id': announcementId.value},
          );
    } on PostgrestException catch (e) {
      throw AnnouncementSubmissionRefused(e.message);
    }
  }
}
