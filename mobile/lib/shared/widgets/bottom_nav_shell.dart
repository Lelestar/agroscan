import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/agro_colors.dart';
import '../../providers/app_providers.dart';

class BottomNavShell extends ConsumerWidget {
  const BottomNavShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(WidgetRef ref, int index) {
    final reselected = index == navigationShell.currentIndex;
    navigationShell.goBranch(
      index,
      initialLocation: reselected,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index == 0) {
        scrollTabToTop(ref.read(homeScrollControllerProvider));
      } else if (index == 2 && reselected) {
        scrollTabToTop(ref.read(historyScrollControllerProvider));
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AgroColors.surface,
          border: Border(top: BorderSide(color: AgroColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Accueil',
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(ref, 0),
                ),
                _NavItem(
                  icon: Icons.center_focus_weak_rounded,
                  label: 'Scanner',
                  selected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(ref, 1),
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'Historique',
                  selected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(ref, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AgroColors.primary : AgroColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AgroColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
