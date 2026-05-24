import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/agro_colors.dart';
import '../../data/advice/advice_models.dart';
import '../../domain/models/diagnosis_display.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/agro_detail_app_bar.dart';

final adviceForDiagnosisProvider =
    FutureProvider.autoDispose.family<DiseaseAdvice, String>((ref, id) async {
  final record = await ref.watch(diagnosisRepositoryProvider).getById(id);
  if (record == null) {
    throw StateError('Diagnostic introuvable');
  }
  return ref
      .watch(adviceRepositoryProvider)
      .getByKey(record.display.adviceKey);
});

class AdviceScreen extends ConsumerWidget {
  const AdviceScreen({super.key, required this.diagnosisId});

  final String diagnosisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(diagnosisByIdProvider(diagnosisId));
    final adviceAsync = ref.watch(adviceForDiagnosisProvider(diagnosisId));

    return Scaffold(
      backgroundColor: AgroColors.background,
      appBar: const AgroDetailAppBar(title: 'Fiche diagnostic'),
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return const Center(child: Text('Diagnostic introuvable.'));
          }
          return adviceAsync.when(
            data: (advice) => _AdviceBody(
              imagePath: record.imagePath,
              display: record.display,
              advice: advice,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _AdviceBody extends StatelessWidget {
  const _AdviceBody({
    required this.imagePath,
    required this.display,
    required this.advice,
  });

  final String imagePath;
  final DiagnosisDisplay display;
  final DiseaseAdvice advice;

  @override
  Widget build(BuildContext context) {
    final isHealthySheet =
        display.isHealthy || advice.key == 'generic_healthy';
    final showSymptoms =
        !isHealthySheet && advice.symptoms.isNotEmpty;

    return SingleChildScrollView(
      padding: AgroColors.screenScrollPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AgroColors.radiusCard),
                child: Image.file(
                  File(imagePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHealthySheet
                        ? AgroColors.success
                        : AgroColors.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    advice.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Plante : ${display.plantName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AgroColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            advice.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (advice.key == 'generic_disease' &&
              !display.isHealthy &&
              display.diseaseName != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AgroColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AgroColors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Fiche générique — diagnostic IA : ${display.diseaseName}',
                style: const TextStyle(
                  color: AgroColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            advice.description,
            style: const TextStyle(color: AgroColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (showSymptoms) ...[
            _SectionCard(
              icon: Icons.coronavirus_outlined,
              iconColor: AgroColors.danger,
              title: 'Symptômes',
              child: Column(
                children: [
                  for (final symptom in advice.symptoms) ...[
                    _SymptomTile(symptom: symptom),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionCard(
            icon: isHealthySheet
                ? Icons.eco_outlined
                : Icons.shield_outlined,
            iconColor: AgroColors.success,
            title: isHealthySheet ? 'Entretien et prévention' : 'Que faire ?',
            child: Column(
              children: [
                for (var i = 0; i < advice.steps.length; i++) ...[
                  _StepTile(index: i + 1, step: advice.steps[i]),
                  if (i < advice.steps.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(AgroColors.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(advice.disclaimer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgroColors.surface,
        borderRadius: BorderRadius.circular(AgroColors.radiusCard),
        border: Border.all(color: AgroColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.symptom});

  final AdviceSymptom symptom;

  @override
  Widget build(BuildContext context) {
    final bg = symptom.isPrimary ? AgroColors.dangerLight : const Color(0xFFF3F4F6);
    final iconColor =
        symptom.isPrimary ? AgroColors.danger : AgroColors.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            symptom.isPrimary ? Icons.circle : Icons.eco_outlined,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(symptom.text)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final AdviceStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AgroColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AgroColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                step.description,
                style: const TextStyle(color: AgroColors.textMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
