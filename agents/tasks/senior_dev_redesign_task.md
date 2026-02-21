# SENIOR DEVELOPER AGENT - REDESIGN SPRINT TASK

## Mission
Implement the complete redesign of GitDoIt app using Industrial Minimalism guidelines and new architecture.

## Context
You are implementing a complete visual redesign based on:
- Universal Design Guidelines (Industrial Minimalism & Spatial Depth)
- New design tokens (colors, typography, spacing, elevation, animations)
- Custom theme system (no Material Design visible)
- Atomic widget library
- Redesigned screens
- Spring physics animations
- Z-axis spatial depth

## Your Tasks

### Phase 1: Design Tokens Implementation (90 min)
Create the design token system in `lib/design_tokens/`:

1. **colors.dart**
   ```dart
   class AppColors {
     // Background
     static const black = Color(0xFF000000);
     static const white = Color(0xFFFFFFFF);
     
     // Surface
     static const lightGray = Color(0xFFF5F5F7);
     static const darkGray = Color(0xFF1C1C1E);
     
     // Border
     static const lightBorder = Color(0xFFE1E1E1);
     static const darkBorder = Color(0xFF333333);
     
     // Accent
     static const signalOrange = Color(0xFFFF5500);
     static const statusGreen = Color(0xFF00FF00);
     static const errorRed = Color(0xFFFF3333);
   }
   ```

2. **typography.dart**
   ```dart
   class AppTypography {
     // Primary: Inter
     // Secondary: JetBrains Mono
     // Define all text styles (display, headline, body, label, caption)
   }
   ```

3. **spacing.dart**
   ```dart
   class AppSpacing {
     // Base unit: 8px
     static const double unit = 8.0;
     static const double xs = 8.0;   // 1x
     static const double sm = 16.0;  // 2x
     static const double md = 24.0;  // 3x
     static const double lg = 32.0;  // 4x
     static const double xl = 48.0;  // 6x
   }
   ```

4. **elevation.dart**
   ```dart
   class AppElevation {
     // Z=0, Z=1, Z=2 levels
     // Shadow values, lighting angles
   }
   ```

5. **animations.dart**
   ```dart
   class AppAnimations {
     // Spring parameters (mass, tension, friction)
     // Duration constants
     // Curve definitions
   }
   ```

### Phase 2: Theme Implementation (60 min)
Create custom theme in `lib/theme/`:

1. **app_theme.dart**
   - Custom ThemeData (minimal Material usage)
   - Color scheme integration
   - Typography theme
   - Component themes (buttons, cards, inputs)

2. **industrial_theme.dart**
   - Custom theme class
   - Z-level management
   - Lighting and shadow utilities
   - Spatial depth helpers

