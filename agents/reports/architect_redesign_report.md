# Architecture Redesign Report

**Project:** GitDoIt - GitHub Issues TODO Tool  
**Theme:** Industrial Minimalism + Spatial Depth  
**Date:** 2026-02-21  
**Author:** Architect Agent  
**Sprint:** REDESIGN_SPRINT_PLAN.md

---

## Executive Summary

This report defines the complete component architecture and data flow redesign for GitDoIt, transitioning from Material Design to a custom Industrial Minimalism theme with spatial depth. The architecture supports:

- **Design Token System** - Centralized theming with colors, typography, spacing, elevation, and animations
- **Atomic Widget Library** - Hierarchical component structure (atoms → molecules → organisms)
- **Z-Axis Spatial Depth** - Elevation through translation, lighting, and shadows
- **Spring Physics Animations** - Natural motion with configurable spring simulations
- **Offline-First Data Patterns** - Local caching with background sync
- **Pure Flutter Rendering** - No platform-specific adaptations

---

## 🏗️ Component Architecture

### Directory Structure

```
gitdoit/lib/
├── design_tokens/                    # NEW - Design token system
│   ├── colors.dart                   # Color palette (monochrome + Signal Orange)
│   ├── typography.dart               # Inter + JetBrains Mono
│   ├── spacing.dart                  # 8px grid system
│   ├── elevation.dart                # Z-axis depth tokens
│   ├── animations.dart               # Spring physics parameters
│   └── tokens.dart                   # Barrel export
│
├── theme/                            # NEW - Custom theme implementation
│   ├── app_theme.dart                # Main theme configuration
│   ├── industrial_theme.dart         # Industrial Minimalism specifics
│   ├── theme_provider.dart           # Theme state management
│   └── widgets/                      # Themed widget primitives
│       ├── button.dart               # IndustrialButton
│       ├── card.dart                 # IndustrialCard
│       ├── input.dart                # IndustrialInput
│       ├── badge.dart                # IndustrialBadge
│       ├── divider.dart              # IndustrialDivider
│       └── icon_button.dart          # IndustrialIconButton
│
├── widgets/                          # REDESIGN - Atomic design structure
│   ├── atoms/                        # Basic UI elements
│   │   ├── industrial_button.dart    # Primary action button
│   │   ├── industrial_icon_button.dart
│   │   ├── industrial_text.dart      # Styled text components
│   │   ├── industrial_icon.dart      # Custom icon renderer
│   │   ├── industrial_divider.dart   # Grid-aligned dividers
│   │   └── industrial_spacer.dart    # 8px grid spacers
│   │
│   ├── molecules/                    # Composite components
│   │   ├── issue_card.dart           # Issue summary card (redesigned)
│   │   ├── label_badge.dart          # Label chip with dot-matrix
│   │   ├── status_indicator.dart     # Open/closed status
│   │   ├── search_bar.dart           # Custom search input
│   │   ├── filter_chip.dart          # Filter selection
│   │   ├── metadata_row.dart         # Key-value metadata display
│   │   └── offline_banner.dart       # Offline state indicator
│   │
│   └── organisms/                    # Complex composite widgets
│       ├── issue_list.dart           # Scrollable issue list
│       ├── issue_header.dart         # Issue detail header
│       ├── issue_body.dart           # Markdown content area
│       ├── issue_actions.dart        # Action button bar
│       ├── auth_form.dart            # Authentication form
│       ├── settings_group.dart       # Settings section
│       └── navigation_rail.dart      # Side navigation
│
├── screens/                          # REDESIGN - Screen compositions
│   ├── auth_screen.dart              # Login / offline entry
│   ├── home_screen.dart              # Main dashboard
│   ├── issue_detail_screen.dart      # Issue detail view
│   ├── edit_issue_screen.dart        # Issue editor
│   └── settings_screen.dart          # App configuration
│
├── providers/                        # MODIFY - State management
│   ├── auth_provider.dart            # Authentication state
│   ├── issues_provider.dart          # Issues state + cache
│   ├── theme_provider.dart           # Theme state (NEW)
│   └── sync_provider.dart            # Background sync (NEW)
│
├── services/                         # MODIFY - Business logic
│   ├── github_service.dart           # GitHub API client
│   ├── cache_service.dart            # Hive cache manager (NEW)
│   ├── sync_service.dart             # Background sync (NEW)
│   └── haptic_service.dart           # Haptic feedback (NEW)
│
├── animations/                       # NEW - Animation utilities
│   ├── spring_physics.dart           # Spring simulation config
│   ├── z_axis_transitions.dart       # Z-axis page transitions
│   ├── hover_effects.dart            # Hover state animations
│   └── press_effects.dart            # Press state animations
│
├── painters/                         # NEW - Custom painting
│   ├── dot_matrix_pattern.dart       # Dot-matrix textures
│   ├── grid_lines.dart               # Technical grid lines
│   ├── glow_effect.dart              # Glow/halo effects
│   └── hardware_controls.dart        # Hardware-like control rendering
│
├── models/                           # KEEP - Data models
│   ├── issue.dart                    # GitHub issue model
│   ├── issue.g.dart                  # Generated code
│   ├── user.dart                     # User model (extracted)
│   ├── label.dart                    # Label model (extracted)
│   └── milestone.dart                # Milestone model (extracted)
│
├── utils/                            # MODIFY - Utilities
│   ├── logger.dart                   # Logging system (enhanced)
│   ├── formatters.dart               # Date/number formatters (NEW)
│   ├── validators.dart               # Input validators (NEW)
│   └── constants.dart                # App constants (NEW)
│
└── main.dart                         # MODIFY - App entry point
```

