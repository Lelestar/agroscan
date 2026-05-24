import 'package:flutter/material.dart';

import '../../core/theme/agro_colors.dart';

class AgroPrimaryButton extends StatelessWidget {
  const AgroPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AgroColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AgroColors.radiusButton),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class AgroSecondaryButton extends StatelessWidget {
  const AgroSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AgroColors.primaryLight,
          foregroundColor: AgroColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AgroColors.radiusButton),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class AgroGhostButton extends StatelessWidget {
  const AgroGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AgroColors.textMuted,
          side: const BorderSide(color: AgroColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AgroColors.radiusButton),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
