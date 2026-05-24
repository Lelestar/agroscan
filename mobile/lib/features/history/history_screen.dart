import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/agro_colors.dart';
import '../../providers/app_providers.dart';
import '../../router/navigation_helpers.dart';
import '../../shared/diagnosis_delete.dart';
import '../../shared/widgets/agro_scan_header.dart';
import '../../shared/widgets/diagnostic_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(allDiagnosticsProvider);
    final scrollController = ref.watch(historyScrollControllerProvider);

    return Scaffold(
      backgroundColor: AgroColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AgroScanHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AgroColors.screenHorizontalPadding,
                AgroColors.screenScrollTopPadding,
                AgroColors.screenHorizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Historique',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            size: 14, color: AgroColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Stockage local',
                          style: TextStyle(
                            fontSize: 12,
                            color: AgroColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun diagnostic enregistré.',
                        style: TextStyle(color: AgroColors.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AgroColors.tabScrollHorizontalPadding,
                      0,
                      AgroColors.tabScrollHorizontalPadding,
                      AgroColors.tabScrollBottomPadding,
                    ),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final cardRadius =
                          BorderRadius.circular(AgroColors.radiusCard);
                      return ClipRRect(
                        borderRadius: cardRadius,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AgroColors.danger,
                                  borderRadius: cardRadius,
                                ),
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 24),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Dismissible(
                              key: ValueKey(record.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) =>
                                  confirmDeleteDiagnosis(context),
                              onDismissed: (_) async {
                                await deleteDiagnosisAndRefresh(
                                  ref,
                                  record.id,
                                );
                              },
                              background: const ColoredBox(
                                color: Colors.transparent,
                              ),
                              child: DiagnosticCard(
                                imagePath: record.imagePath,
                                display: record.display,
                                createdAt: record.createdAt,
                                onTap: () => openResultFromHistory(
                                  context,
                                  ref,
                                  record.id,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