---

### Component Hierarchy (Atomic Design)

```
┌─────────────────────────────────────────────────────────────────┐
│                           SCREENS                                │
│  ┌─────────────┐ ┌──────────┐ ┌────────────┐ ┌───────────────┐ │
│  │ AuthScreen  │ │HomeScreen│ │IssueDetail │ │ SettingsScreen│ │
│  └──────┬──────┘ └────┬─────┘ └─────┬──────┘ └───────┬───────┘ │
└─────────┼─────────────┼─────────────┼────────────────┼──────────┘
          │             │             │                │
┌─────────▼─────────────▼─────────────▼────────────────▼──────────┐
│                         ORGANISMS                                │
│  ┌────────────┐ ┌───────────┐ ┌────────────┐ ┌──────────────┐  │
│  │ AuthForm   │ │ IssueList │ │IssueHeader │ │SettingsGroup │  │
│  │            │ │           │ │IssueBody   │ │              │  │
│  │            │ │           │ │IssueActions│ │              │  │
│  └─────┬──────┘ └─────┬─────┘ └─────┬──────┘ └──────┬───────┘  │
└────────┼──────────────┼─────────────┼───────────────┼───────────┘
         │              │             │               │
┌────────▼──────────────▼─────────────▼───────────────▼───────────┐
│                        MOLECULES                                 │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────────┐  │
│  │IssueCard │ │LabelBadge│ │StatusInd. │ │ MetadataRow      │  │
│  │SearchBar │ │FilterChip│ │OfflineBnr │ │                  │  │
│  └────┬─────┘ └────┬─────┘ └─────┬─────┘ └────────┬─────────┘  │
└───────┼────────────┼─────────────┼────────────────┼────────────┘
        │            │             │                │
┌───────▼────────────▼─────────────▼────────────────▼────────────┐
│                          ATOMS                                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │Button    │ │ IconButton│ │  Text    │ │  Divider         │   │
│  │Input     │ │  Icon    │ │  Spacer  │ │  Container       │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         ▲
         │
┌────────┴────────────────────────────────────────────────────────┐
│                      DESIGN TOKENS                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ Colors   │ │Typography│ │ Spacing  │ │  Elevation       │   │
│  │Animations│ │ Borders  │ │ Radius   │ │  Shadows         │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

### Design Token System

#### Token Definition Strategy

Tokens are defined as **static constants** in dedicated files, accessed via **static references** for performance and simplicity.

```dart
// lib/design_tokens/colors.dart
class AppColors {
  // Background
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // Surface
  static const Color lightGray = Color(0xFFF5F5F7);
  static const Color darkGray = Color(0xFF1C1C1E);
  
  // Border
  static const Color borderLight = Color(0xFFE1E1E1);
  static const Color borderDark = Color(0xFF333333);
  
  // Accent
  static const Color signalOrange = Color(0xFFFF5500);
  static const Color statusGreen = Color(0xFF00FF00);
  static const Color errorRed = Color(0xFFFF3333);
  
  // Semantic (derived from base)
  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark 
          ? darkGray 
          : lightGray;
}

// lib/design_tokens/spacing.dart
class Spacing {
  // Base unit: 8px
  static const double unit = 8.0;
  
