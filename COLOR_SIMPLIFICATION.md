# Color Palette Simplification

**Date:** March 11, 2026  
**Status:** ✅ Simplified from 19 to 12 colors

---

## 📊 Before & After

### Before: 19 Colors (Redundant)
```
background, backgroundGradientStart, backgroundGradientEnd,
cardBackground, orangePrimary, orangeLight, orangeSecondary,
red, error, blue, white, success, warning, issueOpen,
issueClosed, secondaryText, surfaceColor, borderColor, darkBackground
```

### After: 12 Colors (Clean)
```
// Backgrounds (3)
background, card, dark

// Accents (3)
primary, link, error

// Status (3)
success, warning, muted

// Text & Borders (3)
text, textSecondary, border
```

---

## 🎨 New Color Groups

### Backgrounds
| New Name | Old Names | Hex |
|----------|-----------|-----|
| `background` | background, backgroundGradientStart | `#121212` |
| `card` | cardBackground, backgroundGradientEnd | `#1E1E1E` |
| `dark` | darkBackground, surfaceColor | `#0A0A0A` |

### Accents
| New Name | Old Names | Hex |
|----------|-----------|-----|
| `primary` | orangePrimary, orangeSecondary | `#FF6200` |
| `link` | blue | `#0A84FF` |
| `error` | red, error | `#FF3B30` |

### Status
| New Name | Old Names | Hex |
|----------|-----------|-----|
| `success` | success, issueOpen | `#4CAF50` |
| `warning` | warning | `#FFC107` |
| `muted` | issueClosed | `#6E7781` |

### Text & Borders
| New Name | Old Names | Hex |
|----------|-----------|-----|
| `text` | white | `#FFFFFF` |
| `textSecondary` | secondaryText | `#A0A0A5` |
| `border` | borderColor | `#333333` |

---

## 🔄 Migration Guide

### Quick Reference

```dart
// OLD → NEW
AppColors.background → AppColors.background ✓
AppColors.cardBackground → AppColors.card
AppColors.orangePrimary → AppColors.primary
AppColors.orangeLight → AppColors.primary.withValues(alpha: 0.8)
AppColors.orangeSecondary → AppColors.primary
AppColors.red → AppColors.error
AppColors.white → AppColors.text
AppColors.secondaryText → AppColors.textSecondary
AppColors.borderColor → AppColors.border
AppColors.surfaceColor → AppColors.dark
AppColors.darkBackground → AppColors.dark
AppColors.issueOpen → AppColors.success
AppColors.issueClosed → AppColors.muted
```

### Examples

```dart
// Before
Container(
  color: AppColors.cardBackground,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.white),
  ),
)

// After
Container(
  color: AppColors.card,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.text),
  ),
)
```

```dart
// Before
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.borderColor),
    color: AppColors.orangePrimary.withValues(alpha: 0.1),
  ),
)

// After
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.border),
    color: AppColors.primary.withValues(alpha: 0.1),
  ),
)
```

---

## ✅ Benefits

### 1. **Simpler API**
- 12 colors instead of 19
- Logical grouping (backgrounds, accents, status, text/borders)
- Easier to remember and use

### 2. **Less Confusion**
- No duplicate colors (`red` = `error`)
- No near-duplicates (`orangePrimary` vs `orangeSecondary`)
- Clear naming (`text` instead of `white`)

### 3. **Better Maintainability**
- Single source of truth for each color
- Easier theme updates
- Consistent usage across the app

### 4. **Backward Compatible**
- All old names still work via `@Deprecated` getters
- No breaking changes
- Gradual migration possible

---

## 📝 Usage Examples

### Backgrounds
```dart
// Main screen background
Scaffold(backgroundColor: AppColors.background)

// Card background
Container(color: AppColors.card)

// Deep background (modals, overlays)
Container(color: AppColors.dark)
```

### Accents
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
  ),
)

// Link text
Text('Learn more', style: TextStyle(color: AppColors.link))

// Error message
Text('Error!', style: TextStyle(color: AppColors.error))
```

### Status
```dart
// Success badge
Chip(backgroundColor: AppColors.success)

// Warning icon
Icon(Icons.warning, color: AppColors.warning)

// Muted/closed state
Text('Closed', style: TextStyle(color: AppColors.muted))
```

### Text & Borders
```dart
// Primary text
Text('Title', style: TextStyle(color: AppColors.text))

// Secondary text
Text('Subtitle', style: TextStyle(color: AppColors.textSecondary))

// Border
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.border),
  ),
)
```

---

## 🔧 Automatic Migration

Run this to find old color usage:

```bash
grep -r "AppColors\." lib/ | grep -E "(orangePrimary|cardBackground|secondaryText|borderColor)"
```

### IDE Find & Replace

| Find | Replace |
|------|---------|
| `AppColors.orangePrimary` | `AppColors.primary` |
| `AppColors.cardBackground` | `AppColors.card` |
| `AppColors.secondaryText` | `AppColors.textSecondary` |
| `AppColors.borderColor` | `AppColors.border` |
| `AppColors.white` | `AppColors.text` |
| `AppColors.red` | `AppColors.error` |

---

## 📊 Color Usage Stats

| Color | Usage Count |
|-------|-------------|
| `orangePrimary` → `primary` | ~150 |
| `cardBackground` → `card` | ~80 |
| `secondaryText` → `textSecondary` | ~60 |
| `borderColor` → `border` | ~40 |
| `white` → `text` | ~30 |
| `red` → `error` | ~25 |

---

## 🎯 Next Steps

1. ✅ **Done:** Simplify color palette
2. ⏳ **Optional:** Migrate all files to new names
3. ⏳ **Optional:** Add color usage linting rules
4. ⏳ **Optional:** Create color preview widget

---

## 📚 Related Files

- `lib/constants/app_colors.dart` - Main color definitions
- `lib/constants/app_colors.dart` - Typography, spacing, borders
- `AGENTS.md` - Rules compliance (includes color checks)

---

**Reduction:** 19 → 12 colors (37% fewer)  
**Backward Compatible:** ✅ Yes, via `@Deprecated` getters  
**Breaking Changes:** ❌ None
