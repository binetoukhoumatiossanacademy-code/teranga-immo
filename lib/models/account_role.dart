enum AccountRole {
  locataire('locataire', 'Locataire'),
  proprietaire('proprietaire', 'Propriétaire'),
  agence('agence', 'Agence immobilière'),
  admin('admin', 'Administrateur');

  const AccountRole(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  /// Rôles qu'un compte peut choisir lui-même, à l'inscription ou dans son
  /// profil. Le rôle administrateur n'est jamais attribué par l'application
  /// (voir `private.attribuer_role_admin`, réservée au `service_role`).
  static const selectable = [locataire, proprietaire, agence];

  static AccountRole fromDatabase(Object? value) {
    final text = value?.toString();
    return AccountRole.values.firstWhere(
      (role) => role.databaseValue == text,
      orElse: () => throw FormatException('Rôle public invalide : $value'),
    );
  }
}
