import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';

class MarkPaidBottomSheet extends StatefulWidget {
  final int totalPaise;
  final int count;
  final Future<void> Function(String datePaid, String? notes) onConfirm;

  const MarkPaidBottomSheet({
    super.key,
    required this.totalPaise,
    required this.count,
    required this.onConfirm,
  });

  @override
  State<MarkPaidBottomSheet> createState() => _MarkPaidBottomSheetState();
}

class _MarkPaidBottomSheetState extends State<MarkPaidBottomSheet> {
  late DateTime _selectedDate;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dateStr = AppDateUtils.toDbString(_selectedDate);
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
      await widget.onConfirm(dateStr, notes);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as reimbursed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Reimbursement',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Settle ${widget.count} selected item(s)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232D24) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payout Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  CurrencyUtils.format(widget.totalPaise),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Paid Picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Settlement Date'),
            subtitle: Text(AppDateUtils.toDisplay(AppDateUtils.toDbString(_selectedDate))),
            trailing: const Icon(Icons.calendar_today_outlined),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: widget.count == 1
                  ? 'Notes / Reference (Optional)'
                  : 'Batch Notes / Reference (Optional)',
              hintText: 'Enter notes or transaction reference',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Mark Reimbursed (${CurrencyUtils.format(widget.totalPaise)})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
