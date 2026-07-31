import 'package:flutter/material.dart';

import 'group_card.dart';

/// Sliver twin of [GroupCard] for lists that can grow without bound.
///
/// [GroupCard] takes its children as a list, which forces every row to be built
/// before the first frame — 500 notes means 500 fully built rows regardless of
/// what the viewport shows. This builds rows on demand instead, so cost scales
/// with the screen rather than the data.
///
/// The rounded container is reproduced in two halves: [DecoratedSliver] paints
/// the fill, border and shadow across the whole sliver, while the first and
/// last rows clip their own outer corners so a row's own paint (a [Dismissible]
/// background, an ink splash) can't square them off. Prefer [GroupCard] for
/// short fixed sections — settings groups, stat headers — where laziness buys
/// nothing.
class SliverGroupCard extends StatelessWidget {
  const SliverGroupCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.dividerIndent = 16,
  });

  final int itemCount;

  /// Builds the row at [index]. The divider below it is added here, not by the
  /// caller, so that a row and its separator stay one sliver child.
  final IndexedWidgetBuilder itemBuilder;

  /// Left inset of the divider between rows, matching [GroupDivider].
  final double dividerIndent;

  /// Width of the card border. A bordered [BoxDecoration] on a Container insets
  /// its child by this much; [DecoratedSliver] only paints, so the inset has to
  /// be applied by hand or the border would overlap the first and last rows.
  static const _borderWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const corner = Radius.circular(GroupCard.radius);

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(GroupCard.radius),
        border: Border.all(
          width: _borderWidth,
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
      sliver: SliverPadding(
        padding: const EdgeInsets.all(_borderWidth),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final isFirst = index == 0;
              final isLast = index == itemCount - 1;

              Widget row = itemBuilder(context, index);

              // Only the end rows need clipping; skipping it elsewhere avoids
              // a no-op clip layer per row.
              if (isFirst || isLast) {
                row = ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? corner : Radius.zero,
                    topRight: isFirst ? corner : Radius.zero,
                    bottomLeft: isLast ? corner : Radius.zero,
                    bottomRight: isLast ? corner : Radius.zero,
                  ),
                  child: row,
                );
              }

              if (isLast) return row;

              // The divider stays outside the clip: it is a hairline on a
              // fractional offset, and antialiasing it against a clip layer
              // renders it differently from a plain sibling.
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [row, GroupDivider(indent: dividerIndent)],
              );
            },
            childCount: itemCount,
          ),
        ),
      ),
    );
  }
}
