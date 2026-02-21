/// Industrial Minimalism Design Tokens
///
/// Centralized design system for GitDoIt app.
///
/// Tokens include:
/// - Colors: Monochrome base + Signal Orange accent
/// - Typography: Inter + JetBrains Mono
/// - Spacing: 8px grid system
/// - Elevation: Z-axis spatial depth
/// - Animations: Spring physics
///
/// Usage:
/// ```dart
/// import 'package:gitdoit/design_tokens/tokens.dart';
///
/// // Access colors
/// final color = AppColors.signalOrange;
///
/// // Access typography
/// final style = AppTypography.headlineMedium;
///
/// // Access spacing
/// final padding = EdgeInsets.all(AppSpacing.md);
///
/// // Access elevation
/// final shadow = AppElevation.z2ShadowLight;
///
/// // Access animations
/// final spring = AppAnimations.buttonPressSpring;
/// ```
library design_tokens;

export 'colors.dart';
export 'typography.dart';
export 'spacing.dart';
export 'elevation.dart';
export 'animations.dart';
