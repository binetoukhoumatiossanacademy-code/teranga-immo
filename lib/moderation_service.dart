import 'package:supabase_flutter/supabase_flutter.dart';

/// Une version d'annonce en attente de contrôle (`en_attente_controle`),
/// telle que vue par un administrateur.
final class PendingModeration {
  const PendingModeration({
    required this.versionId,
    required this.announcementWorkflowId,
    this.region,
    this.city,
    this.district,
    this.housingType,
    this.monthlyRent,
    this.description,
    this.submittedAt,
  });

  final String versionId;
  final String announcementWorkflowId;
  final String? region;
  final String? city;
  final String? district;
  final String? housingType;
  final int? monthlyRent;
  final String? description;
  final DateTime? submittedAt;

  factory PendingModeration.fromJson(Map<String, dynamic> json) {
    final rent = json['loyer_mensuel'];
    return PendingModeration(
      versionId: json['id'] as String,
      announcementWorkflowId: json['annonce_id'] as String,
      region: json['region'] as String?,
      city: json['ville'] as String?,
      district: json['quartier'] as String?,
      housingType: json['type_logement'] as String?,
      monthlyRent: rent == null ? null : (rent as num).toInt(),
      description: json['description'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
    );
  }
}

/// Une demande de retrait en attente de décision administrative.
final class PendingWithdrawal {
  const PendingWithdrawal({
    required this.id,
    required this.announcementWorkflowId,
    required this.reason,
    required this.rentedOut,
    required this.requestedAt,
  });

  final String id;
  final String announcementWorkflowId;
  final String reason;
  final bool rentedOut;
  final DateTime requestedAt;

  factory PendingWithdrawal.fromJson(Map<String, dynamic> json) =>
      PendingWithdrawal(
        id: json['id'] as String,
        announcementWorkflowId: json['annonce_id'] as String,
        reason: json['motif'] as String? ?? '',
        rentedOut: json['logement_loue'] as bool? ?? false,
        requestedAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Une annonce actuellement publiée (ou approuvée), avec son niveau de
/// contrôle actuel — candidate à un contrôle administratif.
final class PublishedAnnouncement {
  const PublishedAnnouncement({
    required this.announcementWorkflowId,
    this.region,
    this.city,
    this.district,
    this.housingType,
    this.monthlyRent,
    required this.controlLevel,
  });

  final String announcementWorkflowId;
  final String? region;
  final String? city;
  final String? district;
  final String? housingType;
  final int? monthlyRent;
  final String controlLevel;

  factory PublishedAnnouncement.fromJson(Map<String, dynamic> json) {
    final rent = json['loyer_mensuel'];
    return PublishedAnnouncement(
      announcementWorkflowId: json['workflow_id'] as String,
      region: json['region'] as String?,
      city: json['ville'] as String?,
      district: json['quartier'] as String?,
      housingType: json['type_logement'] as String?,
      monthlyRent: rent == null ? null : (rent as num).toInt(),
      controlLevel: json['niveau_controle'] as String? ?? 'declaree',
    );
  }
}

/// Le résultat d'un élément de contrôle, tel qu'envoyé à
/// `enregistrer_controle_annonce`.
final class ControlElementInput {
  const ControlElementInput({
    required this.code,
    required this.result,
    required this.explanation,
  });
  final String code;
  final String result;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'element_code': code,
    'resultat': result,
    'explication_publique': explanation,
  };
}

abstract class ModerationGateway {
  /// Les versions actuellement en attente de contrôle, toutes annonces
  /// confondues.
  Future<List<PendingModeration>> listPendingModeration();

  /// Accepte, refuse ou renvoie en correction une version en attente.
  /// [messageToOwner] est obligatoire pour `demander_correction`/`refuser`.
  Future<void> moderate({
    required String versionId,
    required String decision,
    String? messageToOwner,
    String? internalNote,
  });

  /// Les demandes de retrait en attente de décision.
  Future<List<PendingWithdrawal>> listPendingWithdrawals();

  /// Approuve ou refuse une demande de retrait.
  Future<void> processWithdrawal({
    required String requestId,
    required bool approve,
    String? comment,
  });

  /// Les annonces actuellement publiées, candidates à un contrôle.
  Future<List<PublishedAnnouncement>> listPublished();

  /// Enregistre un contrôle (« informations contrôlées » ou « vérifiée par
  /// Teranga Immo ») sur une annonce publiée, avec ses 8 éléments vérifiés.
  Future<void> recordControl({
    required String announcementWorkflowId,
    required String level,
    required String publicSummary,
    required List<ControlElementInput> elements,
  });
}

class SupabaseModerationGateway implements ModerationGateway {
  SupabaseModerationGateway(this.client);
  final SupabaseClient client;

  @override
  Future<List<PendingModeration>> listPendingModeration() async {
    final rows = await client
        .schema('public')
        .from('annonces_versions')
        .select(
          'id,annonce_id,region,ville,quartier,type_logement,'
          'loyer_mensuel,description,submitted_at',
        )
        .eq('statut_version', 'en_attente_controle')
        .order('submitted_at', ascending: true);
    return rows.map(PendingModeration.fromJson).toList();
  }

  @override
  Future<void> moderate({
    required String versionId,
    required String decision,
    String? messageToOwner,
    String? internalNote,
  }) async {
    await client
        .schema('public')
        .rpc(
          'moderer_annonce',
          params: {
            'p_version_id': versionId,
            'p_decision': decision,
            'p_message_annonceur': messageToOwner,
            'p_note_interne': internalNote,
          },
        );
  }

  @override
  Future<List<PendingWithdrawal>> listPendingWithdrawals() async {
    final rows = await client
        .schema('public')
        .from('demandes_retrait')
        .select('id,annonce_id,motif,logement_loue,created_at')
        .eq('statut', 'en_attente')
        .order('created_at', ascending: true);
    return rows.map(PendingWithdrawal.fromJson).toList();
  }

  @override
  Future<void> processWithdrawal({
    required String requestId,
    required bool approve,
    String? comment,
  }) async {
    await client
        .schema('public')
        .rpc(
          'traiter_demande_retrait',
          params: {
            'p_demande_id': requestId,
            'p_decision': approve ? 'approuver' : 'refuser',
            'p_commentaire': comment,
          },
        );
  }

  @override
  Future<List<PublishedAnnouncement>> listPublished() async {
    final rows = await client
        .schema('public')
        .from('annonces')
        .select(
          'workflow_id,region,ville,quartier,type_logement,'
          'loyer_mensuel,niveau_controle',
        )
        .inFilter('statut', ['approuvee', 'publiee'])
        .order('niveau_controle', ascending: true);
    return rows.map(PublishedAnnouncement.fromJson).toList();
  }

  @override
  Future<void> recordControl({
    required String announcementWorkflowId,
    required String level,
    required String publicSummary,
    required List<ControlElementInput> elements,
  }) async {
    await client
        .schema('public')
        .rpc(
          'enregistrer_controle_annonce',
          params: {
            'p_annonce_id': announcementWorkflowId,
            'p_niveau': level,
            'p_resume_public': publicSummary,
            'p_elements': elements.map((e) => e.toJson()).toList(),
          },
        );
  }
}
