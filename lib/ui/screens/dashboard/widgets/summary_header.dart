import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';

class SummaryHeader extends StatelessWidget {
  final int totalPaise;
  final int count;
  final int selectedCount;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;

  const SummaryHeader({
    super.key,
    required this.totalPaise,
    required this.count,
    this.selectedCount = 0,
    this.onSelectAll,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121216) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C32) : const Color(0xFF1A1A1E);
    final textColor = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final mutedTextColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF666668);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isDark ? 1.0 : 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222226) : const Color(0xFFEEEEF2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: textColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TOTAL UNPAID EXPENSES',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilyBase,
                      color: mutedTextColor,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202026) : const Color(0xFFEEEEF2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? const Color(0xFF383840) : const Color(0xFFD0D0D8),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.unpaidBadge,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$count pending',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilyBase,
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹ ',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamilyBase,
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyUtils.formatPlain(totalPaise),
                style: AppTypography.figure(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? const Color(0xFF24242A) : const Color(0xFFE8E8EC),
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedCount > 0
                    ? '$selectedCount selected for payout'
                    : 'Tap checkboxes to batch claim',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamilyBase,
                  color: mutedTextColor,
                  fontSize: 12,
                  fontWeight: selectedCount > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (count > 0)
                TextButton(
                  onPressed: selectedCount == count ? onClearSelection : onSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                  child: Text(
                    selectedCount == count ? 'Clear' : 'Select All',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamilyBase,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