  // Margins/Padding
  static const double xs = unit;        // 8px
  static const double sm = unit * 2;    // 16px
  static const double md = unit * 3;    // 24px
  static const double lg = unit * 4;    // 32px
  static const double xl = unit * 6;    // 48px
  
  // Touch targets
  static const double touchTarget = 48.0;
}

// lib/design_tokens/elevation.dart
class Elevation {
  // Z-axis levels
  static const double z0 = 0.0;    // Base layer
  static const double z1 = 2.0;    // Interactive (buttons, cards)
  static const double z2 = 4.0;    // Attraction points (hover, key actions)
  static const double z3 = 8.0;    // Modal/overlay
  
  // Shadow configurations
  static List<BoxShadow> get z1Shadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get z2Shadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.signalOrange.withOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 0),
    ),
  ];
}

// lib/design_tokens/animations.dart
class Animations {
  // Spring physics parameters
  static const Duration springDuration = Duration(milliseconds: 400);
  static const double springStiffness = 180.0;
  static const double springDamping = 15.0;
  
  // Preset curves
  static const Curve springCurve = Curves.easeInOutCubicEmphasized;
  static const Curve hoverCurve = Curves.easeOutCubic;
  static const Curve pressCurve = Curves.easeInCubic;
}
```

#### Token Access Pattern

```dart
// Access via static reference (preferred for performance)
Container(
  padding: EdgeInsets.all(Spacing.sm),
  decoration: BoxDecoration(
    boxShadow: Elevation.z1Shadow,
  ),
)

// Access via theme extension (for context-aware tokens)
final theme = Theme.of(context);
final industrialTheme = theme.extension<IndustrialTheme>();
Color surfaceColor = industrialTheme?.surfaceColor ?? AppColors.lightGray;
```

---

## 🔄 Data Flow

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                           │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │  App Start   │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Load Token   │◄─────────────────────────────┐
    │ from Storage │                              │
    └──────┬───────┘                              │
           │                                      │
           ▼                                      │
    ┌──────────────┐                              │
    │ Token Found? │──No──────────────────┐       │
    └──────┬───────┘                      │       │
           │Yes                           │       │
           ▼                              │       │
    ┌──────────────┐                      │       │
    │ Check Online │──Offline─────────────┤       │
    │ Status       │                      │       │
    └──────┬───────┘                      │       │
           │Online                        │       │
           ▼                              │       │
    ┌──────────────┐                      │       │
    │ Validate     │──Invalid─────────────┤       │
    │ with GitHub  │                      │       │
    └──────┬───────┘                      │       │
           │Valid                         │       │
           ▼                              │       │
    ┌──────────────┐      ┌───────────────┴───────┴───────┐
    │ Set Auth     │      │     OFFLINE MODE              │
    │ State        │      │  - Allow app usage            │
    └──────┬───────┘      │  - Cache writes enabled       │
           │              │  - Sync queued                │
           ▼              └───────────────┬───────────────┘
    ┌──────────────┐                      │
    │ Navigate to  │◄─────────────────────┘
    │ HomeScreen   │
    └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Token Storage & Propagation                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│FlutterSecure│────►│ AuthProvider│────►│  UI State   │
│  Storage    │     │ (Notifier)  │     │ (Consumer)  │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │GitHubService│
                    └─────────────┘
```

**Implementation Notes:**
- Token stored in `flutter_secure_storage` (encrypted keychain/keystore)
- `AuthProvider` is a `ChangeNotifier` - state propagates via `Provider`
- Offline mode allows app usage without validation
- Token validation retries on connectivity restoration

---

### Issues Data Flow (Offline-First)

