import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/import_provider.dart';
import '../matters/matters_screen.dart';
import '../forums/forums_screen.dart';
import 'category_management_screen.dart';
import 'widgets/import_bottom_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _downloadTemplate(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(importProvider.notifier).downloadTemplate();
    if (context.mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sample template saved to:\n$path'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 28),
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
                        icon: const Icon(Icons.edit_rounded),
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
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text('Client Matters & Cases'),
                  subtitle: const Text('Manage case titles and forums'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MattersScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.1)),
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF00897B),
                      size: 20,
                    ),
                  ),
                  title: const Text('Courts & Forums'),
                  subtitle: const Text('Manage courts, tribunals, and forums'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForumsScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.1)),
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E24AA).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Color(0xFF8E24AA),
                      size: 20,
                    ),
                  ),
                  title: const Text('Expense Categories'),
                  subtitle: const Text('Customize categories and icons'),
                  trailing: const Icon(Icons.chevron_right_rounded),
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

          // Import Section
          Text(
            'DATA IMPORT & SPREADSHEETS',
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
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                  title: const Text('Import from Excel'),
                  subtitle: const Text('Upload expense records from spreadsheet (.xlsx)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showImportBottomSheet(context),
                ),
                Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.1)),
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Color(0xFF0288D1),
                      size: 20,
                    ),
                  ),
                  title: const Text('Download Sample Template'),
                  subtitle: const Text('Get official Excel spreadsheet template'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () => _downloadTemplate(context, ref),
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