3. **widgets/** (atomic components)
   - industrial_button.dart
   - industrial_card.dart
   - industrial_input.dart
   - industrial_badge.dart
   - industrial_toggle.dart
   - industrial_slider.dart

### Phase 3: Widget Implementation (120 min)
Implement all atomic widgets with:

1. **IndustrialButton**
   - Primary (Signal Orange, Z=1→Z=2)
   - Secondary (Monochrome, border-focused)
   - Text (Minimal, caption style)
   - Spring physics on press
   - Z-axis hover translation
   - Focus illumination

2. **IndustrialCard**
   - Data card (Z=1, modular)
   - Interactive card (Z=1→Z=2 on hover)
   - Soft colored shadows
   - Frosted glass option

3. **IndustrialInput**
   - Border-focused design
   - Focus illumination
   - Monospace labels
   - Technical annotations

4. **IndustrialBadge**
   - Dot-matrix style
   - Status indicators
   - Glyph aesthetics

5. **IndustrialToggle**
   - Physical switch simulation
   - Tactile feedback
   - Z-axis movement

6. **IndustrialSlider**
   - Fader-style control
   - Teenage Engineering aesthetic
   - Precise values

### Phase 4: Screen Redesign (180 min)
Redesign all screens:

1. **auth_screen.dart**
   - Minimal, focused layout
   - Industrial inputs
   - Signal Orange primary button
   - Technical annotations

2. **home_screen.dart**
   - Modular card grid
   - Exposed grid lines (subtle)
   - Z-axis interactions
   - Bottom navigation (mobile)

3. **issue_detail_screen.dart**
   - Spatial depth
   - Technical annotations
   - Monospace metadata
   - Tactile controls

4. **edit_issue_screen.dart**
   - Hardware-like controls
   - Faders and switches
   - Real-time preview
   - Industrial buttons

5. **settings_screen.dart**
   - Technical layout
   - Monospace labels
   - Dot-matrix icons
   - Modular sections

### Phase 5: Animation Integration (60 min)
Implement spring physics throughout:

1. **Button Animations**
   ```dart
   AnimationController with SpringSimulation
   Hover: Z-translation (lift)
   Press: Z-translation (depress)
   ```

2. **Card Animations**
   ```dart
   MouseRegion for hover detection
   AnimatedContainer for Z-level
   Shadow interpolation
   ```

3. **Screen Transitions**
   ```dart
   PageRouteBuilder with custom curves
   Continuous motion (no hard cuts)
   60fps minimum
   ```

### Phase 6: Accessibility Integration (30 min)
Ensure all components are accessible:

1. **Semantic Labels**
   - All CustomPainter elements labeled
   - Button purposes clear
   - Input fields described

2. **Focus Management**
   - Logical focus order
   - Visible focus indicators
   - Keyboard navigation

3. **Contrast Verification**
   - All text passes WCAG AA
   - Test with contrast checker
   - Document in report

## Output Format

Create file: `agents/reports/senior_dev_redesign_report.md`

```markdown
# Senior Developer Redesign Report

## ✅ Implementation Status

### Design Tokens
| Token | Status | File | Notes |
|-------|--------|------|-------|
| Colors | ✅/⚠️/❌ | colors.dart | [notes] |
| Typography | ✅/⚠️/❌ | typography.dart | [notes] |
| Spacing | ✅/⚠️/❌ | spacing.dart | [notes] |
| Elevation | ✅/⚠️/❌ | elevation.dart | [notes] |
| Animations | ✅/⚠️/❌ | animations.dart | [notes] |

### Theme
| Component | Status | File | Notes |
|-----------|--------|------|-------|
| App Theme | ✅/⚠️/❌ | app_theme.dart | [notes] |
| Industrial Theme | ✅/⚠️/❌ | industrial_theme.dart | [notes] |
| Button Widget | ✅/⚠️/❌ | industrial_button.dart | [notes] |
| Card Widget | ✅/⚠️/❌ | industrial_card.dart | [notes] |
| Input Widget | ✅/⚠️/❌ | industrial_input.dart | [notes] |
| Badge Widget | ✅/⚠️/❌ | industrial_badge.dart | [notes] |
| Toggle Widget | ✅/⚠️/❌ | industrial_toggle.dart | [notes] |
| Slider Widget | ✅/⚠️/❌ | industrial_slider.dart | [notes] |

### Screens
| Screen | Status | File | Notes |
|--------|--------|------|-------|
| Auth | ✅/⚠️/❌ | auth_screen.dart | [notes] |
| Home | ✅/⚠️/❌ | home_screen.dart | [notes] |
| Detail | ✅/⚠️/❌ | issue_detail_screen.dart | [notes] |
| Edit | ✅/⚠️/❌ | edit_issue_screen.dart | [notes] |
| Settings | ✅/⚠️/❌ | settings_screen.dart | [notes] |

## 🎯 Implementation Decisions

| Decision | Rationale | Trade-offs |
|----------|-----------|------------|
| [decision] | [why] | [what was sacrificed] |

## 🐛 Challenges & Solutions

### Challenge: [description]
**Solution:** [how you solved it]
**Code:** [snippet if relevant]

### Challenge: [description]
**Solution:** [how you solved it]
**Code:** [snippet if relevant]

## 🎨 Material Design Migration

### What Was Removed
- [List of Material widgets replaced]

### What Was Kept (Themed Beyond Recognition)
- [List of Material widgets that remain but are heavily themed]

### Custom Implementations
- [List of custom widgets that replace Material]

## ⚡ Performance Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| FPS | 60/120 | [value] | ✅/❌ |
| Build Time | <16ms | [value] | ✅/❌ |
| Memory | <100MB | [value] | ✅/❌ |

## ♿ Accessibility Audit

| Check | Status | Notes |
|-------|--------|-------|
| Contrast | ✅/❌ | [details] |
| Semantics | ✅/❌ | [details] |
| Focus | ✅/❌ | [details] |
| Touch Targets | ✅/❌ | [details] |

## 📦 Code Quality

| Metric | Value |
|--------|-------|
| Files Changed | X |
| Lines Added | X |
| Lines Removed | X |
| Complexity | Low/Med/High |

## 🔄 Next Steps

For Cleaner:
- [Files that need formatting]
- [Imports to clean up]
- [Dead code to remove]

For Logger:
- [Components that need logging]
- [Error handling to add]

For Stupid User:
- [Features to test]
- [Flows to validate]
```

## Integration Points

**You receive from:**
- MrUXUIDesigner: Design specifications, component designs
- MrArchitector: Architecture blueprint, implementation guide

**You provide to:**
- MrCleaner: Code to format and clean
- MrLogger: Components needing logging
- MrStupidUser: Features to test

## Success Criteria

- [ ] All design tokens implemented
- [ ] Custom theme functional (no visible Material)
- [ ] All atomic widgets implemented with states
- [ ] All screens redesigned
- [ ] Spring physics on all animations
- [ ] Z-axis depth implemented
- [ ] Accessibility audit passing
- [ ] Report created in `agents/reports/`

## Begin Mission

Start by reading reports from UX/UI and Architect agents. Implement in order: tokens → theme → widgets → screens. Test frequently.

**MOTTO:** *Code is Material. Precision is Everything.*
