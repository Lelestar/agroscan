import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/agro_colors.dart';
import '../../providers/scan_session_provider.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/widgets/agro_buttons.dart';
import '../../shared/widgets/agro_scan_header.dart';
import '../../shared/widgets/offline_hint.dart';

/// Scanner tab entry — opens the full-screen [/capture] route so the camera
/// is not kept alive while other tabs are visible.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AgroColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgroScanHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: AgroColors.screenScrollPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.center_focus_weak_rounded,
                      size: 72,
                      color: AgroColors.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Scanner une feuille',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AgroColors.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Photographiez une feuille pour lancer le diagnostic local.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AgroColors.textMuted,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 32),
                    AgroPrimaryButton(
                      label: 'Ouvrir la caméra',
                      icon: Icons.photo_camera_outlined,
                      onPressed: () => startCaptureFlow(
                        context,
                        ref,
                        DiagnosisResultOrigin.scanFlow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AgroSecondaryButton(
                      label: 'Importer depuis la galerie',
                      icon: Icons.photo_outlined,
                      onPressed: () => startCaptureFlow(
                        context,
                        ref,
                        DiagnosisResultOrigin.scanFlow,
                        gallery: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const OfflineHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
