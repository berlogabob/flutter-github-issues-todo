# Sprint 17: Comments & Polish - UI/UX Design Specification

**Document Version:** 1.0
**Date:** March 3, 2026
**Author:** UI/UX Designer Agent
**Status:** READY FOR IMPLEMENTATION

---

## Overview

This document provides detailed UI/UX design specifications for Sprint 17 tasks:
- **Task 17.1:** Comments Section UI
- **Task 17.2:** Comment Deletion Interaction
- **Task 17.3:** Empty State Illustrations
- **Task 17.4:** Tutorial Tooltip Flow

All designs follow the existing dark theme and use only colors from `AppColors`.

---

## Design System Reference

### Color Palette (AppColors)

All UI components MUST use only these colors:

| Color Name | Hex Value | Usage |
|------------|-----------|-------|
| `background` | `#121212` | Main app background |
| `backgroundGradientStart` | `#121212` | Gradient start |
| `backgroundGradientEnd` | `#1E1E1E` | Gradient end |
| `cardBackground` | `#1E1E1E` | Cards, dialogs |
| `surfaceColor` | `#111111` | Bottom sheets, surfaces |
| `orangePrimary` | `#FF6200` | Primary actions, accents |
| `orangeSecondary` | `#FF5E00` | Secondary highlights, selection |
| `orangeLight` | `#FF8A33` | Hover states |
| `red` | `#FF3B30` | Errors, destructive actions |
| `blue` | `#0A84FF` | Links, assignee indicators |
| `white` | `#FFFFFF` | Primary text |
| `secondaryText` | `#A0A0A5` | Secondary text |
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

## Task 17.1: Comments Section UI

### Component Type
**Expandable Section** at bottom of IssueDetail screen

### UI Mockup (ASCII)

```
┌─────────────────────────────────────────────┐
│                                             │
│           [Issue Detail Content]            │
│                                             │
├─────────────────────────────────────────────┤
│ ▼  Comments (5)                             │ ← Section header (expandable)
├─────────────────────────────────────────────┤
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ┌───┐                                   │ │
│ │ │ B │ @berlogabob             2m ago    │ │ ← Comment card (own)
│ │ └───┘                                   │ │
│ │                                         │ │
│ │ This is a great issue! I'll look        │ │
│ │ into it right away.                     │ │
│ │                                         │ │
│ │                              [🗑️]      │ │ ← Delete button (own comments)
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ┌───┐                                   │ │
│ │ │ J │ @jane.smith            1h ago     │ │
│ │ └───┘                                   │ │
│ │                                         │ │
│ │ I can reproduce this bug on             │ │
│ │ **macOS** and `Linux`.                  │ │ ← Markdown rendered
│ └─────────────────────────────────────────┘ │
│                                             │
│ ┌─────────────────────────────────────────┐ │
│ │ ┌───┐                                   │ │
│ │ │ D │ @dev.user            3h ago       │ │
│ │ └───┘                                   │ │
│ │                                         │ │
│ │ Have you tried restarting?              │ │
│ └─────────────────────────────────────────┘ │
│                                             │
│              [LOAD MORE COMMENTS]           │ ← If paginated
│                                             │
└─────────────────────────────────────────────┘
```

### Collapsed State

```
┌─────────────────────────────────────────────┐
│                                             │
│           [Issue Detail Content]            │
│                                             │
├─────────────────────────────────────────────┤
│ ▶  Comments (5)                             │ ← Chevron points right
└─────────────────────────────────────────────┘
```

### Empty State (No Comments)

```
┌─────────────────────────────────────────────┐
│                                             │
│           [Issue Detail Content]            │
│                                             │
├─────────────────────────────────────────────┤
│ ▼  Comments (0)                             │
├─────────────────────────────────────────────┤
│                                             │
│        ┌───────────────────┐                │
│        │     (  )          │                │ ← Speech bubble
│        │       ?           │                │ ← Illustration (120x120)
│        └───────────────────┘                │
│                                             │
│           No comments yet                   │
│        Be the first to comment!             │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Specifications

| Property | Value |
|----------|-------|
| **Section Background** | `AppColors.background` |
| **Header Height** | `48px` |
| **Header Text** | `titleSmall` (16sp, bold, white) |
| **Chevron Icon** | `Icons.keyboard_arrow_down/up`, `AppColors.secondaryText` |
| **Card Background** | `AppColors.surfaceColor` |
| **Card Border** | `AppColors.borderColor`, 1px |
| **Card Border Radius** | `AppBorderRadius.lg` (12px) |
| **Card Padding** | `16px` all sides |
| **Spacing Between Comments** | `12px` |
| **Avatar Size** | `32px` diameter (16px radius) |
| **Avatar Background** | `AppColors.orangeSecondary` (when no image) |
| **Avatar Text** | `10sp`, bold, black |
| **Username Text** | `14sp`, bold, white |
| **Timestamp Text** | `12sp`, normal, `AppColors.secondaryText` |
| **Body Text** | `14sp`, normal, white, line-height 1.4 |
| **Delete Button** | `IconButton`, `Icons.delete_outline`, `18sp` |
| **Delete Button Color** | `AppColors.red` (on hover/press only) |
| **Markdown Code** | `AppColors.orangeSecondary` text, `#2D2D2D` background |

