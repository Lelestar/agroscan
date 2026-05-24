import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingImagePath extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? path) => state = path;

  void clear() => state = null;
}

final pendingImagePathProvider =
    NotifierProvider<PendingImagePath, String?>(PendingImagePath.new);

/// Where the user opened the current result screen (drives back navigation).
enum DiagnosisResultOrigin { scanFlow, home, history }

class DiagnosisResultOriginHolder extends Notifier<DiagnosisResultOrigin?> {
  @override
  DiagnosisResultOrigin? build() => null;

  void set(DiagnosisResultOrigin origin) => state = origin;

  void clear() => state = null;
}

final diagnosisResultOriginProvider =
    NotifierProvider<DiagnosisResultOriginHolder, DiagnosisResultOrigin?>(
  DiagnosisResultOriginHolder.new,
);

/// Tab/screen that launched the current capture → analysis flow.
final captureEntryOriginProvider =
    NotifierProvider<DiagnosisResultOriginHolder, DiagnosisResultOrigin?>(
  DiagnosisResultOriginHolder.new,
);

/// When set, the next successful analysis updates this record instead of creating one.
class PendingReplaceDiagnosisId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;

  void clear() => state = null;
}

final pendingReplaceDiagnosisIdProvider =
    NotifierProvider<PendingReplaceDiagnosisId, String?>(
  PendingReplaceDiagnosisId.new,
);
