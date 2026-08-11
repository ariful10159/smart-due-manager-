import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/notebook.dart';
import '../models/notebook_page.dart';
import '../models/notebook_repository.dart';
import '../theme/app_colors.dart';

enum _SaveStatus { saved, saving, unsaved }

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key, required this.notebookId, this.initialPageId});

  final String notebookId;
  final String? initialPageId; // ✅ Global Search থেকে সরাসরি নির্দিষ্ট page এ নিয়ে যাওয়ার জন্য

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  final _repo = NotebookRepository();
  final _pageTitleController = TextEditingController();

  NotebookPage? _currentPage;
  QuillController? _quillController;
  Timer? _debounce;
  _SaveStatus _status = _SaveStatus.saved;

  @override
  void dispose() {
    _debounce?.cancel();
    _quillController?.removeListener(_onDocChanged);
    _quillController?.dispose();
    _pageTitleController.dispose();
    super.dispose();
  }

  void _selectPage(NotebookPage page) {
    if (_currentPage?.id == page.id) return;

    _debounce?.cancel();
    _quillController?.removeListener(_onDocChanged);
    _quillController?.dispose();

    Document document;
    try {
      document = Document.fromJson(jsonDecode(page.contentJson) as List);
    } catch (_) {
      document = Document();
    }

    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.addListener(_onDocChanged);

    setState(() {
      _currentPage = page;
      _quillController = controller;
      _pageTitleController.text = page.title;
      _status = _SaveStatus.saved;
    });
  }

  void _onDocChanged() {
    if (_status != _SaveStatus.unsaved) {
      setState(() => _status = _SaveStatus.unsaved);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _saveCurrentPage);
  }

  Future<void> _saveCurrentPage() async {
    final page = _currentPage;
    final controller = _quillController;
    if (page == null || controller == null) return;

    _debounce?.cancel();
    setState(() => _status = _SaveStatus.saving);

    try {
      final json = jsonEncode(controller.document.toDelta().toJson());
      await _repo.updatePageContent(
        notebookId: widget.notebookId,
        pageId: page.id,
        contentJson: json,
      );
      if (!mounted) return;
      setState(() => _status = _SaveStatus.saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _SaveStatus.unsaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveFailedLocalRetry)),
      );
    }
  }

  Future<void> _renamePageTitle(String title) async {
    final page = _currentPage;
    if (page == null) return;
    if (title.trim() == page.title) return;

    await _repo.renamePage(
      notebookId: widget.notebookId,
      pageId: page.id,
      title: title,
    );
    setState(() {
      _currentPage = NotebookPage(
        id: page.id,
        notebookId: page.notebookId,
        title: title.trim().isEmpty ? AppLocalizations.of(context)!.untitledPage : title.trim(),
        contentJson: page.contentJson,
        order: page.order,
        createdAt: page.createdAt,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> _createPage() async {
    final page = await _repo.createPage(
      notebookId: widget.notebookId,
      title: AppLocalizations.of(context)!.untitledPage,
    );
    _selectPage(page);
  }

  Future<void> _duplicatePage(NotebookPage page) async {
    await _repo.duplicatePage(notebookId: widget.notebookId, source: page);
  }

  Future<void> _deletePage(NotebookPage page, List<NotebookPage> allPages) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.deletePageTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(l10n.deletePageConfirmBody(page.title), style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAction, style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _repo.deletePage(notebookId: widget.notebookId, pageId: page.id);

    if (_currentPage?.id == page.id) {
      final remaining = allPages.where((p) => p.id != page.id).toList();
      if (remaining.isNotEmpty) {
        _selectPage(remaining.first);
      } else {
        setState(() {
          _currentPage = null;
          _quillController?.removeListener(_onDocChanged);
          _quillController?.dispose();
          _quillController = null;
        });
      }
    }
  }

  Future<void> _renamePageDialog(NotebookPage page) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: page.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(l10n.renamePageTitle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.trim().isEmpty) return;

    await _repo.renamePage(notebookId: widget.notebookId, pageId: page.id, title: newTitle);
    if (_currentPage?.id == page.id) {
      _pageTitleController.text = newTitle.trim();
      setState(() {
        _currentPage = NotebookPage(
          id: page.id,
          notebookId: page.notebookId,
          title: newTitle.trim(),
          contentJson: page.contentJson,
          order: page.order,
          createdAt: page.createdAt,
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  Future<String?> _pickAndUploadImage(BuildContext context) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: colors.accent),
              title: Text(l10n.chooseFromGallery, style: TextStyle(color: colors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: colors.accent),
              title: Text(l10n.takeAPhoto, style: TextStyle(color: colors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;

    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.uploadingImage), duration: const Duration(seconds: 1)),
    );

    try {
      final url = await _repo.uploadNotebookImage(
        notebookId: widget.notebookId,
        file: File(picked.path),
      );
      return url;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imageUploadFailed)),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      endDrawer: _PagesDrawer(
        notebookId: widget.notebookId,
        repo: _repo,
        currentPageId: _currentPage?.id,
        onSelectPage: (page) {
          Navigator.pop(context);
          _selectPage(page);
        },
        onCreatePage: _createPage,
        onRenamePage: _renamePageDialog,
        onDuplicatePage: _duplicatePage,
        onDeletePage: _deletePage,
      ),
      appBar: AppBar(
        title: StreamBuilder<List<Notebook>>(
          stream: _repo.streamNotebooks(),
          builder: (context, snapshot) {
            final notebook = snapshot.data?.where((n) => n.id == widget.notebookId).firstOrNull;
            return Text(
              notebook?.title ?? l10n.notebookFallbackTitle,
              style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.view_sidebar_outlined, color: colors.textPrimary),
              tooltip: l10n.pagesLabel,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotebookPage>>(
        stream: _repo.streamPages(widget.notebookId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.pageLoadFailed('${snapshot.error}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          final pages = snapshot.data!;

          if (pages.isEmpty) {
            return _EmptyPageState(onCreatePage: _createPage);
          }

          if (_currentPage == null) {
            final initialPage = widget.initialPageId == null
                ? null
                : pages.where((p) => p.id == widget.initialPageId).firstOrNull;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentPage == null) _selectPage(initialPage ?? pages.first);
            });
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          final controller = _quillController;
          if (controller == null) {
            return Center(child: CircularProgressIndicator(color: colors.accent));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pageTitleController,
                        onChanged: (value) {
                          _debounce?.cancel();
                          _debounce = Timer(const Duration(milliseconds: 700), () {
                            _renamePageTitle(value);
                          });
                        },
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: l10n.pageTitleHint,
                        ),
                      ),
                    ),
                    _SaveStatusChip(status: _status),
                  ],
                ),
              ),
              Divider(color: colors.borderColor, height: 1),
              QuillSimpleToolbar(
                controller: controller,
                config: QuillSimpleToolbarConfig(
                  showAlignmentButtons: true,
                  color: colors.surface,
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(
                    imageButtonOptions: QuillToolbarImageButtonOptions(
                      imageButtonConfig: QuillToolbarImageConfig(
                        onRequestPickImage: _pickAndUploadImage,
                      ),
                    ),
                    videoButtonOptions: null,
                  ),
                ),
              ),
              Divider(color: colors.borderColor, height: 1),
              Expanded(
                child: Container(
                  color: colors.scaffoldBg,
                  child: Shortcuts(
                    shortcuts: <LogicalKeySet, Intent>{
                      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
                          const _SaveIntent(),
                      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
                          const _SaveIntent(),
                    },
                    child: Actions(
                      actions: <Type, Action<Intent>>{
                        _SaveIntent: CallbackAction<_SaveIntent>(
                          onInvoke: (_) => _saveCurrentPage(),
                        ),
                      },
                      child: Focus(
                        autofocus: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: QuillEditor.basic(
                            controller: controller,
                            config: QuillEditorConfig(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                              placeholder: l10n.startWritingPlaceholder,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _SaveStatusChip extends StatelessWidget {
  const _SaveStatusChip({required this.status});

  final _SaveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (label, color) = switch (status) {
      _SaveStatus.saved => (l10n.savedStatus, colors.clear),
      _SaveStatus.saving => (l10n.savingStatus, colors.warn),
      _SaveStatus.unsaved => (l10n.unsavedStatus, colors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _EmptyPageState extends StatelessWidget {
  const _EmptyPageState({required this.onCreatePage});

  final VoidCallback onCreatePage;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_add_outlined, size: 40, color: colors.accent),
            const SizedBox(height: 12),
            Text(
              l10n.notebookEmptyTitle,
              style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.createFirstPageDesc,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreatePage,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.newPagePlus),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagesDrawer extends StatelessWidget {
  const _PagesDrawer({
    required this.notebookId,
    required this.repo,
    required this.currentPageId,
    required this.onSelectPage,
    required this.onCreatePage,
    required this.onRenamePage,
    required this.onDuplicatePage,
    required this.onDeletePage,
  });

  final String notebookId;
  final NotebookRepository repo;
  final String? currentPageId;
  final void Function(NotebookPage page) onSelectPage;
  final VoidCallback onCreatePage;
  final void Function(NotebookPage page) onRenamePage;
  final void Function(NotebookPage page) onDuplicatePage;
  final void Function(NotebookPage page, List<NotebookPage> allPages) onDeletePage;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: colors.scaffoldBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.view_sidebar_outlined, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pagesLabel,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: colors.accent),
                    tooltip: l10n.newPageTooltip,
                    onPressed: onCreatePage,
                  ),
                ],
              ),
            ),
            Divider(color: colors.borderColor, height: 1),
            Expanded(
              child: StreamBuilder<List<NotebookPage>>(
                stream: repo.streamPages(notebookId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: colors.accent));
                  }
                  final pages = snapshot.data!;

                  if (pages.isEmpty) {
                    return Center(
                      child: Text(l10n.noPagesYet, style: TextStyle(color: colors.textSecondary)),
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: pages.length,
                    onReorder: (oldIndex, newIndex) async {
                      final reordered = [...pages];
                      if (newIndex > oldIndex) newIndex -= 1;
                      final moved = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, moved);
                      await repo.reorderPages(notebookId: notebookId, orderedPages: reordered);
                    },
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final selected = page.id == currentPageId;

                      return ListTile(
                        key: ValueKey(page.id),
                        selected: selected,
                        selectedTileColor: colors.accent.withValues(alpha: 0.1),
                        leading: Icon(
                          Icons.description_outlined,
                          color: selected ? colors.accent : colors.textSecondary,
                        ),
                        title: Text(
                          page.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected ? colors.textPrimary : colors.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        onTap: () => onSelectPage(page),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textSecondary),
                          color: colors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: colors.borderColor),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                onRenamePage(page);
                                break;
                              case 'duplicate':
                                onDuplicatePage(page);
                                break;
                              case 'delete':
                                onDeletePage(page, pages);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'rename', child: Text(l10n.renameAction, style: TextStyle(color: colors.textPrimary))),
                            PopupMenuItem(value: 'duplicate', child: Text(l10n.duplicateAction, style: TextStyle(color: colors.textPrimary))),
                            PopupMenuItem(value: 'delete', child: Text(l10n.deleteAction, style: TextStyle(color: colors.due))),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
