import 'announcement_status.dart';
import 'control_level.dart';
import 'model_parsing.dart';

final class LegacyAnnouncementId {
  LegacyAnnouncementId._(this.value);

  final int value;

  factory LegacyAnnouncementId.fromJson(Object? value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      throw FormatException('Identifiant bigint historique invalide : $value');
    }
    return LegacyAnnouncementId._(parsed);
  }

  @override
  bool operator ==(Object other) =>
      other is LegacyAnnouncementId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

final class AnnouncementWorkflowId {
  AnnouncementWorkflowId._(this.value);

  final String value;

  factory AnnouncementWorkflowId.fromJson(Object? value) =>
      AnnouncementWorkflowId._(
        ModelParsing.validateUuid(value?.toString() ?? '', 'workflow_id'),
      );

  @override
  bool operator ==(Object other) =>
      other is AnnouncementWorkflowId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

enum HousingType {
  appartement('Appartement'),
  studio('Studio'),
  maison('Maison');

  const HousingType(this.databaseValue);
  final String databaseValue;

  static HousingType fromDatabase(Object? value) =>
      HousingType.values.firstWhere(
        (type) => type.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Type de logement invalide : $value'),
      );
}

enum AvailabilityMode {
  maintenant('maintenant'),
  date('date');

  const AvailabilityMode(this.databaseValue);
  final String databaseValue;

  static AvailabilityMode fromDatabase(Object? value) =>
      AvailabilityMode.values.firstWhere(
        (mode) => mode.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Mode de disponibilité invalide : $value'),
      );
}

final class Announcement {
  const Announcement({
    required this.legacyId,
    required this.workflowId,
    required this.controlLevel,
    required this.publicationAuthorized,
    required this.submittedVersion,
    required this.updatedAt,
    required this.premiumActive,
    this.status,
    this.announcerId,
    this.region,
    this.city,
    this.district,
    this.housingType,
    this.monthlyRent,
    this.bedroomCount,
    this.furnished,
    this.description,
    this.availabilityMode,
    this.availableFrom,
    this.publishedVersionId,
    this.workingVersionId,
    this.createdAt,
    this.lastSubmittedAt,
    this.publishedAt,
    this.retiredAt,
    this.premiumStartedAt,
    this.premiumEndsAt,
  });

  final LegacyAnnouncementId legacyId;
  final AnnouncementWorkflowId workflowId;
  final String? announcerId;
  final AnnouncementStatus? status;
  final String? region;
  final String? city;
  final String? district;
  final HousingType? housingType;
  final int? monthlyRent;
  final int? bedroomCount;
  final bool? furnished;
  final String? description;
  final AvailabilityMode? availabilityMode;
  final DateTime? availableFrom;
  final ControlLevel controlLevel;
  final bool publicationAuthorized;
  final int submittedVersion;
  final String? publishedVersionId;
  final String? workingVersionId;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final DateTime? lastSubmittedAt;
  final DateTime? publishedAt;
  final DateTime? retiredAt;
  final bool premiumActive;
  final DateTime? premiumStartedAt;
  final DateTime? premiumEndsAt;

  bool get hasPublicCompatibleStatus => status?.isPublicCompatible ?? false;

  bool isPremiumAt(DateTime instant) =>
      premiumActive &&
      (premiumStartedAt == null || !instant.isBefore(premiumStartedAt!)) &&
      (premiumEndsAt == null || instant.isBefore(premiumEndsAt!));

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final housingValue = ModelParsing.nullableString(json, 'type_logement');
    final availabilityValue = ModelParsing.nullableString(
      json,
      'mode_disponibilite',
    );
    final statusValue = ModelParsing.nullableString(json, 'statut');
    final monthlyRent = ModelParsing.nullableInt(json, 'loyer_mensuel');
    final bedroomCount = ModelParsing.nullableInt(json, 'nombre_chambres');
    final availableFrom = ModelParsing.nullableDateTime(
      json,
      'disponible_a_partir',
    );
    final premiumStartedAt = ModelParsing.nullableDateTime(
      json,
      'premium_debut_at',
    );
    final premiumEndsAt = ModelParsing.nullableDateTime(json, 'premium_fin_at');
    final premiumActive = ModelParsing.requiredBool(json, 'premium_actif');
    if (monthlyRent != null && monthlyRent < 0) {
      throw FormatException('Loyer mensuel invalide : $monthlyRent');
    }
    if (bedroomCount != null && (bedroomCount < 0 || bedroomCount > 32767)) {
      throw FormatException(
        'Nombre de chambres smallint invalide : $bedroomCount',
      );
    }
    _validateAvailability(availabilityValue, availableFrom);
    if (premiumStartedAt != null &&
        premiumEndsAt != null &&
        !premiumEndsAt.isAfter(premiumStartedAt)) {
      throw const FormatException('Période Premium invalide');
    }
    if ((premiumActive && premiumEndsAt == null) ||
        (!premiumActive && premiumEndsAt != null)) {
      throw const FormatException('État Premium incohérent');
    }
    return Announcement(
      legacyId: LegacyAnnouncementId.fromJson(json['id']),
      workflowId: AnnouncementWorkflowId.fromJson(json['workflow_id']),
      announcerId: ModelParsing.nullableUuid(json, 'annonceur_id'),
      status: statusValue == null
          ? null
          : AnnouncementStatus.fromDatabase(statusValue),
      region: ModelParsing.nullableString(json, 'region'),
      city: ModelParsing.nullableString(json, 'ville'),
      district: ModelParsing.nullableString(json, 'quartier'),
      housingType: housingValue == null
          ? null
          : HousingType.fromDatabase(housingValue),
      monthlyRent: monthlyRent,
      bedroomCount: bedroomCount,
      furnished: ModelParsing.nullableBool(json, 'est_meuble'),
      description: ModelParsing.nullableString(json, 'description'),
      availabilityMode: availabilityValue == null
          ? null
          : AvailabilityMode.fromDatabase(availabilityValue),
      availableFrom: availableFrom,
      controlLevel: ControlLevel.fromDatabase(json['niveau_controle']),
      publicationAuthorized: ModelParsing.requiredBool(
        json,
        'publication_autorisee',
      ),
      submittedVersion: ModelParsing.requiredInt(json, 'version_soumise'),
      publishedVersionId: ModelParsing.nullableUuid(json, 'version_publiee_id'),
      workingVersionId: ModelParsing.nullableUuid(json, 'version_travail_id'),
      createdAt: ModelParsing.nullableDateTime(json, 'created_at'),
      updatedAt: ModelParsing.requiredDateTime(json, 'updated_at'),
      lastSubmittedAt: ModelParsing.nullableDateTime(
        json,
        'derniere_soumission_at',
      ),
      publishedAt: ModelParsing.nullableDateTime(json, 'published_at'),
      retiredAt: ModelParsing.nullableDateTime(json, 'retired_at'),
      premiumActive: premiumActive,
      premiumStartedAt: premiumStartedAt,
      premiumEndsAt: premiumEndsAt,
    );
  }
}

void _validateAvailability(String? mode, DateTime? availableFrom) {
  if (mode == null) return;
  if (mode == AvailabilityMode.maintenant.databaseValue &&
      availableFrom != null) {
    throw const FormatException(
      'Une disponibilité immédiate ne doit pas avoir de date',
    );
  }
  if (mode == AvailabilityMode.date.databaseValue && availableFrom == null) {
    throw const FormatException('Une disponibilité datée exige une date');
  }
}
