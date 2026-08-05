import 'package:flutter/material.dart';

import '../models/job_status.dart';
import '../utils/app_spacing.dart';

/// The tinted pill naming an application's stage, drawn identically by the
/// jobs list and the dashboard.
///
/// Takes the [JobStatus] rather than a label and a colour, so the two can no
/// longer disagree. The earlier version of this widget carried its own
/// geometry — a wider pill with a border — that neither screen used.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = Color(status.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}
