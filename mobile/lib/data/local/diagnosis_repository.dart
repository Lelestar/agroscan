import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:typed_data';

import '../../domain/models/diagnosis_display.dart';
import '../ml/grad_cam.dart';
import 'database.dart';

class DiagnosisRepository {
  static String heatmapPathFor(String id, String imagePath) =>
      p.join(p.dirname(imagePath), '${id}_heatmap.bin');

  Future<String> persistDiagnosis({
    required File sourceImage,
    required DiagnosisDisplay display,
    Float32List? heatmap,
  }) async {
    final db = await AppDatabase.instance();
    final id = const Uuid().v4();
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'diagnostics'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourceImage.path);
    final destPath = p.join(imagesDir.path, '$id$ext');
    await sourceImage.copy(destPath);

    await db.insert('diagnostics', {
      'id': id,
      'image_path': destPath,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'raw_label': display.rawLabel,
      'confidence': display.confidence,
      'display_json': jsonEncode(_displayToJson(display)),
    });

    if (heatmap != null) {
      await GradCamComputer.writeHeatmapFile(
        heatmapPathFor(id, destPath),
        heatmap,
      );
    }

    return id;
  }

  /// Overwrites an existing diagnostic (same id) — used when the user retries a scan.
  Future<String> replaceDiagnosis({
    required String id,
    required File sourceImage,
    required DiagnosisDisplay display,
    Float32List? heatmap,
  }) async {
    final existing = await getById(id);
    if (existing == null) {
      return persistDiagnosis(
        sourceImage: sourceImage,
        display: display,
        heatmap: heatmap,
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'diagnostics'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourceImage.path);
    final destPath = p.join(imagesDir.path, '$id$ext');

    final oldFile = File(existing.imagePath);
    if (existing.imagePath != destPath && await oldFile.exists()) {
      await oldFile.delete();
    }
    await sourceImage.copy(destPath);

    final db = await AppDatabase.instance();
    await db.update(
      'diagnostics',
      {
        'image_path': destPath,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'raw_label': display.rawLabel,
        'confidence': display.confidence,
        'display_json': jsonEncode(_displayToJson(display)),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (heatmap != null) {
      await GradCamComputer.writeHeatmapFile(
        heatmapPathFor(id, destPath),
        heatmap,
      );
    }

    return id;
  }

  Future<List<DiagnosisRecord>> listRecent({int limit = 5}) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'diagnostics',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToRecord).toList();
  }

  Future<List<DiagnosisRecord>> listAll() async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'diagnostics',
      orderBy: 'created_at DESC',
    );
    return rows.map(_rowToRecord).toList();
  }

  Future<DiagnosisRecord?> getById(String id) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'diagnostics',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToRecord(rows.first);
  }

  Future<void> deleteById(String id) async {
    final record = await getById(id);
    if (record == null) return;

    final imageFile = File(record.imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
    final heatmapFile = File(heatmapPathFor(id, record.imagePath));
    if (await heatmapFile.exists()) {
      await heatmapFile.delete();
    }

    final db = await AppDatabase.instance();
    await db.delete(
      'diagnostics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  DiagnosisRecord _rowToRecord(Map<String, Object?> row) {
    final displayMap =
        jsonDecode(row['display_json']! as String) as Map<String, dynamic>;
    return DiagnosisRecord(
      id: row['id']! as String,
      imagePath: row['image_path']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      display: _displayFromJson(displayMap),
    );
  }

  Map<String, dynamic> _displayToJson(DiagnosisDisplay d) => {
        'plantName': d.plantName,
        'diseaseName': d.diseaseName,
        'headline': d.headline,
        'isHealthy': d.isHealthy,
        'confidence': d.confidence,
        'adviceKey': d.adviceKey,
        'rawLabel': d.rawLabel,
        'topLabels': d.topLabels
            .map((p) => {
                  'label': p.label,
                  'displayName': p.displayName,
                  'score': p.score,
                })
            .toList(),
      };

  DiagnosisDisplay _displayFromJson(Map<String, dynamic> json) =>
      DiagnosisDisplay(
        plantName: json['plantName'] as String,
        diseaseName: json['diseaseName'] as String?,
        headline: json['headline'] as String,
        isHealthy: json['isHealthy'] as bool,
        confidence: (json['confidence'] as num).toDouble(),
        adviceKey: json['adviceKey'] as String,
        rawLabel: json['rawLabel'] as String,
        topLabels: ((json['topLabels'] as List<dynamic>?) ?? const [])
            .map(
              (item) => DiagnosisPrediction(
                label: (item as Map<String, dynamic>)['label'] as String,
                displayName:
                    item['displayName'] as String? ?? item['label'] as String,
                score: (item['score'] as num).toDouble(),
              ),
            )
            .toList(),
      );
}