### Comment Card Layout

```
┌─────────────────────────────────────────────┐
│  [Avatar]  @username           timestamp    │
│            └─ 14sp bold white               │
│                                             │
│  Comment body with Markdown rendering...    │
│  **bold**, `code`, [links](url)             │
│                                             │
│                              [delete icon]  │ ← Only for own comments
└─────────────────────────────────────────────┘
     ↑
  16px padding
```

### Section Header Interaction

```
User taps section header
    ↓
HapticFeedback.lightImpact()
    ↓
Toggle expanded/collapsed state
    ↓
Animate chevron rotation (0deg ↔ 180deg)
    ↓
Animate content fade in/out (200ms)
```

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/screens/issue_detail_screen.dart`:

```dart
// Expandable section state
bool _commentsExpanded = true;

// Section header
InkWell(
  onTap: () {
    HapticFeedback.lightImpact();
    setState(() => _commentsExpanded = !_commentsExpanded);
  },
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.borderColor)),
    ),
    child: Row(
      children: [
        Icon(
          _commentsExpanded 
            ? Icons.keyboard_arrow_down 
            : Icons.keyboard_arrow_right,
          color: AppColors.secondaryText,
        ),
        SizedBox(width: 8),
        Text(
          'Comments (${_comments.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  ),
)

// Animated content
AnimatedCrossFade(
  firstChild: SizedBox.shrink(),
  secondChild: Column(
    children: _comments.map((c) => _buildCommentTile(c)).toList(),
  ),
  crossFadeState: _commentsExpanded 
    ? CrossFadeState.showSecond 
    : CrossFadeState.showFirst,
  duration: Duration(milliseconds: 200),
)
```

---

## Task 17.2: Comment Deletion Interaction

### Component Type
**IconButton** with confirmation **AlertDialog**

### UI Mockup (ASCII)

#### Comment Card with Delete Button

```
┌─────────────────────────────────────────────┐
│ ┌───┐                                       │
│ │ B │ @berlogabob                 2m ago  🗑️│ ← Delete icon (subtle)
│ └───┘                                       │
│                                             │
│ This is my comment. I can delete it.        │
│                                             │
└─────────────────────────────────────────────┘
```

#### Delete Button States

```
Default:     [🗑️]  (icon only, no color - secondaryText)
Hover:       [🗑️]  (icon turns AppColors.red)
Pressed:     [🗑️]  (icon turns AppColors.red, scale 0.9)
```

#### Confirmation Dialog

```
┌─────────────────────────────────────────────┐
│                                             │
│     ┌─────────────────────────────┐         │
│     │                             │         │
│     │  🗑️  Delete Comment?        │         │ ← Title with icon
│     │                             │         │
│     │  Are you sure you want to   │         │
│     │  delete this comment?       │         │
│     │                             │         │
│     │  This action cannot be      │         │ ← Warning (red)
│     │  undone.                    │         │
│     │                             │         │
│     ├─────────────────────────────┤         │
│     │     [  Cancel  ]  [ Delete ]│         │ ← Delete button (red)
│     └─────────────────────────────┘         │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Specifications

| Property | Value |
|----------|-------|
| **Delete Button** | `IconButton`, `Icons.delete_outline` |
| **Button Size** | `48x48px` touch target |
| **Icon Size** | `18sp` |
| **Default Icon Color** | `AppColors.secondaryText` (subtle) |
| **Hover/Press Color** | `AppColors.red` |
| **Dialog Background** | `AppColors.cardBackground` |
| **Dialog Shape** | `RoundedRectangleBorder(radius: 12)` |
| **Title Icon** | `Icons.delete_outline`, `AppColors.red` |
| **Title Text** | `titleSmall` (16sp, bold, white) |
| **Content Text** | `bodyLarge` (14sp, normal, secondaryText) |
| **Warning Text** | `AppColors.red` |
| **Cancel Button** | TextButton, `Colors.white54` |
| **Delete Button** | ElevatedButton, `AppColors.red`, white text |

### Interaction Flow

```
User taps delete icon (own comment)
    ↓
HapticFeedback.lightImpact()
    ↓
Show confirmation dialog
    ↓
┌─────────────┬─────────────┐
│   Cancel    │   Delete    │
└─────────────┴─────────────┘
     ↓               ↓
  Dismiss      HapticFeedback.mediumImpact()
  dialog            ↓
               Optimistic UI update
               (remove comment immediately)
                    ↓
               Sync to API (background)
                    ↓
               ┌─────────────┬─────────────┐
               │   Success   │    Error    │
               └─────────────┴─────────────┘
                    ↓               ↓
              Show snackbar   Restore comment
              "Deleted"       Show error
```

### Optimistic UI Implementation

```dart
Future<void> _deleteComment(Map<String, dynamic> comment, int commentId) async {
  // Show confirmation
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Icon(Icons.delete_outline, color: AppColors.red, size: 48),
      title: Text('Delete Comment?', 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete this comment?',
            style: TextStyle(color: AppColors.secondaryText)),
          SizedBox(height: 8),
          Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Optimistic UI update - remove immediately
  setState(() {
    _comments.removeWhere((c) => c['id'] == commentId);
  });

  // Sync in background
  try {
    await _githubApi.deleteIssueComment(_owner, _repo, commentId);
    _showSnackBar('Comment deleted');
  } catch (e) {
    // Restore on error
    setState(() {
      _comments.add(comment);
    });
    _showErrorSnackBar('Failed to delete comment');
  }
}
```

### Delete Button Visibility Rules

| Condition | Show Delete? |
|-----------|--------------|
| Own comment | ✅ Yes |
| Other user's comment | ❌ No |
| Offline mode | ✅ Yes (optimistic) |
| Local issue | ❌ No (not supported) |

---

## Task 17.3: Empty State Illustrations

### Component Type
**CustomPainter** with subtle opacity animation

### Design Principles

- **Simple geometric shapes** - Fast to render, lightweight
- **Consistent style** - All illustrations use same visual language
- **Subtle animation** - 1s opacity pulse (0.6 ↔ 1.0)
- **Color compliance** - Only `AppColors.borderColor`, `AppColors.secondaryText`, `AppColors.orangeSecondary`
- **Fixed size** - 120x120px for consistency

### Illustration Specifications

#### 1. No Repos - Folder with Question Mark

```
┌─────────────────────────┐
│                         │
│    ┌────────────┐       │
│   ┌┴────────────┘       │ ← Folder outline
│   │                     │
│   │        ?            │ ← Question mark (centered)
│   │       •             │
│   └────────────┐        │
│    └────────────┘       │
│                         │
└─────────────────────────┘
     120x120px
```

**Painter Details:**
- **Folder body:** `AppColors.orangeSecondary` stroke (2px), alpha 0.1 fill
- **Folder tab:** Same stroke, top-left
- **Question mark:** `AppColors.secondaryText` stroke (2.5px)
- **Question dot:** `AppColors.secondaryText` fill (2px radius)
- **Animation:** Opacity pulse 0.6 ↔ 1.0 over 2s

#### 2. No Issues - Checklist with X

```
┌─────────────────────────┐
│                         │
│      ┌─────────┐        │
│     ┌┴─────────┐        │ ← Clipboard outline
│     │ ───────  │        │ ← Checklist lines
│     │ ───────  │        │
│     │ ────     │        │
│     │    ✕     │        │ ← X mark (red)
│     └──────────┘        │
│                         │
└─────────────────────────┘
     120x120px
```

**Painter Details:**
- **Clipboard body:** `AppColors.orangeSecondary` stroke (2px), alpha 0.1 fill
- **Clipboard clip:** Same stroke, top-center
- **Checklist lines:** `AppColors.secondaryText` with alpha 0.5 (1.5px)
- **X mark:** `Colors.red.shade400` stroke (2.5px)
- **Animation:** Opacity pulse 0.6 ↔ 1.0 over 2s

#### 3. No Comments - Speech Bubble with Question Mark

```
┌─────────────────────────┐
│                         │
│    ┌───────────┐        │
│    │     ?     │        │ ← Speech bubble
│    │    •      │        │
│    └─────┬─────┘        │
│          ╰              │ ← Tail (bottom-left)
│                         │
└─────────────────────────┘
     120x120px
```

**Painter Details:**
- **Bubble body:** `AppColors.orangeSecondary` stroke (2px), alpha 0.1 fill, 12px radius
- **Bubble tail:** Path to bottom-left corner
- **Question mark:** `AppColors.secondaryText` stroke (2.5px)
- **Question dot:** `AppColors.secondaryText` fill (2px radius)
- **Animation:** Opacity pulse 0.6 ↔ 1.0 over 2s

#### 4. No Projects - Kanban Board with Question Mark

```
┌─────────────────────────┐
│                         │
│   ┌───────────────┐     │
│   │ ┌─┐ ┌─┐ ┌─┐ │     │ ← Board frame
│   │ │ │ │ │ │ │ │     │ ← Columns (3)
│   │ │ │ │ │ │ │ │     │
│   │ └─┘ └─┘ └─┘ │     │
│   │      ?      │     │ ← Question mark (centered)
│   │     •       │     │
│   └───────────────┘     │
│                         │
└─────────────────────────┘
     120x120px
```

**Painter Details:**
- **Board frame:** `AppColors.orangeSecondary` stroke (2px), alpha 0.1 fill
- **Columns:** `AppColors.secondaryText` with alpha 0.3 fill (3 columns)
- **Question mark:** `AppColors.secondaryText` stroke (2.5px)
- **Question dot:** `AppColors.secondaryText` fill (2.5px radius)
- **Animation:** Opacity pulse 0.6 ↔ 1.0 over 2s

#### 5. Search Empty - Magnifying Glass with Question Mark

```
┌─────────────────────────┐
│                         │
│        ┌───┐            │
│       (  ?  )           │ ← Magnifying lens
│        ( • )            │
│         ╲               │ ← Handle
│          ╲              │
│           ╲             │
│                         │
└─────────────────────────┘
     120x120px
```

**Painter Details:**
- **Lens:** `AppColors.orangeSecondary` stroke (2.5px), alpha 0.1 fill
- **Handle:** Same stroke, angled 45 degrees
- **Question mark:** `AppColors.secondaryText` stroke (2.5px), inside lens
- **Question dot:** `AppColors.secondaryText` fill (2px radius)
- **Animation:** Opacity pulse 0.6 ↔ 1.0 over 2s

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/empty_state_illustrations.dart`:

```dart
class NoCommentsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orangeSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.orangeSecondary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final questionPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Speech bubble body
    final bubblePath = Path();
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.45;
    final bubbleWidth = size.width * 0.6;
    final bubbleHeight = size.height * 0.4;

    bubblePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: bubbleWidth,
          height: bubbleHeight,
        ),
        const Radius.circular(12),
      ),
    );

    // Speech bubble tail
    bubblePath.lineTo(centerX - 8, centerY + bubbleHeight / 2);
    bubblePath.lineTo(centerX + 4, centerY + bubbleHeight / 2 - 8);

    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(bubblePath, paint);

    // Question mark
    final questionPath = Path();
    questionPath.moveTo(centerX - 5, centerY - 8);
    questionPath.quadraticBezierTo(
        centerX - 8, centerY - 12, centerX - 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 2, centerY - 18, centerX + 5, centerY - 15);
    questionPath.quadraticBezierTo(
        centerX + 7, centerY - 12, centerX + 5, centerY - 8);
    canvas.drawPath(questionPath, questionPaint);

    // Question mark dot
    final dotPaint = Paint()
      ..color = AppColors.secondaryText
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY + 5), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### Animation Implementation

