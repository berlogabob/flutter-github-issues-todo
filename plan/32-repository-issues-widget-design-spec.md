# Repository Issues Widget — Visual Design Specification

**Document Version:** 1.0  
**Created:** 2026-02-21  
**Status:** Ready for Implementation  
**Design System:** Industrial Minimalism  
**Platform:** Flutter (Pure, no external UI packages)

---

## 1. Overview

The Repository Issues Widget is a collapsible card component that displays GitHub repository issues in a compact, scannable format. It follows the industrial-minimalist design language: spatial logic, tactile feedback, monochrome base with signal orange accents.

### Component Purpose
- Display repository header with issue counts
- Expand/collapse to show/hide issue list
- Provide at-a-glance issue status (open/closed/assigned)
- Enable quick navigation to issue details

### Design Principles
| Principle | Application |
|-----------|-------------|
| **Spatial Logic** | Clear hierarchy, 8px grid, consistent padding |
| **Tactile Feedback** | Spring animations, press states, elevation changes |
| **Monochrome Base** | Black/white/gray foundation |
| **Signal Orange** | Interactive elements, status indicators, accents |

---

## 2. Color System

### 2.1 Base Palette (Monochrome)

```
┌────────────────────────────────────────────────────────────┐
│  LIGHT THEME                                               │
├────────────────────────────────────────────────────────────┤
│  Background    ██████████ #FFFFFF                          │
│  Surface       ██████████ #F5F5F7                          │
│  Card          ██████████ #FFFFFF                          │
│  Border        ██████████ #E1E1E1                          │
│  Primary Text  ██████████ #000000                          │
│  Secondary     ██████████ #6E6E73                          │
│  Tertiary      ██████████ #8E8E93                          │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  DARK THEME                                                │
├────────────────────────────────────────────────────────────┤
│  Background    ██████████ #000000                          │
│  Surface       ██████████ #1C1C1E                          │
│  Card          ██████████ #2C2C2E                          │
│  Border        ██████████ #3A3A3C                          │
│  Primary Text  ██████████ #FFFFFF                          │
│  Secondary     ██████████ #98989D                          │
│  Tertiary      ██████████ #636366                          │
└────────────────────────────────────────────────────────────┘
```

### 2.2 Status Colors (GitHub Native)

