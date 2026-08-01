import 'package:flutter/material.dart';

/// The autosave state shown in the note editor's app bar.
///
/// Replaces a bare `String` compared against `'saving'` in three places, where
/// a typo would silently pick the wrong branch instead of failing to compile.
///
/// Only the two states the editor actually reaches are modelled. A save
/// failure raises a SnackBar and leaves the note open rather than changing
/// this indicator, so there is no error case to represent here yet.
enum SaveIndicator {
  saving('Saving...', Icons.sync),
  saved('Saved', Icons.cloud_done_outlined);

  const SaveIndicator(this.label, this.icon);

  final String label;
  final IconData icon;
}