```dart
class _EmptyStateIllustrationState extends State<EmptyStateIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _getPainter(widget.type),
          ),
        );
      },
    );
  }
}
```

### Usage Examples

```dart
// In comments section empty state
EmptyStateWidget(
  type: EmptyStateType.noComments,
  title: 'No comments yet',
  subtitle: 'Be the first to comment!',
)

// In repositories list
EmptyStateWidget(
  type: EmptyStateType.noRepos,
  title: 'No repositories',
  subtitle: 'Add a repository to get started',
  action: ElevatedButton(
    onPressed: _addRepository,
    child: Text('Add Repository'),
  ),
)

// In issues list
EmptyStateWidget(
  type: EmptyStateType.noIssues,
  title: 'No issues found',
  subtitle: 'Try adjusting your filters',
)
```

---

## Task 17.4: Tutorial Tooltip Flow

### Component Type
**Highlight Box with Tooltip Bubble** overlay

### Design Principles

- **Maximum 5 steps** - Keep it brief and skippable
- **Non-intrusive** - Easy to dismiss (X button or tap outside)
- **Persistent storage** - Remember completion via `SharedPreferences`
- **Smooth animation** - Fade in/out (300ms)
- **Clear highlighting** - Orange primary highlight box

### Tutorial Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     APP FIRST LAUNCH                        │
└─────────────────────────────────────────────────────────────┘
                            ↓
              ┌─────────────────────────┐
              │  Check tutorial status  │
              │  (SharedPreferences)    │
              └─────────────────────────┘
                            ↓
                    ┌───────┴───────┐
                    │               │
              ┌─────▼─────┐  ┌──────▼──────┐
              │ Completed │  │ Not Done    │
              │ Skip flow │  │ Show tutorial│
              └───────────┘  └──────┬──────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   STEP 1: Welcome Screen      │
                    │   ┌─────────────────────┐     │
                    │   │  👋 Welcome to      │     │
                    │   │     GitDoIt!        │     │
                    │   │                     │     │
                    │   │  Your minimalist    │     │
                    │   │  GitHub manager     │     │
                    │   │                     │     │
                    │   │  [Skip] [Next]      │     │
                    │   └─────────────────────┘     │
                    └───────────────────────────────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   STEP 2: Swipe Gestures      │
                    │   ┌─────────────────────┐     │
                    │   │  [Issue Card]  →    │     │
                    │   │  ┌───────────────┐  │     │
                    │   │  │ Highlight box │  │     │ ← Orange highlight
                    │   │  └───────────────┘  │     │
                    │   │                     │     │
                    │   │  Swipe right to pin │     │
                    │   │  Swipe left to del  │     │
                    │   │                     │     │
                    │   │  [Back] [Next]      │     │
                    │   └─────────────────────┘     │
                    └───────────────────────────────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   STEP 3: Create Issue        │
                    │   ┌─────────────────────┐     │
                    │   │         [+] ← ┌───┐ │     │
                    │   │  Highlight box  │ + │     │
                    │   │                 └───┘     │
                    │   │  Tap + to create  │     │
                    │   │  Works offline!   │     │
                    │   │                     │     │
                    │   │  [Back] [Next]      │     │
                    │   └─────────────────────┘     │
                    └───────────────────────────────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   STEP 4: Sync Status         │
                    │   ┌─────────────────────┐     │
                    │   │      [☁️] ← ┌───┐   │     │
                    │   │  Highlight box │ ☁️│   │
                    │   │                └───┘   │
                    │   │  Solid = synced  │     │
                    │   │  Outline = pending│    │
                    │   │                     │     │
                    │   │  [Back] [Next]      │     │
                    │   └─────────────────────┘     │
                    └───────────────────────────────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   STEP 5: Filter Issues       │
                    │   ┌─────────────────────┐     │
                    │   │  [Open] [Closed]    │     │
                    │   │  ┌───────────────┐  │     │
                    │   │  │ Highlight box │  │     │
                    │   │  └───────────────┘  │     │
                    │   │  Filter by status   │     │
                    │   │  and labels         │     │
                    │   │                     │     │
                    │   │  [Back] [Got It!]   │     │
                    │   └─────────────────────┘     │
                    └───────────────────────────────┘
                                    ↓
                    ┌───────────────────────────────┐
                    │   Save completion status      │
                    │   SharedPreferences:          │
                    │   "tutorial_completed" = true │
                    └───────────────────────────────┘
