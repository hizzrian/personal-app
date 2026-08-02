import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/dependencies.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../models/job.dart';
import '../../models/job_status.dart';
import '../../utils/app_theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/group_card.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/sliver_group_card.dart';
import 'job_editor_screen.dart';
import '../../utils/app_spacing.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  /// Null means "no status filter". Replaces a `'__all__'` sentinel that had
  /// to share a value space with the real statuses.
  JobStatus? _filter;

  List<Job> _jobs = const [];
  bool _isLoading = true;
  Failure? _failure;

  // Derived once per load / filter change rather than on every build.
  List<Job> _visible = const [];
  int _activeCount = 0;
  int _offerCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.jobs.all();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case Ok(:final value):
          _failure = null;
          _jobs = value;
          _activeCount = value.where((j) => j.isActive).length;
          _offerCount = value.where((j) => j.isOffer).length;
          _applyFilter();
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  void _applyFilter() {
    final filter = _filter;
    _visible = filter == null
        ? _jobs
        : _jobs.where((j) => j.status == filter).toList();
  }

  Future<void> _delete(Job job) async {
    final result = await context.jobs.delete(job.id);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    await _load();
  }

  Future<void> _openEditor({Job? job}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => JobEditorScreen(job: job)),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleBar(
            title: 'Applications',
            actions: [
              IconButton(
                onPressed: _openEditor,
                icon: Icon(Icons.add_circle_rounded,
                    color: colors.primary, size: 28),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_failure == null) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page, 0, AppSpacing.page, 12),
              sliver: SliverToBoxAdapter(child: _buildStats()),
            ),
            SliverToBoxAdapter(child: _buildFilters()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          ..._buildBody(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final colors = Theme.of(context).colorScheme;
    return GroupCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(
                  label: 'Total', value: _jobs.length, color: colors.onSurface),
              _StatDivider(),
              _Stat(
                  label: 'Active',
                  value: _activeCount,
                  color: AppTheme.primary),
              _StatDivider(),
              _Stat(
                  label: 'Offers', value: _offerCount, color: AppTheme.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          _filterPill(null, 'All'),
          for (final status in JobStatus.values)
            _filterPill(status, status.label),
        ],
      ),
    );
  }

  Widget _filterPill(JobStatus? status, String label) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _filter == status;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() {
          _filter = status;
          _applyFilter();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: isSelected
                ? null
                : Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? colors.surface : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }

    final failure = _failure;
    if (failure != null) {
      return [
        SliverFillRemaining(
          child: ErrorView(
            title: 'Could not load applications',
            failure: failure,
            onRetry: () {
              setState(() {
                _isLoading = true;
                _failure = null;
              });
              _load();
            },
          ),
        ),
      ];
    }

    if (_visible.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work_off_outlined,
                    size: 40, color: colors.outlineVariant),
                const SizedBox(height: 10),
                Text(
                  _filter == null
                      ? 'No applications yet'
                      : 'None with this status',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        // Prose, not a row title, so without the medium weight.
                        fontWeight: FontWeight.w400,
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        sliver: SliverGroupCard(
          itemCount: _visible.length,
          dividerIndent: 36,
          itemBuilder: (context, i) => _JobRow(
            job: _visible[i],
            onTap: () => _openEditor(job: _visible[i]),
            onConfirmDelete: _confirmDelete,
            onDeleted: () => _delete(_visible[i]),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove application?',
            style: Theme.of(ctx).textTheme.titleMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineSmall!.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: theme.textTheme.labelSmall!
                .copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 28,
      color: colors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  final Job job;
  final VoidCallback onTap;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  /// Static so it isn't reconstructed for every row on every rebuild.
  static final _dateFormat = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = Color(job.status.colorValue);

    return Dismissible(
      key: ValueKey(job.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: AppTheme.error.withValues(alpha: 0.1),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
          ),
        ),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDeleted(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium!
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: Text(
                  job.status.label,
                  style: theme.textTheme.labelSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: colors.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = [
      job.company,
      if (job.location.isNotEmpty) job.location,
      _dateFormat.format(job.appliedDate),
    ];
    return parts.join(' · ');
  }
}
