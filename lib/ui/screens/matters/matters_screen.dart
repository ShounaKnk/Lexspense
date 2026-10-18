import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/client_matter.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/matter_provider.dart';
import '../../../providers/forum_provider.dart';

class MattersScreen extends ConsumerStatefulWidget {
  const MattersScreen({super.key});

  @override
  ConsumerState<MattersScreen> createState() => _MattersScreenState();
}

class _MattersScreenState extends ConsumerState<MattersScreen> {
  String _filter = 'Active'; // 'Active', 'Archived', 'All'

  Future<void> _showMatterDialog({ClientMatter? existingMatter}) async {
    final titleController = TextEditingController(text: existingMatter?.caseTitle);
    int? selectedForumId = existingMatter?.forumId;

    final forums = await ref.read(activeForumsProvider.future);

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingMatter == null ? 'New Client Matter' : 'Edit Matter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Case Title / Client Name *',
                  hintText: 'Enter case title',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: selectedForumId,
                decoration: const InputDecoration(
                  labelText: 'Court / Forum (Optional)',
                  hintText: 'Select forum',
                  prefixIcon: Icon(Icons.account_balance_rounded, color: Color(0xFF00897B)),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...forums.map((f) => DropdownMenuItem<int?>(
                    value: f.id,
                    child: Text(f.name),
                  )),
                ],
                onChanged: (val) {
                  setDialogState(() => selectedForumId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(existingMatter == null ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      try {
        final repo = ref.read(matterRepositoryProvider);
        if (existingMatter == null) {
          final newMatter = ClientMatter(
            caseTitle: titleController.text.trim(),
            forumId: selectedForumId,
          );
          await repo.insert(newMatter);
        } else {
          final updated = existingMatter.copyWith(
            caseTitle: titleController.text.trim(),
            forumId: selectedForumId,
          );
          // If forum was cleared, use clearForum
          final toSave = selectedForumId == null
              ? updated.clearForum()
              : updated;
          await repo.update(toSave);
        }
        ref.invalidate(activeMattersProvider);
        ref.invalidate(allMattersProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving matter: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleArchive(ClientMatter matter) async {
    final repo = ref.read(matterRepositoryProvider);
    if (matter.status == 'Active') {
      await repo.archive(matter.id!);
    } else {
      await repo.unarchive(matter.id!);
    }
    ref.invalidate(activeMattersProvider);
    ref.invalidate(allMattersProvider);
  }

  Future<void> _deleteMatter(ClientMatter matter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Matter?'),
        content: Text(
          'Delete "${matter.caseTitle}"? If expenses are logged against this matter, deletion will be blocked to preserve legal records.',
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
        await ref.read(matterRepositoryProvider).delete(matter.id!);
        ref.invalidate(activeMattersProvider);
        ref.invalidate(allMattersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Matter deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot delete matter: Expenses are linked to it. Please archive it instead.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMattersAsync = ref.watch(allMattersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Matters & Cases'),
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
                  label: const Text('All Cases'),
                  selected: _filter == 'All',
                  onSelected: (_) => setState(() => _filter = 'All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: allMattersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading matters: $e')),
              data: (matters) {
                final filtered = matters.where((m) {
                  if (_filter == 'Active') return m.status == 'Active';
                  if (_filter == 'Archived') return m.status == 'Archived';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_filter.toLowerCase()} matters found.',
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
                                : theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.business_center_rounded,
                            color: isArchived
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.caseTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isArchived ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          item.forumName ?? 'No forum specified',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showMatterDialog(existingMatter: item);
                            } else if (action == 'archive') {
                              _toggleArchive(item);
                            } else if (action == 'delete') {
                              _deleteMatter(item);
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
                                  SizedBox(width: 8),
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
        onPressed: () => _showMatterDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Matter'),
      ),
    );
  }
}
