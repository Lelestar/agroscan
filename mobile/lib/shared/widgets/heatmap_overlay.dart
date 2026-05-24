import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Bump after changing raster logic to invalidate cached overlay images.
const heatmapRasterStyleVersion = 4;

/// Full-screen Grad-CAM overlay: yellow → orange → red colormap.
class HeatmapOverlay extends StatefulWidget {
  const HeatmapOverlay({super.key, required this.grid});

  final Float32List? grid;

  @override
  State<HeatmapOverlay> createState() => _HeatmapOverlayState();
}

class _HeatmapOverlayState extends State<HeatmapOverlay> {
  ui.Image? _image;
  int _buildGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scheduleBuild();
  }

  @override
  void didUpdateWidget(covariant HeatmapOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.grid, widget.grid)) {
      _scheduleBuild();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _scheduleBuild() {
    final grid = widget.grid;
    if (grid == null || grid.isEmpty) {
      _image?.dispose();
      setState(() => _image = null);
      return;
    }

    final generation = ++_buildGeneration;
    HeatmapRaster.toImage(grid).then((image) {
      if (!mounted || generation != _buildGeneration) {
        image.dispose();
        return;
      }
      final previous = _image;
      setState(() => _image = image);
      previous?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: _HeatmapImagePainter(image),
      size: Size.infinite,
    );
  }
}

class _HeatmapImagePainter extends CustomPainter {
  _HeatmapImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = _rectForCover(
      Size(image.width.toDouble(), image.height.toDouble()),
      size,
    );
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, src, dst, paint);
  }

  /// Same framing as [BoxFit.cover] for the photo underneath.
  static Rect _rectForCover(Size imageSize, Size canvasSize) {
    final scale = math.max(
      canvasSize.width / imageSize.width,
      canvasSize.height / imageSize.height,
    );
    final w = imageSize.width * scale;
    final h = imageSize.height * scale;
    return Rect.fromCenter(
      center: Offset(canvasSize.width / 2, canvasSize.height / 2),
      width: w,
      height: h,
    );
  }

  @override
  bool shouldRepaint(covariant _HeatmapImagePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// Converts a float grid in [0, 1] to an RGBA image for the overlay.
abstract final class HeatmapRaster {
  static const _size = AgroConstants.inputSize;
  static const _minVisible = 0.12;

  /// Max opacity for hot regions (screen blend).
  static const _maxAlpha = 0.55;

  static const _yellow = Color(0xFFFFEB3B);
  static const _orange = Color(0xFFFF9800);
  static const _red = Color(0xFFE53935);

  static Future<ui.Image> toImage(Float32List grid) async {
    if (grid.length != _size * _size) {
      throw StateError(
        'Heatmap grid size ${grid.length}, expected ${_size * _size}',
      );
    }

    final rgba = Uint8List(_size * _size * 4);
    for (var i = 0; i < _size * _size; i++) {
      final v = grid[i].clamp(0.0, 1.0);
      final o = i * 4;
      if (v < _minVisible) {
        rgba[o + 3] = 0;
        continue;
      }

      final t = ((v - _minVisible) / (1.0 - _minVisible)).clamp(0.0, 1.0);
      final color = _colorAt(t);
      final a = _alphaForPixel(t);
      final alphaByte = (a * 255).round().clamp(0, 255);
      rgba[o] = (color.r * 255).round().clamp(0, 255);
      rgba[o + 1] = (color.g * 255).round().clamp(0, 255);
      rgba[o + 2] = (color.b * 255).round().clamp(0, 255);
      rgba[o + 3] = alphaByte;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      _size,
      _size,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  static Color _colorAt(double t) {
    if (t < 0.5) {
      return Color.lerp(_yellow, _orange, t * 2)!;
    }
    return Color.lerp(_orange, _red, (t - 0.5) * 2)!;
  }

  /// Low intensity stays very transparent; red peaks are slightly stronger.
  static double _alphaForPixel(double t) {
    if (t < 0.45) {
      return math.pow(t / 0.45, 1.4) * 0.14;
    }
    return 0.14 + (t - 0.45) / 0.55 * (_maxAlpha - 0.14);
  }
}
