import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/add_expense/add_expense_screen.dart';

/// Standard branded AppBar used across all screens in Lexspense.
/// Displays the Lexspense logo on the left and the quick "+ Add Expense" action on the right.
class LexspenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showAddButton;
  final List<Widget>? extraActions;

  const LexspenseAppBar({
    super.key,
    this.showAddButton = true,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      centerTitle: false,
      titleSpacing: canPop ? 0 : 16,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: SvgPicture.asset(
        isDark
            ? 'assets/images/logo_dark_mode.svg'
            : 'assets/images/logo_light_mode.svg',
        height: 24,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (showAddButton)
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Standard page title placed below the LexspenseAppBar at the top of the page body.
class PageHeaderTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