```
┌────────────────────────────────────────────────────────────┐
│  ISSUE STATUS                                              │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  OPEN                                                      │
│  ● Dot     ██████████ #238636  (GitHub green)              │
│  Hover     ██████████ #2EA043                              │
│  Pressed   ██████████ #1C6E2C                              │
│                                                            │
│  CLOSED                                                    │
│  ● Dot     ██████████ #6E7781  (GitHub grey)               │
│  ✓ Check   ██████████ #6E7781                              │
│  Hover     ██████████ #818C99                              │
│                                                            │
│  ASSIGNEE (You)                                            │
│  @you      ██████████ #FF5500  (Signal orange highlight)   │
│  @other    ██████████ #6E7781  (Secondary grey)            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 2.3 Accent Colors (Signal Orange)

```
┌────────────────────────────────────────────────────────────┐
│  SIGNAL ORANGE ACCENTS                                     │
├────────────────────────────────────────────────────────────┤
│  Primary     ██████████ #FF5500                            │
│  Hover       ██████████ #FF6A22                            │
│  Pressed     ██████████ #CC4400                            │
│  Subtle 10%  ██████████ 0x1AFF5500 (overlay)               │
│  Subtle 20%  ██████████ 0x33FF5500 (overlay)               │
└────────────────────────────────────────────────────────────┘
```

### 2.4 Label Priority Colors

```
┌────────────────────────────────────────────────────────────┐
│  PRIORITY LABELS                                           │
├────────────────────────────────────────────────────────────┤
│  bug       ██████████ #D73A49  (Red)                       │
│  high      ██████████ #D73A49  (Red)                       │
│  medium    ██████████ #D9A404  (Yellow)                    │
│  low       ██████████ #0366D6  (Blue)                      │
│  enhanc.   ██████████ #0075CA  (Blue)                      │
│  docs      ██████████ #0075CA  (Blue)                      │
│  default   ██████████ #6E7781  (Grey)                      │
└────────────────────────────────────────────────────────────┘
```

---

## 3. Typography System

### 3.1 Font Families

```
Primary UI Font:    Inter (system default fallback)
Monospace Font:     JetBrains Mono / SF Mono / monospace
```

### 3.2 Type Scale

```
┌────────────────────────────────────────────────────────────┐
│  TEXT STYLES                                               │
├──────────────┬──────────┬──────────┬───────────────────────┤
│  Style       │  Size    │  Weight  │  Usage                │
├──────────────┼──────────┼──────────┼───────────────────────┤
│  headlineS   │  16px    │  600     │  Repo name (header)   │
│  body        │  14px    │  400     │  Issue title          │
│  mono        │  13px    │  400     │  Issue #numbers       │
│  label       │  12px    │  500     │  Labels, time         │
│  caption     │  11px    │  400     │  Metadata             │
└──────────────┴──────────┴──────────┴───────────────────────┘
```

### 3.3 Line Heights & Letter Spacing

```
┌────────────────────────────────────────────────────────────┐
│  LINE METRICS                                              │
├──────────────┬──────────────────┬──────────────────────────┤
│  Style       │  Line Height     │  Letter Spacing          │
├──────────────┼──────────────────┼──────────────────────────┤
│  headlineS   │  24px (1.5)      │  -0.2px                  │
│  body        │  20px (1.43)     │  0px                     │
│  mono        │  20px (1.54)     │  0px                     │
│  label       │  16px (1.33)     │  0.2px                   │
│  caption     │  14px (1.27)     │  0.2px                   │
└──────────────┴──────────────────┴──────────────────────────┘
```

---

## 4. Spacing System (8px Grid)

### 4.1 Base Spacing Tokens

```
┌────────────────────────────────────────────────────────────┐
│  SPACING TOKENS                                            │
├────────┬──────────┬────────────────────────────────────────┤
│  Token │  Value   │  Usage                                 │
├────────┼──────────┼────────────────────────────────────────┤
│  xs    │  4px     │  Tight inline spacing                  │
│  sm    │  8px     │  Small gaps, icon padding              │
│  md    │  16px    │  Standard card padding                 │
│  lg    │  24px    │  Section spacing                       │
│  xl    │  32px    │  Large gaps                            │
└────────┴──────────┴────────────────────────────────────────┘
```

### 4.2 Component Spacing

```
┌────────────────────────────────────────────────────────────┐
│  CARD SPACING                                              │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │ ← md (16px) →                                     │   │
│  │ ┌──────────────────────────────────────────────┐   │   │
│  │ │ ↑                                            │   │   │
│  │ │ md                                           │   │   │
│  │ │ (16px)  Content Area                         │   │   │
│  │ │                                              │   │   │
│  │ │ ↓                                            │   │   │
│  │ │ md                                           │   │   │
│  │ │ (16px)                                       │   │   │
│  │ └──────────────────────────────────────────────┘   │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Border Radius: 8px                                        │
│  Border Width: 1px                                         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 4.3 Issue Row Spacing

```
┌────────────────────────────────────────────────────────────┐
│  ISSUE ROW LAYOUT                                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  #187  Fix login crash...   ● bug   2h                     │
│  ││││  ││││││││││││││││   │││││  │││││                    │
│  ││││  ││││││││││││││││   │││││  └─ sm (8px) ──┘          │
│  ││││  ││││││││││││││││   │││││││                         │
│  ││││  ││││││││││││││││   └─ sm (8px) ──┘                 │
│  ││││  │││││││││││││││││││││││││                          │
│  ││││  └────── flex (expand) ──────┘                       │
│  ││││││││││││││││││││││││││││││││││││││││││││││││││││││││││
│  ││││  └──── sm (8px) ────┘││││││││││││││││││││││││││││││││
│  ││││││││││││││││││││││││││││││││││││││││││││││││││││││││││
│  └─ sm (8px) ─┘││││││││││││││││││││││││││││││││││││││││││││
│                ││││││││││││││││││││││││││││││││││││││││││││
│  Row Height: 40px (minimum)                                 │
│  Row Padding: 0 16px (vertical 0, horizontal 16px)          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 5. Elevation & Shadows

### 5.1 Z-Axis Levels

```
┌────────────────────────────────────────────────────────────┐
│  ELEVATION SYSTEM                                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Z0 - Base                                                 │
│  ─────────────────────────────────────────────────────     │
│  Light:  none                                              │
│  Dark:   none                                              │
│  Usage:  Background surfaces                               │
│                                                            │
│  Z1 - Collapsed Card                                       │
│  ─────────────────────────────────────────────────────     │
│  Light:  0 1px 2px rgba(0, 0, 0, 0.08)                     │
│  Dark:   0 1px 2px rgba(0, 0, 0, 0.3)                      │
│  Usage:  Collapsed repository card                         │
│                                                            │
│  Z2 - Expanded Card                                        │
│  ─────────────────────────────────────────────────────     │
│  Light:  0 2px 4px rgba(0, 0, 0, 0.08)                     │
│  Dark:   0 2px 4px rgba(0, 0, 0, 0.3)                      │
│  Usage:  Expanded repository card                          │
│                                                            │
│  Z3 - Floating Elements                                    │
│  ─────────────────────────────────────────────────────     │
│  Light:  0 4px 8px rgba(0, 0, 0, 0.12)                     │
│  Dark:   0 4px 8px rgba(0, 0, 0, 0.4)                      │
│  Usage:  Dropdowns, popovers                               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 5.2 Elevation Transition

