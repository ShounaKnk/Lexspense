import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/court_forum.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/forum_provider.dart';

class ForumsScreen extends ConsumerStatefulWidget {
  const ForumsScreen({super.key});

  @override
  ConsumerState<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends ConsumerState<ForumsScreen> {
  String _filter = 'Active'; // 'Active', 'Archived', 'All'

  Future<void> _showForumDialog({CourtForum? existingForum}) async {
    final nameController = TextEditingController(text: existingForum?.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingForum == null ? 'New Court / Forum' : 'Edit Forum'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Forum Name *',
            hintText: 'Enter forum name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(existingForum == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final repo = ref.read(courtForumRepositoryProvider);
        if (existingForum == null) {
          final newForum = CourtForum(
            name: nameController.text.trim(),
          );
          await repo.insert(newForum);
        } else {
          final updated = existingForum.copyWith(
            name: nameController.text.trim(),
          );
          await repo.update(updated);
        }
        ref.invalidate(activeForumsProvider);
        ref.invalidate(allForumsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving forum: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleArchive(CourtForum forum) async {
    final repo = ref.read(courtForumRepositoryProvider);
    if (forum.status == 'Active') {
      await repo.archive(forum.id!);
    } else {
      await repo.unarchive(forum.id!);
    }
    ref.invalidate(activeForumsProvider);
    ref.invalidate(allForumsProvider);
  }

  Future<void> _deleteForum(CourtForum forum) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Forum?'),
        content: Text(
          'Delete "${forum.name}"? If client matters are linked to this forum, the forum reference will be removed from those matters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(courtForumRepositoryProvider).delete(forum.id!);
        ref.invalidate(activeForumsProvider);
        ref.invalidate(allForumsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Forum deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot delete forum: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allForumsAsync = ref.watch(allForumsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courts & Forums'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Active'),
                  selected: _filter == 'Active',
                  onSelected: (_) => setState(() => _filter = 'Active'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Archived'),
                  selected: _filter == 'Archived',
                  onSelected: (_) => setState(() => _filter = 'Archived'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'All',
                  onSelected: (_) => setState(() => _filter = 'All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: allForumsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading forums: $e')),
              data: (forums) {
                final filtered = forums.where((f) {
                  if (_filter == 'Active') return f.status == 'Active';
                  if (_filter == 'Archived') return f.status == 'Archived';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_filter.toLowerCase()} forums found.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isArchived = item.status == 'Archived';

                    return Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isArchived
                                ? theme.dividerColor.withOpacity(0.15)
                                : const Color(0xFF00897B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_rounded,
                            color: isArchived
                                ? theme.colorScheme.onSurfaceVariant
                                : const Color(0xFF00897B),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isArchived ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          isArchived ? 'Archived' : 'Active',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showForumDialog(existingForum: item);
                            } else if (action == 'archive') {
                              _toggleArchive(item);
                            } else if (action == 'delete') {
                              _deleteForum(item);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isArchived ? 'Activate' : 'Archive'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForumDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Forum'),
      ),
    );
  }
}
