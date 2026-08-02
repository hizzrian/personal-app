/// Corner radii, named for the kind of surface rather than the number.
///
/// The same four or five values were typed out at forty call sites, so a
/// surface's shape was decided independently each time it was drawn. Naming
/// them by role means a change to, say, every chip is one edit instead of six.
abstract final class AppRadius {
  /// The grab handle at the top of a bottom sheet.
  static const grabber = 2.0;

  /// A status badge sitting inside a list row.
  static const badge = 6.0;

  /// Chips, filter pills, segmented toggles.
  static const control = 8.0;

  /// Surfaces that float above the page: snack bars, the scanner's overlays.
  static const floating = 10.0;

  /// Text fields and primary buttons.
  static const field = 12.0;

  /// Grouped list cards, and the alert dialogs that sit over them.
  static const card = 14.0;

  /// Full-width surfaces: sheets, themed dialogs, the floating action button.
  static const panel = 16.0;

  /// Tag pills and the scanner viewfinder.
  static const pill = 20.0;

  /// The scan frame's outer corners — the roundest surface in the app.
  static const frame = 24.0;
}

/// The two spacing values that carry a design decision rather than a nudge.
///
/// Deliberately not a full 4/8/12/16 scale. The gaps between elements here are
/// judged per layout and renaming `SizedBox(height: 10)` to `AppSpacing.sm`
/// would add a lookup without adding meaning — the same objection that makes
/// bare radii worth replacing. These two are different: they repeat across
/// screens and are expected to move together.
abstract final class AppSpacing {
  /// Horizontal margin from the screen edge to content. Every list, header and
  /// section aligns to it.
  static const page = 20.0;

  /// Inner padding of a list row or card, measured from the card's own edge.
  static const rowInset = 16.0;
}
