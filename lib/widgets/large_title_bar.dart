import 'package:flutter/material.dart';

/// Collapsing large title, matching the iOS Settings/Notes pattern.
/// Replaces four hand-rolled SliverAppBar + FlexibleSpaceBar blocks.
class LargeTitleBar extends StatelessWidget {
  const LargeTitleBar({
    super.key,
    required this.title,
    this.titleColor,
    this.actions,
    this.expandedHeight = 100,
    this.expandedTitleScale = 1.5,
  });

  final String title;

  /// Defaults to onSurface; the dashboard uses the primary colour for branding.
  final Color? titleColor;
  final List<Widget>? actions;
  final double expandedHeight;
  final double expandedTitleScale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        expandedTitleScale: expandedTitleScale,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: titleColor ?? colors.onSurface,
              ),
        ),
      ),
      actions: actions,
    );
  }
}
