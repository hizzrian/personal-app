import 'package:flutter/material.dart';

import '../../core/dependencies.dart';
import '../../core/result.dart';
import '../../models/job.dart';
import '../../models/note.dart';
import '../../utils/relative_time.dart';
import '../../widgets/group_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/large_title_bar.dart';
import '../jobs/job_editor_screen.dart';
import '../jobs/jobs_screen.dart';
import '../notes/note_editor_screen.dart';
import '../notes/notes_screen.dart';
import '../qr/qr_saved_tab.dart';
import '../../utils/app_spacing.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<_NotePreview> _recentNotes = const [];
  List<Job> _recentJobs = const [];
  int _totalNotes = 0;
  int _totalJobs = 0;
  int _activeJobs = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final noteRepo = context.notes;
    final jobRepo = context.jobs;

    // Issued together rather than serially — previously four awaited round
    // trips in sequence.
    final results = await Future.wait([
      noteRepo.recent(limit: 3),
      noteRepo.count(),
      jobRepo.recent(limit: 2),
      jobRepo.count(),
      jobRepo.all(),
    ]);
    if (!mounted) return;

    final recentNotes = results[0] as Result<List<Note>>;
    final noteCount = results[1] as Result<int>;
    final recentJobs = results[2] as Result<List<Job>>;
    final jobCount = results[3] as Result<int>;
    final allJobs = results[4] as Result<List<Job>>;

    setState(() {
      _recentNotes = [
        for (final note in recentNotes.valueOr(const []))
          _NotePreview.from(note),
      ];
      _totalNotes = noteCount.valueOr(0);
      _recentJobs = recentJobs.valueOr(const []);
      _totalJobs = jobCount.valueOr(0);
      _activeJobs = allJobs.valueOr(const []).where((j) => j.isActive).length;
    });
  }

  /// Reloads after returning from a pushed route, so the dashboard counters
  /// can't go stale while it sits alive inside the IndexedStack.
  Future<void> _pushThenReload(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            LargeTitleBar(
              title: 'Clarity',
              titleColor: colors.primary,
              expandedHeight: 120,
              expandedTitleScale: 1.6,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primaryContainer.withValues(alpha: 0.5),
                    ),
                    child: Icon(Icons.person_rounded,
                        color: colors.primary, size: 18),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, 0, AppSpacing.page, 40),
              sliver: SliverList.list(
                children: [
                  Text(
                    '${_greeting()}.',
                    style: theme.textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _summary(),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 28),
                  _sectionHeader(
                    'Recent Notes',
                    '$_totalNotes total',
                    () => _pushThenReload(const NotesScreen()),
                  ),
                  const SizedBox(height: 10),
                  _buildNotesGroup(),
                  const SizedBox(height: 24),
                  _sectionHeader(
                    'Applications',
                    '$_totalJobs total',
                    () => _pushThenReload(const JobsScreen()),
                  ),
                  const SizedBox(height: 10),
                  _buildJobsGroup(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _summary() {
    final parts = [
      if (_totalNotes > 0) '$_totalNotes notes',
      if (_activeJobs > 0) '$_activeJobs active applications',
    ];
    if (parts.isEmpty) {
      return 'Start by adding a note or tracking an application.';
    }
    return 'You have ${parts.join(' and ')}.';
  }

  Widget _sectionHeader(String title, String trailing, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(trailing,
                  style: theme.textTheme.labelMedium!
                      .copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_rounded,
          label: 'New Note',
          onTap: () => _pushThenReload(const NoteEditorScreen()),
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.work_outline_rounded,
          label: 'Add Job',
          onTap: () => _pushThenReload(const JobEditorScreen()),
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.qr_code_rounded,
          label: 'QR Codes',
          onTap: () => _pushThenReload(
            Scaffold(
              appBar: AppBar(title: const Text('Saved QR Codes')),
              body: const QrSavedTab(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesGroup() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_recentNotes.isEmpty) {
      return GroupCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No notes yet. Tap "New Note" to start.',
                style: theme.textTheme.bodySmall!
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }

    return GroupCard(
      children: [
        for (var i = 0; i < _recentNotes.length; i++) ...[
          _NoteTile(
            preview: _recentNotes[i],
            onTap: () => _pushThenReload(
              NoteEditorScreen(note: _recentNotes[i].note),
            ),
          ),
          if (i != _recentNotes.length - 1) const GroupDivider(),
        ],
      ],
    );
  }

  Widget _buildJobsGroup() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_recentJobs.isEmpty) {
      return GroupCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No applications yet. Tap "Add Job" to start.',
                style: theme.textTheme.bodySmall!
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }

    return GroupCard(
      children: [
        for (var i = 0; i < _recentJobs.length; i++) ...[
          _JobTile(
            job: _recentJobs[i],
            onTap: () => _pushThenReload(JobEditorScreen(job: _recentJobs[i])),
          ),
          if (i != _recentJobs.length - 1) const GroupDivider(indent: 36),
        ],
      ],
    );
  }
}

/// A note plus its plain-text preview, computed once at load.
class _NotePreview {
  const _NotePreview({required this.note, required this.preview});

  factory _NotePreview.from(Note note) =>
      _NotePreview(note: note, preview: note.previewText);

  final Note note;
  final String preview;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border:
                Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.preview, required this.onTap});

  final _NotePreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = preview.note;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isNotEmpty ? note.title : 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall!
                        .copyWith(color: colors.onSurface),
                  ),
                  if (preview.preview.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      preview.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              RelativeTime.short(note.updatedAt),
              style:
                  theme.textTheme.labelSmall!.copyWith(color: colors.outline),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.onTap});

  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = Color(job.status.colorValue);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall!
                        .copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.location.isEmpty
                        ? job.company
                        : '${job.company} · ${job.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium!
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            StatusBadge(status: job.status),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: colors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
