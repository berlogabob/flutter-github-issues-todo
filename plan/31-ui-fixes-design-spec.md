# UI Fixes Design Specification

**Document ID:** PLAN-031  
**Created:** 2026-02-21  
**Status:** Ready for Implementation  
**Assigned To:** MrCleaner  
**Priority:** P1 - High  
**Estimate:** 2-3 hours  

---

## Overview

This specification defines three UI fixes for the repository management interface in GitDoIt. All changes follow the **Industrial Minimalism** design system: spatial logic, tactile feedback, monochrome base, signal orange accents.

**Pure Flutter only** — no external packages required.

---

## 1. Repo Widget Placement

### Current State (Incorrect)

```
┌─────────────────────────────────────┐
│  GitDoIt ☁️ + 🔍              │  AppBar
├─────────────────────────────────────┤
│  Filters                           │  Filter Row
├─────────────────────────────────────┤
│  Repo Widget ❌                    │  ← WRONG POSITION
├─────────────────────────────────────┤
│  Issues List                       │
│  ┌───────────────────────────────┐ │
│  │ repo/owner                    │ │
│  │ ───────────────────────────── │ │
│  │ • Issue one                   │ │
│  │ • Issue two                   │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Target State (Correct)

```
┌─────────────────────────────────────┐
│  GitDoIt ☁️ + 🔍              │  AppBar
├─────────────────────────────────────┤
│  Filters                           │  Filter Row
├─────────────────────────────────────┤
│  Repo Widget ✅                    │  ← CORRECT POSITION
├─────────────────────────────────────┤
│  Issues List                       │
│  ┌───────────────────────────────┐ │
│  │ repo/owner                    │ │
│  │ ───────────────────────────── │ │
│  │ • Issue one                   │ │
│  │ • Issue two                   │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Spatial Logic

| Zone | Component | Vertical Order |
|------|-----------|----------------|
| 1 | AppBar | Top (fixed) |
| 2 | Filter Row | Below AppBar |
| 3 | **Repo Widget** | **Below Filters** ← NEW |
| 4 | Issues List | Below Repo Widget (expanded) |

### Implementation Notes

**File:** `lib/screens/home_screen.dart`

**Current Structure:**
```
Column
├── AppBar (via Scaffold)
├── Filter Row
├── Issues List (Expanded)
│   └── Repo Widget (inside list)
```

**Target Structure:**
```
Column
├── AppBar (via Scaffold)
├── Filter Row
├── Repo Widget ← MOVED HERE
└── Issues List (Expanded)
```

### Visual Spacing

| Element | Top Padding | Bottom Padding |
|---------|-------------|----------------|
| Filter Row | 8px (sm) | 8px (sm) |
| Repo Widget | 0 | 8px (sm) |
| Issues List | 0 | 0 |

---

## 2. Repo Widget Design

### Current State (Incorrect)

```
┌─────────────────────────────────────┐
│  ⚙️  berlogabob/flutter-github-issues-todo    🔽  │
│     12 open issues                              │
└─────────────────────────────────────┘
     ↑ Settings icon (REMOVE)
```

### Target State (Correct)

```
┌─────────────────────────────────────┐
│  berlogabob/flutter-github-issues-todo    🔽  │
│     12 open issues                              │
└─────────────────────────────────────┘
     ↑ Clean, no settings icon
```

### Design Specifications

#### Container
| Property | Value |
|----------|-------|
| Background | Surface color (lightGray/darkGray) |
| Border | 1px solid (borderLight/borderDark) |
| Border Radius | 8px |
| Padding | 12px horizontal, 10px vertical |
| Min Height | 56px |

#### Content Layout (Row)

```
┌──────────────────────────────────────────────────────┐
│ [Repo Name + Issue Count]        [Arrow Icon]        │
│  ← Flexible (expanded: true)     ← Fixed right       │
└──────────────────────────────────────────────────────┘
```

#### Typography

