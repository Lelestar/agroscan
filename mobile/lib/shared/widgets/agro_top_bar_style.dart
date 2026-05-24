import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

/// Shared chrome for [AgroScanHeader] and [AgroDetailAppBar].
abstract final class AgroTopBarStyle {
  static const double height = 56;

  /// Status bar inset (battery, network…) for [Scaffold.appBar] bars.
  static double statusBarTopInset() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.implicitView ??
        (dispatcher.views.isNotEmpty ? dispatcher.views.first : null);
    if (view == null) return 0;
    return MediaQueryData.fromView(view).padding.top;
  }

  /// Toolbar + status bar — use as [PreferredSizeWidget.preferredSize].
  static Size preferredAppBarSize([double? topInset]) {
    final top = topInset ?? statusBarTopInset();
    return Size.fromHeight(height + top);
  }

  static const EdgeInsets horizontalPadding =
      EdgeInsets.symmetric(horizontal: 20);

  static const BoxShadow shadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxDecoration decoration = BoxDecoration(
    color: AgroColors.surface,
    border: Border(
      bottom: BorderSide(color: AgroColors.border),
    ),
    boxShadow: [shadow],
  );

  /// Logo row on tab screens (home, scanner, history).
  static TextStyle? brandTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AgroColors.textPrimary,
          height: 1.1,
        );
  }

  /// Centered title on pushed screens — slightly smaller than the brand lockup.
  static TextStyle? detailTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: AgroColors.textPrimary,
          height: 1.2,
        );
  }
}

/// Circular icon control used in all top bars (back, close, actions).
class AgroTopBarIconButton extends StatelessWidget {
  const AgroTopBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: onPressed != null ? 1 : 0.38,
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: AgroColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
