import 'package:flutter/material.dart';

/// The yes/no dialog used before anything destructive.
///
/// Four screens each hand-rolled this same AlertDialog. Colours come from the
/// scheme rather than [AppTheme]'s light constants, which is what the inline
/// copies already did — an earlier version of this widget hardcoded the light
/// palette and would have rendered a white dialog in dark mode.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
  });

  final String title;

  /// Omitted where the title asks the whole question, as in "Delete note?".
  final String? message;

  final String confirmLabel;
  final String cancelLabel;

  /// Defaults to the scheme's error colour, since every current caller is
  /// confirming a deletion.
  final Color? confirmColor;

  /// Returns true only if the user confirmed. A dismissed dialog counts as no.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = message;

    return AlertDialog(
      title: Text(title, style: theme.textTheme.titleMedium),
      content: body == null
          ? null
          : Text(
              body,
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: colors.onSurfaceVariant),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: confirmColor ?? colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