```
┌────────────────────────────────────────────────────────────┐
│  COLLAPSE/EXPAND ANIMATION                                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  COLLAPSED (Z1)              EXPANDED (Z2)                 │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │                    │      │                    │        │
│  │  Repo Header       │  →   │  Repo Header       │        │
│  │  o 12  x 43 ...    │      ├────────────────────┤        │
│  │                    │      │  #187 Issue 1      │        │
│  └────────────────────┘      │  #186 Issue 2      │        │
│      ↑                       │  #185 Issue 3      │        │
│      │                       └────────────────────┘        │
│  Spring Animation                                            │
│  stiffness: 400                                              │
│  damping: 20                                                 │
│  mass: 1                                                     │
│  duration: ~300ms                                            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 6. Component States

### 6.1 Collapsed State

```
┌────────────────────────────────────────────────────────────┐
│  COLLAPSED STATE                                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  berlogabob/ToDo                          [▼]       │ │
│  │                                                      │ │
│  │  ● 12    ✓ 43    ⚑ 12    @ 23                       │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Dimensions:                                               │
│  ─────────────────────────────────────────────────────     │
│  Width:      fill_parent (card margins: 16px sides)        │
│  Height:     72px (fixed)                                  │
│  Padding:    16px all sides                                │
│  Radius:     8px                                           │
│  Border:     1px solid #E1E1E1 (light) / #3A3A3C (dark)    │
│  Elevation:  Z1                                            │
│                                                            │
│  Content Layout:                                           │
│  ─────────────────────────────────────────────────────     │
│  Row 1: Repository name (left) + Chevron (right)           │
│  Row 2: Issue counts (4 metrics, evenly spaced)            │
│                                                            │
│  Interactive:                                              │
│  ─────────────────────────────────────────────────────     │
│  - Tap anywhere → Expand                                   │
│  - Press state: Background #F5F5F7 (light) / #3A3A3C (dark)│
│  - Scale: 0.98 on press                                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 6.2 Expanded State

```
┌────────────────────────────────────────────────────────────┐
│  EXPANDED STATE                                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  berlogabob/ToDo                          [▲]       │ │
│  │                                                      │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │                                                      │ │
│  │  #187  Fix login crash...    ● bug       2h         │ │
│  │                                                      │ │
│  │  #186  Update docs           ✓           5d         │ │
│  │                                                      │ │
│  │  #185  Add feature           ● high      @you       │ │
│  │                                                      │ │
│  │  #184  Refactor module       ● medium    1w         │ │
│  │                                                      │ │
│  │  #183  Write tests           ✓           2w         │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Dimensions:                                               │
│  ─────────────────────────────────────────────────────     │
│  Width:      fill_parent                                   │
│  Height:     auto (header 72px + divider 1px + rows)       │
│  Max Rows:   5 (scroll if more)                            │
│  Padding:    16px all sides                                │
│  Radius:     8px                                           │
│  Border:     1px solid #E1E1E1 (light) / #3A3A3C (dark)    │
│  Elevation:  Z2                                            │
│                                                            │
│  Divider:                                                  │
│  ─────────────────────────────────────────────────────     │
│  Height:     1px                                           │
│  Color:      #E1E1E1 (light) / #3A3A3C (dark)              │
│  Margin:     0 16px (full width minus padding)             │
│                                                            │
│  Interactive:                                              │
│  ─────────────────────────────────────────────────────     │
│  - Tap header → Collapse                                   │
│  - Tap issue row → Navigate to issue detail                │
│  - Press state on rows: Background #F5F5F7 / #3A3A3C       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 6.3 Issue Row Anatomy

```
┌────────────────────────────────────────────────────────────┐
│  ISSUE ROW ANATOMY                                         │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  #187  Fix login crash...    ● bug       2h         │ │
│  │  ││││  ││││││││││││││││││  ││││││││    ││││         │ │
│  │  ││││  ││││││││││││││││││  ││││││││    └─ Time      │ │
│  │  ││││  ││││││││││││││││││  ││││││││││││││││         │ │
│  │  ││││  ││││││││││││││││││  │││││││└─ Label         │ │
│  │  ││││  ││││││││││││││││││  │││││└─ Status          │ │
│  │  ││││  │││││││││││││││││││││││││││││││││││││││││││││││
│  │  ││││  │││││││││││││││││││││││││││││││││││││││││││││││
│  │  ││││  └────── Title (flex, truncate) ──────┘       │ │
│  │  │││││││││││││││││││││││││││││││││││││││││││││││││││││
│  │  └─ Issue Number (mono)                              │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Column Widths:                                            │
│  ─────────────────────────────────────────────────────     │
│  Issue #:      48px (fixed, mono)                          │
│  Title:        flex (expand, truncate with ellipsis)       │
│  Status:       32px (fixed, icon)                          │
│  Label:        auto (max 80px, truncate)                   │
│  Time/Assign:  auto (max 60px, truncate)                   │
│                                                            │
│  Row Height:   40px (minimum)                              │
│  Row Padding:  8px vertical, 16px horizontal               │
│  Tap Target:   48px minimum (includes padding)             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 7. Status Indicators