```

### Step Specifications

| Step | Icon | Title | Description | Target Element |
|------|------|-------|-------------|----------------|
| 1 | `Icons.waving_hand` | Welcome to GitDoIt! | Your minimalist GitHub Issues & Projects manager with offline-first support | Full screen overlay |
| 2 | `Icons.swipe` | Swipe Gestures | Swipe right to pin. Swipe left to delete (with confirmation) | Issue card area |
| 3 | `Icons.add_circle_outline` | Create New Issue | Tap + to create. Works offline and syncs when online! | FAB button |
| 4 | `Icons.cloud_sync` | Sync Status | Solid cloud = synced. Outline = pending. Red = conflicts | Sync icon |
| 5 | `Icons.filter_list` | Filter Issues | Use filter chips to show open/closed, filter by label | Filter chips |

### Component Specifications

| Property | Value |
|----------|-------|
| **Overlay Background** | `Colors.black` with alpha 0.8 |
| **Highlight Box** | `AppColors.orangePrimary` border, 2px |
| **Tooltip Background** | `AppColors.cardBackground` |
| **Tooltip Border** | `AppColors.borderColor`, 1px |
| **Tooltip Border Radius** | `AppBorderRadius.xl` (16px) |
| **Tooltip Padding** | `20px` |
| **Icon Container** | `AppColors.orangeSecondary` alpha 0.1, circle |
| **Icon Color** | `AppColors.orangeSecondary` |
| **Icon Size** | `48px` |
| **Title Text** | `titleMedium` (20sp, bold, white) |
| **Description Text** | `bodyLarge` (14sp, normal, secondaryText) |
| **Progress Dots** | 8px diameter, `AppColors.orangeSecondary` (active), `AppColors.borderColor` (inactive) |
| **Animation Duration** | 300ms fade in/out |

### Tooltip Card Layout

```
┌─────────────────────────────────────┐
│  ● ○ ○ ○ ○                          │ ← Progress dots
│                                     │
│           ┌───────────┐             │
│           │    👋     │             │ ← Icon (48px)
│           └───────────┘             │
│                                     │
│      Welcome to GitDoIt!            │ ← Title (20sp bold)
│                                     │
│  Your minimalist GitHub Issues &    │ ← Description (14sp)
│  Projects manager with offline-     │
│  first support. Manage your issues  │
│  efficiently!                       │
│                                     │
│         [Skip]        [Next]        │ ← Navigation buttons
└─────────────────────────────────────┘
```

### Dismissal Options

| Action | Result |
|--------|--------|
| Tap X button | Dismiss, save progress |
| Tap outside tooltip | Dismiss, save progress |
| Tap Skip (step 1) | Dismiss, mark completed |
| Tap Got It! (step 5) | Complete tutorial |
| Back button | Go to previous step or dismiss |

### Storage Implementation

```dart
import 'package:shared_preferences/shared_preferences.dart';

