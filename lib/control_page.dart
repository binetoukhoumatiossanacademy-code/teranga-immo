import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'design_system/design_system.dart';
import 'models/control_level.dart';
import 'moderation_service.dart';
import 'tenant_widgets.dart';

const _elementLabels = {
  ControlElementCode.identiteAnnonceur: 'Identité de l’annonceur',
  ControlElementCode.existenceLogement: 'Existence du logement',
  ControlElementCode.localisation: 'Localisation',
  ControlElementCode.photosCorrespondantes: 'Photos correspondantes',
  ControlElementCode.prixDeclare: 'Prix déclaré',
  ControlElementCode.caracteristiques: 'Caractéristiques',
  ControlElementCode.disponibilite: 'Disponibilité',
  ControlElementCode.droitProposerLogement: 'Droit de proposer le logement',
};

const _resultLabels = {
  ControlResult.confirme: 'Confirmé',
  ControlResult.nonConfirme: 'Non confirmé',
  ControlResult.nonApplicable: 'Non applicable',
};

/// Formulaire administrateur pour `enregistrer_controle_annonce` : attribue
/// un niveau de contrôle à une annonce déjà publiée, avec ses 8 éléments
/// vérifiés. Indépendant de la modération (acceptation/refus) : une annonce
/// publiée peut être contrôlée à tout moment, plusieurs fois.
class ControlPage extends StatefulWidget {
  const ControlPage({
    super.key,
    required this.announcement,
    required this.moderation,
  });
  final PublishedAnnouncement announcement;
  final ModerationGateway moderation;
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  ControlLevel level = ControlLevel.informationsControlees;
  final summary = TextEditingController();
  final results = {
    for (final code in ControlElementCode.values)
      code: ControlResult.nonApplicable,
  };
  final explanations = {
    for (final code in ControlElementCode.values) code: TextEditingController(),
  };
  bool busy = false;
  String? error;

  @override
  void dispose() {
    summary.dispose();
    for (final controller in explanations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (summary.text.trim().isEmpty) {
      setState(() => error = 'Le résumé public est obligatoire.');
      return;
    }
    for (final code in ControlElementCode.values) {
      if (explanations[code]!.text.trim().isEmpty) {
        setState(
          () => error = 'Une explication est requise pour chaque élément.',
        );
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.moderation.recordControl(
        announcementWorkflowId: widget.announcement.announcementWorkflowId,
        level: level.databaseValue,
        publicSummary: summary.text.trim(),
        elements: [
          for (final code in ControlElementCode.values)
            ControlElementInput(
              code: code.databaseValue,
              result: results[code]!.databaseValue,
              explanation: explanations[code]!.text.trim(),
            ),
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Impossible d’enregistrer le contrôle. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final location = [
      a.district,
      a.city,
      a.region,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    return Scaffold(
      backgroundColor: TerangaColors.ivory,
      appBar: AppBar(
        backgroundColor: TerangaColors.ivory,
        title: const Text('Contrôler l’annonce'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(TerangaSpacing.lg),
              children: [
                Text(
                  a.housingType ?? 'Logement',
                  style: TerangaTypography.sectionTitle.copyWith(fontSize: 20),
                ),
                Text(location, style: TerangaTypography.body),
                const SizedBox(height: TerangaSpacing.lg),
                Text('Niveau de contrôle', style: TerangaTypography.cardTitle),
                const SizedBox(height: TerangaSpacing.sm),
                SegmentedButton<ControlLevel>(
                  segments: const [
                    ButtonSegment(
                      value: ControlLevel.informationsControlees,
                      label: Text('Informations contrôlées'),
                    ),
                    ButtonSegment(
                      value: ControlLevel.verifieeTeranga,
                      label: Text('Vérifiée Teranga Immo'),
                    ),
                  ],
                  selected: {level},
                  onSelectionChanged: (value) =>
                      setState(() => level = value.first),
                ),
                const SizedBox(height: TerangaSpacing.lg),
                TextField(
                  controller: summary,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Résumé public du contrôle',
                  ),
                ),
                const SizedBox(height: TerangaSpacing.xl),
                Text('Éléments vérifiés', style: TerangaTypography.cardTitle),
                for (final code in ControlElementCode.values) elementRow(code),
                const SizedBox(height: TerangaSpacing.md),
                if (error != null) TenantNotice(error!, warning: true),
                const SizedBox(height: TerangaSpacing.md),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enregistrer le contrôle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget elementRow(ControlElementCode code) => Padding(
    padding: const EdgeInsets.only(top: TerangaSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_elementLabels[code]!, style: TerangaTypography.bodyStrong),
        const SizedBox(height: 4),
        Wrap(
          spacing: TerangaSpacing.sm,
          children: [
            for (final result in ControlResult.values)
              ChoiceChip(
                label: Text(_resultLabels[result]!),
                selected: results[code] == result,
                onSelected: (_) => setState(() => results[code] = result),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: explanations[code],
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Explication publique'),
        ),
      ],
    ),
  );
}
