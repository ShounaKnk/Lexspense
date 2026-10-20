import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/import_provider.dart';
import '../../widgets/dot_matrix_background.dart';
import '../../widgets/lexspense_app_bar.dart';
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

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    LawyerProfile profile,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 26,
              ),
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
                      letterSpacing: -0.2,
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
                      color: theme.colorScheme.onSurfaceVariant,
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildIconBadge(IconData icon) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFECECEF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFD6D6DC),
            width: 0.8,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 18,
        ),
      );
    }

    return Scaffold(
      appBar: const LexspenseAppBar(),
      body: DotMatrixBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PageHeaderTitle(
              title: 'Settings',
              subtitle: 'Counsel profile, data management & preferences',
            ),
            // Profile Card
            profileAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => _buildProfileCard(context, ref, theme, const LawyerProfile()),
              data: (profile) => _buildProfileCard(context, ref, theme, profile),
            ),
            const SizedBox(height: 20),

            // Section Header
            Text(
              'DATA & CATEGORIES',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: buildIconBadge(Icons.business_center_rounded),
                    title: const Text('Client Matters & Cases', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Manage case titles and forums'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MattersScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor),
                  ListTile(
                    leading: buildIconBadge(Icons.account_balance_rounded),
                    title: const Text('Courts & Forums', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Manage courts, tribunals, and forums'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForumsScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor),
                  ListTile(
                    leading: buildIconBadge(Icons.category_rounded),
                    title: const Text('Expense Categories', style: TextStyle(fontWeight: FontWeight.w600)),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: theme.dividerColor, width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: buildIconBadge(Icons.upload_file_rounded),
                    title: const Text('Import from Excel', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Upload expense records from spreadsheet (.xlsx)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showImportBottomSheet(context),
                  ),
                  Divider(height: 1, indent: 56, color: theme.dividerColor),
                  ListTile(
                    leading: buildIconBadge(Icons.download_rounded),
                    title: const Text('Download Sample Template', style: TextStyle(fontWeight: FontWeight.w600)),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121216) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF28282E) : const Color(0xFF1A1A1E),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '100% Offline & Private',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Zero network permissions in manifest\n'
                    '• All legal records stored in local SQLite database\n'
                    '• Receipt photos encrypted in app-private storage\n'
                    '• Never uploads client matters or financial data to cloud servers',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16161A) : const Color(0xFFF0F0F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF28282E) : const Color(0xFFDCDCE2),
                        width: 0.8,
                      ),
                    ),
                    child: SvgPicture.asset(
                      isDark
                          ? 'assets/images/icon_dark_mode.svg'
                          : 'assets/images/icon_light_mode.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lexspense v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Advocate Ledger • High-Contrast Legal Edition',
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
      ),
    );
  }
}
