import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/agro_colors.dart';
import '../../domain/models/diagnosis_display.dart';
import '../../providers/app_providers.dart';
import '../../providers/scan_session_provider.dart';
import '../../shared/widgets/agro_buttons.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/diagnosis_delete.dart';
import '../../shared/widgets/agro_detail_app_bar.dart';
import '../../shared/widgets/disclaimer_banner.dart';
import '../../shared/widgets/scan_frame_overlay.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.diagnosisId});

  final String diagnosisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(diagnosisByIdProvider(diagnosisId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leaveResultScreen(context, ref);
      },
      child: Scaffold(
        backgroundColor: AgroColors.background,
        appBar: AgroDetailAppBar(
          title: 'Résultat du scan',
          onBack: () => leaveResultScreen(context, ref),
        ),
        body: recordAsync.when(
          data: (record) {
            if (record == null) {
              return const Center(child: Text('Diagnostic introuvable.'));
            }
            return _ResultBody(record: record, diagnosisId: diagnosisId);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }
}

class _TopPredictions extends StatelessWidget {
  const _TopPredictions({required this.predictions});

  final List<DiagnosisPrediction> predictions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hypothèses principales',
          style: theme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AgroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (final (index, prediction) in predictions.indexed) ...[
          _PredictionRow(
            rank: index + 1,
            prediction: prediction,
          ),
          if (index != predictions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PredictionRow extends StatelessWidget {
  const _PredictionRow({required this.rank, required this.prediction});

  final int rank;
  final DiagnosisPrediction prediction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AgroColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: AgroColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            prediction.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${prediction.scorePercent}%',
          style: const TextStyle(
            color: AgroColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({
    required this.record,
    required this.diagnosisId,
  });

  final DiagnosisRecord record;
  final String diagnosisId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDeleteDiagnosis(context)) return;
    await deleteDiagnosisAndRefresh(ref, diagnosisId);
    if (!context.mounted) return;
    navigateAfterDiagnosisDeleted(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = record.display;
    final imagePath = record.imagePath;
    final origin = ref.watch(diagnosisResultOriginProvider);
    final canRetry = origin == DiagnosisResultOrigin.scanFlow;

    return SingleChildScrollView(
      padding: AgroColors.screenScrollPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AgroColors.radiusCard),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath), fit: BoxFit.cover),
                  const ScanFrameOverlay(showScanLine: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AgroColors.surface,
              borderRadius: BorderRadius.circular(AgroColors.radiusCard),
              border: Border.all(color: AgroColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.plantName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AgroColors.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  display.headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: display.isLowConfidence
                            ? AgroColors.textMuted
                            : display.isHealthy
                                ? AgroColors.success
                                : AgroColors.danger,
                      ),
                ),
                if (display.isLowConfidence) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Confiance insuffisante — essayez de reprendre une photo '
                    'nette, avec une feuille bien cadrée et une bonne luminosité.',
                    style: TextStyle(color: AgroColors.danger, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.adjust,
                          size: 16, color: AgroColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Confiance : ${display.confidencePercent}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (display.topLabels.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _TopPredictions(predictions: display.topLabels),
                ],
                const SizedBox(height: 12),
                const DisclaimerBanner(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AgroPrimaryButton(
            label: 'Voir la fiche diagnostic',
            icon: Icons.menu_book_outlined,
            onPressed: () => context.push('/result/${record.id}/advice'),
          ),
          const SizedBox(height: 12),
          AgroSecondaryButton(
            label: 'Zones analysées',
            icon: Icons.insights_outlined,
            onPressed: () => context.push('/result/${record.id}/explanation'),
          ),
          if (canRetry) ...[
            const SizedBox(height: 12),
            AgroGhostButton(
              label: 'Réessayer',
              icon: Icons.refresh,
              onPressed: () => openRetryCapture(context, ref, diagnosisId),
            ),
          ],
          // After a fresh scan, retry covers a bad photo; delete stays in history.
          if (!canRetry) ...[
            const SizedBox(height: 12),
            AgroGhostButton(
              label: 'Supprimer ce diagnostic',
              icon: Icons.delete_outline,
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
