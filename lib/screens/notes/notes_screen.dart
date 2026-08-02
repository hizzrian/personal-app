import 'package:flutter/material.dart';

import '../../core/dependencies.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../models/note.dart';
import '../../utils/app_theme.dart';
import '../../utils/relative_time.dart';
import '../../widgets/error_view.dart';
import '../../widgets/group_card.dart';
import '../../widgets/large_title_bar.dart';
import '../../widgets/sliver_group_card.dart';
import 'note_editor_screen.dart';
import '../../utils/app_spacing.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  /// Notes with their plain-text preview computed once at load time, so the
  /// search filter and row builder never re-parse the Quill Delta.
  List<_NoteEntry> _entries = const [];
  List<_NoteEntry> _filtered = const [];
  String _query = '';
  bool _isLoading = true;
  Failure? _failure;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await context.notes.all();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case Ok(:final value):
          _failure = null;
          _entries = [for (final note in value) _NoteEntry.from(note)];
          _applyFilter();
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = _entries;
      return;
    }
    final q = _query.toLowerCase();
    _filtered = _entries.where((e) => e.matches(q)).toList();
  }

  Future<void> _delete(Note note) async {
    final result = await context.notes.delete(note.id);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      _showFailure(failure);
      return;
    }
    await _load();
  }

  Future<void> _togglePin(Note note) async {
    final result =
        await context.notes.setPinned(note.id, pinned: !note.isPinned);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      _showFailure(failure);
      return;
    }
    await _load();
  }

  Future<void> _openEditor({Note? note}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
    if (saved == true && mounted) await _load();
  }

  void _showFailure(Failure failure) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleBar(
            title: 'Notes',
            actions: [
              IconButton(
                onPressed: _openEditor,
                icon: Icon(Icons.add_circle_rounded,
                    color: colors.primary, size: 28),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, 0, AppSpacing.page, 12),
            sliver: SliverToBoxAdapter(child: _buildSearchField(colors)),
          ),
          ..._buildBody(),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colors) {
    return TextField(
      controller: _searchController,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: Icon(Icons.search, color: colors.outline, size: 20),
        suffixIcon: _query.isEmpty
            ? null
            : GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _applyFilter();
                  });
                },
                child:
                    Icon(Icons.close_rounded, color: colors.outline, size: 18),
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: (value) => setState(() {
        _query = value;
        _applyFilter();
      }),
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
            title: 'Could not load notes',
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

    if (_filtered.isEmpty) return [_buildEmpty()];

    final pinned = _filtered.where((e) => e.note.isPinned).toList();
    final rest = _filtered.where((e) => !e.note.isPinned).toList();

    return [
      if (pinned.isNotEmpty) ...[
        _buildLabel('Pinned'),
        _buildGroup(pinned),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
      if (rest.isNotEmpty) ...[
        if (pinned.isNotEmpty) _buildLabel('All Notes'),
        _buildGroup(rest),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  Widget _buildLabel(String text) {
    return SliverPadding(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 6),
      sliver: SliverToBoxAdapter(child: GroupLabel(text)),
    );
  }

  Widget _buildEmpty() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined,
                size: 40, color: colors.outlineVariant),
            const SizedBox(height: 10),
            Text(
              _query.isNotEmpty ? 'No results' : 'No notes yet',
              style: theme.textTheme.titleSmall!.copyWith(
                // The empty-state message reads as prose, not as a row title,
                // so it drops the slot's medium weight.
                fontWeight: FontWeight.w400,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(List<_NoteEntry> entries) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: SliverGroupCard(
        itemCount: entries.length,
        itemBuilder: (context, i) => _NoteRow(
          entry: entries[i],
          onTap: () => _openEditor(note: entries[i].note),
          onTogglePin: () => _togglePin(entries[i].note),
          onConfirmDelete: () => _confirmDelete(entries[i].note),
          onDeleted: () => _delete(entries[i].note),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete note?', style: Theme.of(ctx).textTheme.titleMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// A note plus its derived display fields, computed once per load.
class _NoteEntry {
  _NoteEntry({
    required this.note,
    required this.preview,
    required this.searchBlob,
  });

  factory _NoteEntry.from(Note note) {
    final preview = note.previewText;
    return _NoteEntry(
      note: note,
      preview: preview,
      searchBlob:
          '${note.title}\n$preview\n${note.tags.join(' ')}'.toLowerCase(),
    );
  }

  final Note note;
  final String preview;

  /// Pre-lowercased title + body + tags, so filtering is a single substring
  /// check instead of re-parsing the Delta on every keystroke.
  final String searchBlob;

  bool matches(String lowercaseQuery) => searchBlob.contains(lowercaseQuery);
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.entry,
    required this.onTap,
    required this.onTogglePin,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  final _NoteEntry entry;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = entry.note;

    return Dismissible(
      key: ValueKey(note.id),
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
        onLongPress: onTogglePin,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              if (note.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.push_pin_rounded,
                      size: 12, color: colors.primary),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: note.title.isNotEmpty
                            ? colors.onSurface
                            : colors.outline,
                      ),
                    ),
                    if (entry.preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                    if (note.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.tags.map((t) => '#$t').join('  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: colors.primary.withValues(alpha: 0.7),
                        ),
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
      ),
    );
  }
}
