enum AccountRole {
  locataire('locataire', 'Locataire'),
  proprietaire('proprietaire', 'Propriétaire'),
  agence('agence', 'Agence immobilière');

  const AccountRole(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static AccountRole fromDatabase(Object? value) {
    final text = value?.toString();
    return AccountRole.values.firstWhere(
      (role) => role.databaseValue == text,
      orElse: () => throw FormatException('Rôle public invalide : $value'),
    );
  }
}