### 7.1 Open Issue

```
┌────────────────────────────────────────────────────────────┐
│  OPEN ISSUE INDICATOR                                      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Visual:                                                   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    ●  bug                                         │   │
│  │    ↑                                               │   │
│  │    │  Circle, 8px diameter                         │   │
│  │    │  Fill: #238636 (GitHub green)                 │   │
│  │    │  No stroke                                    │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  States:                                                   │
│  ─────────────────────────────────────────────────────     │
│  Default:  ● #238636                                       │
│  Hover:    ● #2EA043                                       │
│  Pressed:  ● #1C6E2C (scale 0.9)                           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 7.2 Closed Issue

```
┌────────────────────────────────────────────────────────────┐
│  CLOSED ISSUE INDICATOR                                    │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Visual (Option A - Checkmark):                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    ✓                                              │   │
│  │    ↑                                               │   │
│  │    │  Checkmark icon, 14px                         │   │
│  │    │  Stroke: #6E7781 (GitHub grey)                │   │
│  │    │  Stroke width: 2px                            │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Visual (Option B - Grey Dot):                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    ●                                              │   │
│  │    ↑                                               │   │
│  │    │  Circle, 8px diameter                         │   │
│  │    │  Fill: #6E7781 (GitHub grey)                  │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Recommendation: Use checkmark (✓) for closed issues       │
│  to provide clear visual distinction from open (●)         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 7.3 Assignee Indicator

```
┌────────────────────────────────────────────────────────────┐
│  ASSIGNEE INDICATOR                                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Assigned to Current User (@you):                          │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    @you                                            │   │
│  │    ││││                                            │   │
│  │    ││││  Font: Inter Medium, 12px                  │   │
│  │    ││││  Color: #FF5500 (Signal orange)            │   │
│  │    ││││  Background: 0x1AFF5500 (10% orange)       │   │
│  │    ││││  Padding: 4px 8px                          │   │
│  │    ││││  Radius: 4px                               │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Assigned to Other User:                                   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    @berloga                                        │   │
│  │    ││││││││                                        │   │
│  │    ││││││││  Font: Inter Regular, 12px             │   │
│  │    ││││││││  Color: #6E7781 (Secondary grey)       │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Unassigned:                                               │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │    (empty - no indicator shown)                    │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 8. Label Styles

### 8.1 Label Badge

```
┌────────────────────────────────────────────────────────────┐
│  LABEL BADGE SPECIFICATION                                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │                                                    │   │
│  │  ┌─────┐  ┌────────┐  ┌──────┐  ┌─────┐          │   │
│  │  │ bug │  │  high  │  │ docs │  │ low │          │   │
│  │  └─────┘  └────────┘  └──────┘  └─────┘          │   │
│  │                                                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Dimensions:                                               │
│  ─────────────────────────────────────────────────────     │
│  Min Width:    32px                                        │
│  Height:       20px                                        │
│  Padding:      4px 8px (vertical, horizontal)              │
│  Radius:       4px (full rounded corners)                  │
│  Font:         Inter Medium, 11px                          │
│  Line Height:  14px                                        │
│                                                            │
│  Colors by Label Type:                                     │
│  ─────────────────────────────────────────────────────     │
│  bug:        bg #FFEBE9, text #D73A49 (red family)         │
│  high:       bg #FFEBE9, text #D73A49 (red family)         │
│  medium:     bg #FFF8C5, text #D9A404 (yellow family)      │
│  low:        bg #DBEDFF, text #0366D6 (blue family)        │
│  docs:       bg #DBEDFF, text #0075CA (blue family)        │
│  enhancement:bg #DBEDFF, text #0075CA (blue family)        │
│  default:    bg #F6F8FA, text #6E7781 (grey family)        │
│                                                            │
│  Dark Theme Adjustments:                                   │
│  ─────────────────────────────────────────────────────     │
│  Increase background saturation by 15%                     │
│  Ensure WCAG AA contrast (4.5:1 minimum)                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 9. Time Display

