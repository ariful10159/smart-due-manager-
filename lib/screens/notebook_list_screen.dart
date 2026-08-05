import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notebook.dart';
import '../models/notebook_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'notebook_screen.dart';

enum NotebookSortOption {
  recentlyUpdated,
  recentlyCreated,
  nameAZ,
  nameZA,
}

const List<int> kNotebookCoverColors = [
  0xFF6C5CE7,
  0xFF0984E3,
  0xFF00B894,
  0xFFE17055,
  0xFFD63031,
  0xFFE84393,
  0xFFFDCB6E,
  0xFF636E72,
];

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  final _repo = NotebookRepository();
  final _searchController = TextEditingController();

  String _query = '';
  NotebookSortOption _sort = NotebookSortOption.recentlyUpdated;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Notebook> _filterAndSort(List<Notebook> notebooks) {
    var result = notebooks.where((n) {
      if (_query.trim().isEmpty) return true;
      return n.title.toLowerCase().contains(_query.trim().toLowerCase());
    }).toList();

    switch (_sort) {
      case NotebookSortOption.recentlyUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NotebookSortOption.recentlyCreated:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NotebookSortOption.nameAZ:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NotebookSortOption.nameZA:
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return result;
  }

  Future<void> _createNotebook() async {
    final result = await _showNotebookEditor(context);
    if (result == null) return;

    final notebook = await _repo.createNotebook(
      title: result.title,
      description: result.description,
      coverColor: result.coverColor,
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotebookScreen(notebookId: notebook.id)),
    );
  }

  Future<void> _renameNotebook(Notebook notebook) async {
    final result = await _showNotebookEditor(context, initial: notebook);
    if (result == null) return;

    await _repo.updateNotebook(
      notebookId: notebook.id,
      title: result.title,
      description: result.description,
      coverColor: result.coverColor,
    );
  }

  Future<void> _duplicateNotebook(Notebook notebook) async {
    await _repo.duplicateNotebook(notebook);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${notebook.title}" duplicated')),
    );
  }

  Future<void> _deleteNotebook(Notebook notebook) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text("Delete Notebook", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          '"${notebook.title}" ও এর সব page স্থায়ীভাবে মুছে যাবে। আপনি কি নিশ্চিত?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: colors.due, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repo.deleteNotebook(notebook.id);
    }
  }

  void _showNotebookMenu(Notebook notebook) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
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
              leading: Icon(Icons.open_in_new_rounded, color: colors.accent),
              title: Text("Open", style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NotebookScreen(notebookId: notebook.id)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.accent),
              title: Text("Rename / Edit", style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _renameNotebook(notebook);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_all_outlined, color: colors.accent),
              title: Text("Duplicate", style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _duplicateNotebook(notebook);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: colors.due),
              title: Text("Delete", style: TextStyle(color: colors.due)),
              onTap: () {
                Navigator.pop(context);
                _deleteNotebook(notebook);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      drawer: const AppDrawer(currentRoute: 'notebooks'),
      appBar: AppBar(
        title: Text("Notebooks", style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          PopupMenuButton<NotebookSortOption>(
            onSelected: (value) => setState(() => _sort = value),
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.borderColor),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: NotebookSortOption.recentlyUpdated,
                child: Text("Recently Updated", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: NotebookSortOption.recentlyCreated,
                child: Text("Recently Created", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: NotebookSortOption.nameAZ,
                child: Text("Name A-Z", style: TextStyle(color: colors.textPrimary)),
              ),
              PopupMenuItem(
                value: NotebookSortOption.nameZA,
                child: Text("Name Z-A", style: TextStyle(color: colors.textPrimary)),
              ),
            ],
            icon: Icon(Icons.sort_rounded, color: colors.textPrimary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNotebook,
        backgroundColor: colors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("New Notebook"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: "Search notebooks...",
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Notebook>>(
              stream: _repo.streamNotebooks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: "নোটবুক লোড করা যায়নি",
                    subtitle: "${snapshot.error}",
                  );
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: colors.accent));
                }

                final notebooks = _filterAndSort(snapshot.data!);

                if (snapshot.data!.isEmpty) {
                  return _EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: "Create your first notebook",
                    subtitle: "Notebooks let you write, organize and format notes freely.",
                    actionLabel: "+ New Notebook",
                    onAction: _createNotebook,
                  );
                }

                if (notebooks.isEmpty) {
                  return _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: "No notebooks found",
                    subtitle: 'No results for "$_query"',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = notebooks[index];
                    return _NotebookCard(
                      notebook: notebook,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotebookScreen(notebookId: notebook.id),
                          ),
                        );
                      },
                      onLongPress: () => _showNotebookMenu(notebook),
                      onMenu: () => _showNotebookMenu(notebook),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookEditResult {
  final String title;
  final String description;
  final int coverColor;

  _NotebookEditResult(this.title, this.description, this.coverColor);
}

Future<_NotebookEditResult?> _showNotebookEditor(
  BuildContext context, {
  Notebook? initial,
}) async {
  final colors = AppColors.of(context);
  final titleController = TextEditingController(text: initial?.title ?? '');
  final descController = TextEditingController(text: initial?.description ?? '');
  int selectedColor = initial?.coverColor ?? kNotebookCoverColors.first;

  return showDialog<_NotebookEditResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.borderColor),
            ),
            title: Text(
              initial == null ? "New Notebook" : "Edit Notebook",
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Notebook name",
                      hintStyle: TextStyle(color: colors.textSecondary),
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Description (optional)",
                      hintStyle: TextStyle(color: colors.textSecondary),
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
                  const SizedBox(height: 14),
                  Text("Cover color", style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kNotebookCoverColors.map((c) {
                      final isSelected = c == selectedColor;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: colors.textPrimary, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  Navigator.pop(
                    dialogContext,
                    _NotebookEditResult(
                      titleController.text.trim(),
                      descController.text.trim(),
                      selectedColor,
                    ),
                  );
                },
                child: Text(
                  initial == null ? "Create" : "Save",
                  style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({
    required this.notebook,
    required this.onTap,
    required this.onLongPress,
    required this.onMenu,
  });

  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final coverColor = Color(notebook.coverColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.surface, colors.surfaceAlt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: coverColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: 8,
                      bottom: -6,
                      child: Icon(Icons.menu_book_rounded, color: Colors.white24, size: 46),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                        onPressed: onMenu,
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notebook.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary, fontSize: 13.5),
                    ),
                    if (notebook.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        notebook.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      "Updated ${DateFormat('d MMM').format(notebook.updatedAt)}",
                      style: TextStyle(color: colors.hintColor, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: colors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
