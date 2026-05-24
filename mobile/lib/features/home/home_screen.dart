import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/agro_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/scan_session_provider.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/widgets/agro_buttons.dart';
import '../../shared/widgets/agro_scan_header.dart';
import '../../shared/widgets/diagnostic_card.dart';
import '../../shared/widgets/offline_hint.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(homeDiagnosticsProvider);
    final scrollController = ref.watch(homeScrollControllerProvider);

    return Scaffold(
      backgroundColor: AgroColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgroScanHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: AgroColors.screenScrollPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Diagnostiquer une feuille',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AgroColors.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analysez la santé de vos cultures en quelques secondes, même sans connexion internet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AgroColors.textMuted,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 28),
                    AgroPrimaryButton(
                      label: 'Scanner une feuille',
                      icon: Icons.center_focus_weak_rounded,
                      onPressed: () => startCaptureFlow(
                        context,
                        ref,
                        DiagnosisResultOrigin.home,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AgroSecondaryButton(
                      label: 'Importer depuis la galerie',
                      icon: Icons.photo_outlined,
                      onPressed: () => startCaptureFlow(
                        context,
                        ref,
                        DiagnosisResultOrigin.home,
                        gallery: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const OfflineHint(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Derniers diagnostics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/history'),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    recentAsync.when(
                      data: (records) {
                        if (records.isEmpty) {
                          return _EmptyRecent();
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < records.length; i++) ...[
                              DiagnosticCard(
                                compact: true,
                                imagePath: records[i].imagePath,
                                display: records[i].display,
                                createdAt: records[i].createdAt,
                                onTap: () => openResultFromHome(
                                  context,
                                  ref,
                                  records[i].id,
                                ),
                              ),
                              if (i < records.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _EmptyRecent(),
                    ),
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

class _EmptyRecent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AgroColors.surface,
        borderRadius: BorderRadius.circular(AgroColors.radiusCard),
        border: Border.all(color: AgroColors.border),
      ),
      child: Text(
        'Aucun diagnostic pour le moment. Scannez une feuille pour commencer.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AgroColors.textMuted,
            ),
      ),
    );
  }
}