### 9.1 Relative Time Format

```
┌────────────────────────────────────────────────────────────┐
│  RELATIVE TIME FORMATTING                                  │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Format Rules:                                             │
│  ─────────────────────────────────────────────────────     │
│  < 1 hour:     "{m}m"     (e.g., "45m")                    │
│  < 24 hours:   "{h}h"     (e.g., "2h", "12h")              │
│  < 7 days:     "{d}d"     (e.g., "3d", "5d")               │
│  < 4 weeks:    "{w}w"     (e.g., "2w", "3w")               │
│  >= 4 weeks:   "{M}mo"    (e.g., "2mo", "6mo")             │
│  >= 1 year:    "{y}y"     (e.g., "1y", "2y")               │
│                                                            │
│  Typography:                                               │
│  ─────────────────────────────────────────────────────     │
│  Font:         Inter Medium, 12px                          │
│  Color:        #6E7781 (Secondary)                         │
│  Monospace:    No (use proportional for time)              │
│                                                            │
│  Examples:                                                 │
│  ─────────────────────────────────────────────────────     │
│  30 minutes ago    →  "30m"                                │
│  2 hours ago       →  "2h"                                 │
│  5 days ago        →  "5d"                                 │
│  3 weeks ago       →  "3w"                                 │
│  2 months ago      →  "2mo"                                │
│  1 year ago        →  "1y"                                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 10. Animations & Interactions

### 10.1 Expand/Collapse Animation

```
┌────────────────────────────────────────────────────────────┐
│  EXPAND/COLLAPSE SPRING ANIMATION                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Physics:                                                  │
│  ─────────────────────────────────────────────────────     │
│  Type:         Spring                                      │
│  Stiffness:    400                                         │
│  Damping:      20                                          │
│  Mass:         1                                           │
│  Duration:     ~300ms (varies by distance)                 │
│                                                            │
│  Animated Properties:                                      │
│  ─────────────────────────────────────────────────────     │
│  1. Card Height: 72px → auto (content height)              │
│  2. Icon Rotation: 0° → 180° (chevron)                     │
│  3. Elevation:     Z1 → Z2                                 │
│  4. Opacity:       1 → 1 (issue rows fade in)              │
│                                                            │
│  Sequence:                                                 │
│  ─────────────────────────────────────────────────────     │
│  1. Tap detected                                           │
│  2. Spring animation starts                                │
│  3. Height expands first (leading edge)                    │
│  4. Icon rotates in parallel                               │
│  5. Issue rows fade in with 50ms stagger delay             │
│  6. Elevation increases on completion                      │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 10.2 Press Feedback

```
┌────────────────────────────────────────────────────────────┐
│  PRESS STATE FEEDBACK                                      │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Card Press (Collapsed/Expanded Header):                   │
│  ─────────────────────────────────────────────────────     │
│  Scale:        0.98                                        │
│  Background:   #F5F5F7 (light) / #3A3A3C (dark)            │
│  Duration:     100ms (fast spring)                         │
│                                                            │
│  Issue Row Press:                                          │
│  ─────────────────────────────────────────────────────     │
│  Background:   #F5F5F7 (light) / #3A3A3C (dark)            │
│  Scale:        1.0 (no scale, background only)             │
│  Duration:     100ms                                       │
│                                                            │
│  Chevron Icon Press:                                       │
│  ─────────────────────────────────────────────────────     │
│  Scale:        0.9                                         │
│  Color:        #FF5500 (signal orange)                     │
│  Duration:     100ms                                       │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 10.3 Icon Rotation

```
┌────────────────────────────────────────────────────────────┐
│  CHEVRON ICON ROTATION                                     │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  COLLAPSED                 EXPANDED                        │
│  ┌────────────┐            ┌────────────┐                 │
│  │            │            │            │                 │
│  │     ▼      │    ──→     │     ▲      │                 │
│  │   (0°)     │            │   (180°)   │                 │
│  │            │            │            │                 │
│  └────────────┘            └────────────┘                 │
│                                                            │
│  Animation:                                                │
│  ─────────────────────────────────────────────────────     │
│  Type:         Tween (0° → 180°)                           │
│  Curve:        EaseInOut                                   │
│  Duration:     250ms                                       │
│  Icon Size:    20px × 20px                                 │
│  Color:        #6E7781 (secondary)                         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 11. Accessibility

