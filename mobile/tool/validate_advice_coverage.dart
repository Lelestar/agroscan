// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:agroscan/domain/mappers/advice_key.dart';

/// Ensures every disease class has an entry in diseases_fr.json.
/// Usage (from mobile/): dart run tool/validate_advice_coverage.dart
void main() {
  final labelsFile = File('assets/models/labels.json');
  final adviceFile = File('assets/advice/diseases_fr.json');

  if (!labelsFile.existsSync() || !adviceFile.existsSync()) {
    stderr.writeln('Run from the mobile/ directory.');
    exit(1);
  }

  final labels =
      (jsonDecode(labelsFile.readAsStringSync()) as List<dynamic>).cast<String>();
  final adviceKeys =
      (jsonDecode(adviceFile.readAsStringSync()) as Map<String, dynamic>).keys;

  final missing = <String>[];
  for (final raw in labels) {
    if (raw.endsWith('___healthy')) {
      if (!adviceKeys.contains('generic_healthy')) {
        missing.add('generic_healthy (required for $raw)');
      }
      continue;
    }
    final key = adviceKeyFromRawLabel(raw);
    if (!adviceKeys.contains(key)) {
      missing.add('$key  ←  $raw');
    }
  }

  if (missing.isEmpty) {
    print('OK: ${labels.length} classes, all disease sheets present.');
    exit(0);
  }

  stderr.writeln('Missing sheets (${missing.length}):');
  for (final line in missing) {
    stderr.writeln('  - $line');
  }
  exit(1);
}
