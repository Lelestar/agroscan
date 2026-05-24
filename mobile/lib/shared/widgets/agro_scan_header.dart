import 'package:flutter/material.dart';

import 'agro_top_bar_style.dart';
import 'agroscan_logo.dart';

class AgroScanHeader extends StatelessWidget {
  const AgroScanHeader({
    super.key,
    this.trailing,
    this.showTitle = true,
  });

  final Widget? trailing;
  final bool showTitle;

  /// Same height as [AgroDetailAppBar] for consistent top chrome.
  static const double toolbarHeight = AgroTopBarStyle.height;

  /// Compact back control for stacked flows (result, child routes).
  static Widget trailingBack(
    BuildContext context, {
    VoidCallback? onPressed,
  }) {
    return AgroTopBarIconButton(
      icon: Icons.arrow_back,
      tooltip: 'Retour',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }

  /// Dismiss control for modal-style steps (e.g. analysis in progress).
  static Widget trailingClose(
    BuildContext context, {
    VoidCallback? onPressed,
  }) {
    return AgroTopBarIconButton(
      icon: Icons.close,
      tooltip: 'Fermer',
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AgroTopBarStyle.decoration,
      child: SizedBox(
        height: AgroTopBarStyle.height,
        child: Padding(
          padding: AgroTopBarStyle.horizontalPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AgroScanLogo(size: 28),
              if (showTitle) ...[
                const SizedBox(width: 8),
                Text(
                  'AgroScan',
                  style: AgroTopBarStyle.brandTitleStyle(context),
                ),
              ],
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
