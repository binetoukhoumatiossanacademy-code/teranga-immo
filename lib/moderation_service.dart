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
}
