import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

import '../../core/dependencies.dart';
import '../../core/result.dart';
import '../../models/note.dart';
import '../../utils/app_theme.dart';
import '../../utils/note_body.dart';
import 'save_indicator.dart';
import '../../utils/app_spacing.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _tagController;
  late QuillController _quillController;
  late List<String> _tags;
  bool _hasChanges = false;
  SaveIndicator _saveStatus = SaveIndicator.saved;
  Timer? _saveStatusTimer;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  // The Quill editor runs with scrollable: false inside the outer ListView, so
  // this controller is never driven — but QuillEditor requires an instance, and
  // reusing _scrollController would attach one controller to two scrollables.
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _tagController = TextEditingController();
    _tags = List.from(widget.note?.tags ?? []);

    // Note bodies may be Quill Delta JSON or legacy plain text.
    _quillController = QuillController(
      document: NoteBody.toDocument(widget.note?.body ?? ''),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _titleController.addListener(_onChanged);
    _quillController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
    if (_saveStatus != SaveIndicator.saving) {
      setState(() => _saveStatus = SaveIndicator.saving);
    }
    // Debounce: a single timer, restarted on each edit, cancelled on dispose.
    _saveStatusTimer?.cancel();
    _saveStatusTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _saveStatus = SaveIndicator.saved);
    });
  }

  @override
  void dispose() {
    _saveStatusTimer?.cancel();
    _titleController.dispose();
    _tagController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final bodyDelta = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    final now = DateTime.now();
    final existing = widget.note;
    final note = Note(
      id: existing?.id ?? const Uuid().v4(),
      title: title,
      body: bodyDelta,
      tags: _tags,
      color: existing?.color ?? 0,
      isPinned: existing?.isPinned ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = await context.notes.save(note);
    if (!mounted) return;

    if (result case Err(:final failure)) {
      // Deliberately does not pop: popping would discard the user's work.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    _saveStatusTimer?.cancel();
    Navigator.pop(context, true);
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase().replaceAll(' ', '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        _hasChanges = true;
      });
    }
  }

  void _showAddTagDialog() {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Tag', style: Theme.of(ctx).textTheme.titleMedium),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name'),
          onSubmitted: (_) {
            _addTag();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _addTag();
              Navigator.pop(ctx);
            },
            child: const Text('Add',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  int get _wordCount {
    final text = _quillController.document.toPlainText().trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  String get _readingTime {
    final mins = (_wordCount / 200).ceil();
    if (mins <= 0) return '< 1 min';
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmUnsavedChanges();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _EditorHeader(
                saveStatus: _saveStatus,
                onBack: () {
                  if (_hasChanges) {
                    _saveNote();
                  } else {
                    Navigator.pop(context);
                  }
                },
                onDone: _saveNote,
              ),
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page, 20, AppSpacing.page, 20),
                  children: [
                    _TagStrip(
                      tags: _tags,
                      onRemove: _removeTag,
                      onAdd: _showAddTagDialog,
                    ),
                    const SizedBox(height: 20),
                    _TitleField(controller: _titleController),
                    const SizedBox(height: 12),
                    _BodyEditor(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                    ),
                  ],
                ),
              ),
              _EditorFooter(
                controller: _quillController,
                wordCount: _wordCount,
                readingTime: _readingTime,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Offered when leaving with unsaved edits. Discard pops twice — once for the
  /// dialog, once for the editor — so the caller's blocked pop still happens.
  Future<void> _confirmUnsavedChanges() {
    final colors = Theme.of(context).colorScheme;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Unsaved changes', style: Theme.of(ctx).textTheme.titleMedium),
        content: Text('Save before leaving?',
            style: Theme.of(ctx)
                .textTheme
                .bodyMedium!
                .copyWith(color: colors.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Discard', style: TextStyle(color: AppTheme.error)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveNote();
            },
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Back button, wordmark, autosave indicator and the Done button.
class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.saveStatus,
    required this.onBack,
    required this.onDone,
  });

  final SaveIndicator saveStatus;
  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 18, color: colors.onSurfaceVariant),
            onPressed: onBack,
          ),
          Text('Clarity',
              style:
                  theme.textTheme.titleLarge!.copyWith(color: colors.primary)),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(saveStatus.icon, size: 14, color: muted),
              const SizedBox(width: 4),
              Text(saveStatus.label,
                  style: theme.textTheme.labelSmall!.copyWith(color: muted)),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.field)),
              child: Text('Done',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

/// The note's tags, plus the pill that opens the add-tag dialog. Long-pressing
/// a tag removes it.
class _TagStrip extends StatelessWidget {
  const _TagStrip({
    required this.tags,
    required this.onRemove,
    required this.onAdd,
  });

  final List<String> tags;
  final void Function(String tag) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          GestureDetector(
            onLongPress: () => onRemove(tag),
            child: _pill(
              context,
              icon: Icons.tag,
              iconColor: colors.primary,
              label: tag,
              labelStyle: theme.textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              fill: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderAlpha: 0.3,
            ),
          ),
        GestureDetector(
          onTap: onAdd,
          child: _pill(
            context,
            icon: Icons.add,
            iconColor: colors.onSurfaceVariant.withValues(alpha: 0.6),
            label: 'Add Tag',
            labelStyle: theme.textTheme.labelMedium!.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
            borderAlpha: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextStyle labelStyle,
    required double borderAlpha,
    Color? fill,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

/// Borderless title field that grows with its content.
class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.headlineLarge!;

    return TextField(
      controller: controller,
      style: style.copyWith(
        color: colors.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'Note Title',
        hintStyle: style.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
    );
  }
}

/// The rich-text body. Runs unscrollable inside the screen's ListView, so the
/// title and the body scroll as one.
class _BodyEditor extends StatelessWidget {
  const _BodyEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      controller: controller,
      focusNode: focusNode,
      scrollController: scrollController,
      config: QuillEditorConfig(
        scrollable: false,
        expands: false,
        autoFocus: false,
        padding: EdgeInsets.zero,
        placeholder: 'Start writing...',
        customStyles: _documentStyles(Theme.of(context).colorScheme),
      ),
    );
  }

  /// Document typography — how the note's own content reads, the way a word
  /// processor styles a page. Deliberately off the app type scale, which
  /// describes the UI around the note rather than the note itself.
  static DefaultStyles _documentStyles(ColorScheme colors) {
    DefaultTextBlockStyle block(
      TextStyle style, {
      VerticalSpacing spacing = const VerticalSpacing(0, 0),
    }) =>
        DefaultTextBlockStyle(
          style,
          const HorizontalSpacing(0, 0),
          spacing,
          const VerticalSpacing(0, 0),
          null,
        );

    return DefaultStyles(
      paragraph: block(
        TextStyle(
            fontSize: 16,
            height: 1.7,
            color: colors.onSurface.withValues(alpha: 0.85)),
        spacing: const VerticalSpacing(6, 0),
      ),
      h1: block(
        TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: colors.onSurface),
        spacing: const VerticalSpacing(16, 8),
      ),
      h2: block(
        TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface),
        spacing: const VerticalSpacing(12, 6),
      ),
      h3: block(
        TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface),
        spacing: const VerticalSpacing(8, 4),
      ),
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      placeHolder: block(
        TextStyle(
            fontSize: 16,
            color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// Formatting toolbar with the word count beneath it, pinned above the keyboard.
class _EditorFooter extends StatelessWidget {
  const _EditorFooter({
    required this.controller,
    required this.wordCount,
    required this.readingTime,
  });

  final QuillController controller;
  final int wordCount;
  final String readingTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
            top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuillSimpleToolbar(
              controller: controller,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: false,
                showListBullets: true,
                showListNumbers: true,
                showListCheck: true,
                showHeaderStyle: true,
                showLink: true,
                showCodeBlock: true,
                showQuote: true,
                showIndent: false,
                showAlignmentButtons: false,
                showFontFamily: false,
                showFontSize: false,
                showSearchButton: false,
                showInlineCode: true,
                showClearFormat: true,
                showDividers: true,
                showSmallButton: false,
                showSubscript: false,
                showSuperscript: false,
                toolbarSize: 40,
                multiRowsDisplay: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    '$wordCount words · $readingTime read',
                    style: theme.textTheme.labelSmall!.copyWith(
                        color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
