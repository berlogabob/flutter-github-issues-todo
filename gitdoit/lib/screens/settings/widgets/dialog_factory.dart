import 'package:flutter/material.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/issues_provider.dart';

import '../dialogs/clear_data_dialog.dart';
import '../dialogs/login_dialog.dart';
import '../dialogs/logout_dialog.dart';
import '../dialogs/repository_dialog.dart';
import '../dialogs/storage_dialog.dart';
import '../dialogs/theme_dialog.dart';

/// Dialog Factory for Settings Screen
///
/// Centralized factory for creating and showing all settings-related dialogs.
/// This provides a single point of access for dialog operations and promotes
/// code reusability across the settings module.
///
/// Usage:
/// ```dart
/// final dialogFactory = DialogFactory(context);
/// await dialogFactory.showRepositoryDialog();
/// await dialogFactory.showLoginDialog();
/// ```
class DialogFactory {
  final BuildContext context;

  DialogFactory(this.context);

  /// Show repository configuration dialog
  Future<void> showRepositoryDialog(IssuesProvider issuesProvider) async {
    await RepositoryDialog.show(context, issuesProvider);
  }

  /// Show login dialog with OAuth and Token options
  Future<void> showLoginDialog(AuthProvider auth) async {
    await LoginDialog.show(context, auth);
  }

  /// Show theme selection dialog
  Future<void> showThemeDialog() async {
    await ThemeDialog.show(context);
  }

  /// Show storage statistics dialog
  Future<void> showStorageDialog() async {
    await StorageDialog.show(context);
  }

  /// Show clear cache/data dialog
  Future<void> showClearDataDialog() async {
    await ClearDataDialog.show(context);
  }

  /// Show logout confirmation dialog
  Future<void> showLogoutDialog() async {
    await LogoutDialog.show(context);
  }
}

/// Extension on BuildContext for easy dialog factory access
extension DialogFactoryExtension on BuildContext {
  DialogFactory get dialogs => DialogFactory(this);
}
