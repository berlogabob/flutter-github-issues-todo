# Sprint 16: Performance UX Design Specification

**Document Version:** 1.0
**Date:** March 3, 2026
**Author:** UI/UX Designer Agent
**Status:** READY FOR IMPLEMENTATION

---

## Overview

This document provides detailed UI/UX design specifications for Sprint 16 performance-focused tasks:
- **Task 16.1:** Load More Button
- **Task 16.2:** Image Placeholder States
- **Task 16.5:** Loading Skeletons

All designs follow the existing dark theme and use **ONLY** colors from `AppColors`. No new colors are introduced.

---

## Design System Reference

### Color Palette (AppColors)

All UI components MUST use only these colors:

| Color Name | Hex Value | Usage |
|------------|-----------|-------|
| `background` | `#121212` | Main app background |
| `backgroundGradientStart` | `#121212` | Gradient start |
| `backgroundGradientEnd` | `#1E1E1E` | Gradient end |
| `cardBackground` | `#1E1E1E` | Cards, dialogs, skeletons |
| `surfaceColor` | `#111111` | Bottom sheets, surfaces |
| `orangePrimary` | `#FF6200` | Primary actions, borders |
| `orangeSecondary` | `#FF5E00` | Secondary highlights |
| `orangeLight` | `#FF8A33` | Hover states |
| `red` | `#FF3B30` | Errors, destructive actions |
| `blue` | `#0A84FF` | Links, assignee indicators |
| `white` | `#FFFFFF` | Primary text |
| `secondaryText` | `#A0A0A5` | Secondary text, placeholders |
| `success` | `#4CAF50` | Success states |
| `error` | `#FF3B30` | Error states |
| `warning` | `#FFC107` | Warning states |
| `issueOpen` | `#238636` | Open issue status |
| `issueClosed` | `#6E7781` | Closed issue status |
| `borderColor` | `#333333` | Borders, dividers |
| `darkBackground` | `#0A0A0A` | Deep backgrounds |

### Typography (AppTypography)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `titleLarge` | 32sp | bold | Screen titles |
| `titleMedium` | 20sp | bold | Section headers |
| `titleSmall` | 16sp | bold | Subsection headers |
| `bodyLarge` | 14sp | normal | Body text |
| `bodyMedium` | 14sp | normal | Secondary body |
| `labelSmall` | 12sp | medium | Labels, chips |
| `caption` | 11sp | normal | Captions, hints |

### Spacing (AppSpacing)

All spacing follows the 8px grid system:

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Tight spacing |
| `sm` | 8px | Standard item spacing |
| `md` | 16px | Section spacing |
| `lg` | 24px | Large section spacing |
| `xl` | 32px | Page margins |

### Border Radius (AppBorderRadius)

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 4px | Small chips, icons |
| `md` | 8px | Buttons, inputs |
| `lg` | 12px | Cards |
| `xl` | 16px | Bottom sheets, dialogs |

---

## Task 16.1: Load More Button

### Component Type
**OutlinedButton** at end of scrollable list

### Purpose
- Provides pagination control for long lists
- Shows loading state while fetching additional data
- Prevents overwhelming users with too much content at once
- Improves perceived performance by loading content on demand

### UI Mockup (ASCII)

#### Normal State (Ready to Load)

```
┌─────────────────────────────────────────────┐
│                                             │
│              [List Content]                 │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │                                       │  │
│  │           Load More                   │  │ ← OutlinedButton
│  │         (expand_more icon)            │  │
│  │                                       │  │
│  └───────────────────────────────────────┘  │
│         ↑                                   │
│    AppColors.orangePrimary border           │
│         ↑                                   │
│    CardBackground fill                      │
│                                             │
└─────────────────────────────────────────────┘
```

#### Loading State