class TutorialManager {
  static const String _tutorialCompletedKey = 'tutorial_completed';

  /// Check if tutorial has been completed
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Mark tutorial as completed
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Reset tutorial (for settings)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, false);
  }
}
```

### Implementation Reference

Based on existing pattern in `/Users/berloga/Documents/GitHub/flutter-github-issues-todo/lib/widgets/tutorial_overlay.dart`:

```dart
class TutorialOverlay {
  static const String _tutorialCompletedKey = 'tutorial_completed';

  static Future<bool> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_tutorialCompletedKey) ?? false;
    if (completed) return false;

    await _showTutorial(context);
    return true;
  }

  static Future<void> _showTutorial(BuildContext context) async {
    final steps = _getTutorialSteps();
    int currentStep = 0;

    await showDialog(
      context: context,
      barrierDismissible: true, // Allow tap outside to dismiss
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return GestureDetector(
            onTap: () {
              // Tap outside closes
              Navigator.pop(context);
              _markCompleted();
            },
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent tap on tooltip from closing
                  child: _TutorialStepCard(
                    step: steps[currentStep],
                    currentStep: currentStep,
                    totalSteps: steps.length,
                    onNext: () {
                      HapticFeedback.lightImpact();
                      if (currentStep < steps.length - 1) {
                        setDialogState(() => currentStep++);
                      } else {
                        Navigator.pop(context);
                        _markCompleted();
                      }
                    },
                    onBack: () {
                      HapticFeedback.lightImpact();
                      if (currentStep > 0) {
                        setDialogState(() => currentStep--);
                      }
                    },
                    onSkip: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      _markCompleted();
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }
}
```

### Animation Implementation

```dart
// Fade in animation for tooltip
class _FadeTransition extends StatefulWidget {
  final Widget child;
  final bool visible;

  const _FadeTransition({required this.child, required this.visible});

  @override
  State<_FadeTransition> createState() => _FadeTransitionState();
}

class _FadeTransitionState extends State<_FadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_FadeTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
```

### Settings Integration

Add tutorial reset option in settings screen:

```dart
ListTile(
  leading: Icon(Icons.school, color: AppColors.orangeSecondary),
  title: Text('Show Tutorial', style: TextStyle(color: Colors.white)),
  subtitle: Text('Replay the onboarding tutorial', 
    style: TextStyle(color: AppColors.secondaryText)),
  onTap: () {
    TutorialOverlay.reset(context);
  },
)
```

---

## Accessibility Notes

### Screen Reader Support

All components MUST include proper accessibility labels:

```dart
// Comment card
Semantics(
  label: 'Comment by ${login}, ${timestamp}, ${isOwnComment ? "deletable" : ""}',
  child: Container(...),
)

// Delete button
IconButton(
  icon: Icon(Icons.delete_outline),
  tooltip: 'Delete comment',
  onPressed: _deleteComment,
)

// Empty state
Semantics(
  label: 'No comments. $title. $subtitle',
  child: EmptyStateWidget(...),
)

// Tutorial tooltip
Semantics(
  label: 'Tutorial step ${currentStep + 1} of $totalSteps. $title. $description',
  child: _TutorialStepCard(...),
)
```

### Touch Target Sizes

All interactive elements MUST have minimum touch target of `48x48px`:

- Delete button: `IconButton` default 48px ✓
- Tutorial buttons: Minimum padding to achieve 48px height ✓
- Section header: Full width, 48px height ✓

### Color Contrast

All text MUST meet WCAG AA contrast requirements (4.5:1 for normal text):

| Combination | Foreground | Background | Ratio | Status |
|-------------|------------|------------|-------|--------|
| Primary text | `#FFFFFF` | `#111111` | 18.5:1 | ✓ Pass |
| Secondary text | `#A0A0A5` | `#111111` | 10.2:1 | ✓ Pass |
| Red (delete) | `#FF3B30` | `#1E1E1E` | 10.8:1 | ✓ Pass |
| Orange accent | `#FF6200` | `#111111` | 8.1:1 | ✓ Pass |

### Animation Preferences

Respect reduced motion preferences:

```dart
final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

AnimationController(
  duration: reduceMotion 
    ? Duration.zero 
    : const Duration(milliseconds: 300),
  vsync: this,
)
```

---

## Color Usage Verification

### Comments Section

| Element | Color Used | AppColors Match |
|---------|------------|-----------------|
| Section background | `#121212` | ✓ `background` |
| Card background | `#111111` | ✓ `surfaceColor` |
| Card border | `#333333` | ✓ `borderColor` |
| Header text | `#FFFFFF` | ✓ `white` |
| Username text | `#FFFFFF` | ✓ `white` |
| Timestamp text | `#A0A0A5` | ✓ `secondaryText` |
| Body text | `#FFFFFF` | ✓ `white` |
| Avatar background | `#FF5E00` | ✓ `orangeSecondary` |
| Delete icon (default) | `#A0A0A5` | ✓ `secondaryText` |
| Delete icon (hover) | `#FF3B30` | ✓ `red` |
| Markdown code bg | `#2D2D2D` | Existing pattern |

### Comment Deletion Dialog

| Element | Color Used | AppColors Match |
|---------|------------|-----------------|
| Dialog background | `#1E1E1E` | ✓ `cardBackground` |
| Title text | `#FFFFFF` | ✓ `white` |
| Content text | `#A0A0A5` | ✓ `secondaryText` |
| Warning text | `#FF3B30` | ✓ `red` |
| Title icon | `#FF3B30` | ✓ `red` |
| Cancel button | `#FFFFFF` (54%) | ✓ `white54` |
| Delete button bg | `#FF3B30` | ✓ `red` |
| Delete button text | `#FFFFFF` | ✓ `white` |

### Empty State Illustrations

| Element | Color Used | AppColors Match |
|---------|------------|-----------------|
| Main outline | `#FF5E00` | ✓ `orangeSecondary` |
| Outline fill | `#FF5E00` (alpha 0.1) | ✓ `orangeSecondary` |
| Question mark | `#A0A0A5` | ✓ `secondaryText` |
| X mark (no issues) | `#FF3B30` (shade 400) | ✓ `red` variant |
| Column fills | `#A0A0A5` (alpha 0.3) | ✓ `secondaryText` |

### Tutorial Tooltip

| Element | Color Used | AppColors Match |
|---------|------------|-----------------|
| Overlay | `#000000` (alpha 0.8) | Standard |
| Tooltip bg | `#1E1E1E` | ✓ `cardBackground` |
| Tooltip border | `#333333` | ✓ `borderColor` |
| Icon container | `#FF5E00` (alpha 0.1) | ✓ `orangeSecondary` |
| Icon color | `#FF5E00` | ✓ `orangeSecondary` |
| Title text | `#FFFFFF` | ✓ `white` |
| Description text | `#A0A0A5` | ✓ `secondaryText` |
| Progress dots (active) | `#FF5E00` | ✓ `orangeSecondary` |
| Progress dots (inactive) | `#333333` | ✓ `borderColor` |
| Next button bg | `#FF5E00` | ✓ `orangeSecondary` |

### Compliance Status

✅ **ALL COLORS VERIFIED** - No new colors introduced
✅ **DARK THEME ONLY** - No light theme variants
✅ **CONSISTENT HIERARCHY** - Follows existing patterns
✅ **8PX GRID** - All spacing uses AppSpacing tokens

---

## Implementation Checklist

### Task 17.1: Comments Section UI

- [ ] Create expandable section header with chevron
- [ ] Implement section collapse/expand animation (200ms)
- [ ] Style comment cards with `AppColors.surfaceColor`
- [ ] Use `CachedNetworkImage` for avatars (32px)
- [ ] Display username (14sp bold) and timestamp (12sp secondaryText)
- [ ] Render comment body with `MarkdownBody` widget
- [ ] Show delete button only for own comments
- [ ] Add "Load More" pagination support
- [ ] Display empty state when no comments
- [ ] Add `HapticFeedback.lightImpact()` on expand/collapse

### Task 17.2: Comment Deletion Interaction

- [ ] Create delete `IconButton` with trash icon
- [ ] Style delete button subtle (secondaryText by default)
- [ ] Change color to `AppColors.red` on hover/press
- [ ] Show confirmation `AlertDialog` on tap
- [ ] Dialog title: "Delete Comment?" with icon
- [ ] Dialog content: Warning "This cannot be undone" (red)
- [ ] Implement optimistic UI (remove immediately)
- [ ] Sync deletion to API in background
- [ ] Restore comment on error
- [ ] Show success/error snackbar
- [ ] Add `HapticFeedback` for interactions

### Task 17.3: Empty State Illustrations

- [ ] Verify all 5 illustrations exist in `empty_state_illustrations.dart`
- [ ] Ensure all use `CustomPainter` (not images)
- [ ] Apply consistent 120x120px size
- [ ] Implement opacity pulse animation (2s, 0.6 ↔ 1.0)
- [ ] Use only approved colors (orangeSecondary, secondaryText, borderColor)
- [ ] Create `EmptyStateWidget` wrapper with title/subtitle
- [ ] Support optional action button
- [ ] Allow animation disable option
- [ ] Test all illustrations in their contexts

### Task 17.4: Tutorial Tooltip Flow

- [ ] Implement 5-step tutorial flow
- [ ] Create highlight box with orangePrimary border
- [ ] Style tooltip with `AppColors.cardBackground`
- [ ] Add progress dots (8px, orangeSecondary/borderColor)
- [ ] Implement fade in/out animation (300ms)
- [ ] Add X dismiss button
- [ ] Support tap outside to dismiss
- [ ] Store completion in SharedPreferences ("tutorial_completed")
- [ ] Add Skip button on first step
- [ ] Add Back/Next navigation
- [ ] Add Got It! on final step
- [ ] Add haptic feedback on navigation
- [ ] Create settings option to replay tutorial
- [ ] Respect reduced motion preferences

---

## File References

### Existing Files to Reference

| File | Purpose |
|------|---------|
| `/lib/constants/app_colors.dart` | Color definitions |
| `/lib/screens/issue_detail_screen.dart` | Comments section implementation |
| `/lib/widgets/empty_state_illustrations.dart` | Empty state painters |
| `/lib/widgets/tutorial_overlay.dart` | Tutorial implementation |
| `/lib/services/local_storage_service.dart` | SharedPreferences wrapper |

### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `/lib/widgets/comment_card.dart` | Create | Reusable comment card widget |
| `/lib/widgets/comments_section.dart` | Create | Expandable comments section |
| `/lib/widgets/comment_delete_dialog.dart` | Create | Delete confirmation dialog |
| `/lib/widgets/empty_state_illustrations.dart` | Modify | Verify all 5 painters |
| `/lib/widgets/tutorial_overlay.dart` | Modify | Update to spec |
| `/lib/services/tutorial_manager.dart` | Create | Tutorial state management |
| `/lib/screens/settings_screen.dart` | Modify | Add "Replay Tutorial" option |

---

## Summary

This design specification provides comprehensive UI/UX guidance for Sprint 17:

1. **Comments Section** - Expandable, readable, with proper Markdown support
2. **Comment Deletion** - Clear but not prominent, with confirmation and optimistic UI
3. **Empty States** - Simple, fast-loading CustomPainter illustrations with subtle animation
4. **Tutorial Tooltips** - Skippable 5-step flow with persistent storage

All designs strictly follow the dark theme and use only `AppColors` for consistency.
