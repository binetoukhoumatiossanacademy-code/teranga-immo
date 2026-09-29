import 'package:flutter_test/flutter_test.dart';
import 'package:teranga_immo/models/account_role.dart';
import 'package:teranga_immo/models/announcement.dart';
import 'package:teranga_immo/models/announcement_contact.dart';
import 'package:teranga_immo/models/announcement_photo.dart';
import 'package:teranga_immo/models/announcement_status.dart';
import 'package:teranga_immo/models/announcement_version.dart';
import 'package:teranga_immo/models/control_level.dart';
import 'package:teranga_immo/models/user_profile.dart';

const userId = '11111111-1111-4111-8111-111111111111';
const workflowId = '22222222-2222-4222-8222-222222222222';
const versionId = '33333333-3333-4333-8333-333333333333';
const photoId = '44444444-4444-4444-8444-444444444444';
const timestamp = '2026-09-28T10:00:00Z';

Map<String, dynamic> announcementJson({
  String? status = 'brouillon',
  bool publicationAuthorized = false,
  int submittedVersion = 0,
  bool premiumActive = false,
}) => {
  'id': 42,
  'workflow_id': workflowId,
  'statut': status,
  'niveau_controle': 'declaree',
  'publication_autorisee': publicationAuthorized,
  'version_soumise': submittedVersion,
  'premium_actif': premiumActive,
  'updated_at': timestamp,
};

