enum AnnouncementStatus {
  approuvee('approuvee'),
  enAttenteLegacy('en_attente'),
  brouillon('brouillon'),
  enAttenteControle('en_attente_controle'),
  correctionDemandee('correction_demandee'),
  publiee('publiee'),
  retraitDemande('retrait_demande'),
  retiree('retiree'),
  refusee('refusee');

  const AnnouncementStatus(this.databaseValue);

  final String databaseValue;

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
