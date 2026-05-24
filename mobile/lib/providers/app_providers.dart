import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/advice/advice_repository.dart';
import '../data/explanation/explanation_service.dart';
import '../data/local/diagnosis_repository.dart';
import '../data/ml/diagnosis_service.dart';
import '../domain/mappers/label_mapper.dart';
import '../domain/models/diagnosis_display.dart';

final labelMapperProvider = Provider<LabelMapper>((ref) => LabelMapper());

final diagnosisServiceProvider = Provider<DiagnosisService>((ref) {
  return DiagnosisService(ref.watch(labelMapperProvider));
});

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return DiagnosisRepository();
});

final adviceRepositoryProvider = Provider<AdviceRepository>((ref) {
  return AdviceRepository();
});

final explanationServiceProvider = Provider<ExplanationService>((ref) {
  return ExplanationService();
});

/// Increment after a new diagnosis is saved so list providers refetch.
class DiagnosticsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final diagnosticsRevisionProvider =
    NotifierProvider<DiagnosticsRevision, int>(DiagnosticsRevision.new);

final homeDiagnosticsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(diagnosticsRevisionProvider);
  return ref.watch(diagnosisRepositoryProvider).listRecent(limit: 3);
});

final allDiagnosticsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(diagnosticsRevisionProvider);
  return ref.watch(diagnosisRepositoryProvider).listAll();
});

final diagnosisByIdProvider = FutureProvider.autoDispose
    .family<DiagnosisRecord?, String>((ref, id) async {
  ref.watch(diagnosticsRevisionProvider);
  return ref.watch(diagnosisRepositoryProvider).getById(id);
});

/// Tab scroll positions — kept alive while [StatefulShellRoute] branches are stacked.
final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

final historyScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

void scrollTabToTop(ScrollController controller) {
  if (!controller.hasClients) return;
  controller.animateTo(
    0,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );
}
