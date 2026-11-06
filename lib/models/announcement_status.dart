enum AnnouncementStatus {
  approuvee('approuvee', 'Publiée'),
  enAttenteLegacy('en_attente', 'En attente de contrôle'),
  brouillon('brouillon', 'Brouillon'),
  enAttenteControle('en_attente_controle', 'En attente de contrôle'),
  correctionDemandee('correction_demandee', 'Correction demandée'),
  publiee('publiee', 'Publiée'),
  retraitDemande('retrait_demande', 'Retrait demandé'),
  retiree('retiree', 'Retirée'),
  refusee('refusee', 'Refusée');

  const AnnouncementStatus(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  bool get isPublicCompatible => switch (this) {
    AnnouncementStatus.approuvee ||
    AnnouncementStatus.publiee ||
    AnnouncementStatus.retraitDemande => true,
    _ => false,
  };

  static AnnouncementStatus fromDatabase(Object? value) =>
      AnnouncementStatus.values.firstWhere(
        (status) => status.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Statut d’annonce invalide : $value'),
      );
}

const publicAnnouncementStatuses = <AnnouncementStatus>{
  AnnouncementStatus.approuvee,
  AnnouncementStatus.publiee,
  AnnouncementStatus.retraitDemande,
};

enum AnnouncementVersionStatus {
  brouillon('brouillon'),
  enAttenteControle('en_attente_controle'),
  correctionDemandee('correction_demandee'),
  publiee('publiee'),
  refusee('refusee'),
  archivee('archivee');

  const AnnouncementVersionStatus(this.databaseValue);
  final String databaseValue;

  static AnnouncementVersionStatus fromDatabase(Object? value) =>
      AnnouncementVersionStatus.values.firstWhere(
        (status) => status.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Statut de version invalide : $value'),
      );
}

enum WithdrawalRequestStatus {
  enAttente('en_attente'),
  approuvee('approuvee'),
  refusee('refusee');

  const WithdrawalRequestStatus(this.databaseValue);
  final String databaseValue;

  static WithdrawalRequestStatus fromDatabase(Object? value) =>
      WithdrawalRequestStatus.values.firstWhere(
        (status) => status.databaseValue == value?.toString(),
        orElse: () =>
            throw FormatException('Statut de retrait invalide : $value'),
      );
}