### 11.1 Touch Targets

```
┌────────────────────────────────────────────────────────────┐
│  TOUCH TARGET REQUIREMENTS                                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Minimum Tap Target: 48px × 48px                           │
│                                                            │
│  Card Header:                                              │
│  ─────────────────────────────────────────────────────     │
│  Visual Height:  72px                                      │
│  Tap Height:     72px (full header)                        │
│  Tap Width:      fill_parent                               │
│  Status:         ✅ Passes (exceeds 48px)                  │
│                                                            │
│  Issue Row:                                                │
│  ─────────────────────────────────────────────────────     │
│  Visual Height:  40px                                      │
│  Tap Height:     48px (includes 4px padding top/bottom)    │
│  Tap Width:      fill_parent                               │
│  Status:         ✅ Passes (with padding)                  │
│                                                            │
│  Chevron Icon:                                             │
│  ─────────────────────────────────────────────────────     │
│  Visual Size:    20px × 20px                               │
│  Tap Size:       48px × 48px (invisible padding)           │
│  Status:         ✅ Passes (with padding)                  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 11.2 Color Contrast

```
┌────────────────────────────────────────────────────────────┐
│  WCAG CONTRAST REQUIREMENTS                                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Text on Background:                                       │
│  ─────────────────────────────────────────────────────     │
│  Primary Text:   #000000 on #FFFFFF = 21:1 ✅ AAA          │
│  Primary Text:   #FFFFFF on #000000 = 21:1 ✅ AAA          │
│  Secondary Text: #6E7781 on #FFFFFF = 5.2:1 ✅ AA          │
│  Secondary Text: #98989D on #1C1C1E = 5.8:1 ✅ AA          │
│                                                            │
│  Status Indicators:                                        │
│  ─────────────────────────────────────────────────────     │
│  Open Green:   #238636 on #FFFFFF = 4.6:1 ⚠️ AA (large)    │
│  Closed Grey:  #6E7781 on #FFFFFF = 5.2:1 ✅ AA            │
│  Signal Orange:#FF5500 on #FFFFFF = 3.0:1 ⚠️ AA (large)    │
│                                                            │
│  Note: Status indicators are decorative (icons + text)     │
│  The accompanying text provides the semantic meaning.      │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 11.3 Screen Reader Support

```
┌────────────────────────────────────────────────────────────┐
│  SEMANTIC LABELS                                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Card Header:                                              │
│  ─────────────────────────────────────────────────────     │
│  Label: "Repository {owner}/{name}. {open} open,           │
│          {closed} closed. Tap to expand."                  │
│                                                            │
│  Issue Row:                                                │
│  ─────────────────────────────────────────────────────     │
│  Label: "Issue {number}: {title}. {status}.                │
│          {label}. {time}."                                 │
│  Example: "Issue 187: Fix login crash. Open.               │
│            Bug label. 2 hours ago."                        │
│                                                            │
│  Chevron Button:                                           │
│  ─────────────────────────────────────────────────────     │
│  Label (collapsed): "Expand"                               │
│  Label (expanded):  "Collapse"                             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 12. Edge Cases & Variations

### 12.1 Empty States

```
┌────────────────────────────────────────────────────────────┐
│  NO ISSUES STATE                                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  berlogabob/ToDo                          [▲]       │ │
│  │                                                      │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │                                                      │ │
│  │                                                      │ │
│  │              No issues                               │ │
│  │                                                      │ │
│  │         All caught up! 🎉                            │ │
│  │                                                      │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Typography:                                               │
│  ─────────────────────────────────────────────────────     │
│  "No issues":    Inter Medium, 14px, #6E7781               │
│  Subtitle:       Inter Regular, 12px, #8E8E93              │
│                                                            │
│  Spacing:                                                  │
│  ─────────────────────────────────────────────────────     │
│  Padding:        32px vertical                             │
│  Icon (if used): 48px × 48px                               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 12.2 Loading State

