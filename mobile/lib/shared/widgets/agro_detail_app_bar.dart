import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/agro_colors.dart';
import 'agro_top_bar_style.dart';

/// Top bar for [Scaffold.appBar]: status-bar inset + back + centered title.
class AgroDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AgroDetailAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => AgroTopBarStyle.preferredAppBarSize();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final trailing = actions == null || actions!.isEmpty
        ? const SizedBox(width: 40)
        : SizedBox(
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AgroColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: DecoratedBox(
        decoration: AgroTopBarStyle.decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topInset),
            SizedBox(
              height: AgroTopBarStyle.height,
              child: Padding(
                padding: AgroTopBarStyle.horizontalPadding,
                child: Row(
                  children: [
                    AgroTopBarIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Retour',
                      onPressed: onBack ?? () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AgroTopBarStyle.detailTitleStyle(context),
                      ),
                    ),
                    trailing,
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
