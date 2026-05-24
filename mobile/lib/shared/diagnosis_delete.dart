import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/agro_colors.dart';
import '../providers/app_providers.dart';

export '../router/navigation_helpers.dart' show navigateAfterDiagnosisDeleted;

Future<bool> confirmDeleteDiagnosis(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer ce diagnostic ?'),
      content: const Text(
        'La photo et le résultat seront effacés définitivement de cet appareil.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AgroColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<void> deleteDiagnosisAndRefresh(WidgetRef ref, String id) async {
  await ref.read(diagnosisRepositoryProvider).deleteById(id);
  ref.read(diagnosticsRevisionProvider.notifier).bump();
  ref.invalidate(diagnosisByIdProvider(id));
}
