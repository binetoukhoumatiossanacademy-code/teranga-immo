import 'package:flutter/material.dart';
import 'account_service.dart';
import 'models/account_role.dart';
import 'owner_flow.dart';

/// Réutilise les formulaires et les garde-fous des annonceurs, avec le rôle
/// Agence confirmé par le profil serveur. Aucune permission d'administration.
class AgencyFlow extends StatelessWidget {
  const AgencyFlow({super.key, this.account, required this.onOwner});
  final AccountController? account;
  final VoidCallback onOwner;
  @override
  Widget build(BuildContext context) =>
      OwnerFlow(account: account, role: AccountRole.agence, onOwner: onOwner);
}