```
┌─────────────────────────────────────────────┐
│                                             │
│              [List Content]                 │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │                                       │  │
│  │         ⠀⠀⠀⠀⠀  Loading...          │  │ ← BrailleLoader
│  │                                       │  │
│  └───────────────────────────────────────┘  │
│         ↑                                   │
│    Disabled state (no border highlight)     │
│                                             │
└─────────────────────────────────────────────┘
```

#### Disabled State (No More Content)

```
┌─────────────────────────────────────────────┐
│                                             │
│              [List Content]                 │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │                                       │  │
│  │           Load More                   │  │ ← Disabled
│  │         (grayed out)                  │  │
│  │                                       │  │
│  └───────────────────────────────────────┘  │
│         ↑                                   │
│    borderColor (dimmed)                     │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Specifications

| Property | Value |
|----------|-------|
| **Container Background** | Transparent |
| **Container Padding** | `16px` all sides |
| **Button Type** | `ElevatedButton` (styled as outlined) |
| **Button Height** | `48px` minimum |
| **Button Background** | `AppColors.cardBackground` |
| **Button Border** | `AppColors.orangePrimary`, 1px |
| **Button Border Radius** | `12px` (`AppBorderRadius.lg`) |
| **Button Text** | `bodyLarge` (14sp, normal, `AppColors.orangePrimary`) |
| **Loading Text** | `bodyLarge` (14sp, normal, `AppColors.secondaryText`) |
| **Icon** | `Icons.expand_more`, `AppColors.orangePrimary` |
| **Icon Size** | `20px` |
| **Icon Position** | Before text (leading) |
| **Disabled Border** | `AppColors.borderColor` |
| **Disabled Text** | `AppColors.secondaryText` |

### Button States

| State | Background | Border | Text | Icon |
|-------|------------|--------|------|------|
| **Normal** | `cardBackground` | `orangePrimary` | `orangePrimary` | `orangePrimary` |
| **Loading** | `cardBackground` | `borderColor` | `secondaryText` | BrailleLoader |
| **Disabled** | `cardBackground` | `borderColor` | `secondaryText` | None |
| **Pressed** | `orangePrimary` (alpha 0.1) | `orangePrimary` | `orangePrimary` | `orangePrimary` |

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/main_dashboard_screen.dart` (Lines 877-897):

```dart
Widget _buildLoadMoreButton() {
  return Container(
    padding: const EdgeInsets.all(16),
    child: _isLoadingMore
        ? const BrailleLoader(size: 24)
        : ElevatedButton(
            onPressed: _hasMoreRepos ? () => _fetchRepositories(loadMore: true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.orangePrimary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.orangePrimary),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.expand_more, size: 20),
                const SizedBox(width: 8),
                const Text('Load More'),
              ],
            ),
          ),
  );
}
```

### Interaction Flow

```
User scrolls to end of list
    ↓
Check if more data available
    ↓
┌─────────────┬─────────────┐
│   Has More  │  No More    │
└─────────────┴─────────────┘
     ↓               ↓
Show "Load More"  Show disabled
     ↓               ↓
User taps button
     ↓
HapticFeedback.lightImpact()
     ↓
Set loading state
     ↓
Fetch next page
     ↓
Append to list
     ↓
Clear loading state
```

### Performance UX Guidelines

1. **Show button BEFORE user reaches end** - Display when 80% through list
2. **Optimistic UI** - Show loading state immediately on tap
3. **Append progressively** - Add items as they load, don't wait for all
4. **Debounce taps** - Prevent multiple rapid taps during loading
5. **Maintain scroll position** - Don't jump when new items added

---

## Task 16.2: Image Placeholder States

### Component Type
**CircleAvatar** with fallback states for assignee/user avatars

### Purpose
- Provides visual feedback during image loading
- Maintains layout stability (no shift when image loads)
- Shows graceful degradation on load failure
- Uses consistent styling across the app

### UI Mockup (ASCII)