void main() {
  group('rôles et profil', () {
    test('les trois rôles publics correspondent au schéma Supabase', () {
      expect(AccountRole.values.map((role) => role.databaseValue), [
        'locataire',
        'proprietaire',
        'agence',
      ]);
      expect(
        () => AccountRole.fromDatabase('admin'),
        throwsA(isA<FormatException>()),
      );
    });

    test('un profil agence conserve ses champs Supabase', () {
      final profile = UserProfile.fromJson({
        'id': userId,
        'nom': 'Awa Diop',
        'type_compte': 'agence',
        'nom_agence': 'Teranga Habitat',
        'telephone_whatsapp': '77 000 00 00',
        'created_at': '2026-09-28T10:00:00Z',
        'updated_at': '2026-09-28T11:00:00Z',
      });
      expect(profile.role, AccountRole.agence);
      expect(profile.agencyName, 'Teranga Habitat');
      expect(profile.toProfileRow(), {
        'id': userId,
        'type_compte': 'agence',
        'nom': 'Awa Diop',
        'nom_agence': 'Teranga Habitat',
        'telephone_whatsapp': '77 000 00 00',
      });
    });

    test('un nom d’agence est obligatoire uniquement pour une agence', () {
      expect(
        () => UserProfile(
          id: userId,
          name: 'Awa',
          role: AccountRole.agence,
          createdAt: DateTime.utc(2026, 9, 28),
          updatedAt: DateTime.utc(2026, 9, 28),
        ),
        throwsArgumentError,
      );
      expect(
        () => UserProfile(
          id: userId,
          name: 'Awa',
          role: AccountRole.locataire,
          agencyName: 'Agence interdite',
          createdAt: DateTime.utc(2026, 9, 28),
          updatedAt: DateTime.utc(2026, 9, 28),
        ),
        throwsArgumentError,
      );
      expect(
        () => UserProfile(
          id: userId,
          name: 'Awa',
          role: AccountRole.locataire,
          agencyName: '',
          createdAt: DateTime.utc(2026, 9, 28),
          updatedAt: DateTime.utc(2026, 9, 28),
        ),
        throwsArgumentError,
      );
      expect(
        () => UserProfile.fromJson({
          'nom': 'Awa',
          'type_compte': 'locataire',
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('annonce', () {
    test('distingue le bigint historique du workflow UUID', () {
      final announcement = Announcement.fromJson({
        'id': 42,
        'workflow_id': workflowId,
        'annonceur_id': userId,
        'statut': 'approuvee',
        'region': 'Dakar',
        'ville': 'Dakar',
        'quartier': 'Ngor',
        'type_logement': 'Appartement',
        'loyer_mensuel': 350000,
        'nombre_chambres': 3,
        'est_meuble': true,
        'description': 'Appartement lumineux.',
        'mode_disponibilite': 'maintenant',
        'niveau_controle': 'declaree',
        'publication_autorisee': true,
        'version_soumise': 1,
        'version_publiee_id': versionId,
        'premium_actif': false,
        'updated_at': timestamp,
      });
      expect(announcement.legacyId.value, 42);
      expect(announcement.workflowId.value, workflowId);
      expect(announcement.legacyId, isNot(isA<AnnouncementWorkflowId>()));
      expect(announcement.status, AnnouncementStatus.approuvee);
      expect(announcement.hasPublicCompatibleStatus, isTrue);
      expect(announcement.controlLevel, ControlLevel.declaree);
      expect(announcement.housingType, HousingType.appartement);
      expect(announcement.publicationAuthorized, isTrue);
      expect(
        Announcement.fromJson(announcementJson(status: null)).status,
        isNull,
      );
      final missingRequired = announcementJson()..remove('premium_actif');
      expect(
        () => Announcement.fromJson(missingRequired),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Announcement.fromJson({
          ...announcementJson(),
          'version_soumise': 'invalide',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'reconnaît les trois statuts compatibles avec la lecture publique',
      () {
        expect(
          publicAnnouncementStatuses
              .map((status) => status.databaseValue)
              .toSet(),
          {'approuvee', 'publiee', 'retrait_demande'},
        );
        expect(AnnouncementStatus.enAttenteLegacy.isPublicCompatible, isFalse);
        expect(
          AnnouncementStatus.correctionDemandee.isPublicCompatible,
          isFalse,
        );
        expect(
          AnnouncementVersionStatus.values
              .map((status) => status.databaseValue)
              .toSet(),
          {
            'brouillon',
            'en_attente_controle',
            'correction_demandee',
            'publiee',
            'refusee',
            'archivee',
          },
        );
        expect(
          WithdrawalRequestStatus.values
              .map((status) => status.databaseValue)
              .toSet(),
          {'en_attente', 'approuvee', 'refusee'},
        );
      },
    );

    test('une version distingue les états modifiables des états figés', () {
      final version = AnnouncementVersion.fromJson({
        'id': versionId,
        'annonce_id': workflowId,
        'numero_version': 2,
        'statut_version': 'correction_demandee',
        'type_logement': 'Maison',
        'loyer_mensuel': 250000,
        'created_by': userId,
        'created_at': timestamp,
        'updated_at': timestamp,
      });
      expect(version.announcementId.value, workflowId);
      expect(version.status, AnnouncementVersionStatus.correctionDemandee);
      expect(version.canBeEdited, isTrue);
      expect(version.versionNumber, 2);
      expect(
        () => AnnouncementVersion.fromJson({
          'id': versionId,
          'annonce_id': workflowId,
          'numero_version': 2,
          'statut_version': 'brouillon',
          'mode_disponibilite': 'date',
          'created_at': timestamp,
          'updated_at': timestamp,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejette un workflow_id qui ne serait pas un UUID', () {
      expect(
        () => AnnouncementWorkflowId.fromJson('42'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('contact, photos et contrôle', () {
    test('parse le contact propriétaire de la version publiée', () {
      final contact = AnnouncementContact.fromJson({
        'version_id': versionId,
        'annonce_id': workflowId,
        'nom_contact': 'Awa Diop',
        'type_contact': 'proprietaire',
        'telephone_whatsapp': '77 000 00 00',
        'email_contact': 'awa@example.com',
        'appel_autorise': true,
        'whatsapp_autorise': true,
        'updated_at': '2026-09-28T10:00:00Z',
      });
      expect(contact.role, AccountRole.proprietaire);
      expect(contact.callAllowed, isTrue);
      expect(contact.whatsAppAllowed, isTrue);
    });

    test('rejette un locataire comme annonceur de contact', () {
      expect(
        () => AnnouncementContact.fromJson({
          'version_id': versionId,
          'annonce_id': workflowId,
          'nom_contact': 'Locataire',
          'type_contact': 'locataire',
          'telephone_whatsapp': '77 000 00 00',
          'appel_autorise': true,
          'whatsapp_autorise': true,
          'updated_at': '2026-09-28T10:00:00Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('respecte les formats et la limite de 8 Mo des photos', () {
      final photo = AnnouncementPhoto.fromJson({
        'id': photoId,
        'annonce_id': workflowId,
        'storage_path': '$userId/$workflowId/photo.webp',
        'created_by': userId,
        'mime_type': 'image/webp',
        'taille_octets': maxAnnouncementPhotoBytes,
        'created_at': '2026-09-28T10:00:00Z',
      });
      expect(photo.mimeType, AnnouncementPhotoMimeType.webp);
      expect(photo.sizeBytes, maxAnnouncementPhotoBytes);
      expect(
        () => AnnouncementPhoto.fromJson({
          'id': photoId,
          'annonce_id': workflowId,
          'storage_path': '$userId/$workflowId/photo.webp',
          'created_by': userId,
          'mime_type': 'image/webp',
          'taille_octets': maxAnnouncementPhotoBytes + 1,
          'created_at': '2026-09-28T10:00:00Z',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AnnouncementPhoto.fromJson({
          'id': photoId,
          'annonce_id': workflowId,
          'storage_path': '$workflowId/$userId/photo.webp',
          'created_by': userId,
          'mime_type': 'image/webp',
          'taille_octets': 1024,
          'created_at': timestamp,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('conserve ordre et photo principale par version', () {
      final link = AnnouncementVersionPhoto.fromJson({
        'version_id': versionId,
        'photo_id': photoId,
        'ordre': 0,
        'est_principale': true,
      });
      expect(link.order, 0);
      expect(link.isPrimary, isTrue);
    });

    test('les niveaux de contrôle restent distincts de Premium', () {
      expect(ControlLevel.declaree.databaseValue, 'declaree');
      expect(ControlLevel.declaree.indicator, '🔴');
      expect(
        ControlLevel.informationsControlees.databaseValue,
        'informations_controlees',
      );
      expect(ControlLevel.verifieeTeranga.databaseValue, 'verifiee_teranga');
      expect(
        ControlElementCode.values.map((value) => value.databaseValue).toSet(),
        {
          'identite_annonceur',
          'existence_logement',
          'localisation',
          'photos_correspondantes',
          'prix_declare',
          'caracteristiques',
          'disponibilite',
          'droit_proposer_logement',
        },
      );
      expect(
        () => AnnouncementControl.fromJson({
          'id': photoId,
          'annonce_id': workflowId,
          'version_id': versionId,
          'administrateur_id': userId,
          'niveau_attribue': 'declaree',
          'resume_public': 'Résumé.',
          'effectue_at': timestamp,
          'created_at': timestamp,
        }),
        throwsA(isA<FormatException>()),
      );
      final announcement = Announcement.fromJson({
        'id': 7,
        'workflow_id': workflowId,
        'statut': 'publiee',
        'niveau_controle': 'declaree',
        'version_soumise': 1,
        'premium_actif': true,
        'premium_debut_at': '2026-09-01T00:00:00Z',
        'premium_fin_at': '2026-10-01T00:00:00Z',
        'publication_autorisee': true,
        'updated_at': timestamp,
      });
      expect(announcement.controlLevel, ControlLevel.declaree);
      expect(announcement.isPremiumAt(DateTime.utc(2026, 9, 15)), isTrue);
      expect(
        () => Announcement.fromJson({
          ...announcementJson(premiumActive: true),
          'premium_debut_at': '2026-10-01T00:00:00Z',
          'premium_fin_at': '2026-09-01T00:00:00Z',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Announcement.fromJson({...announcementJson(premiumActive: true)}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