```
┌────────────────────────────────────────────────────────────┐
│  LOADING STATE                                             │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  berlogabob/ToDo                          [▼]       │ │
│  │                                                      │ │
│  │  ────────  ────────  ────────  ────────              │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Skeleton Loading:                                         │
│  ─────────────────────────────────────────────────────     │
│  Bar Height:   12px                                        │
│  Bar Radius:   4px                                         │
│  Bar Color:    #E1E1E1 (light) / #3A3A3C (dark)            │
│  Animation:    Shimmer (left → right, 1.5s loop)           │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 12.3 Error State

```
┌────────────────────────────────────────────────────────────┐
│  ERROR STATE                                               │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                                                      │ │
│  │  berlogabob/ToDo                          [▼]       │ │
│  │                                                      │ │
│  │  ⚠️  Failed to load issues                           │ │
│  │                                                      │ │
│  │  [Retry]                                             │ │
│  │                                                      │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Typography:                                               │
│  ─────────────────────────────────────────────────────     │
│  Icon:         20px × 20px, #D73A49 (error red)            │
│  Message:      Inter Regular, 14px, #D73A49                │
│  Retry Button: Inter Medium, 14px, #FF5500                 │
│                                                            │
│  Retry Button:                                             │
│  ─────────────────────────────────────────────────────     │
│  Style:        Text button (no background)                 │
│  Padding:      8px 16px                                    │
│  Press State:  Background #F5F5F7 / #3A3A3C                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 12.4 Long Title Truncation

```
┌────────────────────────────────────────────────────────────┐
│  TITLE TRUNCATION                                          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Short Title (No Truncation):                              │
│  ┌────────────────────────────────────────────────────┐   │
│  │  #187  Fix login crash    ● bug    2h             │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Long Title (Truncated):                                   │
│  ┌────────────────────────────────────────────────────┐   │
│  │  #187  Fix login crash on iOS 17 when...  ● bug 2h│   │
│  │        ↑                                           │   │
│  │        └─ Ellipsis after ~28 characters            │   │
│  └────────────────────────────────────────────────────┘   │
│                                                            │
│  Implementation:                                           │
│  ─────────────────────────────────────────────────────     │
│  Max Lines:    1                                           │
│  Overflow:     TextOverflow.ellipsis                       │
│  Min Width:    120px (for title before truncation)         │
│  Tooltip:      Show full title on long press               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 12.5 Many Issues (Scrolling)

```
┌────────────────────────────────────────────────────────────┐
│  SCROLLING BEHAVIOR (6+ ISSUES)                            │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  berlogabob/ToDo                          [▲]       │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │  #187  Fix login crash...    ● bug       2h         │ │
│  │  #186  Update docs           ✓           5d         │ │
│  │  #185  Add feature           ● high      @you       │ │
│  │  #184  Refactor module       ● medium    1w         │ │
│  │  #183  Write tests           ✓           2w         │ │
│  │  #182  Deploy pipeline       ● low       3w         │ │
│  │  ... (scrollable)                                    │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  Max Visible Rows: 5                                       │
│  Scroll:       Vertical (single axis)                      │
│  Scrollbar:    Thin, auto-hide (Flutter default)           │
│  Physics:      ClampingScrollPhysics (no bounce)           │
│                                                            │
│  Container Height:                                         │
│  ─────────────────────────────────────────────────────     │
│  Header:       72px                                        │
│  Divider:      1px                                         │
│  Issues:       5 × 40px = 200px                            │
│  Total:        273px maximum                               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## 13. Implementation Notes

### 13.1 Widget Structure

```
RepositoryIssuesWidget (StatefulWidget)
├── Card (container with elevation, border, radius)
│   └── InkWell (tap handling, splash)
│       └── Column
│           ├── _buildHeader()
│           │   ├── Row
│           │   │   ├── Text (repo name)
│           │   │   └── RotationTransition (chevron)
│           │   └── Row (issue counts)
│           │       ├── _buildCountChip() × 4
│           ├── Divider (conditional)
│           └── _buildIssueList() (conditional, animated)
│               └── ListView.builder (clipped, 5 max)
│                   └── _buildIssueRow()
│                       ├── Row
│                       │   ├── Text (issue #, mono)
│                       │   ├── Text (title, flex, overflow)
│                       │   ├── _buildStatusIcon()
│                       │   ├── _buildLabelChip()
│                       │   └── _buildMetaChip() (time/assignee)
```

