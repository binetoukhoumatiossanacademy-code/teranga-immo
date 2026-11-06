import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'account_service.dart';
import 'design_system/design_system.dart';
import 'moderation_service.dart';
import 'tenant_widgets.dart';

/// Back-office minimal pour les comptes administrateur : file d'attente de
/// contrôle des annonces et des demandes de retrait. Le rôle administrateur
/// n'est jamais attribué par l'application (voir `AccountRole.admin`) ; cet
/// écran n'est donc jamais atteint en s'inscrivant depuis l'app.
class AdminFlow extends StatefulWidget {
  const AdminFlow({super.key, required this.account, this.moderation});
  final AccountController account;
  final ModerationGateway? moderation;
  @override
  State<AdminFlow> createState() => _AdminFlowState();
}

class _AdminFlowState extends State<AdminFlow> {
  List<PendingModeration>? pendingModeration;
  List<PendingWithdrawal>? pendingWithdrawals;
  String? loadError;
  bool loading = false;
  final busyVersionIds = <String>{};
  final busyWithdrawalIds = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final gateway = widget.moderation;
    if (gateway == null) return;
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final moderation = await gateway.listPendingModeration();
      final withdrawals = await gateway.listPendingWithdrawals();
      if (mounted) {
        setState(() {
          pendingModeration = moderation;
          pendingWithdrawals = withdrawals;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => loadError =
              'Impossible de charger la file d’attente. Vérifiez votre connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String?> _promptMessage({
    required String title,
    required bool required,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: required
                ? 'Message pour l’annonceur (obligatoire)'
                : 'Commentaire (optionnel)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (required && text.isEmpty) return;
              Navigator.pop(dialogContext, text.isEmpty ? null : text);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> decide(PendingModeration item, String decision) async {
    final needsMessage = decision != 'accepter';
    String? message;
    if (needsMessage) {
      message = await _promptMessage(
        title: decision == 'refuser'
            ? 'Refuser l’annonce'
            : 'Demander une correction',
        required: true,
      );
      if (message == null) return;
    }
    setState(() => busyVersionIds.add(item.versionId));
    try {
      await widget.moderation!.moderate(
        versionId: item.versionId,
        decision: decision,
        messageToOwner: message,
      );
      if (mounted) {
        setState(
          () => pendingModeration = pendingModeration!
              .where((element) => element.versionId != item.versionId)
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’enregistrer la décision. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busyVersionIds.remove(item.versionId));
    }
  }

  Future<void> decideWithdrawal(PendingWithdrawal item, bool approve) async {
    final comment = await _promptMessage(
      title: approve ? 'Approuver le retrait' : 'Refuser le retrait',
      required: false,
    );
    setState(() => busyWithdrawalIds.add(item.id));
    try {
      await widget.moderation!.processWithdrawal(
        requestId: item.id,
        approve: approve,
        comment: comment,
      );
      if (mounted) {
        setState(
          () => pendingWithdrawals = pendingWithdrawals!
              .where((element) => element.id != item.id)
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’enregistrer la décision. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busyWithdrawalIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TerangaColors.ivory,
    appBar: AppBar(
      backgroundColor: TerangaColors.ivory,
      title: const Text('Modération Teranga Immo'),
      actions: [
        IconButton(
          tooltip: 'Se déconnecter',
          onPressed: () => widget.account.gateway.signOut(),
          icon: const Icon(LucideIcons.log_out),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(TerangaSpacing.lg),
              children: [
                if (widget.moderation == null)
                  const TenantNotice(
                    'Supabase n’est pas configuré. Aucune décision ne peut être enregistrée.',
                    warning: true,
                  ),
                if (loadError != null) ...[
                  TenantNotice(loadError!, warning: true),
                  const SizedBox(height: TerangaSpacing.sm),
                  OutlinedButton(
                    onPressed: load,
                    child: const Text('Réessayer'),
                  ),
                ],
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: TerangaSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: TerangaColors.gold,
                      ),
                    ),
                  ),
                Text(
                  'Annonces en attente de contrôle',
                  style: TerangaTypography.sectionTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: TerangaSpacing.sm),
                if (!loading && (pendingModeration ?? const []).isEmpty)
                  Text(
                    'Aucune annonce en attente.',
                    style: TerangaTypography.meta,
                  ),
                for (final item in pendingModeration ?? const [])
                  moderationCard(item),
                const SizedBox(height: TerangaSpacing.xxl),
                Text(
                  'Demandes de retrait',
                  style: TerangaTypography.sectionTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: TerangaSpacing.sm),
                if (!loading && (pendingWithdrawals ?? const []).isEmpty)
                  Text(
                    'Aucune demande en attente.',
                    style: TerangaTypography.meta,
                  ),
                for (final item in pendingWithdrawals ?? const [])
                  withdrawalCard(item),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget moderationCard(PendingModeration item) {
    final busy = busyVersionIds.contains(item.versionId);
    final location = [
      item.district,
      item.city,
      item.region,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: TerangaSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(TerangaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.housingType ?? 'Logement',
              style: TerangaTypography.cardTitle,
            ),
            Text(location, style: TerangaTypography.body),
            if (item.monthlyRent != null)
              Text(
                '${item.monthlyRent} FCFA / mois',
                style: TerangaTypography.body,
              ),
            const SizedBox(height: TerangaSpacing.sm),
            Text(
              item.description ?? 'Description non renseignée.',
              style: TerangaTypography.meta,
            ),
            const SizedBox(height: TerangaSpacing.md),
            if (busy)
              const Center(
                child: CircularProgressIndicator(color: TerangaColors.gold),
              )
            else
              Wrap(
                spacing: TerangaSpacing.sm,
                runSpacing: TerangaSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: () => decide(item, 'accepter'),
                    child: const Text('Accepter'),
                  ),
                  OutlinedButton(
                    onPressed: () => decide(item, 'demander_correction'),
                    child: const Text('Demander une correction'),
                  ),
                  OutlinedButton(
                    onPressed: () => decide(item, 'refuser'),
                    child: const Text('Refuser'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget withdrawalCard(PendingWithdrawal item) {
    final busy = busyWithdrawalIds.contains(item.id);
    return Card(
      margin: const EdgeInsets.only(bottom: TerangaSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(TerangaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motif : ${item.reason}', style: TerangaTypography.body),
            Text(
              item.rentedOut
                  ? 'Le logement a été loué.'
                  : 'Le logement n’a pas été loué.',
              style: TerangaTypography.meta,
            ),
            const SizedBox(height: TerangaSpacing.md),
            if (busy)
              const Center(
                child: CircularProgressIndicator(color: TerangaColors.gold),
              )
            else
              Wrap(
                spacing: TerangaSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: () => decideWithdrawal(item, true),
                    child: const Text('Approuver'),
                  ),
                  OutlinedButton(
                    onPressed: () => decideWithdrawal(item, false),
                    child: const Text('Refuser'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
