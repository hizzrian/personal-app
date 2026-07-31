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
  String _saveStatus = 'saved';
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
    if (_saveStatus != 'saving') setState(() => _saveStatus = 'saving');
    // Debounce: a single timer, restarted on each edit, cancelled on dispose.
    _saveStatusTimer?.cancel();
    _saveStatusTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _saveStatus = 'saved');
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
      setState(() { _tags.add(tag); _tagController.clear(); _hasChanges = true; });
    }
  }

  void _showAddTagDialog() {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name'),
          onSubmitted: (_) { _addTag(); Navigator.pop(ctx); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _addTag(); Navigator.pop(ctx); },
            child: const Text('Add', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    setState(() { _tags.remove(tag); _hasChanges = true; });
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
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: Text('Save before leaving?', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: const Text('Discard', style: TextStyle(color: AppTheme.error)),
              ),
              TextButton(
                onPressed: () { Navigator.pop(ctx); _saveNote(); },
                child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurfaceVariant),
                      onPressed: () {
                        if (_hasChanges) { _saveNote(); } else { Navigator.pop(context); }
                      },
                    ),
                    Text('Clarity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.primary)),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _saveStatus == 'saving' ? Icons.sync : Icons.cloud_done_outlined,
                          size: 14, color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _saveStatus == 'saving' ? 'Saving...' : 'Saved',
                          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _saveNote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    // Tags
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ..._tags.map((tag) => GestureDetector(
                          onLongPress: () => _removeTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tag, size: 12, color: colors.primary),
                                const SizedBox(width: 4),
                                Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary)),
                              ],
                            ),
                          ),
                        )),
                        GestureDetector(
                          onTap: _showAddTagDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Text('Add Tag', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colors.onSurface, letterSpacing: -0.5, height: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.2), fontSize: 26, fontWeight: FontWeight.w700),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        filled: false, contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 12),

                    // Rich text editor
                    QuillEditor(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      config: QuillEditorConfig(
                        scrollable: false,
                        expands: false,
                        autoFocus: false,
                        padding: EdgeInsets.zero,
                        placeholder: 'Start writing...',
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            TextStyle(fontSize: 16, height: 1.7, color: colors.onSurface.withValues(alpha: 0.85)),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(6, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          h1: DefaultTextBlockStyle(
                            TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.onSurface),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(16, 8),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          h2: DefaultTextBlockStyle(
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(12, 6),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          h3: DefaultTextBlockStyle(
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(8, 4),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                          bold: const TextStyle(fontWeight: FontWeight.w700),
                          italic: const TextStyle(fontStyle: FontStyle.italic),
                          placeHolder: DefaultTextBlockStyle(
                            TextStyle(fontSize: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
                            const HorizontalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            const VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quill Toolbar
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.2))),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuillSimpleToolbar(
                        controller: _quillController,
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
                      // Word count row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '$_wordCount words · $_readingTime read',
                              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
