/// Industrial Minimalism Atomic Widgets
///
/// Custom widget library implementing Industrial Minimalism design.
///
/// Widgets include:
/// - IndustrialButton: Primary, Secondary, Text, Destructive variants
/// - IndustrialCard: Data and Interactive cards with Z-axis depth
/// - IndustrialInput: Text inputs with focus illumination
/// - IndustrialBadge: Status badges and label chips
/// - IndustrialToggle: Physical switch simulation
/// - IndustrialSlider: Fader-style controls
///
/// Usage:
/// ```dart
/// import 'package:gitdoit/theme/widgets/widgets.dart';
///
/// IndustrialButton(
///   onPressed: () => print('Pressed!'),
///   label: 'Save',
///   variant: IndustrialButtonVariant.primary,
/// )
/// ```
library industrial_widgets;

export 'industrial_button.dart';
export 'industrial_card.dart';
export 'industrial_input.dart';
export 'industrial_badge.dart';
export 'industrial_toggle.dart';
export 'industrial_slider.dart';
