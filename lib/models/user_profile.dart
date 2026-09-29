import 'account_role.dart';
import 'model_parsing.dart';

final class UserProfile {
  UserProfile({
    required String id,
    required String name,
    required this.role,
    String? agencyName,
    String? phoneWhatsApp,
    required this.createdAt,
    required this.updatedAt,
  }) : id = ModelParsing.validateUuid(id, 'id'),
       name = name.trim(),
       agencyName = agencyName?.trim(),
       phoneWhatsApp = phoneWhatsApp?.trim() {
    if (this.name.isEmpty || this.name.length > 120) {
      throw ArgumentError.value(name, 'name', 'Nom invalide');
    }
    if (role == AccountRole.agence) {
      if (this.agencyName == null ||
          this.agencyName!.isEmpty ||
          this.agencyName!.length > 160) {
        throw ArgumentError.value(
          agencyName,
          'agencyName',
          'Nom d’agence obligatoire et limité à 160 caractères',
        );
      }
    } else if (this.agencyName != null) {
      throw ArgumentError.value(
        agencyName,
        'agencyName',
        'Réservé aux comptes agence',
      );
    }
  }

  final String id;
  final String name;
  final AccountRole role;
  final String? agencyName;
  final String? phoneWhatsApp;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: ModelParsing.requiredUuid(json, 'id'),
    name: ModelParsing.requiredString(json, 'nom'),
    role: AccountRole.fromDatabase(json['type_compte']),
    agencyName: ModelParsing.nullableString(json, 'nom_agence'),
    phoneWhatsApp: ModelParsing.nullableString(json, 'telephone_whatsapp'),
    createdAt: ModelParsing.requiredDateTime(json, 'created_at'),
    updatedAt: ModelParsing.requiredDateTime(json, 'updated_at'),
  );

  Map<String, dynamic> toProfileRow() => {
    'id': id,
    ...publicFields(
      name: name,
      role: role,
      agencyName: agencyName,
      phoneWhatsApp: phoneWhatsApp,
    ),
  };

  Map<String, dynamic> toAuthMetadata() => publicFields(
    name: name,
    role: role,
    agencyName: agencyName,
    phoneWhatsApp: phoneWhatsApp,
  );

  Map<String, dynamic> mutableFields({
    required String name,
    String? agencyName,
    String? phoneWhatsApp,
  }) {
    final fields = publicFields(
      name: name,
      role: role,
      agencyName: agencyName,
      phoneWhatsApp: phoneWhatsApp,
    );
    fields.remove('type_compte');
    return fields;
  }

  static Map<String, dynamic> publicFields({
    required String name,
    required AccountRole role,
    String? agencyName,
    String? phoneWhatsApp,
  }) {
    final normalizedName = name.trim();
    final normalizedAgency = agencyName?.trim();
    final normalizedPhone = phoneWhatsApp?.trim();
    if (normalizedName.isEmpty || normalizedName.length > 120) {
      throw ArgumentError.value(name, 'name', 'Nom invalide');
    }
    if (role == AccountRole.agence) {
      if (normalizedAgency == null ||
          normalizedAgency.isEmpty ||
          normalizedAgency.length > 160) {
        throw ArgumentError.value(
          agencyName,
          'agencyName',
          'Nom d’agence obligatoire et limité à 160 caractères',
        );
      }
    } else if (normalizedAgency != null && normalizedAgency.isNotEmpty) {
      throw ArgumentError.value(
        agencyName,
        'agencyName',
        'Réservé aux comptes agence',
      );
    }
    return {
      'type_compte': role.databaseValue,
      'nom': normalizedName,
      'nom_agence': role == AccountRole.agence ? normalizedAgency : null,
      'telephone_whatsapp': normalizedPhone?.isEmpty == true
          ? null
          : normalizedPhone,
    };
  }
}
