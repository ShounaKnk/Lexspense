import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/client_matter.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_view.dart';
import '../../../data/models/receipt_image.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/matter_provider.dart';
import '../../../providers/forum_provider.dart';
import 'widgets/amount_input.dart';
import 'widgets/category_picker.dart';
import 'widgets/matter_picker.dart';
import 'widgets/receipt_capture.dart';
import '../../widgets/dot_matrix_background.dart';
import '../../widgets/lexspense_app_bar.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final bool fromWidget;
  final ExpenseView? expenseToEdit;

  const AddExpenseScreen({
    super.key,
    this.fromWidget = false,
    this.expenseToEdit,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedMatterId;
  int? _selectedCategoryId;
  late DateTime _selectedDate;
  final List<File> _receiptImages = [];
  List<ReceiptImage> _existingReceipts = [];
  final List<ReceiptImage> _receiptsToDelete = [];
  bool _isSaving = false;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final exp = widget.expenseToEdit!.expense;
      final amount = exp.amountPaise / 100.0;
      _amountController.text = (amount == amount.toInt())
          ? amount.toInt().toString()
          : amount.toStringAsFixed(2);
      _selectedMatterId = exp.matterId;
      _selectedCategoryId = exp.categoryId;
      try {
        _selectedDate = AppDateUtils.fromDbString(exp.expenseDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
      _notesController.text = exp.notes ?? '';
      _loadExistingReceipts(exp.id!);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _loadExistingReceipts(int expenseId) async {
    try {
      final receipts = await ref.read(expenseRepositoryProvider).getReceiptsForExpense(expenseId);
      if (mounted) {
        setState(() {
          _existingReceipts = receipts;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showQuickAddMatterDialog() async {
    final titleController = TextEditingController();
    int? selectedForumId;

    final forums = await ref.read(activeForumsProvider.future);

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Client Matter'),
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
              child: const Text('Save Matter'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      try {
        final newMatter = ClientMatter(
          caseTitle: titleController.text.trim(),
          forumId: selectedForumId,
        );
        final newId = await ref.read(matterRepositoryProvider).insert(newMatter);
        ref.invalidate(activeMattersProvider);
        ref.invalidate(allMattersProvider);
        setState(() {
          _selectedMatterId = newId;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create matter: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveExpense() async {
    final paise = CurrencyUtils.parseToPaise(_amountController.text);
    if (paise == null || paise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category')),
      );
      return;
    }

    if (_selectedMatterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client matter / case')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final receiptStorage = ref.read(receiptStorageServiceProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);

      if (_isEditing) {
        final existingExpense = widget.expenseToEdit!.expense;

        // 1. Delete removed receipts
        for (final receipt in _receiptsToDelete) {
          await expenseRepo.deleteReceiptImage(receipt);
        }

        // 2. Add new receipts
        for (final imageFile in _receiptImages) {
          final fileName = await receiptStorage.saveReceipt(imageFile);
          await expenseRepo.addReceiptImage(existingExpense.id!, fileName);
        }

        // 3. Update expense row
        final updatedExpense = Expense(
          id: existingExpense.id,
          matterId: _selectedMatterId!,
          categoryId: _selectedCategoryId!,
          reimbursementId: existingExpense.reimbursementId,
          amountPaise: paise,
          expenseDate: AppDateUtils.toDbString(_selectedDate),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: existingExpense.createdAt,
        );

        await expenseRepo.updateExpense(updatedExpense);

        // 4. Invalidate providers
        ref.invalidate(unpaidExpensesProvider);
        ref.invalidate(singleExpenseProvider(existingExpense.id!));
        ref.invalidate(expenseReceiptsProvider(existingExpense.id!));
        await ref.read(widgetSyncServiceProvider).updateWidgetData();

        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense updated successfully!',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final receiptFileNames = <String>[];
        for (final imageFile in _receiptImages) {
          final fileName = await receiptStorage.saveReceipt(imageFile);
          receiptFileNames.add(fileName);
        }

        final expense = Expense(
          matterId: _selectedMatterId!,
          categoryId: _selectedCategoryId!,
          amountPaise: paise,
          expenseDate: AppDateUtils.toDbString(_selectedDate),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        await expenseRepo.insertExpense(
          expense,
          receiptFileNames: receiptFileNames,
        );

        ref.invalidate(unpaidExpensesProvider);
        await ref.read(widgetSyncServiceProvider).updateWidgetData();

        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logged ${CurrencyUtils.format(paise)} successfully!',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mattersAsync = ref.watch(activeMattersProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const LexspenseAppBar(showAddButton: false),
      body: DotMatrixBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeaderTitle(
                  title: _isEditing ? 'Edit Expense' : 'Log Expense',
                  subtitle: _isEditing
                      ? 'Update billable expenditure (#${widget.expenseToEdit!.expense.id})'
                      : 'Record billable case expenditure with receipt',
                ),
                // 1. Amount
                Text(
                  'AMOUNT SPENT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                AmountInput(controller: _amountController),
                const SizedBox(height: 24),

                // 2. Matter
                Text(
                  'CLIENT MATTER / CASE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                mattersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading matters: $e'),
                  data: (matters) => MatterPicker(
                    matters: matters,
                    selectedMatterId: _selectedMatterId,
                    onMatterSelected: (id) => setState(() => _selectedMatterId = id),
                    onQuickAddMatter: _showQuickAddMatterDialog,
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Category
                Text(
                  'EXPENSE CATEGORY',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading categories: $e'),
                  data: (categories) {
                    // Preselect first if not selected and not editing
                    if (!_isEditing && _selectedCategoryId == null && categories.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedCategoryId == null) {
                          setState(() => _selectedCategoryId = categories.first.id);
                        }
                      });
                    }
                    return CategoryPicker(
                      categories: categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: (id) => setState(() => _selectedCategoryId = id),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 4. Date
                Text(
                  'EXPENSE DATE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121216) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dividerColor, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text(
                          AppDateUtils.toDisplay(AppDateUtils.toDbString(_selectedDate)),
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Notes
                Text(
                  'NOTES & DESCRIPTION (OPTIONAL)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Enter description (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 24),

                // Existing Receipts (when editing)
                if (_isEditing && _existingReceipts.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT RECEIPTS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${_existingReceipts.length} attached',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingReceipts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final receipt = _existingReceipts[idx];
                        return FutureBuilder<File>(
                          future: ref.read(receiptStorageServiceProvider).getReceiptFile(receipt.fileName),
                          builder: (context, snapshot) {
                            return Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: theme.dividerColor, width: 0.8),
                                    color: isDark ? const Color(0xFF1E1E22) : Colors.grey.shade100,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: snapshot.hasData
                                      ? Image.file(snapshot.data!, fit: BoxFit.cover)
                                      : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _receiptsToDelete.add(receipt);
                                        _existingReceipts.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 6. Receipts
                ReceiptCapture(
                  receiptFiles: _receiptImages,
                  onImageAdded: (file) => setState(() => _receiptImages.add(file)),
                  onImageRemoved: (index) => setState(() => _receiptImages.removeAt(index)),
                ),
                const SizedBox(height: 36),

                // Save Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  icon: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(_isEditing ? Icons.check_circle_outline_rounded : Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Saving...' : (_isEditing ? 'Save Changes' : 'Save Expense'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