```
┌─────────────────────────────────────────────────────────────────┐
│                    ISSUES DATA FLOW                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FETCH FLOW                                                      │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ User Opens   │
    │ HomeScreen   │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ IssuesProvider│
    │ .loadIssues()│
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Check Online │──Offline───────┐
    │ Status       │                │
    └──────┬───────┘                │
           │Online                  │
           ▼                        │
    ┌──────────────┐                │
    │ GitHub API   │                │
    │ Fetch        │                │
    └──────┬───────┘                │
           │                        │
           ▼                        │
    ┌──────────────┐                │
    │ Update Local │                │
    │ State        │                │
    └──────┬───────┘                │
           │                        │
           ▼                        │
    ┌──────────────┐                │
    │ Cache to     │                │
    │ Hive         │                │
    └──────┬───────┘                │
           │                        │
           ▼                        │
    ┌──────────────┐      ┌─────────▼─────────┐
    │ Notify       │      │  Load from Cache  │
    │ Listeners    │      │  (Hive)           │
    └──────┬───────┘      └─────────┬─────────┘
           │                        │
           └───────────┬────────────┘
                       │
                       ▼
              ┌────────────────┐
              │ UI Rebuild     │
              │ (IssueList)    │
              └────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│  SYNC FLOW (Background)                                          │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ Connectivity │
    │ Restored     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ SyncProvider │
    │ Detects      │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Check Pending│
    │ Mutations    │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Process Queue│──► GitHub API
    │ (FIFO)       │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Update Cache │
    │ & State      │
    └──────────────┘
```

**Offline-First Pattern:**
1. **Read:** Always read from local cache first (Hive)
2. **Write:** Write to cache immediately, queue for sync
3. **Sync:** Background sync when connectivity restored
4. **Conflict:** Last-write-wins (timestamp-based)

---

### User Interaction Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    INTERACTION FLOW                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  TOUCH → ANIMATION → FEEDBACK                                    │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ Touch Input  │
    │ (GestureDet.)│
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ HapticService│────► Vibration (mobile)
    │ .feedback()  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Animation    │
    │ Controller   │
    └──────┬───────┘
           │
           ├─────────────────┬─────────────────┐
           │                 │                 │
           ▼                 ▼                 ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │ Z-Axis      │  │ Scale       │  │ Opacity     │
    │ Translation │  │ Transform   │  │ Fade        │
    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
           │                │                │
           └────────────────┴────────────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │ Visual Feedback│
                   │ (60/120fps)    │
                   └────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│  HOVER STATE (Desktop/Web)                                       │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────┐
    │ Mouse Enter  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ MouseTracker │
    │ .attach()    │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Animate Z    │
    │ from 0 → 1   │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Add Glow     │
    │ (Signal      │
    │  Orange)     │
    └──────┬───────┘
           │
           ▼
    ┌──────────────┐
    │ Cursor       │
    │ Change       │
    └──────────────┘
