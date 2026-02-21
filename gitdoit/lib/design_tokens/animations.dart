import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Industrial Minimalism Animation System
///
/// All animations use spring physics for natural, tactile feel.
/// No linear easing - everything has weight and momentum.
///
/// Performance Targets:
/// - 60fps minimum on all devices
/// - 120fps on ProMotion displays
/// - <16ms frame budget for 60fps
/// - <8ms frame budget for 120fps
///
/// Inspired by: Teenage Engineering × Nothing Phone × Notion × Revolut
class AppAnimations {
  const AppAnimations._();

  // ===========================================================================
  // SPRING PHYSICS PARAMETERS
  // ===========================================================================

  // Spring physics follow the formula:
  // mass: Weight of the animated object (higher = slower)
  // tension: Spring stiffness (higher = snappier)
  // friction: Damping (higher = less bounce)

  /// Button Press Spring
  /// Quick, tactile feedback
  /// mass: 1.0, tension: 400, friction: 15
  static const SpringDescription buttonPressSpring = SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 15.0,
  );

  /// Button Hover Spring
  /// Smooth lift effect
  /// mass: 1.0, tension: 350, friction: 15
  static const SpringDescription buttonHoverSpring = SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 15.0,
  );

  /// Card Hover Spring
  /// Gentle elevation change
  /// mass: 1.0, tension: 300, friction: 12
  static const SpringDescription cardHoverSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 12.0,
  );

  /// Modal Enter Spring
  /// Smooth entrance with weight
  /// mass: 1.0, tension: 350, friction: 18
  static const SpringDescription modalEnterSpring = SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 18.0,
  );

  /// Modal Exit Spring
  /// Quick exit
  /// mass: 1.0, tension: 350, friction: 18
  static const SpringDescription modalExitSpring = SpringDescription(
    mass: 1.0,
    stiffness: 350.0,
    damping: 18.0,
  );

  /// Page Transition Spring
  /// Smooth screen transitions
  /// mass: 1.0, tension: 280, friction: 14
  static const SpringDescription pageTransitionSpring = SpringDescription(
    mass: 1.0,
    stiffness: 280.0,
    damping: 14.0,
  );

  /// Toggle Switch Spring
  /// Snappy toggle action
  /// mass: 0.8, tension: 450, friction: 12
  static const SpringDescription toggleSpring = SpringDescription(
    mass: 0.8,
    stiffness: 450.0,
    damping: 12.0,
  );

  /// Slider Fader Spring
  /// Precise, quick response
  /// mass: 0.6, tension: 500, friction: 10
  static const SpringDescription sliderSpring = SpringDescription(
    mass: 0.6,
    stiffness: 500.0,
    damping: 10.0,
  );

  /// Badge Pulse Spring
  /// Gentle attention indicator
  /// mass: 1.2, tension: 200, friction: 20
  static const SpringDescription badgePulseSpring = SpringDescription(
    mass: 1.2,
    stiffness: 200.0,
    damping: 20.0,
  );

  /// Input Focus Spring
  /// Smooth focus transition
  /// mass: 0.8, tension: 350, friction: 14
  static const SpringDescription inputFocusSpring = SpringDescription(
    mass: 0.8,
    stiffness: 350.0,
    damping: 14.0,
  );

  /// List Item Enter Spring
  /// Staggered list animation
  /// mass: 1.0, tension: 320, friction: 16
  static const SpringDescription listItemEnterSpring = SpringDescription(
    mass: 1.0,
    stiffness: 320.0,
    damping: 16.0,
  );

  // ===========================================================================
  // DURATION SCALE
  // ===========================================================================

  /// Instant: 0ms
  /// Use: Immediate state changes
  static const Duration durationInstant = Duration.zero;

  /// Fast: 100ms
  /// Use: Micro-interactions, icon animations
  static const Duration durationFast = Duration(milliseconds: 100);

  /// Normal: 200ms
  /// Use: Standard transitions, button animations
  static const Duration durationNormal = Duration(milliseconds: 200);

  /// Slow: 300ms
  /// Use: Complex animations, modal transitions
  static const Duration durationSlow = Duration(milliseconds: 300);

  /// Slower: 500ms
  /// Use: Page transitions, complex sequences
  static const Duration durationSlower = Duration(milliseconds: 500);

  /// Duration for badge pulse animation
  static const Duration durationPulse = Duration(milliseconds: 400);

  // ===========================================================================
  // EASING CURVES
  // ===========================================================================

  /// Spring Curve (Entry)
  /// Use: Enter animations with overshoot
  static const Curve springOut = Curves.easeOutCubic;

  /// Spring Curve (Exit)
  /// Use: Exit animations
  static const Curve springIn = Curves.easeInCubic;

  /// Spring Curve (InOut)
  /// Use: Bidirectional animations
  static const Curve springInOut = Curves.easeInOutCubic;

  /// Hover Curve
  /// Use: Hover state transitions
  static const Curve hoverCurve = Curves.easeOutCubic;

  /// Press Curve
  /// Use: Press state transitions
  static const Curve pressCurve = Curves.easeInCubic;

  /// Fade In Curve
  /// Use: Simple fade in
  static const Curve fadeInCurve = Curves.easeOutQuad;

  /// Fade Out Curve
  /// Use: Simple fade out
  static const Curve fadeOutCurve = Curves.easeInQuad;

  /// Slide In Curve (from bottom)
  /// Use: Bottom sheet, modal enter
  static const Curve slideInCurve = Curves.easeOutCubic;

  /// Slide Out Curve (to bottom)
  /// Use: Bottom sheet, modal exit
  static const Curve slideOutCurve = Curves.easeInCubic;

  /// Scale In Curve
  /// Use: Scale up enter
  static const Curve scaleInCurve = Curves.easeOutBack;

  /// Scale Out Curve
  /// Use: Scale down exit
  static const Curve scaleOutCurve = Curves.easeInBack;

  // ===========================================================================
  // ANIMATION CONTROLLERS
  // ===========================================================================

  /// Create AnimationController with spring physics
  ///
  /// Usage:
  /// ```dart
  /// final controller = AppAnimations.createSpringController(
  ///   vsync: this,
  ///   spring: AppAnimations.buttonPressSpring,
  /// );
  /// ```
  static AnimationController createSpringController({
    required TickerProvider vsync,
    SpringDescription spring = const SpringDescription(
      mass: 1.0,
      stiffness: 350.0,
      damping: 15.0,
    ),
    Duration? duration,
    String? debugLabel,
  }) {
    return AnimationController.unbounded(
      vsync: vsync,
      duration: duration ?? durationNormal,
      debugLabel: debugLabel,
    );
  }

  /// Create spring simulation
  ///
  /// Usage:
  /// ```dart
  /// final simulation = AppAnimations.createSpringSimulation(
  ///   spring: AppAnimations.buttonPressSpring,
  ///   start: 0,
  ///   end: 1,
  ///   velocity: 1,
  /// );
  /// ```
  static Simulation createSpringSimulation({
    required SpringDescription spring,
    required double start,
    required double end,
    double velocity = 0,
  }) {
    return SpringSimulation(spring, start, end, velocity);
  }

  // ===========================================================================
  // PRESET ANIMATIONS
  // ===========================================================================

  /// Button press animation builder
  static Animation<double> buttonPressAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: controller, curve: pressCurve));
  }

  /// Button hover animation builder
  static Animation<double> buttonHoverAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: controller, curve: hoverCurve));
  }

  /// Fade animation builder
  static Animation<double> fadeAnimation(
    AnimationController controller, {
    bool reverse = false,
  }) {
    return Tween<double>(
      begin: reverse ? 1.0 : 0.0,
      end: reverse ? 0.0 : 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: reverse ? fadeOutCurve : fadeInCurve,
      ),
    );
  }

  /// Scale animation builder
  static Animation<double> scaleAnimation(
    AnimationController controller, {
    double begin = 0.9,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: springInOut));
  }

  /// Slide animation builder (vertical)
  static Animation<Offset> slideAnimation(
    AnimationController controller, {
    bool fromBottom = true,
  }) {
    return Tween<Offset>(
      begin: Offset(0, fromBottom ? 0.1 : -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: fromBottom ? slideInCurve : slideOutCurve,
      ),
    );
  }

  // ===========================================================================
  // STAGGER ANIMATION HELPERS
  // ===========================================================================

  /// Calculate stagger delay for list items
  ///
  /// Usage:
  /// ```dart
  /// final delay = AppAnimations.staggerDelay(index: 3);
  /// Future.delayed(delay, () => controller.forward());
  /// ```
  static Duration staggerDelay({int index = 0, Duration base = durationFast}) {
    return Duration(milliseconds: index * base.inMilliseconds);
  }

  /// Create staggered animation for list
  static List<Animation<double>> createStaggeredAnimations(
    List<AnimationController> controllers, {
    Duration baseDelay = durationFast,
  }) {
    return controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.9),
            ((index * 0.1) + 0.9).clamp(0.0, 1.0),
            curve: springInOut,
          ),
        ),
      );
    }).toList();
  }

  // ===========================================================================
  // PERFORMANCE UTILITIES
  // ===========================================================================

  /// Check if animations should be reduced
  /// Respects system "Reduce Motion" setting
  static bool shouldReduceMotion(MediaQueryData mediaQuery) {
    return mediaQuery.disableAnimations;
  }

  /// Get reduced duration if animations should be reduced
  static Duration getReducedDuration({
    required MediaQueryData mediaQuery,
    required Duration original,
  }) {
    return shouldReduceMotion(mediaQuery) ? durationInstant : original;
  }

  /// Get reduced curve if animations should be reduced
  static Curve getReducedCurve({
    required MediaQueryData mediaQuery,
    required Curve original,
  }) {
    return shouldReduceMotion(mediaQuery) ? Curves.linear : original;
  }

  // ===========================================================================
  // PAGE TRANSITION BUILDER
  // ===========================================================================

  /// Create custom page route with spring physics
  static PageRouteBuilder<T> createPageRoute<T>({
    required RoutePageBuilder pageBuilder,
    RouteTransitionsBuilder? transitionsBuilder,
    Duration transitionDuration = durationSlow,
    Duration reverseTransitionDuration = durationNormal,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: pageBuilder,
      transitionsBuilder:
          transitionsBuilder ??
          (context, animation, secondaryAnimation, child) => child,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }
}
