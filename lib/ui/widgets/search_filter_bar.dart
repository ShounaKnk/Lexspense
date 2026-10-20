import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/client_matter.dart';

enum DateFilterOption {
  all,
  today,
  thisWeek,
  thisMonth,
  custom,
}

class DateFilterHelper {
  static String getLabel(DateFilterOption option, DateTimeRange? customRange) {
    switch (option) {
      case DateFilterOption.all:
        return 'All Dates';
      case DateFilterOption.today:
        return 'Today';
      case DateFilterOption.thisWeek:
        return 'This Week';
      case DateFilterOption.thisMonth:
        return 'This Month';
      case DateFilterOption.custom:
        if (customRange != null) {
          final start = AppDateUtils.toDisplay(AppDateUtils.toDbString(customRange.start));
          final end = AppDateUtils.toDisplay(AppDateUtils.toDbString(customRange.end));
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  static bool matchesDate(
    String dateStr,
    DateFilterOption option,
    DateTimeRange? customRange,
  ) {
    if (option == DateFilterOption.all) return true;

    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (option) {
      case DateFilterOption.all:
        return true;
      case DateFilterOption.today:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day);
        break;
      case DateFilterOption.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        end = DateTime(now.year, now.month, now.day);
        break;
      case DateFilterOption.thisMonth:
        start = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        end = DateTime(now.year, now.month, lastDay.day);
        break;
      case DateFilterOption.custom:
        if (customRange == null) return true;
        start = customRange.start;
        end = customRange.end;
        break;
    }

    final startStr = AppDateUtils.toDbString(start);
    final endStr = AppDateUtils.toDbString(end);

    return dateStr.compareTo(startStr) >= 0 && dateStr.compareTo(endStr) <= 0;
  }
}

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final String searchHint;
  final int? selectedMatterId;
  final String? selectedMatterTitle;
  final List<ClientMatter> matters;
  final ValueChanged<int?> onMatterChanged;
  final DateFilterOption selectedDateFilter;
  final DateTimeRange? customDateRange;
  final void Function(DateFilterOption option, DateTimeRange? customRange) onDateFilterChanged;
  final VoidCallback onClearAll;
  final String? activeFilterSummary;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    this.searchHint = 'Search records...',
    required this.selectedMatterId,
    this.selectedMatterTitle,
    required this.matters,
    required this.onMatterChanged,
    required this.selectedDateFilter,
    this.customDateRange,
    required this.onDateFilterChanged,
    required this.onClearAll,
    this.activeFilterSummary,
  });

  bool get hasActiveFilter =>
      searchQuery.trim().isNotEmpty ||
      selectedMatterId != null ||
      selectedDateFilter != DateFilterOption.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141418) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? const Color(0xFF28282E) : const Color(0xFFD6D6DC),
                width: 0.8,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: searchHint,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: onSearchCleared,
                        tooltip: 'Clear search',
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Case Pill
                _FilterPill(
                  icon: Icons.business_center_rounded,
                  label: selectedMatterId == null
                      ? 'Case: All'
                      : 'Case: ${selectedMatterTitle ?? '#$selectedMatterId'}',
                  isActive: selectedMatterId != null,
                  onTap: () => _showCasePicker(context),
                  onClear: selectedMatterId != null ? () => onMatterChanged(null) : null,
                ),
                const SizedBox(width: 8),

                // Date Pill
                _FilterPill(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date: ${DateFilterHelper.getLabel(selectedDateFilter, customDateRange)}',
                  isActive: selectedDateFilter != DateFilterOption.all,
                  onTap: () => _showDatePicker(context),
                  onClear: selectedDateFilter != DateFilterOption.all
                      ? () => onDateFilterChanged(DateFilterOption.all, null)
                      : null,
                ),

                // Clear All Button (appears when any filter is active)
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClearAll,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_off_rounded,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Optional Filter Summary Indicator
          if (activeFilterSummary != null && hasActiveFilter) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                activeFilterSummary!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCasePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _CasePickerSheet(
        matters: matters,
        selectedMatterId: selectedMatterId,
        onSelected: (id) {
          Navigator.of(ctx).pop();
          onMatterChanged(id);
        },
      ),
    );
  }

  void _showDatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _DatePickerSheet(
        currentOption: selectedDateFilter,
        customRange: customDateRange,
        onSelected: (option, customRange) {
          Navigator.of(ctx).pop();
          onDateFilterChanged(option, customRange);
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isActive
        ? (isDark ? const Color(0xFF25252C) : const Color(0xFFE4E4E8))
        : (isDark ? const Color(0xFF141418) : const Color(0xFFF6F6F8));

    final borderColor = isActive
        ? (isDark ? Colors.white70 : Colors.black87)
        : (isDark ? const Color(0xFF28282E) : const Color(0xFFD6D6DC));

    final textColor = isActive
        ? (isDark ? Colors.white : Colors.black)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isActive ? 1.0 : 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.close_rounded, size: 14, color: textColor),
                ),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _CasePickerSheet extends StatefulWidget {
  final List<ClientMatter> matters;
  final int? selectedMatterId;
  final ValueChanged<int?> onSelected;

  const _CasePickerSheet({
    required this.matters,
    required this.selectedMatterId,
    required this.onSelected,
  });

  @override
  State<_CasePickerSheet> createState() => _CasePickerSheetState();
}