```

**Performance Targets:**
- **60fps minimum** on all devices
- **120fps** on ProMotion displays
- **<16ms** frame budget for 60fps
- **<8ms** frame budget for 120fps

**Optimization Strategies:**
- Use `Transform` properties (not layout shifts)
- Pre-cache images and fonts
- Use `RepaintBoundary` for complex widgets
- Batch state updates with `setState` grouping

---

## 📋 Architecture Decisions

| Decision | Rationale | Impact |
|----------|-----------|--------|
| **Static Token Access** | Performance over flexibility. Tokens don't change at runtime. | Faster access, simpler code. Less dynamic theming. |
| **Provider for State** | Existing codebase uses Provider. Migration to Riverpod not worth cost. | Consistent with existing patterns. Some boilerplate. |
| **Hive for Cache** | Already integrated. Fast, simple, supports custom objects. | No additional dependencies. Limited query capabilities. |
| **Atomic Design** | Clear component hierarchy. Reusability. Easier testing. | More files. Clearer organization. |
| **Custom Theme (not Material)** | Industrial Minimalism requires full control. Material leaks. | More code. Complete visual control. |
| **Z-Axis via Transform** | GPU-accelerated. No layout recalculation. | Requires careful coordinate management. |
| **Spring Physics** | Natural motion. Matches hardware aesthetic. | More complex than tween animations. |
| **Offline-First** | Core requirement. Works without network. | More complex sync logic. Better UX. |
| **Pure Flutter** | Consistent behavior across platforms. | No platform-specific optimizations. |
| **Extracted Models** | Separate Issue, User, Label, Milestone for clarity. | More files. Better organization. |

---

## 🔍 Codebase Review

### KEEP (No Changes Required)

| File | Reason |
|------|--------|
| `models/issue.dart` | Data models are theme-agnostic. Well-structured. |
| `models/issue.g.dart` | Generated code. Will regenerate if models change. |
| `services/github_service.dart` | API logic is theme-independent. Solid implementation. |
| `utils/logger.dart` | Logging system is already excellent. |
| `providers/auth_provider.dart` | Auth logic is sound. Only needs theme integration. |
| `providers/issues_provider.dart` | State management is good. Cache pattern correct. |

---

### MODIFY (Requires Updates)

| File | Required Changes |
|------|------------------|
| `main.dart` | - Remove Material theme configuration<br>- Add IndustrialTheme<br>- Add ThemeProvider<br>- Update routes with Z-axis transitions |
| `screens/auth_screen.dart` | - Replace Material widgets with Industrial widgets<br>- Add Z-axis hover states<br>- Implement spring animations<br>- Update visual design |
| `screens/home_screen.dart` | - Replace AppBar with custom header<br>- Replace FAB with IndustrialButton<br>- Update IssueCard usage<br>- Add offline-first UI patterns |
| `screens/issue_detail_screen.dart` | - Complete visual redesign<br>- Add spatial depth to sections<br>- Implement hardware-like controls<br>- Update markdown styling |
| `screens/edit_issue_screen.dart` | - Replace text fields with IndustrialInput<br>- Add tactile controls<br>- Implement preview with grid lines |
| `screens/settings_screen.dart` | - Redesign as technical settings panel<br>- Add annotations<br>- Update tiles with Industrial styling |
| `widgets/issue_card.dart` | - Complete redesign with atomic structure<br>- Add Z-axis hover/press states<br>- Implement spring animations |
| `widgets/offline_indicator.dart` | - Update visual design<br>- Add subtle animation<br>- Match industrial aesthetic |

---

### REMOVE (Delete These Files/Patterns)

| File/Pattern | Reason |
|--------------|--------|
| **All Material widgets** | `ElevatedButton`, `OutlinedButton`, `TextButton`, `Card`, `AppBar`, `ListTile`, `FilterChip`, `FloatingActionButton`, `CircularProgressIndicator`, `SnackBar`, `AlertDialog`, `InkWell`, `Divider` | Replace with Industrial equivalents |
| **Material imports** | `import 'package:flutter/material.dart'` | Keep only for Scaffold, SafeArea, Basic widgets |
| **Theme.of(context).colorScheme** | Using design tokens instead | Replace with `AppColors.*` or `IndustrialTheme` |
| **BorderRadius.circular()** | Using token-based radius | Replace with `BorderRadiusToken.small/medium/large` |
| **EdgeInsets.symmetric/all** | Using spacing tokens | Replace with `SpacingToken.*` |
| **Colors.green / Colors.red** | Using semantic colors | Replace with `AppColors.statusGreen / errorRed` |

---

## 🛠️ Technical Specifications

### Z-Axis Translation System

```dart
// lib/design_tokens/elevation.dart
import 'package:flutter/material.dart';
import 'colors.dart';

class ZAxis {
  // Elevation levels
  static const double base = 0.0;
  static const double raised = 2.0;
  static const double elevated = 4.0;
  static const double floating = 8.0;
  static const double overlay = 16.0;
  
  // Shadow configurations
  static List<BoxShadow> shadowFor(double z) {
    switch (z) {
      case base:
        return [];
      case raised:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case elevated:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.signalOrange.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ];
      case floating:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.signalOrange.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 0),
          ),
        ];
      default:
        return shadowFor(base);
    }
  }
  
  // Transform for Z-axis animation
  static Matrix4 transformFor(double z) {
    return Matrix4.translationValues(0, 0, z);
  }
}

// lib/widgets/atoms/industrial_button.dart
class IndustrialButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double elevation; // z-axis level
  
  const IndustrialButton({
    required this.child,
    this.onPressed,
    this.elevation = ZAxis.raised,
  });
  
  @override
  State<IndustrialButton> createState() => _IndustrialButtonState();
}

