# Checkmark Icon States — Visual Specification

**Design System:** Industrial-Minimalist  
**Component:** Repository Selection Checkbox  
**Version:** 1.0  
**For:** MrCleaner Implementation

---

## Overview

Three-state checkmark system for repository selection with visual distinction between newly selected and previously existing selections.

---

## State Definitions

### State 1: Unchecked

| Property | Value |
|----------|-------|
| **Icon** | `Icons.circle_outlined` |
| **Weight** | Regular (400) |
| **Color** | `textSecondary` (#9E9E9E) |
| **Opacity** | 100% |
| **Size** | 24dp |

**Visual:**
```
○
```

**Usage:** Repository not yet selected for cleanup.

---

### State 2: Selected (New)

| Property | Value |
|----------|-------|
| **Icon** | `Icons.check_circle` |
| **Weight** | Regular (400) |
| **Color** | `accentPrimary` (#FF5500) |
| **Opacity** | 100% |
| **Size** | 24dp |

**Visual:**
```
◉
```

**Usage:** Repository just selected in current session. Indicates active, fresh selection.

---

### State 3: Previously Selected

| Property | Value |
|----------|-------|
| **Icon** | `Icons.check_circle` |
| **Weight** | Bold (700) |
| **Color** | `accentPrimary` (#FF5500) |
| **Opacity** | 100% |
| **Size** | 24dp |

**Visual:**
```
◉ (bold stroke)
```

**Usage:** Repository was selected in prior session. Visual weight indicates established state.

---

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| `accentPrimary` | `#FF5500` | Signal Orange — selected states |
| `textSecondary` | `#9E9E9E` | Grey — unchecked state |
| `surface` | `#FFFFFF` | Background |

**Dark Mode Adjustments:**
- `textSecondary` → `#B0B0B0` (increased contrast)
- `accentPrimary` → `#FF6A22` (slightly brightened for visibility)

---

## Interaction States

### Hover (Desktop)

| State | Effect |
|-------|--------|
| Unchecked | Icon color → `textSecondary` @ 80% opacity |
| Selected | Scale 1.0 → 1.1 (subtle grow) |

### Press/Touch

| State | Effect |
|-------|--------|
| All states | Scale 1.0 → 0.95 (tactile press) |
| Duration | 100ms ease-out |

### Focus (Keyboard)

| State | Effect |
|-------|--------|
| All states | Orange ring, 2dp, `accentPrimary` @ 40% opacity |
| Offset | 2dp from icon bounds |

---

## Transition Specifications

| Transition | Duration | Curve |
|------------|----------|-------|
| State change | 150ms | `Curves.easeInOut` |
| Icon swap | 120ms | `Curves.easeOut` |
| Color fade | 150ms | `Curves.easeInOut` |

---

## Layout Metrics

```
┌─────────────────────────────────────┐
│  [icon]  repo-name                  │
│   24dp   │                          │
│          └─ 16dp padding            │
│                                     │
│  Total row height: 48dp             │
│  Icon vertical center aligned       │
└─────────────────────────────────────┘
```

**Spacing:**
- Icon to text: 16dp
- Row padding (L/R): 16dp
- Row padding (T/B): 12dp

---

## Flutter Implementation Notes

### Icon Rendering

```
Unchecked:
  Icon(Icons.circle_outlined, color: textSecondary, size: 24)

Selected (New):
  Icon(Icons.check_circle, color: accentPrimary, size: 24)

Previously Selected:
  Icon(Icons.check_circle, color: accentPrimary, size: 24, weight: 700)
```

### Bold Weight Approach

Since `Icon` widget doesn't support weight directly:
- **Option A:** Use `IconTheme` with custom font variation
- **Option B:** Use two layered icons with stroke manipulation
- **Option C (Recommended):** Use `Icon(Icons.check_circle_rounded)` for bolder appearance, or custom SVG with stroke-width

---

## Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **Contrast** | Orange on white: 4.5:1 minimum (WCAG AA) |
| **Touch Target** | 48dp × 48dp minimum |
| **Screen Reader** | Semantics label: "repo-name, selected/not selected" |
| **Keyboard** | Tab navigation, Enter/Space to toggle |

---

## State Comparison Matrix

| Attribute | Unchecked | Selected (New) | Previously Selected |
|-----------|-----------|----------------|---------------------|
| Icon | `circle_outlined` | `check_circle` | `check_circle` |
| Stroke | Thin (2dp) | Regular | Bold (4dp) |
| Fill | None | None | None |
| Color | Grey | Signal Orange | Signal Orange |
| Visual Weight | Light | Medium | Heavy |

---

## Visual Reference

```
UNSELECTED          NEW SELECTED        PREVIOUSLY SELECTED
     ○                    ◉                    ◉
   grey               orange               orange
  (thin)            (regular)              (bold)

[ ] repo-alpha   [✓] repo-beta      [✓] repo-gamma
```

---

## File Deliverables for MrCleaner

1. `checkmark_states.dart` — Widget implementation
2. `icon_colors.dart` — Color token definitions
3. `checkmark_transitions.dart` — Animation curves and durations
4. `checkmark_test.dart` — Unit and widget tests

---

**Approved:** UX_AGENT  
**Date:** 2026-02-21  
**Status:** Ready for Implementation