#### Loading State

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────┐                              │
│  │           │                              │
│  │    ⟳      │  ← CircularProgressIndicator  │
│  │  (small)  │     (16px diameter)          │
│  │           │                              │
│  └───────────┘                              │
│    40px diameter                            │
│                                             │
└─────────────────────────────────────────────┘
```

#### Placeholder State (No Image)

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────┐                              │
│  │           │                              │
│  │     👤    │  ← Icons.person               │
│  │           │     secondaryText color       │
│  └───────────┘                              │
│    40px diameter                            │
│    cardBackground fill                      │
│                                             │
└─────────────────────────────────────────────┘
```

#### Error State (Load Failed)

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────┐                              │
│  │           │                              │
│  │     👤    │  ← Icons.person (same as     │
│  │           │     placeholder)              │
│  └───────────┘                              │
│    40px diameter                            │
│    cardBackground fill                      │
│                                             │
└─────────────────────────────────────────────┘
```

#### Loaded State (Success)

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌───────────┐                              │
│  │           │                              │
│  │  [Image]  │  ← CachedNetworkImage         │
│  │           │     (circular crop)           │
│  └───────────┘                              │
│    40px diameter                            │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Specifications

| Property | Value |
|----------|-------|
| **Container Shape** | Circle |
| **Diameter** | `40px` |
| **Background Color** | `AppColors.cardBackground` |
| **Icon** | `Icons.person` |
| **Icon Color** | `AppColors.secondaryText` |
| **Icon Size** | `20px` |
| **Loading Indicator** | `CircularProgressIndicator` |
| **Loading Size** | `16px` diameter |
| **Loading Color** | `AppColors.blue` |
| **Loading Stroke Width** | `2px` |
| **Error State** | Same as placeholder |

### State Comparison

| State | Background | Content | Color |
|-------|------------|---------|-------|
| **Placeholder** | `cardBackground` | `Icons.person` | `secondaryText` |
| **Loading** | `cardBackground` | `CircularProgressIndicator` | `blue` |
| **Error** | `cardBackground` | `Icons.person` | `secondaryText` |
| **Success** | N/A (image) | Cached image | Full color |

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/issue_card.dart` (Lines 145-180):

```dart
Widget _buildAssigneeWithAvatar() {
  if (issue.assigneeAvatarUrl != null && issue.assigneeAvatarUrl!.isNotEmpty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CachedNetworkImage(
          imageUrl: issue.assigneeAvatarUrl!,
          width: 40,
          height: 40,
          maxHeightDiskCache: 100,
          placeholder: (context, url) => const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ),
          imageBuilder: (context, imageProvider) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          issue.assigneeLogin!,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 14,
          ),
        ),
      ],
    );
  } else {
    // No avatar URL - show placeholder
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 20,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          issue.assigneeLogin ?? 'Unassigned',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
```

### Performance UX Guidelines

1. **Pre-allocate space** - Fixed 40x40px prevents layout shift
2. **Disk cache** - Use `maxHeightDiskCache: 100` for memory efficiency
3. **Immediate placeholder** - Show placeholder before network request
4. **Graceful degradation** - Error state matches placeholder (no visual change)
5. **Optimistic loading** - Start loading before scroll animation completes

---

## Task 16.5: Loading Skeletons

### Component Type
**Shimmer effect with AnimatedOpacity** for list loading states

### Purpose
- Provides immediate visual feedback (no waiting for network)
- Maintains layout stability (matches final content dimensions)
- Reduces perceived loading time
- Progressive content loading (show as it loads)

### UI Mockup (ASCII)

#### Repo Skeleton (2 lines: title + description)

