# Test Session: Repo Selection Flow

**Date:** 2026-02-21  
**Tester:** MrTester  
**Device:** XPH0219904001750 (ELE L29 - Android 10)  
**App Version:** 1.0.0+2  
**Session Status:** COMPLETED  

---

## Test Scenarios & Results

### Scenario 1: Tap + button → See 2 options

**Expected:**
- Dialog appears with 2 buttons
- "SHOW MY REPOS" (primary button)
- "ADD BY URL" (secondary button)

**Actual:**
✅ PASS - Dialog appears correctly with both options

**UI Issues Found:**
- None for this step

---

### Scenario 2: Tap "SHOW MY REPOS" → See repo list with circles

**Expected:**
- Navigate to repo list screen
- Each repo shows an empty circle (`Icons.circle_outlined`) on the right
- Repositories load from GitHub API
- Search bar at top

**Actual:**
✅ PASS - Repo list displays with circles

**UI Issues Found:**
⚠️ **ISSUE #1: Search bar creates new TextEditingController on every build**
- Location: `repo_list_picker_screen.dart:221`
- Problem: `controller: TextEditingController()..text = _searchQuery` creates new controller each build
- Impact: Could cause cursor position loss, memory leak
- Severity: Medium

```dart
// BUGGY CODE (line 221):
IndustrialInput(
  label: 'SEARCH',
  hintText: 'Search repositories...',
  controller: TextEditingController()..text = _searchQuery,  // ❌ Creates new controller
  ...
)

// FIX:
final _searchController = TextEditingController();
// In initState: _searchController.text = _searchQuery;
// In dispose: _searchController.dispose();
```

---

### Scenario 3: Tap repo → Circle changes to checkmark

**Expected:**
- Empty circle (`Icons.circle_outlined`) → Check circle (`Icons.check_circle`)
- Visual feedback is instant
- Checkmark is green (statusSuccess color)

**Actual:**
✅ PASS - Circle changes to checkmark

**UI Issues Found:**
⚠️ **ISSUE #2: Multi-select behavior contradicts expected single-select**
- Location: `repo_list_picker_screen.dart:118-125`
- Problem: Code allows selecting multiple repos, but test scenario implies single-select
- Test says: "Tap repo → Circle changes to checkmark" (singular)
- Code allows: Multiple repos can be selected simultaneously
- Severity: Medium (UX confusion)

```dart
// Current multi-select implementation:
void _toggleSelection(String repoFullName) {
  setState(() {
    if (_selectedRepos.contains(repoFullName)) {
      _selectedRepos.remove(repoFullName);  // Toggle off
    } else {
      _selectedRepos.add(repoFullName);     // Toggle on (allows multiple)
    }
  });
}

// If single-select expected:
void _selectRepo(String repoFullName) {
  setState(() {
    _selectedRepos.clear();                 // Clear previous
    _selectedRepos.add(repoFullName);       // Add new
  });
}
```

---

### Scenario 4: Tap different repo → Previous unchecked, new checked

**Expected:**
- Previously checked repo returns to empty circle
- Newly tapped repo shows checkmark
- Only ONE repo selected at a time

**Actual:**
❌ **FAIL - Multiple repos can be selected simultaneously**

**State Management Bug:**
⚠️ **ISSUE #3: State doesn't match test expectation**
- Location: `repo_list_picker_screen.dart`
- Problem: `_selectedRepos` is a `Set<String>` allowing multiple selections
- Test expects: Single selection (radio button behavior)
- Actual behavior: Multi-selection (checkbox behavior)
- Severity: High (functional mismatch)

**Evidence:**
```dart
final Set<String> _selectedRepos = {};  // Allows multiple
```

**Recommendation:**
Either:
1. Change to single-select (use `String? _selectedRepo`)
2. Update test scenarios to reflect multi-select behavior

---

### Scenario 5: Tap ADD → Selected repos appear on main screen

**Expected:**
- Navigate back to HomeScreen
- Selected repos appear as collapsible sections
- Issues from selected repos are displayed

**Actual:**
✅ PASS - Repos appear on main screen

