import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({
    super.key,
    this.message = 'Diagnostic préliminaire à confirmer.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AgroColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AgroColors.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