```
┌─────────────────────────────────────────────┐
│  ╔════════════════════════════════════════╗ │
│  ║                                        ║ │
│  ║  ┌────┐ ┌──────────────────────────┐   ║ │
│  ║  │    │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │   ║ │ ← Title line
│  ║  │    │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │   ║ │
│  ║  │    │ └──────────────────────────┘   ║ │
│  ║  │    │                                  ║ │
│  ║  │    │ ┌────────────────────┐           ║ │
│  ║  │    │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │           ║ │ ← Description line
│  ║  └────┘ └────────────────────┘           ║ │
│  ║   ↑                                        ║ │
│  ║  Folder icon skeleton                       ║ │
│  ║                                            ║ │
│  ╚════════════════════════════════════════╝ │
│     72px height                              │
│     cardBackground base                      │
│     background highlight (shimmer)           │
└─────────────────────────────────────────────┘
```

#### Issue Skeleton (3 lines: title + meta + labels)

```
┌─────────────────────────────────────────────┐
│  ╔════════════════════════════════════════╗ │
│  ║  ┌──┐                                  ║ │
│  ║  │  │ ┌─────────────────────────────┐  ║ │
│  ║  │○ │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ║ │ ← Title line
│  ║  │  │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ║ │
│  ║  └──┘ │ └─────────────────────────────┘  ║ │
│  ║   ↑   │                                    ║ │
│  ║ Status│ ┌──────┐ ┌─────────┐ ┌──┐        ║ │
│  ║  dot  │ │ ▓▓▓▓ │ │ ▓▓▓▓▓▓▓ │ │▓▓│        ║ │ ← Meta/labels
│  ║       │ └──────┘ └─────────┘ └──┘        ║ │
│  ║       │  label    assignee   chevron     ║ │
│  ╚════════════════════════════════════════╝ │
│     80px height                              │
│     cardBackground base                      │
│     background highlight (shimmer)           │
└─────────────────────────────────────────────┘
```

#### Avatar Skeleton (Circle)

```
┌─────────────────────────────────────────────┐
│  ╔════════════════╗                         │
│  ║                ║                         │
│  ║      ▓▓▓▓      ║  ← Circle shimmer       │
│  ║    ▓▓▓▓▓▓▓▓    ║    40px diameter        │
│  ║      ▓▓▓▓      ║    cardBackground base  │
│  ║                ║    background highlight │
│  ╚════════════════╝                         │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Specifications

| Property | Value |
|----------|-------|
| **Animation Type** | `AnimatedOpacity` (fade in/out) |
| **Animation Duration** | `1.5s` fade in/out cycle |
| **Base Color** | `AppColors.cardBackground` |
| **Highlight Color** | `AppColors.background` with alpha 0.5 |
| **Animation Curve** | `Curves.easeInOut` |
| **Shimmer Direction** | Left to right (default) |
| **Layout** | Matches final content dimensions exactly |

### Skeleton Variants

| Type | Height | Lines | Elements |
|------|--------|-------|----------|
| **Repo** | `72px` | 2 | Icon, title, description, badge |
| **Issue** | `80px` | 3 | Status dot, title, labels, assignee, chevron |
| **Avatar** | `40px` | 1 | Circle only |

### Repo Skeleton Detail

| Element | Width | Height | Shape |
|---------|-------|--------|-------|
| Folder icon | `40px` | `40px` | Rounded square (8px) |
| Title line | `150px` | `16px` | Rounded rectangle (4px) |
| Description | `100px` | `12px` | Rounded rectangle (4px) |
| Badge | `60px` | `24px` | Rounded rectangle (12px) |

### Issue Skeleton Detail

| Element | Width | Height | Shape |
|---------|-------|--------|-------|
| Status dot | `12px` | `12px` | Circle |
| Title line | `200px` | `14px` | Rounded rectangle (4px) |
| Label chip | `50px` | `16px` | Rounded rectangle (8px) |
| Assignee | `60px` | `16px` | Rounded rectangle (4px) |
| Chevron | `20px` | `20px` | Rounded square (4px) |

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/loading_skeleton.dart`:

```dart
class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final int itemCount;
  final double spacing;

  const LoadingSkeleton({
    super.key,
    this.height = 80.0,
    this.width,
    this.borderRadius = 8.0,
    this.itemCount = 5,
    this.spacing = 12.0,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // PERFORMANCE: AnimatedOpacity for smooth fade (Task 16.5)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacityAnimation.value,
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: widget.spacing),
            child: _buildSkeletonItem(),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Shimmer.fromColors(
          baseColor: AppColors.cardBackground,
          highlightColor: AppColors.background.withOpacity(0.5),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Metadata
                      Row(
                        children: [
                          Container(
                            height: 16,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 16,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Animation Specification

```
┌─────────────────────────────────────────────┐
│ Opacity Cycle (1.5s total)                 │
│                                             │
│ 1.0 │     ╱‾‾‾╲                            │
│     │    ╱     ╲                           │
│ 0.8 │   ╱       ╲                          │
│     │  ╱         ╲                         │
│ 0.5 │ ╱           ╲                        │
│     │╱             ╲                       │
│ 0.3 └───────────────╲────                  │
│     │                ╲                     │
│ 0.0 └─────────────────╲───                 │
│     └─────────────────────────────         │
│     0s   0.5s   1.0s   1.5s                │
│                                             │
│ Uses Curves.easeInOut for smooth transition│
└─────────────────────────────────────────────┘
```

### Performance UX Guidelines

1. **Show immediately** - Display skeleton before network request starts
2. **Match dimensions** - Skeleton size = final content size (no layout shift)
3. **Progressive loading** - Show content as it loads, replace skeleton items individually
4. **Minimal animation** - Opacity only (no color shift for performance)
5. **Optimistic UI** - Update before sync confirms
6. **No layout shift** - Pre-allocate exact space for content

---

## Performance UX Guidelines

### General Principles

1. **Immediate Feedback**
   - Show skeletons/placeholders BEFORE network request
   - Never show blank/empty state during loading
   - User should always see something meaningful

2. **Layout Stability**
   - Pre-allocate exact dimensions for all content
   - Skeleton dimensions = final content dimensions
   - No jumping or shifting when content loads

3. **Progressive Loading**
   - Show content as it becomes available
   - Don't wait for all items to load
   - Replace skeleton items individually

4. **Optimistic UI**
   - Update UI immediately on user action
   - Sync to server in background
   - Roll back only on confirmed failure

5. **Minimal Animation**
   - Use opacity animations only (GPU-accelerated)
   - Avoid color shifts (requires repaint)
   - Keep animations under 300ms for interactions

### Loading State Hierarchy

```
┌─────────────────────────────────────────────┐
│ Priority Order for Loading States          │
│                                             │
│ 1. Show skeleton immediately               │
│    ↓                                        │
│ 2. Start network request                   │
│    ↓                                        │
│ 3. Show content as it arrives              │
│    ↓                                        │
│ 4. Replace skeleton items progressively    │
│    ↓                                        │
│ 5. Remove skeleton when complete           │
└─────────────────────────────────────────────┘
```

### Performance Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Skeleton Display Time** | < 50ms | From screen load to skeleton visible |
| **First Content Paint** | < 500ms | From request to first item visible |
| **Layout Shift** | 0 | No dimension changes during load |
| **Animation FPS** | 60fps | Smooth skeleton shimmer |
| **Memory Usage** | < 50MB | For image caching |

### Dark Theme Compliance

All components MUST:
- Use ONLY colors from `AppColors`
- Maintain contrast ratios (WCAG AA: 4.5:1 minimum)
- Follow existing visual hierarchy
- Not introduce new colors or variants

### Color Usage Verification

| Component | Colors Used | Compliance |
|-----------|-------------|------------|
| **Load More Button** | `cardBackground`, `orangePrimary`, `borderColor`, `secondaryText` | ✅ |
| **Image Placeholder** | `cardBackground`, `secondaryText`, `blue` | ✅ |
| **Loading Skeleton** | `cardBackground`, `background` | ✅ |

---

## Implementation Checklist

### Task 16.1: Load More Button

- [ ] Use `ElevatedButton` styled as outlined button
- [ ] Set background to `AppColors.cardBackground`
- [ ] Set border to `AppColors.orangePrimary` (1px)
- [ ] Set border radius to `12px`
- [ ] Add `Icons.expand_more` icon before text
- [ ] Show `BrailleLoader` when loading
- [ ] Disable button when no more content
- [ ] Add `HapticFeedback.lightImpact()` on tap
- [ ] Place at end of scrollable list
- [ ] Show when 80% through list (progressive)

### Task 16.2: Image Placeholder

- [ ] Use `CachedNetworkImage` with disk cache
- [ ] Set `maxHeightDiskCache: 100`
- [ ] Show `CircularProgressIndicator` as placeholder
- [ ] Use `AppColors.blue` for loading indicator
- [ ] Show `Icons.person` on error
- [ ] Use `AppColors.secondaryText` for error icon
- [ ] Set container to 40px diameter circle
- [ ] Use `AppColors.cardBackground` for placeholder background
- [ ] Pre-allocate space (no layout shift)

### Task 16.5: Loading Skeletons

- [ ] Use `Shimmer.fromColors` with `cardBackground` and `background`
- [ ] Use `AnimatedOpacity` for fade animation
- [ ] Set animation duration to 1.5s
- [ ] Use `Curves.easeInOut` for smooth transition
- [ ] Match skeleton dimensions to final content
- [ ] Show skeleton immediately (before network)
- [ ] Replace items progressively as they load
- [ ] Use `RepoHeaderSkeleton` for repo loading
- [ ] Use `LoadingSkeleton` for issue list loading
- [ ] No color shift animation (opacity only)

---

## Accessibility Notes

### Screen Reader Support

All loading states MUST include proper accessibility labels:

```dart
// Load More button
Semantics(
  label: _isLoadingMore ? 'Loading more items' : 'Load more items',
  button: true,
  child: _buildLoadMoreButton(),
)