class _IndustrialButtonState extends State<IndustrialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _zAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _zAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 2, // Hover adds 2px Z
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }
  
  void _onHoverEnter() {
    if (widget.onPressed != null) {
      setState(() => _isHovered = true);
      _controller.forward();
      HapticService.lightClick(); // Haptic feedback
    }
  }
  
  void _onHoverExit() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }
  
  void _onTapDown(_) {
    setState(() => _isPressed = true);
    _controller.reverse(); // Press = lower Z
    HapticService.mediumClick();
  }
  
  void _onTapUp(_) {
    setState(() => _isPressed = false);
    if (_isHovered) _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapUp,
        child: AnimatedBuilder(
          animation: _zAnimation,
          builder: (context, child) {
            return Transform(
              transform: ZAxis.transformFor(_zAnimation.value),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? AppColors.signalOrange.withOpacity(0.8)
                      : AppColors.signalOrange,
                  borderRadius: BorderRadius.circular(RadiusToken.medium),
                  boxShadow: ZAxis.shadowFor(_zAnimation.value),
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### Spring Animation Setup

```dart
// lib/animations/spring_physics.dart
import 'package:flutter/animation.dart';

/// Spring physics configuration for natural motion
class SpringPhysics {
  // Default spring parameters
  static const double defaultStiffness = 180.0;
  static const double defaultDamping = 15.0;
  static const double defaultMass = 1.0;
  
  // Preset configurations
  static const SpringDescription stiff = SpringDescription(
    stiffness: 250.0,
    damping: 20.0,
    mass: 1.0,
  );
  
  static const SpringDescription gentle = SpringDescription(
    stiffness: 120.0,
    damping: 10.0,
    mass: 1.0,
  );
  
  static const SpringDescription bouncy = SpringDescription(
    stiffness: 150.0,
    damping: 8.0,
    mass: 0.8,
  );
  
  // Animation duration derived from spring parameters
  static Duration get duration => const Duration(milliseconds: 400);
  
  // Create spring simulation
  static SpringSimulation createSimulation({
    double stiffness = defaultStiffness,
    double damping = defaultDamping,
    double mass = defaultMass,
    double start = 0.0,
    double end = 1.0,
    double velocity = 0.0,
  }) {
    return SpringSimulation(
      SpringDescription(
        stiffness: stiffness,
        damping: damping,
        mass: mass,
      ),
      start,
      end,
      velocity,
    );
  }
}

// lib/animations/z_axis_transitions.dart
class ZAxisTransitions {
  // Page transition with Z-axis effect
  static Route<T> createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubicEmphasized,
        );
        
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final zValue = curvedAnimation.value * 8.0; // 0 to 8px Z
            final scaleValue = 0.95 + (curvedAnimation.value * 0.05);
            
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..translate(0, 0, zValue)
                ..scale(scaleValue),
              alignment: Alignment.center,
              child: Opacity(
                opacity: curvedAnimation.value,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      transitionDuration: SpringPhysics.duration,
    );
  }
}

// Usage in navigation
Navigator.push(
  context,
  ZAxisTransitions.createRoute(IssueDetailScreen(issue: issue)),
);
```

---

### CustomPainter Guidelines

```dart
// lib/painters/dot_matrix_pattern.dart
import 'package:flutter/material.dart';

/// Dot-matrix pattern for industrial aesthetic
class DotMatrixPattern extends CustomPainter {
  final double dotSize;
  final double spacing;
  final Color color;
  final double opacity;
  
  DotMatrixPattern({
    this.dotSize = 2.0,
    this.spacing = 8.0,
    this.color = Colors.black,
    this.opacity = 0.1,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DotMatrixPattern oldDelegate) {
    return oldDelegate.dotSize != dotSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}

// lib/painters/grid_lines.dart
class GridLinesPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;
  final bool showHorizontal;
  final bool showVertical;
  
  GridLinesPainter({
    this.color = Colors.black,
    this.strokeWidth = 0.5,
    this.spacing = 8.0,
    this.showHorizontal = true,
    this.showVertical = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (showHorizontal) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }
    
    if (showVertical) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant GridLinesPainter oldDelegate) => true;
}

// lib/painters/glow_effect.dart
class GlowEffectPainter extends CustomPainter {
  final Color glowColor;
  final double intensity;
  final double blurRadius;
  
  GlowEffectPainter({
    required this.glowColor,
    this.intensity = 0.3,
    this.blurRadius = 20.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Outer glow
    final outerPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          glowColor.withOpacity(intensity),
          glowColor.withOpacity(0),
        ],
      ).createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    
    canvas.drawRect(rect.inflate(blurRadius), outerPaint);
  }
  
  @override
  bool shouldRepaint(covariant GlowEffectPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor ||
        oldDelegate.intensity != intensity ||
        oldDelegate.blurRadius != blurRadius;
  }
}

// Usage in widgets
CustomPaint(
  painter: DotMatrixPattern(opacity: 0.05),
  child: Container(
    padding: EdgeInsets.all(Spacing.lg),
    child: Text('Industrial Content'),
  ),
)
```

---

## ⚠️ Constraints & Considerations

### Performance

| Target | Strategy |
|--------|----------|
| **60fps minimum** | Use `Transform` for animations, avoid layout shifts |
| **120fps on ProMotion** | Enable `RenderView.useWideGamut`, optimize paint ops |
| **<100ms interaction** | Pre-load assets, use `RepaintBoundary` |
| **<1s cold start** | Lazy-load non-critical widgets, defer initialization |

**Optimization Strategies:**
- Use `const` constructors everywhere possible
- Cache `Paint` objects in `CustomPainter`
- Use `RepaintBoundary` for complex custom painters
- Batch state updates with single `setState` call
- Use `ValueListenableBuilder` for granular rebuilds
- Pre-cache fonts and images on app start

---

### Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **WCAG AA Contrast (4.5:1)** | Verify all color combinations. Use `AppColors` with built-in contrast checks. |
| **48x48dp Touch Targets** | Enforce via `Spacing.touchTarget` constant. All buttons/inputs minimum 48px. |
| **Semantic Labels** | Add `Semantics` widgets around `CustomPainter` elements. |
| **Logical Focus Order** | Use `FocusTraversalGroup` for screen readers. |
| **Reduce Motion** | Check `MediaQuery.disableAnimations`. Provide static fallbacks. |
| **Color + Icon/Text** | Never use color alone for status. Always pair with icon or text. |

```dart
// Accessibility helper
Semantics(
  label: 'Close issue button',
  button: true,
  child: CustomPaint(
    painter: StatusIndicatorPainter(isOpen: false),
    child: SizedBox(
      width: Spacing.touchTarget,
      height: Spacing.touchTarget,
    ),
  ),
)
```

---

### Cross-Platform

| Platform | Consideration |
|----------|---------------|
| **iOS** | Use `CupertinoTextThemeData` for text rendering consistency |
| **Android** | Handle back button navigation properly |
| **Web** | Enable URL strategy, handle browser back/forward |
| **Desktop** | Support keyboard shortcuts, window resizing |
| **All** | No platform-specific widgets. Pure Flutter only. |

**Consistency Requirements:**
- Same fonts on all platforms (bundle Inter and JetBrains Mono)
- Same colors (no platform theme adaptation)
- Same animations (spring physics everywhere)
- Same touch targets (48px minimum)

---

## 📦 Handoff Notes

### For Senior Developer

**Implementation Priorities:**
1. **Phase 1:** Design tokens + theme system (foundation)
2. **Phase 2:** Atomic widgets (button, card, input)
3. **Phase 3:** Screen redesign (auth, home first)
4. **Phase 4:** Polish (animations, accessibility)

**Complex Decisions:**
- Z-axis translation requires `Matrix4` with perspective for proper depth
- Spring animations need tuning per use case (stiffness/damping)
- Custom painters should be cached to avoid repaint overhead

**Potential Challenges:**
- Material widget leakage - audit all imports
- Performance on low-end devices - provide reduced motion mode
- Font loading latency - preload fonts in `main()`

---

### For UX/UI

**Technical Constraints:**
- All animations must use spring physics (no linear easing)
- Z-axis depth limited to 16px (beyond causes clipping)
- Custom painters require explicit semantics for accessibility
- 8px grid is enforced - no fractional spacing

**Performance Budgets:**
- Max 3 custom painters per screen
- Max 5 concurrent animations
- Font file size < 500KB total (subset if needed)
- Image assets < 100KB each

---

### For Cleaner

**Files to Remove:**
- All Material widget usage (replace with Industrial equivalents)
- Unused imports after refactoring
- Dead code from old theme system
- Redundant styling (now handled by tokens)

**Refactoring Priorities:**
1. Extract inline styles to design tokens
2. Replace Material widgets with Industrial widgets
3. Remove duplicate color definitions
4. Consolidate spacing values to 8px grid

---

## ✅ Success Criteria Checklist

- [x] Directory structure defined and documented
- [x] Component hierarchy clear (atomic design)
- [x] Data flows mapped for all features
- [x] Architecture decisions documented with rationale
- [x] Codebase review complete (keep/modify/remove)
- [x] Technical specifications provided (Z-axis, springs, painting)
- [x] Report created in `agents/reports/`

---

**MOTTO:** *Structure First. Flow Second. Polish Third.*

**NEXT STEPS:**
1. Senior Developer: Implement design tokens and theme system
2. UX/UI: Design atomic widget library
3. Architect: Review implementation against this specification
4. Cleaner: Begin removing Material Design dependencies

---

*Report generated: 2026-02-21*  
*Agent: Architect*  
*Sprint: REDESIGN_SPRINT_PLAN.md*