**UI Issues Found:**
⚠️ **ISSUE #4: First selected repo becomes default without clear indication**
- Location: `repo_list_picker_screen.dart:140-148`
- Problem: First repo in selection automatically becomes "active"
- User not informed which repo will be default
- Severity: Medium

```dart
// Set first selected repo as active (silent behavior)
String? firstRepo;
for (final fullName in _selectedRepos) {
  // ...
  firstRepo ??= fullName;  // First one becomes default
}
```

---

### Scenario 6: Verify default repo on top

**Expected:**
- Default repo (first configured) appears at top of issue list
- Clearly distinguished from other repos

**Actual:**
✅ PASS - Default repo appears first

**UI Issues Found:**
⚠️ **ISSUE #5: "Default" vs "Active" repo terminology unclear**
- Location: `issues_provider.dart:185-193`
- Problem: `defaultRepo` returns first configured repo
- No visual distinction between "default" and "selected" repos
- User may not understand repo ordering
- Severity: Low

---

### Scenario 7: Verify selected repos listed below

**Expected:**
- Selected repos appear below default repo
- Each repo has its own collapsible header

**Actual:**
✅ PASS - Selected repos listed below default

---

### Scenario 8: Verify all repos collapsible

**Expected:**
- Each repo header has arrow/chevron
- Tap toggles expand/collapse
- Animation is smooth

**Actual:**
✅ PASS - Repos are collapsible

**UI Issues Found:**
⚠️ **ISSUE #6: No "Expand All" / "Collapse All" controls**
- Location: `home_screen.dart`
- Problem: User must tap each repo header individually
- With many repos, this becomes tedious
- Severity: Low (UX enhancement)

---

### Scenario 9: Verify checkmark states correct

**Expected:**
- Unchecked: Empty circle (`Icons.circle_outlined`)
- Newly selected: Check circle (`Icons.check_circle`)
- Previously selected: Check circle with visual distinction

**Actual:**
⚠️ **PARTIAL PASS - Visual distinction for "previously selected" is subtle**

**UI Issues Found:**
⚠️ **ISSUE #7: Previously selected state uses complex Stack rendering**
- Location: `repo_list_picker_screen.dart:405-420`
- Problem: Uses Stack with two icons for "bold" effect
- May not render consistently across devices
- Visual difference is subtle (slightly larger/different opacity)
- Severity: Medium

```dart
// Previously selected: Complex Stack rendering
Widget _buildCheckmarkIcon(IndustrialThemeData industrialTheme) {
  if (isPreviouslySelected) {
    return Stack(  // ⚠️ Complex rendering
      alignment: Alignment.center,
      children: [
        Icon(Icons.circle, size: 24, color: success.withValues(alpha: 0.2)),
        Icon(Icons.check_circle, size: 20, color: success),
      ],
    );
  }
  // ...
}

// Better: Use distinct icon
if (isPreviouslySelected) {
  return Icon(Icons.check_circle_outline, size: 24, color: success);
}
```

---

## Summary of Issues

### Critical (High Severity)
| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 3 | Multi-select contradicts single-select expectation | `repo_list_picker_screen.dart:118` | High |

### Medium Severity
| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | Search creates new TextEditingController each build | `repo_list_picker_screen.dart:221` | Medium |
| 2 | Multi-select behavior unclear | `repo_list_picker_screen.dart:118` | Medium |
| 4 | First selected repo becomes default silently | `repo_list_picker_screen.dart:140` | Medium |
| 7 | Previously selected state uses complex Stack | `repo_list_picker_screen.dart:405` | Medium |

### Low Severity
| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 5 | Default vs Active repo terminology unclear | `issues_provider.dart:185` | Low |
| 6 | No Expand All / Collapse All controls | `home_screen.dart` | Low |

---

## Checkmark Rendering Analysis

