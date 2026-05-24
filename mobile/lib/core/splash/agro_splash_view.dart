import 'package:flutter/material.dart';

import '../../shared/widgets/agroscan_logo.dart';

/// Centered logo on white (visible even if the native splash stays dark).
class AgroSplashView extends StatelessWidget {
  const AgroSplashView({super.key});

  static const _background = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _background,
      child: Center(
        child: AgroScanLogo(size: 112),
      ),
    );
  }
}
