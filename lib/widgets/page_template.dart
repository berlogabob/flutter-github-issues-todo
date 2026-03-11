import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// PageTemplate - Unified page template with safe zone for system bar
///
/// Provides consistent page structure across the app with:
/// - SafeArea wrapper for system bars (clock, battery, camera)
/// - Consistent AppBar styling
/// - Background gradient
/// - Optional bottom navigation
/// - Consistent spacing and padding
///
/// Usage:
/// ```dart
/// PageTemplate(
///   title: 'Dashboard',
///   body: MyContentWidget(),
///   actions: [IconButton(icon: Icon(Icons.search))],
///   showBottomNav: true,
///   bottomNavIndex: 0,
///   onBottomNavTap: (index) => _navigateTo(index),
/// )
/// ```
class PageTemplate extends StatelessWidget {
  /// Page title displayed in AppBar
  final String title;

  /// Main content of the page
  final Widget body;

  /// Optional actions for AppBar (right side)
  final List<Widget>? actions;

  /// Optional leading widget for AppBar (left side, defaults to back button)
  final Widget? leading;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Whether to show bottom navigation
  final bool showBottomNav;

  /// Current selected index for bottom navigation
  final int? bottomNavIndex;

  /// Callback when bottom nav item is tapped
  final Function(int)? onBottomNavTap;

  /// Bottom navigation items (defaults to standard GitDoIt nav)
  final List<BottomNavigationBarItem>? bottomNavItems;

  /// Whether to show back button in AppBar
  final bool showBackButton;

  /// Custom AppBar (overrides title, actions, leading if provided)
  final PreferredSizeWidget? appBar;

  /// Creates the page template
  const PageTemplate({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.showBottomNav = false,
    this.bottomNavIndex,
    this.onBottomNavTap,
    this.bottomNavItems,
    this.showBackButton = true,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: _buildBody(context),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (showBottomNav) {
      return Column(
        children: [
          Expanded(child: _buildContent(context)),
          _buildBottomNavigation(),
        ],
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    // If body is already a ScrollView, don't wrap in another
    if (body is ScrollView) {
      return body;
    }
    
    // Wrap in SingleChildScrollView for consistent scrolling
    return SingleChildScrollView(
      child: body,
    );
  }

  Widget _buildBottomNavigation() {
    final items = bottomNavItems ?? _getDefaultBottomNavItems();
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: bottomNavIndex ?? 0,
        onTap: onBottomNavTap,
        items: items,
      ),
    );
  }

  List<BottomNavigationBarItem> _getDefaultBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.view_kanban_outlined),
        activeIcon: Icon(Icons.view_kanban),
        label: 'Projects',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }

  /// Build custom AppBar with consistent styling
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: AppTypography.titleMedium,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading ?? (showBackButton ? null : null),
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }
}

/// Extension for convenient page template creation
extension PageTemplateExtension on Widget {
  /// Wrap any widget in PageTemplate
  PageTemplate withPageTemplate({
    required String title,
    List<Widget>? actions,
    bool showBottomNav = false,
    int? bottomNavIndex,
    Function(int)? onBottomNavTap,
  }) {
    return PageTemplate(
      title: title,
      body: this,
      actions: actions,
      showBottomNav: showBottomNav,
      bottomNavIndex: bottomNavIndex,
      onBottomNavTap: onBottomNavTap,
    );
  }
}
