/// Settings Module Barrel Export
///
/// Centralized export file for all settings-related components.
/// Import this file to access all settings screens, dialogs, and widgets.
///
/// Usage:
/// ```dart
/// import 'package:gitdoit/screens/settings/settings.dart';
///
/// // Access screens
/// const AccountSettingsScreen()
/// const RepositorySettingsScreen()
/// const AppearanceSettingsScreen()
/// const DataSettingsScreen()
/// const DeveloperSettingsScreen()
///
/// // Access dialogs
/// RepositoryDialog.show(context, issuesProvider)
/// LoginDialog.show(context, auth)
/// ThemeDialog.show(context)
/// StorageDialog.show(context)
/// ClearDataDialog.show(context)
/// LogoutDialog.show(context)
///
/// // Access widgets
/// SettingsTile(...)
/// SettingsSectionHeader(...)
/// SettingsAppVersion(...)
///
/// // Access dialog factory
/// context.dialogs.showThemeDialog()
/// ```

// Screens
export 'account_settings_screen.dart';
export 'repository_settings_screen.dart';
export 'appearance_settings_screen.dart';
export 'data_settings_screen.dart';
export 'developer_settings_screen.dart';

// Dialogs
export 'dialogs/repository_dialog.dart';
export 'dialogs/login_dialog.dart';
export 'dialogs/theme_dialog.dart';
export 'dialogs/storage_dialog.dart';
export 'dialogs/clear_data_dialog.dart';
export 'dialogs/logout_dialog.dart';

// Widgets
export 'widgets/widgets.dart';