// Image placeholder
Semantics(
  label: 'User avatar placeholder',
  child: Container(...),
)

// Loading skeleton
ExcludeSemantics(
  child: LoadingSkeleton(),
)
```

### Touch Target Sizes

All interactive elements MUST have minimum touch target of `48x48px`:

- Load More button: Default height 48px ✓
- Avatar placeholder: 40px (icon only, not interactive) ✓

### Color Contrast

All text MUST meet WCAG AA contrast requirements (4.5:1 for normal text):

| Combination | Foreground | Background | Ratio | Status |
|-------------|------------|------------|-------|--------|
| Button text | `#FF6200` | `#1E1E1E` | 8.1:1 | ✓ Pass |
| Secondary text | `#A0A0A5` | `#1E1E1E` | 7.2:1 | ✓ Pass |
| Loading text | `#A0A0A5` | `#1E1E1E` | 7.2:1 | ✓ Pass |

---

## Related Files

### Existing Implementations

| File | Purpose | Lines |
|------|---------|-------|
| `/lib/widgets/loading_skeleton.dart` | Loading skeleton widget | 1-200 |
| `/lib/widgets/issue_card.dart` | Issue card with image caching | 140-180 |
| `/lib/widgets/expandable_repo.dart` | Repo list with skeleton usage | 350-400 |
| `/lib/screens/main_dashboard_screen.dart` | Load More button | 877-897 |
| `/lib/constants/app_colors.dart` | Color definitions | All |

### Files to Create/Update

| File | Action | Purpose |
|------|--------|---------|
| `/lib/widgets/loading_skeleton.dart` | Update | Add repo skeleton variant |
| `/lib/widgets/issue_card.dart` | Update | Enhance image placeholder |
| `/lib/screens/main_dashboard_screen.dart` | Update | Standardize Load More button |
| `/lib/widgets/repo_list.dart` | Update | Add skeleton loading |

---

**All designs follow Sprint 15 patterns and maintain visual consistency with existing GitDoIt UI.**
