import 'package:flutter/material.dart';

/// The centred icon-and-message shown when a list has nothing in it.
///
/// Reproduces what Notes and Applications already drew inline. The earlier
/// version of this widget described a different, larger design that nothing
/// used — a 64px icon against the 40px the screens actually draw — so it was
/// brought to the app rather than the app to it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;

  /// A second, quieter line. Only the saved-QR list uses one.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final second = subtitle;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.outlineVariant),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall!.copyWith(
              // Prose, not a row title, so without the slot's medium weight.
              fontWeight: FontWeight.w400,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (second != null) ...[
            const SizedBox(height: 4),
            Text(
              second,
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.labelMedium!.copyWith(color: colors.outline),
            ),
          ],
        ],
      ),
    );
  }
}
