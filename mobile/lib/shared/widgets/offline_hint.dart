import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

class OfflineHint extends StatelessWidget {
  const OfflineHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 16, color: AgroColors.textMuted),
        const SizedBox(width: 6),
        Text(
          'Analyse disponible hors connexion',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AgroColors.textMuted,
              ),
        ),
      ],
    );
  }
}