### Current Implementation
```dart
Widget _buildCheckmarkIcon(IndustrialThemeData industrialTheme) {
  if (isPreviouslySelected) {
    // Previously selected: bold/thick check circle
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.circle, size: 24, color: success.withValues(alpha: 0.2)),
        Icon(Icons.check_circle, size: 20, color: success),
      ],
    );
  } else if (isSelected) {
    // Newly selected: standard check circle
    return Icon(Icons.check_circle, size: 24, color: success);
  } else {
    // Unchecked: empty circle
    return Icon(Icons.circle_outlined, size: 24, color: textTertiary);
  }
}
```

### Problems
1. **Stack complexity**: Two icons layered may cause rendering issues on low-end devices
2. **Subtle visual difference**: Alpha overlay is hard to distinguish
3. **Inconsistent sizing**: 24px outer, 20px inner creates unclear visual hierarchy

### Recommended Fix
```dart
Widget _buildCheckmarkIcon(IndustrialThemeData industrialTheme) {
  if (isPreviouslySelected) {
    // Previously selected: outlined check circle (distinct from solid)
    return Icon(
      Icons.check_circle_outline,
      size: 24,
      color: industrialTheme.statusSuccess,
    );
  } else if (isSelected) {
    // Newly selected: solid check circle
    return Icon(
      Icons.check_circle,
      size: 24,
      color: industrialTheme.statusSuccess,
    );
  } else {
    // Unchecked: empty circle
    return Icon(
      Icons.circle_outlined,
      size: 24,
      color: industrialTheme.textTertiary,
    );
  }
}
```

---

## State Management Analysis

### Current State Structure
```dart
class _RepoListPickerScreenState extends State<RepoListPickerScreen> {
  final Set<String> _selectedRepos = {};              // NEW selections
  final Set<String> _previouslySelectedRepos = {};    // EXISTING selections
  // ...
}
```

### Problems
1. **Two separate Sets**: Confusing state management
2. **No single source of truth**: Which set determines UI state?
3. **Merge logic unclear**: What happens when newly selected overlaps with previously selected?

### Recommended State Structure
```dart
class _RepoListPickerScreenState extends State<RepoListPickerScreen> {
  // Single source of truth: all selected repos
  final Set<String> _allSelectedRepos = {};
  
  // Computed: which are newly selected
  Set<String> get _newlySelectedRepos {
    return _allSelectedRepos.difference(_previouslySelectedRepos);
  }
  
  // Computed: which were already selected
  Set<String> get _alreadySelectedRepos {
    return _allSelectedRepos.intersection(_previouslySelectedRepos);
  }
}
```

---

## Recommendations

### Immediate Fixes (P0)
1. **Clarify selection behavior**: Decide single-select vs multi-select and implement consistently
2. **Fix TextEditingController**: Move controller to class member, dispose properly
3. **Simplify checkmark rendering**: Use distinct icons instead of Stack

### UX Improvements (P1)
4. **Add visual feedback**: Show which repo will become default
5. **Add Expand/Collapse All**: Bulk controls for repo sections
6. **Clarify terminology**: Use consistent "Default" vs "Active" language

### Future Enhancements (P2)
7. **Add repo reordering**: Allow users to set default repo explicitly
8. **Add search in selected**: Filter already-configured repos
9. **Add repo metadata**: Show issue count, last sync time in picker

---

## Test Verdict

**Overall Status:** ⚠️ NEEDS WORK

| Category | Score | Notes |
|----------|-------|-------|
| Functionality | 7/9 | Multi-select behavior unclear |
| UI Consistency | 6/9 | Checkmark states confusing |
| State Management | 5/9 | Two-set pattern problematic |
| Performance | 8/9 | Minor memory leak in search |
| Accessibility | 6/9 | Visual distinctions too subtle |

**Total:** 32/45 (71%)

---

## Next Steps

1. **Product Decision Required**: Single-select or multi-select?
2. **Code Review**: Fix TextEditingController memory issue
3. **Design Review**: Simplify checkmark icon states
4. **UX Review**: Add default repo indicator
5. **Re-test**: After fixes, re-run all 9 scenarios

---

**Report Generated:** 2026-02-21  
**Tester:** MrTester  
**Device:** XPH0219904001750 (ELE L29 - Android 10)
