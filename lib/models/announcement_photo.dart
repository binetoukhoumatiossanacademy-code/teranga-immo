import 'model_parsing.dart';

const maxAnnouncementPhotoBytes = 8 * 1024 * 1024;

enum AnnouncementPhotoMimeType {
  jpeg('image/jpeg'),
  png('image/png'),
  webp('image/webp');

  const AnnouncementPhotoMimeType(this.databaseValue);
  final String databaseValue;

  static AnnouncementPhotoMimeType fromDatabase(Object? value) =>
      AnnouncementPhotoMimeType.values.firstWhere(
        (type) => type.databaseValue == value?.toString(),
        orElse: () => throw FormatException('Type MIME invalide : $value'),
      );
}

final class AnnouncementPhoto {
  const AnnouncementPhoto({
    required this.id,
    required this.announcementId,
    required this.storagePath,
    required this.createdBy,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String announcementId;
  final String storagePath;
  final String createdBy;
  final AnnouncementPhotoMimeType mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  factory AnnouncementPhoto.fromJson(Map<String, dynamic> json) {
    final size = ModelParsing.requiredInt(json, 'taille_octets');
    if (size <= 0 || size > maxAnnouncementPhotoBytes) {
      throw FormatException('Taille de photo invalide : $size');
    }
    final announcementId = ModelParsing.requiredUuid(json, 'annonce_id');
    final createdBy = ModelParsing.requiredUuid(json, 'created_by');
    final storagePath = ModelParsing.requiredString(json, 'storage_path');
    final pathParts = storagePath.split('/');
    if (pathParts.length != 3 ||
        pathParts[0] != createdBy ||
        pathParts[1] != announcementId ||
        pathParts[2].isEmpty) {
      throw const FormatException(
        'Chemin Storage attendu : utilisateur/annonce/fichier',
      );
    }
    return AnnouncementPhoto(
      id: ModelParsing.requiredUuid(json, 'id'),
      announcementId: announcementId,
      storagePath: storagePath,
      createdBy: createdBy,
      mimeType: AnnouncementPhotoMimeType.fromDatabase(json['mime_type']),
      sizeBytes: size,
      createdAt: ModelParsing.requiredDateTime(json, 'created_at'),
    );
  }
}

final class AnnouncementVersionPhoto {
  const AnnouncementVersionPhoto({
    required this.versionId,
    required this.photoId,
    required this.order,
    required this.isPrimary,
  });

  final String versionId;
  final String photoId;
  final int order;
  final bool isPrimary;

  factory AnnouncementVersionPhoto.fromJson(Map<String, dynamic> json) {
    final order = ModelParsing.requiredInt(json, 'ordre');
    if (order < 0 || order > 9) {
      throw FormatException('Ordre de photo invalide : $order');
    }
    return AnnouncementVersionPhoto(
      versionId: ModelParsing.requiredUuid(json, 'version_id'),
      photoId: ModelParsing.requiredUuid(json, 'photo_id'),
      order: order,
      isPrimary: ModelParsing.requiredBool(json, 'est_principale'),
    );
  }
}
