import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/agro_colors.dart';
import '../../domain/models/diagnosis_display.dart';
import 'agroscan_logo.dart';
import 'confidence_badge.dart';

/// Shared diagnosis row for home (compact) and history (accent + large %).
class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard({
    super.key,
    required this.imagePath,
    required this.display,
    required this.createdAt,
    required this.onTap,
    this.compact = false,
  });

  final String imagePath;
  final DiagnosisDisplay display;
  final DateTime createdAt;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusText = _statusLabel(display);
    final accentColor = _cardAccentColor(display);
    final dateLabel = formatDiagnosisDate(createdAt);
    final radius = BorderRadius.circular(AgroColors.radiusCard);

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          color: AgroColors.primaryLight,
          child: const Center(child: AgroScanLogo(size: 40)),
        ),
      ),
    );

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          Row(
            children: [
              Expanded(
                child: Text(
                  display.plantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              ConfidenceBadge(
                percent: display.confidencePercent,
                isHealthy: display.isHealthy,
                isUncertain: display.isLowConfidence,
              ),
            ],
          )
        else
          Text(
            display.plantName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AgroColors.textMuted,
              ),
        ),
      ],
    );

    final body = Row(
      children: [
        thumbnail,
        const SizedBox(width: 12),
        Expanded(child: textColumn),
        if (!compact) ...[
          const SizedBox(width: 8),
          _ProminentConfidence(display: display),
        ],
      ],
    );

    if (compact) {
      return Material(
        color: AgroColors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AgroColors.border),
            ),
            child: body,
          ),
        ),
      );
    }

    return Material(
      color: AgroColors.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AgroColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(color: accentColor, child: const SizedBox(width: 6)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProminentConfidence extends StatelessWidget {
  const _ProminentConfidence({required this.display});

  final DiagnosisDisplay display;

  @override
  Widget build(BuildContext context) {
    final accent = _cardAccentColor(display);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${display.confidencePercent}%',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const Text(
          'Confiance',
          style: TextStyle(
            fontSize: 11,
            color: AgroColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Stripe, status line, and prominent % — low confidence is always muted.
Color _cardAccentColor(DiagnosisDisplay display) {
  if (display.isLowConfidence) return AgroColors.textMuted;
  if (display.isHealthy) return AgroColors.success;
  return AgroColors.danger;
}

String _statusLabel(DiagnosisDisplay display) {
  if (display.isHealthy) return 'Plante saine';
  return display.diseaseName ?? 'Maladie suspectée';
}

/// Same relative date rules on home and history (today + time, yesterday, etc.).
String formatDiagnosisDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) {
    return "Aujourd'hui, ${DateFormat.Hm('fr').format(date)}";
  }
  if (diff.inDays == 1) {
    return 'Hier';
  }
  if (date.year != now.year) {
    return DateFormat('d MMM yyyy', 'fr').format(date);
  }
  return DateFormat('d MMM', 'fr').format(date);
}
