import 'announcement.dart';
import 'announcement_status.dart';
import 'model_parsing.dart';

final class AnnouncementVersion {
  const AnnouncementVersion({
    required this.id,
    required this.announcementId,
    required this.versionNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
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
    this.createdBy,
    this.submittedAt,
    this.publishedAt,
  });

  final String id;
  final AnnouncementWorkflowId announcementId;
  final int versionNumber;
  final AnnouncementVersionStatus status;
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
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? publishedAt;

  bool get canBeEdited => switch (status) {
    AnnouncementVersionStatus.brouillon ||
    AnnouncementVersionStatus.correctionDemandee => true,
    _ => false,
  };

  factory AnnouncementVersion.fromJson(Map<String, dynamic> json) {
    final housingValue = ModelParsing.nullableString(json, 'type_logement');
    final availabilityValue = ModelParsing.nullableString(
      json,
      'mode_disponibilite',
    );
    final versionNumber = ModelParsing.requiredInt(json, 'numero_version');
    if (versionNumber <= 0) {
      throw FormatException('Numéro de version invalide : $versionNumber');
    }
    final monthlyRent = ModelParsing.nullableInt(json, 'loyer_mensuel');
    final bedroomCount = ModelParsing.nullableInt(json, 'nombre_chambres');
    final availableFrom = ModelParsing.nullableDateTime(
      json,
      'disponible_a_partir',
    );
    if (monthlyRent != null && monthlyRent < 0) {
      throw FormatException('Loyer mensuel invalide : $monthlyRent');
    }
    if (bedroomCount != null && (bedroomCount < 0 || bedroomCount > 32767)) {
      throw FormatException(
        'Nombre de chambres smallint invalide : $bedroomCount',
      );
    }
    if (availabilityValue == AvailabilityMode.maintenant.databaseValue &&
        availableFrom != null) {
      throw const FormatException(
        'Une disponibilité immédiate ne doit pas avoir de date',
      );
    }
    if (availabilityValue == AvailabilityMode.date.databaseValue &&
        availableFrom == null) {
      throw const FormatException('Une disponibilité datée exige une date');
    }
    return AnnouncementVersion(
      id: ModelParsing.requiredUuid(json, 'id'),
      announcementId: AnnouncementWorkflowId.fromJson(json['annonce_id']),
      versionNumber: versionNumber,
      status: AnnouncementVersionStatus.fromDatabase(json['statut_version']),
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
      createdBy: ModelParsing.nullableUuid(json, 'created_by'),
      createdAt: ModelParsing.requiredDateTime(json, 'created_at'),
      updatedAt: ModelParsing.requiredDateTime(json, 'updated_at'),
      submittedAt: ModelParsing.nullableDateTime(json, 'submitted_at'),
      publishedAt: ModelParsing.nullableDateTime(json, 'published_at'),
    );
  }
}
