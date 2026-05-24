import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/agro_colors.dart';
import '../../data/ml/diagnosis_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/scan_session_provider.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/widgets/agro_buttons.dart';
import '../../shared/widgets/agro_detail_app_bar.dart';
import '../../shared/widgets/scan_frame_overlay.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  bool _running = true;
  bool _cancelled = false;
  String? _error;
  late final AnimationController _scanLine;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: kAnalysisScanPassDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  @override
  void dispose() {
    _cancelled = true;
    _scanLine.dispose();
    super.dispose();
  }

  void _interrupt() {
    _cancelled = true;
    ref.read(pendingReplaceDiagnosisIdProvider.notifier).clear();
    context.pop();
  }

  /// Waits for at least one full pass ([kAnalysisScanPassDuration] each time).
  /// If inference is slower, additional passes run at the same fixed speed.
  Future<void> _waitForScanLineWith(Future<void> analysisWork) async {
    while (true) {
      final pass = _scanLine.forward(from: 0);
      final analysisDone = await Future.any<bool>([
        analysisWork.then((_) => true),
        pass.then((_) => false),
      ]);
      if (analysisDone) {
        if (_scanLine.isAnimating || _scanLine.value < 1.0) {
          await _scanLine.forward();
        }
        return;
      }
    }
  }

  Future<void> _runAnalysis() async {
    final imagePath = ref.read(pendingImagePathProvider);
    if (imagePath == null) {
      setState(() {
        _error = 'Aucune image à analyser.';
        _running = false;
      });
      return;
    }

    try {
      final service = ref.read(diagnosisServiceProvider);
      InferenceResult? inferenceResult;

      // Inference only — persist after the scan line finishes and only if
      // the user did not tap Interrompre (inference can finish much earlier).
      Future<void> inferenceWork() async {
        inferenceResult = await service.analyze(File(imagePath));
      }

      await _waitForScanLineWith(inferenceWork());

      if (_cancelled || !mounted || inferenceResult == null) return;

      final repo = ref.read(diagnosisRepositoryProvider);
      final replaceId = ref.read(pendingReplaceDiagnosisIdProvider);
      final isNewRecord = replaceId == null;
      final String diagnosisId;
      if (replaceId != null) {
        diagnosisId = await repo.replaceDiagnosis(
          id: replaceId,
          sourceImage: File(imagePath),
          display: inferenceResult!.display,
          heatmap: inferenceResult!.heatmap,
        );
        ref.read(pendingReplaceDiagnosisIdProvider.notifier).clear();
      } else {
        diagnosisId = await repo.persistDiagnosis(
          sourceImage: File(imagePath),
          display: inferenceResult!.display,
          heatmap: inferenceResult!.heatmap,
        );
      }

      if (_cancelled || !mounted) {
        if (isNewRecord) {
          await repo.deleteById(diagnosisId);
        }
        return;
      }

      ref.read(diagnosticsRevisionProvider.notifier).bump();
      ref.invalidate(diagnosisByIdProvider(diagnosisId));
      ref.read(pendingImagePathProvider.notifier).clear();
      openResultAfterCapture(context, ref, diagnosisId);
    } catch (e, st) {
      debugPrint('Analysis failed: $e\n$st');
      if (!mounted) return;
      final detail = kDebugMode ? '$e' : null;
      setState(() {
        _error = detail ??
            'Erreur lors de l\'analyse locale. Voir les logs (flutter run ou adb logcat).';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = ref.watch(pendingImagePathProvider);

    return Scaffold(
      backgroundColor: AgroColors.background,
      appBar: AgroDetailAppBar(
        title: 'Analyse',
        onBack: _interrupt,
      ),
      body: ColoredBox(
        color: AgroColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AgroColors.screenHorizontalPadding,
                    AgroColors.screenScrollTopPadding,
                    AgroColors.screenHorizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (imagePath != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AgroColors.radiusCard,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                ),
                                ScanFrameOverlay(
                                  borderColor: Colors.white70,
                                  showScanLine: true,
                                  scanLineAnimation: _scanLine,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox.shrink()),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AgroColors.surface,
                          borderRadius: BorderRadius.circular(
                            AgroColors.radiusCard,
                          ),
                          border: Border.all(color: AgroColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_running) ...[
                              const SizedBox(
                                width: 56,
                                height: 56,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AgroColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Analyse de la feuille en cours localement...',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ] else if (_error != null) ...[
                              const Icon(
                                Icons.error_outline,
                                color: AgroColors.danger,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              SelectableText(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AgroColors.screenHorizontalPadding,
                  16,
                  AgroColors.screenHorizontalPadding,
                  AgroColors.screenScrollBottomPadding,
                ),
                child: AgroGhostButton(
                  label: 'Interrompre',
                  icon: Icons.stop_circle_outlined,
                  onPressed: _interrupt,
                ),
              ),
            ],
        ),
      ),
    );
  }
}
