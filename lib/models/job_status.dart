/// The stage an application has reached.
///
/// Previously a bare `String` paired with three parallel maps for the label,
/// the colour and the terminal set. Every lookup then needed a fallback for a
/// value the maps might not contain, and nothing stopped a typo from reaching
/// the database. Here the three attributes travel with the value itself and
/// the compiler enforces exhaustiveness.
enum JobStatus {
  applied('Applied', 0xFF00D4FF),
  screening('Screening', 0xFFFBBF24),
  interview('Interview', 0xFFA78BFA),
  technical('Technical', 0xFFFF6B9D),
  offer('Offer', 0xFF4ADE80),
  accepted('Accepted', 0xFF22C55E),
  rejected('Rejected', 0xFFF87171),
  withdrawn('Withdrawn', 0xFF888888);

  const JobStatus(this.label, this.colorValue);

  /// Shown on chips and filter pills.
  final String label;

  /// ARGB value for the status dot and badge. Kept as an `int` so the model
  /// layer stays free of Flutter imports; call sites wrap it in a `Color`.
  final int colorValue;

  /// The value stored in the `status` column. It matches the old string form,
  /// so existing rows keep working without a migration.
  String get dbValue => name;

  /// A closed application, resolved either way.
  bool get isTerminal =>
      this == rejected || this == withdrawn || this == accepted;

  /// Reached an offer, whether or not it was taken.
  bool get isOffer => this == offer || this == accepted;

  /// Reads the stored form, falling back to [applied] for anything
  /// unrecognised. A hand-edited backup or a future status rolled back to an
  /// older build must not be able to crash a list screen.
  static JobStatus fromDb(String? raw) =>
      values.firstWhere((s) => s.name == raw, orElse: () => applied);
}
