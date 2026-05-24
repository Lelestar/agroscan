import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.percent,
    required this.isHealthy,
    this.isUncertain = false,
  });

  final int percent;
  final bool isHealthy;
  /// Low confidence (healthy or diseased) — matches history stripe / result warning.
  final bool isUncertain;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isUncertain) {
      bg = const Color(0xFFF3F4F6);
      fg = AgroColors.textMuted;
    } else if (isHealthy) {
      bg = AgroColors.successLight;
      fg = AgroColors.success;
    } else {
      bg = AgroColors.dangerLight;
      fg = AgroColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
