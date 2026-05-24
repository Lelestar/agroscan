import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/scan_session_provider.dart';

/// Opens capture from home or scanner; remembered for result back navigation.
void startCaptureFlow(
  BuildContext context,
  WidgetRef ref,
  DiagnosisResultOrigin entry, {
  bool gallery = false,
}) {
  ref.read(captureEntryOriginProvider.notifier).set(entry);
  ref.read(pendingReplaceDiagnosisIdProvider.notifier).clear();
  context.push(gallery ? '/capture?gallery=1' : '/capture');
}

/// Opens the result after capture → analysis, without leaving capture underneath.
void openResultAfterCapture(BuildContext context, WidgetRef ref, String id) {
  final entry =
      ref.read(captureEntryOriginProvider) ?? DiagnosisResultOrigin.scanFlow;
  ref.read(captureEntryOriginProvider.notifier).clear();
  ref.read(diagnosisResultOriginProvider.notifier).set(entry);
  context.go('/result/$id');
}

void openResultFromHome(BuildContext context, WidgetRef ref, String id) {
  ref.read(diagnosisResultOriginProvider.notifier).set(
        DiagnosisResultOrigin.home,
      );
  context.push('/result/$id');
}

void openResultFromHistory(BuildContext context, WidgetRef ref, String id) {
  ref.read(diagnosisResultOriginProvider.notifier).set(
        DiagnosisResultOrigin.history,
      );
  context.push('/result/$id');
}

/// Leaves the result screen to the screen the user came from.
void leaveResultScreen(BuildContext context, WidgetRef ref) {
  final origin = ref.read(diagnosisResultOriginProvider);
  ref.read(diagnosisResultOriginProvider.notifier).clear();

  switch (origin) {
    case DiagnosisResultOrigin.scanFlow:
      context.go('/scanner');
    case DiagnosisResultOrigin.home:
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    case DiagnosisResultOrigin.history:
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/history');
      }
    case null:
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/scanner');
      }
  }
}

/// Retry scan: replaces [diagnosisId] on the next successful analysis (not history).
void openRetryCapture(
  BuildContext context,
  WidgetRef ref,
  String diagnosisId, {
  bool gallery = false,
}) {
  final origin = ref.read(diagnosisResultOriginProvider);
  if (origin != null) {
    ref.read(captureEntryOriginProvider.notifier).set(origin);
  }
  ref.read(pendingReplaceDiagnosisIdProvider.notifier).set(diagnosisId);
  // Push so closing capture returns to the result being retried (go left nothing to pop).
  context.push(gallery ? '/capture?gallery=1' : '/capture');
}

/// Navigation only — the capture screen must release the camera before calling this.
void leaveCaptureScreen(BuildContext context, WidgetRef ref) {
  final replaceId = ref.read(pendingReplaceDiagnosisIdProvider);
  ref.read(pendingReplaceDiagnosisIdProvider.notifier).clear();

  if (context.canPop()) {
    context.pop();
    return;
  }

  if (replaceId != null) {
    context.go('/result/$replaceId');
    return;
  }

  final entry =
      ref.read(captureEntryOriginProvider) ?? DiagnosisResultOrigin.scanFlow;
  ref.read(captureEntryOriginProvider.notifier).clear();
  switch (entry) {
    case DiagnosisResultOrigin.home:
      context.go('/');
    case DiagnosisResultOrigin.history:
      context.go('/history');
    case DiagnosisResultOrigin.scanFlow:
      context.go('/scanner');
  }
}

void navigateAfterDiagnosisDeleted(BuildContext context, WidgetRef ref) {
  final origin = ref.read(diagnosisResultOriginProvider);
  ref.read(diagnosisResultOriginProvider.notifier).clear();

  switch (origin) {
    case DiagnosisResultOrigin.scanFlow:
      context.go('/scanner');
    case DiagnosisResultOrigin.home:
      context.go('/');
    case DiagnosisResultOrigin.history:
      context.go('/history');
    case null:
      context.go('/scanner');
  }
}
