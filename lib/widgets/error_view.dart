import 'package:flutter/material.dart';

import '../core/failure.dart';
import '../utils/app_theme.dart';

/// Shown when a load fails, so a failure can never present as an eternal
/// spinner or an empty list.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.failure,
    this.onRetry,
  });

  final String title;
  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding
        (padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.error),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
