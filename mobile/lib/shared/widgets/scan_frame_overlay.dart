import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

/// Fixed duration for one top-to-bottom scan pass (constant speed every time).
/// Also the minimum analysis dwell before showing the result. Extra passes while
/// inference runs use the same duration — they do not accelerate.
const kAnalysisScanPassDuration = Duration(milliseconds: 1800);

class ScanFrameOverlay extends StatefulWidget {
  const ScanFrameOverlay({
    super.key,
    this.showScanLine = true,
    this.scanLineOnce = false,
    this.scanLineDuration = kAnalysisScanPassDuration,
    this.scanLineAnimation,
    this.borderColor = Colors.white,
  });

  final bool showScanLine;
  /// When true, the green line sweeps top → bottom once (analysis screen).
  final bool scanLineOnce;
  final Duration scanLineDuration;
  /// When set, the parent drives scan-line position (analysis screen).
  final Animation<double>? scanLineAnimation;
  final Color borderColor;

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncScanLineAnimation();
  }

  @override
  void didUpdateWidget(ScanFrameOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showScanLine != widget.showScanLine ||
        oldWidget.scanLineOnce != widget.scanLineOnce ||
        oldWidget.scanLineDuration != widget.scanLineDuration ||
        oldWidget.scanLineAnimation != widget.scanLineAnimation) {
      _syncScanLineAnimation(force: true);
    }
  }

  Animation<double>? get _scanAnimation =>
      widget.scanLineAnimation ?? _controller;

  void _syncScanLineAnimation({bool force = false}) {
    if (!widget.showScanLine || widget.scanLineAnimation != null) {
      _controller?.dispose();
      _controller = null;
      return;
    }

    if (_controller != null && !force) return;

    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scanLineDuration,
    );
    if (widget.scanLineOnce) {
      _controller!.forward();
    } else {
      _controller!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth * 0.75,
          constraints.maxHeight * 0.45,
        );
        return Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                CustomPaint(
                  size: size,
                  painter: _CornerPainter(color: widget.borderColor),
                ),
                if (widget.showScanLine && _scanAnimation != null)
                  AnimatedBuilder(
                    animation: _scanAnimation!,
                    builder: (context, child) {
                      return Positioned(
                        top: size.height * _scanAnimation!.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AgroColors.scanLine,
                            boxShadow: [
                              BoxShadow(
                                color: AgroColors.scanLine.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});

  final Color color;
  static const _len = 28.0;
  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset origin, bool top, bool left) {
      final dx = left ? 1.0 : -1.0;
      final dy = top ? 1.0 : -1.0;
      canvas.drawLine(origin, origin + Offset(_len * dx, 0), paint);
      canvas.drawLine(origin, origin + Offset(0, _len * dy), paint);
    }

    corner(const Offset(0, 0), true, true);
    corner(Offset(size.width, 0), true, false);
    corner(Offset(0, size.height), false, true);
    corner(Offset(size.width, size.height), false, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
