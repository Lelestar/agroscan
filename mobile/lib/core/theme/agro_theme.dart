import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/agro_top_bar_style.dart';
import 'agro_colors.dart';

abstract final class AgroTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AgroColors.background,
      colorScheme: const ColorScheme.light(
        primary: AgroColors.primary,
        onPrimary: Colors.white,
        surface: AgroColors.surface,
        onSurface: AgroColors.textPrimary,
      ),
    );

    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AgroColors.textPrimary,
      displayColor: AgroColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        toolbarHeight: AgroTopBarStyle.height + AgroTopBarStyle.statusBarTopInset(),
        backgroundColor: AgroColors.surface,
        foregroundColor: AgroColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: AgroTopBarStyle.shadow.color,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: AgroColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}