### 13.2 Data Model

```dart
class RepositoryIssuesWidgetData {
  final String owner;
  final String repo;
  final bool isExpanded;
  final int openCount;
  final int closedCount;
  final int labeledCount;
  final int assignedCount;
  final List<IssueRowData> issues;
}

class IssueRowData {
  final int number;
  final String title;
  final bool isOpen;
  final String? label;
  final String? assignee;
  final DateTime updatedAt;
  final bool isAssigneeCurrentUser;
}
```

### 13.3 Dependencies

```
Required Flutter Packages:
├── flutter (SDK)
├── intl (for relative time formatting)
└── provider (state management, optional)

No External UI Packages:
└── Pure Flutter widgets only (Material/Cupertino)
```

---

## 14. Visual Reference Summary

### 14.1 Complete Component Mockup

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  LIGHT THEME - COLLAPSED                                    │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                                                       │ │
│  │  berlogabob/ToDo                            ▼        │ │
│  │                                                       │ │
│  │  ● 12      ✓ 43      ⚑ 12      @ 23                  │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  LIGHT THEME - EXPANDED                                     │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                                                       │ │
│  │  berlogabob/ToDo                            ▲        │ │
│  │                                                       │ │
│  ├───────────────────────────────────────────────────────┤ │
│  │                                                       │ │
│  │  #187  Fix login crash on iOS...   ● bug       2h    │ │
│  │                                                       │ │
│  │  #186  Update documentation        ✓           5d    │ │
│  │                                                       │ │
│  │  #185  Add new feature             ● high    @you    │ │
│  │                                                       │ │
│  │  #184  Refactor auth module        ● medium    1w    │ │
│  │                                                       │ │
│  │  #183  Write unit tests            ✓           2w    │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 14.2 Color Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│  COLOR PALETTE SWATCHES                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  MONOCHROME BASE                                            │
│  ██████ #000000  Pure Black                                 │
│  ██████ #FFFFFF  Pure White                                 │
│  ██████ #F5F5F7  Light Gray (Surface)                       │
│  ██████ #1C1C1E  Dark Gray (Surface)                        │
│  ██████ #E1E1E1  Border Light                               │
│  ██████ #3A3A3C  Border Dark                                │
│  ██████ #6E7781  Secondary Text                             │
│  ██████ #8E8E93  Tertiary Text                              │
│                                                             │
│  STATUS COLORS                                              │
│  ██████ #238636  Open (Green)                               │
│  ██████ #6E7781  Closed (Grey)                              │
│                                                             │
│  SIGNAL ORANGE ACCENT                                       │
│  ██████ #FF5500  Primary Accent                             │
│  ██████ #FF6A22  Hover                                      │
│  ██████ #CC4400  Pressed                                    │
│                                                             │
│  LABEL COLORS                                               │
│  ██████ #D73A49  Bug/High                                   │
│  ██████ #D9A404  Medium                                     │
│  ██████ #0366D6  Low                                        │
│  ██████ #0075CA  Docs/Enhancement                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 15. Checklist for Implementation

### Pre-Implementation
- [ ] Review all color values against design tokens
- [ ] Confirm typography availability (Inter, JetBrains Mono)
- [ ] Set up 8px spacing constants
- [ ] Define spring animation physics

### Component Build
- [ ] Create RepositoryIssuesWidget StatefulWidget
- [ ] Implement collapsed state layout
- [ ] Implement expanded state layout
- [ ] Add expand/collapse animation
- [ ] Build issue row component
- [ ] Add status indicators (open/closed)
- [ ] Add label badges
- [ ] Add time/assignee metadata
- [ ] Implement scrolling for 6+ issues

### States & Edge Cases
- [ ] Empty state (no issues)
- [ ] Loading state (skeleton)
- [ ] Error state (with retry)
- [ ] Long title truncation
- [ ] Dark theme support

### Accessibility
- [ ] Touch targets ≥ 48px
- [ ] Semantic labels for screen readers
- [ ] Color contrast verification
- [ ] Keyboard navigation (if applicable)

### Testing
- [ ] Visual regression tests
- [ ] Animation smoothness (60fps)
- [ ] Dark/light theme switching
- [ ] Various issue counts (0, 1, 5, 10+)
- [ ] Long title edge cases

---

**End of Specification**

*Industrial Minimalism — Spatial Logic · Tactile Feedback · Monochrome Base · Signal Orange*
