import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';

class MarkPaidBottomSheet extends StatefulWidget {
  final int totalPaise;
  final int count;
  final DateTime minClaimDate;
  final Future<void> Function(String datePaid, String? notes) onConfirm;

  const MarkPaidBottomSheet({
    super.key,
    required this.totalPaise,
    required this.count,
    required this.minClaimDate,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = DateTime(
      widget.minClaimDate.year,
      widget.minClaimDate.month,
      widget.minClaimDate.day,
    );
    _selectedDate = today.isBefore(minDate) ? minDate : today;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final minDate = DateTime(
      widget.minClaimDate.year,
      widget.minClaimDate.month,
      widget.minClaimDate.day,
    );
    final maxDate = DateTime(now.year + 5, 12, 31);
    final initial = _selectedDate.isBefore(minDate) ? minDate : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final minDay = DateTime(
      widget.minClaimDate.year,
      widget.minClaimDate.month,
      widget.minClaimDate.day,
    );

    if (selectedDay.isBefore(minDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claim date cannot be earlier than expense date (${AppDateUtils.toDisplay(AppDateUtils.toDbString(widget.minClaimDate))})',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Reimbursement',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
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
              color: isDark ? const Color(0xFF121216) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF28282E) : const Color(0xFF1A1A1E),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payout Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹ ',
                      style: AppTypography.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(widget.totalPaise).replaceAll('₹', '').trim(),
                      style: AppTypography.figure(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date Paid Picker
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text('Settlement Date', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(AppDateUtils.toDisplay(AppDateUtils.toDbString(_selectedDate))),
            trailing: const Icon(Icons.calendar_today_rounded, size: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: theme.dividerColor, width: 0.8),
            ),
            onTap: _pickDate,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Cannot be earlier than expense date: ${AppDateUtils.toDisplay(AppDateUtils.toDbString(widget.minClaimDate))}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
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
