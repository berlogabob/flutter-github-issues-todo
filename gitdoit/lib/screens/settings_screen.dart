import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/issues_provider.dart';
import '../utils/logger.dart';

/// Settings Screen - App configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.d('Building SettingsScreen', context: 'Settings');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          _buildSectionTitle(context, 'Account'),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return _SettingsTile(
                icon: Icons.person,
                title: 'GitHub Account',
                subtitle: auth.username ?? 'Not logged in',
              );
            },
          ),

          const Divider(height: 32),

          // Repository section
          _buildSectionTitle(context, 'Repository'),
          Consumer<IssuesProvider>(
            builder: (context, issues, _) {
              return _SettingsTile(
                icon: Icons.folder,
                title: 'Default Repository',
                subtitle: 'Configure which repo to use',
                onTap: () => _showRepositoryDialog(context, issues),
              );
            },
          ),

          const Divider(height: 32),

          // App section
          _buildSectionTitle(context, 'App'),
          const _SettingsTile(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light / Dark / System',
          ),
          const _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Coming soon',
          ),
          const _SettingsTile(
            icon: Icons.storage,
            title: 'Offline Storage',
            subtitle: 'Manage cached data',
          ),

          const Divider(height: 32),

          // Data section
          _buildSectionTitle(context, 'Data'),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove locally stored issues',
            onTap: () => _showClearCacheDialog(context),
          ),

          const Divider(height: 32),

          // Danger zone
          _buildSectionTitle(context, 'Danger Zone', color: Colors.red),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Remove saved token'),
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'GitDoIt v0.1.3-day4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Built with ❤️ using Flutter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showRepositoryDialog(
    BuildContext context,
    IssuesProvider issuesProvider,
  ) {
    final ownerController = TextEditingController();
    final repoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Repository'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ownerController,
              decoration: const InputDecoration(
                labelText: 'Owner',
                hintText: 'e.g., berlogabob',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repoController,
              decoration: const InputDecoration(
                labelText: 'Repository',
                hintText: 'e.g., flutter-github-issues-todo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final owner = ownerController.text.trim();
              final repo = repoController.text.trim();

              if (owner.isEmpty || repo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in both fields')),
                );
                return;
              }

              Logger.i('Setting repository: $owner/$repo', context: 'Settings');
              issuesProvider.setRepository(owner, repo);
              Navigator.pop(context);

              // Load issues for the new repository
              issuesProvider.loadIssues();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Repository set to $owner/$repo')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all locally cached issues. They will be re-downloaded next time you refresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Logger.i('Clearing cache', context: 'Settings');
              // TODO: Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to enter your token again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Logger.i('User logged out', context: 'Settings');
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Reusable settings tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
