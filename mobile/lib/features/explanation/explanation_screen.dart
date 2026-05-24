import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/agro_colors.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/agro_detail_app_bar.dart';
import '../../shared/widgets/heatmap_overlay.dart';
import '../../shared/widgets/scan_frame_overlay.dart';

final heatmapGridProvider =
    FutureProvider.autoDispose.family<Float32List?, String>((ref, id) async {
  final record = await ref.watch(diagnosisRepositoryProvider).getById(id);
  if (record == null) return null;
  return ref.watch(explanationServiceProvider).loadHeatmap(
        id,
        record.imagePath,
      );
});

class ExplanationScreen extends ConsumerWidget {
  const ExplanationScreen({super.key, required this.diagnosisId});

  final String diagnosisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(diagnosisByIdProvider(diagnosisId));
    final heatmapAsync = ref.watch(heatmapGridProvider(diagnosisId));

    return Scaffold(
      backgroundColor: AgroColors.background,
      appBar: const AgroDetailAppBar(title: 'Zones analysées'),
      body: recordAsync.when(
        data: (record) {
          if (record == null) {
            return const Center(child: Text('Diagnostic introuvable.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AgroColors.screenHorizontalPadding,
                  AgroColors.screenScrollTopPadding,
                  AgroColors.screenHorizontalPadding,
                  0,
                ),
                child: Text(
                  'Les zones colorées indiquent ce que le modèle a le plus pris en compte pour ce diagnostic.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AgroColors.textMuted,
                        height: 1.4,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AgroColors.screenHorizontalPadding,
                    0,
                    AgroColors.screenHorizontalPadding,
                    AgroColors.screenScrollBottomPadding,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AgroColors.radiusCard),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(record.imagePath),
                                fit: BoxFit.cover,
                              ),
                              const ScanFrameOverlay(showScanLine: false),
                              heatmapAsync.when(
                                data: (grid) => HeatmapOverlay(
                                  key: ValueKey(
                                    '$heatmapRasterStyleVersion-${grid?.hashCode}',
                                  ),
                                  grid: grid,
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HeatmapLegend(
                        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AgroColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AgroColors.surface,
                          borderRadius:
                              BorderRadius.circular(AgroColors.radiusCard),
                          border: Border.all(color: AgroColors.border),
                        ),
                        child: const Row(
                          children: [
                            _InsightIcon(),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Visualisation indicative : elle aide à comprendre la prédiction, sans remplacer l\'observation de la plante sur le terrain.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({required this.labelStyle});

  final TextStyle? labelStyle;

  static const _gradient = LinearGradient(
    colors: [
      Color(0xFFFFEB3B),
      Color(0xFFFF9800),
      Color(0xFFE53935),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: _gradient,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Influence faible', style: labelStyle),
            Text('Influence forte', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _InsightIcon extends StatelessWidget {
  const _InsightIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AgroColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.insights_outlined, color: AgroColors.primary),
    );
  }
}
