import 'dart:convert';
import 'dart:io';

import 'package:agroscan/domain/mappers/advice_key.dart';
import 'package:agroscan/domain/mappers/label_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> labels;

  setUpAll(() {
    final file = File('assets/models/labels.json');
    labels = (jsonDecode(file.readAsStringSync()) as List<dynamic>)
        .cast<String>();
  });

  group('adviceKeyFromRawLabel', () {
    test('healthy labels map to generic_healthy', () {
      expect(adviceKeyFromRawLabel('Tomato___healthy'), 'generic_healthy');
    });

    test('tomato late blight', () {
      expect(
        adviceKeyFromRawLabel('Tomato___Late_blight'),
        'tomato_late_blight',
      );
    });

    test('pepper bell bacterial spot', () {
      expect(
        adviceKeyFromRawLabel('Pepper,_bell___Bacterial_spot'),
        'pepper_bell_bacterial_spot',
      );
    });

    test('tomato spider mites label with spaces', () {
      expect(
        adviceKeyFromRawLabel(
          'Tomato___Spider_mites Two-spotted_spider_mite',
        ),
        'tomato_spider_mites_two-spotted_spider_mite',
      );
    });

    test('grape esca with parentheses', () {
      expect(
        adviceKeyFromRawLabel('Grape___Esca_(Black_Measles)'),
        'grape_esca_black_measles',
      );
    });

    test('apple scab uses plant prefix in key', () {
      expect(
        adviceKeyFromRawLabel('Apple___Apple_scab'),
        'apple_apple_scab',
      );
    });
  });

  group('LabelMapper display', () {
    test('low confidence uses cautious headline', () {
      final display = LabelMapper().map('Tomato___Late_blight', 0.35);
      expect(display.isLowConfidence, isTrue);
      expect(display.headline, contains('possible'));
      expect(display.plantName, 'Tomate');
    });

    test('healthy label', () {
      final display = LabelMapper().map('Tomato___healthy', 0.92);
      expect(display.isHealthy, isTrue);
      expect(display.diseaseName, isNull);
    });
  });

  group('LabelMapper advice keys', () {
    test('every disease label gets a non-generic advice key', () {
      final mapper = LabelMapper();
      for (final raw in labels) {
        if (raw.endsWith('___healthy')) continue;
        final display = mapper.map(raw, 0.9);
        expect(
          display.adviceKey,
          isNot('generic_disease'),
          reason: 'missing dedicated key for $raw',
        );
        expect(display.adviceKey, isNot('generic_healthy'));
      }
    });
  });
}
