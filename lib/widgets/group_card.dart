import 'package:flutter/material.dart';

import '../utils/app_spacing.dart';

/// The iOS-style grouped inset container used by every list and settings
/// section. Replaces five hand-rolled copies of the same BoxDecoration.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.clip = true});

  /// Rows to stack. Dividers are the caller's responsibility so each screen
  /// can control indentation.
  final List<Widget> children;

  /// Clips children to the rounded corners. Disable when a child needs to
  /// paint outside the bounds (e.g. a Dismissible background).
  final bool clip;

  /// Kept as an alias so SliverGroupCard and its goldens have one number
  /// to agree on.
  static const radius = AppRadius.card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(children: children);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: clip
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: content,
            )
          : content,
    );
  }
}

/// Hairline separator between rows inside a [GroupCard].
class GroupDivider extends StatelessWidget {
  const GroupDivider({super.key, this.indent = 16});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(
        height: 0.5,
        color: colors.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Uppercase section label above a [GroupCard].
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.outline,
            letterSpacing: 0.5,
          ),
    );
  }
}
