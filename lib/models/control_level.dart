import 'model_parsing.dart';

enum ControlLevel {
  declaree('declaree', 'Déclarée par l’annonceur', '🔴'),
  informationsControlees(
    'informations_controlees',
    'Informations contrôlées',
    '🟡',
  ),
  verifieeTeranga('verifiee_teranga', 'Vérifiée par Teranga Immo', '🟢');

  const ControlLevel(this.databaseValue, this.label, this.indicator);
  final String databaseValue;
  final String label;
  final String indicator;

  static ControlLevel fromDatabase(Object? value) =>
      ControlLevel.values.firstWhere(
        (level) => level.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Niveau de contrôle invalide : $value'),
      );
}

enum ControlElementCode {
  identiteAnnonceur('identite_annonceur'),
  existenceLogement('existence_logement'),
  localisation('localisation'),
  photosCorrespondantes('photos_correspondantes'),
  prixDeclare('prix_declare'),
  caracteristiques('caracteristiques'),
  disponibilite('disponibilite'),
  droitProposerLogement('droit_proposer_logement');

  const ControlElementCode(this.databaseValue);
  final String databaseValue;

  static ControlElementCode fromDatabase(Object? value) =>
      ControlElementCode.values.firstWhere(
        (code) => code.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Élément de contrôle invalide : $value'),
      );
}

enum ControlResult {
  confirme('confirme'),
  nonConfirme('non_confirme'),
  nonApplicable('non_applicable');

  const ControlResult(this.databaseValue);
  final String databaseValue;

  static ControlResult fromDatabase(Object? value) =>
      ControlResult.values.firstWhere(
        (result) => result.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Résultat de contrôle invalide : $value'),
      );
}

final class AnnouncementControl {
  const AnnouncementControl({
    required this.id,
    required this.announcementId,
    required this.versionId,
    required this.administratorId,
    required this.level,
    required this.publicSummary,
    required this.performedAt,
    required this.createdAt,
  });

  final String id;
  final String announcementId;
  final String versionId;
  final String administratorId;
  final ControlLevel level;
  final String publicSummary;
  final DateTime performedAt;
  final DateTime createdAt;

  factory AnnouncementControl.fromJson(Map<String, dynamic> json) {
    final level = ControlLevel.fromDatabase(json['niveau_attribue']);
    if (level == ControlLevel.declaree) {
      throw const FormatException(
        'Un contrôle ne peut attribuer que informations_controlees ou verifiee_teranga',
      );
    }
    return AnnouncementControl(
      id: ModelParsing.requiredUuid(json, 'id'),
      announcementId: ModelParsing.requiredUuid(json, 'annonce_id'),
      versionId: ModelParsing.requiredUuid(json, 'version_id'),
      administratorId: ModelParsing.requiredUuid(json, 'administrateur_id'),
      level: level,
      publicSummary: ModelParsing.requiredString(json, 'resume_public'),
      performedAt:
          ModelParsing.nullableDateTime(json, 'effectue_at') ??
          (throw const FormatException('Date de contrôle absente')),
      createdAt:
          ModelParsing.nullableDateTime(json, 'created_at') ??
          (throw const FormatException('Date de création absente')),
    );
  }
}

final class ControlElement {
  const ControlElement({
    required this.id,
    required this.controlId,
    required this.code,
    required this.result,
    required this.publicExplanation,
    required this.verifiedAt,
    required this.order,
  });

  final String id;
  final String controlId;
  final ControlElementCode code;
  final ControlResult result;
  final String publicExplanation;
  final DateTime verifiedAt;
  final int order;

  factory ControlElement.fromJson(Map<String, dynamic> json) {
    final order = ModelParsing.requiredInt(json, 'ordre');
    if (order < -32768 || order > 32767) {
      throw FormatException('Ordre smallint invalide : $order');
    }
    return ControlElement(
      id: ModelParsing.requiredUuid(json, 'id'),
      controlId: ModelParsing.requiredUuid(json, 'controle_id'),
      code: ControlElementCode.fromDatabase(json['element_code']),
      result: ControlResult.fromDatabase(json['resultat']),
      publicExplanation: ModelParsing.requiredString(
        json,
        'explication_publique',
      ),
      verifiedAt: ModelParsing.requiredDateTime(json, 'verifie_at'),
      order: order,
    );
  }
}
