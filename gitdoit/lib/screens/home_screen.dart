import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/logger.dart';

/// Home Screen - Main dashboard after authentication
///
/// Shows list of GitHub issues as TODO items
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.username ?? 'User';

    Logger.d('Building HomeScreen for user: $username', context: 'Home');

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitDoIt'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Logger.d('Refresh pressed', context: 'Home');
              // TODO: Implement refresh
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Logger.d('Settings pressed', context: 'Home');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: const _HomeContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Logger.d('Create issue pressed', context: 'Home');
          // TODO: Navigate to create issue screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${authProvider.username ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your GitHub Issues as TODOs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // TODO: Issue list will go here
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: colorScheme.primary.withAlpha(128),
                ),
                const SizedBox(height: 16),
                Text(
                  'No issues loaded yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Issues will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Logger.d('Load issues pressed', context: 'Home');
                    // TODO: Implement load issues
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Issues'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
          _buildSectionTitle('Account'),
          const _SettingsTile(
            icon: Icons.person,
            title: 'GitHub Account',
            subtitle: 'Manage your GitHub connection',
          ),

          const Divider(height: 32),

          // Repository section
          _buildSectionTitle('Repository'),
          const _SettingsTile(
            icon: Icons.folder,
            title: 'Default Repository',
            subtitle: 'Select which repo to use for TODOs',
          ),

          const Divider(height: 32),

          // App section
          _buildSectionTitle('App'),
          const _SettingsTile(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light / Dark / System',
          ),
          const _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Configure issue notifications',
          ),

          const Divider(height: 32),

          // Danger zone
          _buildSectionTitle('Danger Zone', color: Colors.red),
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
              'GitDoIt v0.1.2-day3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color? color}) {
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

  const _SettingsTile({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to specific settings page
        Logger.d('Settings tapped: $title', context: 'Settings');
      },
    );
  }
}
