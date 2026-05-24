import 'package:flutter/material.dart';

abstract final class AgroColors {
  static const background = Color(0xFFFDFCF8);
  static const primary = Color(0xFF1B4332);
  static const primaryLight = Color(0xFFD8EAD8);
  static const surface = Color(0xFFFFFFFF);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFF2D1D1);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const scanLine = Color(0xFF4ADE80);
  static const heatmapCore = Color(0xFFE53935);
  static const heatmapMid = Color(0xFFFF9800);

  static const radiusCard = 16.0;
  static const radiusButton = 14.0;

  static const screenHorizontalPadding = 20.0;
  static const screenScrollTopPadding = 24.0;
  static const screenScrollBottomPadding = 24.0;

  /// Tab screens (home, history) and pushed scroll screens (result, advice, …).
  static const tabScrollHorizontalPadding = screenHorizontalPadding;
  static const tabScrollBottomPadding = screenScrollBottomPadding;

  static const EdgeInsets screenScrollPadding = EdgeInsets.fromLTRB(
    screenHorizontalPadding,
    screenScrollTopPadding,
    screenHorizontalPadding,
    screenScrollBottomPadding,
  );
}
