import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/local_storage_service.dart';

/// Tutorial overlay for first-time users.
///
/// Provides a guided tour of the app's main features using tooltips.
/// Shows only on first launch and can be dismissed or skipped.
///
/// Tutorial steps:
/// 1. Welcome + app purpose
/// 2. Swipe gestures on issues
/// 3. FAB for new issue
/// 4. Sync cloud icon meaning
/// 5. Filter chips usage
///
/// Usage:
/// ```dart
/// TutorialOverlay.show(context);
/// ```
class TutorialOverlay {
  static final LocalStorageService _localStorage = LocalStorageService();
  static const String _tutorialCompletedKey = 'tutorial_completed';

  /// Shows the tutorial if not already completed.
  ///
  /// Returns true if tutorial was shown, false if already completed.
  static Future<bool> showIfNeeded(BuildContext context) async {
    final completed = await _localStorage.getBool(_tutorialCompletedKey) ?? false;
    if (completed) {
      return false;
    }

    await _showTutorial(context);
    return true;
  }

  /// Shows the full tutorial.
  static Future<void> _showTutorial(BuildContext context) async {
    final steps = _getTutorialSteps();
    int currentStep = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TutorialStepCard(
                      step: steps[currentStep],
                      currentStep: currentStep,
                      totalSteps: steps.length,
                      onNext: () {
                        HapticFeedback.lightImpact();
                        if (currentStep < steps.length - 1) {
                          setDialogState(() => currentStep++);
                        } else {
                          Navigator.pop(context);
                          _markCompleted();
                        }
                      },
                      onBack: () {
                        HapticFeedback.lightImpact();
                        if (currentStep > 0) {
                          setDialogState(() => currentStep--);
                        }
                      },
                      onSkip: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        _markCompleted();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static List<_TutorialStep> _getTutorialSteps() {
    return [
      _TutorialStep(
        icon: Icons.waving_hand,
        title: 'Welcome to GitDoIt!',
        description:
            'Your minimalist GitHub Issues & Projects manager with offline-first support. Manage your issues efficiently!',
      ),
      _TutorialStep(
        icon: Icons.swipe,
        title: 'Swipe Gestures',
        description:
            'Swipe right on an issue to pin it for quick access. Swipe left to delete (with confirmation).',
      ),
      _TutorialStep(
        icon: Icons.add_circle_outline,
        title: 'Create New Issue',
        description:
            'Tap the + button to create a new issue. Works offline and syncs when you\'re back online!',
      ),
      _TutorialStep(
        icon: Icons.cloud_sync,
        title: 'Sync Status',
        description:
            'The cloud icon shows sync status. Solid cloud = synced. Outline = pending sync. Red = conflicts.',
      ),
      _TutorialStep(
        icon: Icons.filter_list,
        title: 'Filter Issues',
        description:
            'Use filter chips to show open/closed issues, filter by label, or see only your assigned issues.',
      ),
    ];
  }

  static Future<void> _markCompleted() async {
    await _localStorage.setBool(_tutorialCompletedKey, true);
  }

  /// Resets the tutorial completion status.
  ///
  /// Call this from settings to allow users to replay the tutorial.
  static Future<void> reset(BuildContext context) async {
    await _localStorage.setBool(_tutorialCompletedKey, false);
    await _showTutorial(context);
  }

  /// Checks if tutorial has been completed.
  static Future<bool> isCompleted() async {
    return await _localStorage.getBool(_tutorialCompletedKey) ?? false;
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _TutorialStepCard extends StatelessWidget {
  final _TutorialStep step;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _TutorialStepCard({
    required this.step,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalSteps,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= currentStep
                      ? AppColors.orangeSecondary
                      : AppColors.borderColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orangeSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 48,
              color: AppColors.orangeSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            step.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentStep > 0)
                TextButton(
                  onPressed: onBack,
                  child: Text(
                    'BACK',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'SKIP',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  currentStep < totalSteps - 1 ? 'NEXT' : 'GOT IT',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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

/// Widget for displaying a tutorial tooltip overlay.
///
/// This is a simple tooltip that can be used for contextual help.
class TutorialTooltip extends StatelessWidget {
  /// Title text for the tooltip.
  final String title;

  /// Description text for the tooltip.
  final String description;

  /// Icon to display in the tooltip.
  final IconData icon;

  /// Callback when user dismisses the tooltip.
  final VoidCallback? onDismiss;

  /// Creates a tutorial tooltip.
  ///
  /// [title] is the main heading (required).
  /// [description] is the explanatory text (required).
  /// [icon] is the icon to display (required).
  /// [onDismiss] callback when tooltip is dismissed.
  const TutorialTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.orangeSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onDismiss ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'GOT IT',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manager for tutorial state and preferences.
class TutorialManager {
  static final LocalStorageService _localStorage = LocalStorageService();
  static const String _prefix = 'tutorial_';

  /// Marks a specific tutorial step as seen.
  static Future<void> markStepSeen(String stepId) async {
    await _localStorage.setBool('$_prefix$stepId', true);
  }

  /// Checks if a specific tutorial step has been seen.
  static Future<bool> isStepSeen(String stepId) async {
    return await _localStorage.getBool('$_prefix$stepId') ?? false;
  }

  /// Resets all tutorial steps.
  static Future<void> resetAll() async {
    // Reset the main tutorial completed flag
    await _localStorage.setBool('${_prefix}completed', false);
  }

  /// Checks if the main tutorial has been completed.
  static Future<bool> isTutorialCompleted() async {
    return await _localStorage.getBool('${_prefix}completed') ?? false;
  }

  /// Marks the main tutorial as completed.
  static Future<void> markTutorialCompleted() async {
    await _localStorage.setBool('${_prefix}completed', true);
  }
}
