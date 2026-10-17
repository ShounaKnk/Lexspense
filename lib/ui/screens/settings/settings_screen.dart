import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../matters/matters_screen.dart';
import '../forums/forums_screen.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editProfile(BuildContext context, WidgetRef ref, LawyerProfile current) async {
    final nameController = TextEditingController(text: current.lawyerName);
    final firmController = TextEditingController(text: current.firmName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Counsel Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your Name / Designation',
                hintText: 'Enter lawyer name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: firmController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Chambers / Law Firm',
                hintText: 'Enter firm name',
              ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(settingsProvider.notifier).updateProfile(
        lawyerName: nameController.text.trim().isEmpty ? 'Advocate' : nameController.text.trim(),
        firmName: firmController.text.trim().isEmpty ? 'Chambers of Law' : firmController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          profileAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (profile) {
              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                        child: Icon(Icons.person, color: theme.colorScheme.primary, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.lawyerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.firmName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Printed on generated PDF vouchers',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Profile',
                        onPressed: () => _editProfile(context, ref, profile),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Section Header
          Text(
            'DATA & CATEGORIES',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.business_center_outlined),
                  title: const Text('Client Matters & Cases'),
                  subtitle: const Text('Manage case titles and forums'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MattersScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.1)),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('Courts & Forums'),
                  subtitle: const Text('Manage courts, tribunals, and forums'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForumsScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.1)),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Expense Categories'),
                  subtitle: const Text('Customize categories and icons'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy Card
          Text(
            'PRIVACY & SECURITY',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paidBadge.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.paidBadge.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: AppColors.paidBadge, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '100% Offline & Private',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.paidBadge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Zero network permissions in manifest\n'
                  '• All legal records stored in local SQLite database\n'
                  '• Receipt photos encrypted in app-private storage\n'
                  '• Never uploads client matters or financial data to cloud servers',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About section
          Center(
            child: Column(
              children: [
                Text(
                  'Lexspense v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open Source • MIT License',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
