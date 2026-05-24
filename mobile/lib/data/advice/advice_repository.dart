import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import 'advice_models.dart';

class AdviceRepository {
  Map<String, DiseaseAdvice>? _cache;

  Future<DiseaseAdvice> getByKey(String key) async {
    await _load();
    final advice = _cache![key];
    if (advice != null) return advice;
    assert(() {
      debugPrint(
        'AdviceRepository: missing sheet for "$key", '
        'falling back to generic_disease',
      );
      return true;
    }());
    return _cache!['generic_disease']!;
  }

  Future<void> _load() async {
    if (_cache != null) return;
    final raw = await rootBundle.loadString(AgroConstants.adviceAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = {
      for (final entry in json.entries)
        entry.key: DiseaseAdvice.fromJson(entry.value as Map<String, dynamic>),
    };
  }
}