class _CasePickerSheetState extends State<_CasePickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredMatters = widget.matters.where((m) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return m.caseTitle.toLowerCase().contains(q) ||
          (m.forum != null && m.forum!.toLowerCase().contains(q));
    }).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Client Matter / Case',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onSelected(null),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),

            // Search inside picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141418) : const Color(0xFFF6F6F8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.dividerColor, width: 0.8),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _filter = val),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: 'Search cases...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // List of cases
            Expanded(
              child: ListView(
                children: [
                  // All Cases Option
                  ListTile(
                    leading: const Icon(Icons.all_inclusive_rounded),
                    title: const Text('All Cases (No Filter)'),
                    trailing: widget.selectedMatterId == null
                        ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => widget.onSelected(null),
                  ),
                  const Divider(height: 1),

                  if (filteredMatters.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No cases match "$_filter"',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...filteredMatters.map((m) {
                      final isSelected = widget.selectedMatterId == m.id;
                      return ListTile(
                        leading: Icon(
                          Icons.business_center_rounded,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                        title: Text(
                          m.caseTitle,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: m.forum != null && m.forum!.isNotEmpty
                            ? Text(m.forum!)
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () => widget.onSelected(m.id),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerSheet extends StatelessWidget {
  final DateFilterOption currentOption;
  final DateTimeRange? customRange;
  final void Function(DateFilterOption option, DateTimeRange? customRange) onSelected;

  const _DatePickerSheet({
    required this.currentOption,
    this.customRange,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              'Filter by Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          _buildTile(
            context,
            title: 'All Dates',
            subtitle: 'Show all recorded expenses regardless of date',
            icon: Icons.all_inclusive_rounded,
            isSelected: currentOption == DateFilterOption.all,
            onTap: () => onSelected(DateFilterOption.all, null),
          ),
          _buildTile(
            context,
            title: 'Today',
            subtitle: 'Expenses logged for today',
            icon: Icons.today_rounded,
            isSelected: currentOption == DateFilterOption.today,
            onTap: () => onSelected(DateFilterOption.today, null),
          ),
          _buildTile(
            context,
            title: 'This Week',
            subtitle: 'Expenses logged this week (from Monday)',
            icon: Icons.date_range_rounded,
            isSelected: currentOption == DateFilterOption.thisWeek,
            onTap: () => onSelected(DateFilterOption.thisWeek, null),
          ),
          _buildTile(
            context,
            title: 'This Month',
            subtitle: 'Expenses for current calendar month',
            icon: Icons.calendar_month_rounded,
            isSelected: currentOption == DateFilterOption.thisMonth,
            onTap: () => onSelected(DateFilterOption.thisMonth, null),
          ),
          _buildTile(
            context,
            title: 'Custom Date Range...',
            subtitle: customRange != null
                ? DateFilterHelper.getLabel(DateFilterOption.custom, customRange)
                : 'Select specific start and end dates',
            icon: Icons.edit_calendar_rounded,
            isSelected: currentOption == DateFilterOption.custom,
            onTap: () async {
              Navigator.of(context).pop();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: customRange ??
                    DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    ),
              );
              if (picked != null) {
                onSelected(DateFilterOption.custom, picked);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