| Element | Style | Color (Light/Dark) |
|---------|-------|-------------------|
| Repo Name | labelLarge (14px, Medium) | Primary (#000000 / #FFFFFF) |
| Issue Count | bodySmall (12px, Regular) | Secondary (#6E6E73 / #98989D) |

#### Arrow Icon (RIGHT Side)

| Property | Value |
|----------|-------|
| Icon | `Icons.keyboard_arrow_down` or `Icons.expand_more` |
| Size | 20x20 |
| Color | Secondary text color |
| Position | Far right, vertically centered |
| Rotation | 0° (expanded) / 180° (collapsed) |

#### Tactile Feedback

| Interaction | Response |
|-------------|----------|
| Tap | Scale animation (0.98) + toggle collapse |
| Duration | 150ms (fast) |
| Curve | Spring (stiffness: 400, damping: 20) |

### Component Structure

```
RepoWidget
└── Container (surface, border, radius: 8)
    └── Padding (12h, 10v)
        └── Row
            ├── Expanded
            │   └── Column
            │       ├── Row (repo name)
            │       │   ├── Icon (repo, 16px, signalOrange)
            │       │   ├── SizedBox (4px)
            │       │   └── Text (repo name, labelLarge)
            │       └── Text (issue count, bodySmall, secondary)
            └── Icon (arrow, 20px, secondary)
```

### Files to Modify

| File | Changes |
|------|---------|
| `lib/widgets/repository_section_header.dart` | Remove settings icon, move arrow to right |
| `lib/screens/home_screen.dart` | Update widget placement |

---

## 3. + Repo Flow

### Overview

The "Add Repository" flow consists of two stages:

1. **Plus Button** → Opens selection menu
2. **Selection Menu** → Two options: SHOW MY REPOS / ADD BY URL
3. **SHOW MY REPOS** → List picker with radio selection

### Stage 1: Plus Button

#### Placement

```
┌─────────────────────────────────────────────────────┐
│  GitDoIt           [☁️]  [+]  [🔍]           │
└─────────────────────────────────────────────────────┘
                        ↑
              Between cloud and search
```

| Property | Value |
|----------|-------|
| Position | AppBar actions, index 1 (after cloud, before search) |
| Icon | `Icons.add_circle_outline` |
| Size | 24x24 |
| Color | Primary text color |
| Padding | 8px horizontal |

#### Interaction

| Action | Response |
|--------|----------|
| Tap | Open `RepoAddMenu` popup |
| Duration | 150ms fade |

---

### Stage 2: Selection Menu (RepoAddMenu)

#### Visual Structure

```
┌─────────────────────────────────────┐
│  SELECT REPO                        │  ← Header
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │  [SHOW MY REPOS]              │  │  ← Primary Button (Top)
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  [ADD BY URL]                 │  │  ← Secondary Button (Bottom)
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

#### Container

| Property | Value |
|----------|-------|
| Width | 280px (fixed) |
| Background | Surface color |
| Border | 1px solid border color |
| Border Radius | 12px |
| Padding | 16px |
| Elevation | z2 (shadow) |

#### Header

| Property | Value |
|----------|-------|
| Text | "SELECT REPO" |
| Style | labelLarge (14px, Medium) |
| Color | Secondary text |
| Padding | 0 0 16px 0 |
| Alignment | Center |

#### Buttons

**SHOW MY REPOS (Primary):**
| Property | Value |
|----------|-------|
| Background | Signal Orange (#FF5500) |
| Text Color | White (#FFFFFF) |
| Border | None |
| Border Radius | 8px |
| Padding | 16px horizontal, 12px vertical |
| Min Width | 248px (full width minus padding) |
| Min Height | 48px |

**ADD BY URL (Secondary):**
| Property | Value |
|----------|-------|
| Background | Transparent |
| Text Color | Primary text |
| Border | 1px solid border color |
| Border Radius | 8px |
| Padding | 16px horizontal, 12px vertical |
| Min Width | 248px |
| Min Height | 48px |

#### Button Spacing

| Element | Spacing |
|---------|---------|
| Header to SHOW MY REPOS | 0 |
| SHOW MY REPOS to ADD BY URL | 12px (md) |
| ADD BY URL to container edge | 0 |

#### Tactile Feedback

| Interaction | Response |
|-------------|----------|
| Hover (web) | Scale 1.02, brightness +10% |
| Press | Scale 0.96, brightness -10% |
| Duration | 150ms |
| Curve | Spring (stiffness: 400, damping: 20) |

---

### Stage 3: SHOW MY REPOS Dialog

#### Visual Structure

```
┌─────────────────────────────────────┐
│  SELECT REPO                        │  ← Header
├─────────────────────────────────────┤
│  ○  berlogabob/repo-one            │  ← Radio item
│  ◉  berlogabob/repo-two (prev)     │  ← Selected
│  ○  berlogabob/repo-three          │  ← Radio item
├─────────────────────────────────────┤
│  [Cancel]              [Add]        │  ← Action buttons
└─────────────────────────────────────┘
```

#### Container

| Property | Value |
|----------|-------|
| Width | 320px (fixed) |
| Background | Surface color |
| Border | 1px solid border color |
| Border Radius | 12px |
| Padding | 0 (header/footer have own padding) |
| Elevation | z3 (shadow) |

#### Header

| Property | Value |
|----------|-------|
| Text | "SELECT REPO" |
| Style | labelLarge (14px, Medium) |
| Color | Secondary text |
| Padding | 16px |
| Alignment | Center |
| Bottom Border | 1px solid border color |

#### Repository List

**List Item Structure:**
```
┌─────────────────────────────────────┐
│  [Radio]  [Repo Name]  [(prev)]    │
└─────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Min Height | 48px per item |
| Padding | 12px horizontal, 8px vertical |
| Background | Transparent (selected: 10% signalOrange) |

**Radio Button:**
| Property | Value |
|----------|-------|
| Size | 20x20 |
| Color (unselected) | Border color |
| Color (selected) | Signal Orange |
| Position | Left, vertically centered |

**Repo Name:**
| Property | Value |
|----------|-------|
| Style | bodyMedium (14px, Regular) |
| Color | Primary text |
| Max Lines | 1 (ellipsis) |
| Padding | 12px left, 0 right |

**"(prev)" Label:**
| Property | Value |
|----------|-------|
| Text | "(prev)" |
| Style | bodySmall (12px, Regular) |
| Color | Secondary text |
| Padding | 8px left |

#### Footer (Action Buttons)

```
┌─────────────────────────────────────┐
│  [Cancel]              [Add]        │
└─────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Padding | 16px |
| Top Border | 1px solid border color |
| Layout | Row (spaceBetween) |

**Cancel Button:**
| Property | Value |
|----------|-------|
| Background | Transparent |
| Text | "Cancel" |
| Text Color | Secondary text |
| Border | None |
| Padding | 12px 24px |

**Add Button:**
| Property | Value |
|----------|-------|
| Background | Signal Orange |
| Text | "Add" |
| Text Color | White |
| Border | None |
| Border Radius | 8px |
| Padding | 12px 24px |
| Enabled | Only when selection changed |

#### Tactile Feedback

| Interaction | Response |
|-------------|----------|
| Radio Tap | Scale 0.95 + update selection |
| List Item Tap | Toggle radio |
| Button Press | Scale 0.96 |
| Duration | 150ms |
| Curve | Spring (stiffness: 400, damping: 20) |

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        REPO ADD FLOW                            │
└─────────────────────────────────────────────────────────────────┘

    [HomeScreen]
         │
         │ Tap [+]
         ▼
┌─────────────────────────┐
│    RepoAddMenu          │
│  ┌───────────────────┐  │
│  │ [SHOW MY REPOS]   │──┼──┐
│  └───────────────────┘  │  │
│                         │  │
│  ┌───────────────────┐  │  │
│  │ [ADD BY URL]      │  │  │
│  └───────────────────┘  │  │
└─────────────────────────┘  │
         │                   │
         │                   │
         ▼                   ▼
┌─────────────────┐   ┌─────────────────┐
│ ShowMyRepos     │   │ AddByUrl        │
│ Dialog          │   │ (existing)      │
│                 │   │                 │
│ ○ repo1         │   │ [Input field]   │
│ ◉ repo2 (prev)  │   │ [Add] [Cancel]  │
│ ○ repo3         │   └─────────────────┘
│                 │
│ [Cancel] [Add]  │
└─────────────────┘
         │
         │ Tap [Add]
         ▼
    [Provider adds repo]
         │
         │ Success
         ▼
    [Snackbar: "Repo added"]
         │
         ▼
    [HomeScreen refreshes]
```

---

## Implementation Checklist

### Task 1: Repo Widget Placement
- [ ] Move RepoWidget from inside Issues List to above it
- [ ] Update home_screen.dart Column structure
- [ ] Verify spacing (8px bottom padding on widget)
- [ ] Test with 1, 2, 5+ repos

### Task 2: Repo Widget Design
- [ ] Remove settings icon from repository_section_header.dart
- [ ] Move arrow icon to right side (end of Row)
- [ ] Update arrow rotation logic (0° expanded, 180° collapsed)
- [ ] Verify tactile feedback on tap
- [ ] Test collapsed/expanded states

### Task 3: Plus Button
- [ ] Add IconButton to home_screen.dart AppBar actions
- [ ] Position between cloud icon and search
- [ ] Use `Icons.add_circle_outline`
- [ ] Wire to existing RepoAddMenu

### Task 4: RepoAddMenu Update
- [ ] Update menu container styling (280px width, rounded corners)
- [ ] Add "SELECT REPO" header
- [ ] Create SHOW MY REPOS button (primary, signalOrange)
- [ ] Create ADD BY URL button (secondary, outlined)
- [ ] Add tactile feedback (scale animation)
- [ ] Wire SHOW MY REPOS to new dialog

### Task 5: ShowMyRepos Dialog
- [ ] Create new dialog widget
- [ ] Implement radio button list
- [ ] Fetch user's repos from GitHub API
- [ ] Highlight previously added repos with "(prev)" label
- [ ] Implement Cancel/Add footer buttons
- [ ] Add validation (enable Add only on selection)
- [ ] Wire to IssuesProvider.addRepository()
- [ ] Show success/error snackbar

### Task 6: Testing
- [ ] Test flow with no repos
- [ ] Test flow with 1-3 repos
- [ ] Test flow with 10+ repos (scrolling)
- [ ] Test adding duplicate repo
- [ ] Test cancel flow
- [ ] Test offline state behavior
- [ ] Verify animations smooth (60fps)

---

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/screens/home_screen.dart` | Modify | Move RepoWidget, add Plus button |
| `lib/widgets/repository_section_header.dart` | Modify | Remove settings icon, right-align arrow |
| `lib/screens/repo_add_menu.dart` | Modify | Update menu design, add two buttons |
| `lib/screens/show_my_repos_dialog.dart` | **Create** | New dialog for repo selection |
| `lib/services/github_service.dart` | Modify | Add `listUserRepos()` if not exists |

---

## Acceptance Criteria

### Functional
- [ ] Repo widget appears below filters, above issues list
- [ ] Repo widget has no settings icon
- [ ] Arrow icon on right side of repo widget
- [ ] Plus button opens selection menu
- [ ] SHOW MY REPOS shows user's GitHub repos
- [ ] Previously added repos marked with "(prev)"
- [ ] Add button adds selected repo
- [ ] Cancel button closes dialog
- [ ] Success snackbar on add
- [ ] Home screen refreshes after add

### Visual
- [ ] All spacing follows 8px grid
- [ ] Signal orange used for primary actions only
- [ ] Monochrome base maintained
- [ ] Typography matches design tokens
- [ ] Border radius consistent (8px widgets, 12px dialogs)

### Tactile
- [ ] All buttons have press animation (scale 0.96)
- [ ] Animations complete in 150ms
- [ ] Spring physics applied (stiffness: 400, damping: 20)
- [ ] No jank during transitions

### Performance
- [ ] Dialog opens in <100ms
- [ ] Repo list renders 50+ items smoothly
- [ ] No frame drops during animations

---

## Notes for MrCleaner

1. **Start with Task 1 & 2** — These are simple relocations and visual cleanup.

2. **Use existing patterns** — Check `auth_screen.dart` for button styling, `settings_screen.dart` for dialog patterns.

3. **GitHub API** — The `listUserRepos()` method may already exist. Check `github_service.dart` before implementing.

4. **Provider integration** — Use `IssuesProvider.addRepository()` for adding repos. Do not duplicate logic.

5. **Testing** — Run on physical device if possible. Emulator animations may not reflect true performance.

6. **Ask MrTester** — Once implementation complete, request test coverage for new dialog.

---

## Related Documents

- `ToDo.md` — Project status and design system tokens
- `lib/design_tokens/` — Color, spacing, typography definitions
- `lib/theme/industrial_theme.dart` — Theme extensions

---

**End of Specification**
