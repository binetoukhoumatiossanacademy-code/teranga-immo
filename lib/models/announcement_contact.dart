import 'account_role.dart';
import 'model_parsing.dart';

final class AnnouncementContact {
  const AnnouncementContact({
    required this.versionId,
    required this.announcementId,
    required this.name,
    required this.role,
    required this.phoneWhatsApp,
    required this.callAllowed,
    required this.whatsAppAllowed,
    required this.updatedAt,
    this.email,
  });

  final String versionId;
  final String announcementId;
  final String name;
  final AccountRole role;
  final String phoneWhatsApp;
  final String? email;
  final bool callAllowed;
  final bool whatsAppAllowed;
  final DateTime updatedAt;

  factory AnnouncementContact.fromJson(Map<String, dynamic> json) {
    final role = AccountRole.fromDatabase(json['type_contact']);
    if (role == AccountRole.locataire) {
      throw const FormatException(
        'Un contact d’annonce doit être propriétaire ou agence',
      );
    }
    return AnnouncementContact(
      versionId: ModelParsing.requiredUuid(json, 'version_id'),
      announcementId: ModelParsing.requiredUuid(json, 'annonce_id'),
      name: ModelParsing.requiredString(json, 'nom_contact'),
      role: role,
      phoneWhatsApp: ModelParsing.requiredString(json, 'telephone_whatsapp'),
      email: ModelParsing.nullableString(json, 'email_contact'),
      callAllowed: ModelParsing.requiredBool(json, 'appel_autorise'),
      whatsAppAllowed: ModelParsing.requiredBool(json, 'whatsapp_autorise'),
      updatedAt:
          ModelParsing.nullableDateTime(json, 'updated_at') ??
          (throw const FormatException('Date de mise à jour absente')),
    );
  }
}
