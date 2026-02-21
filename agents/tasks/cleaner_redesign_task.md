# CLEANER AGENT - REDESIGN SPRINT TASK

## Mission
Ensure code cleanliness, remove old design artifacts, and maintain consistent style throughout the redesign.

## Context
The app is undergoing a complete visual redesign. Your role is to:
- Remove old Material Design artifacts
- Clean up dead code from previous implementations
- Ensure consistent formatting across all new files
- Optimize imports and remove unused dependencies
- Refactor complex code for clarity

## Your Tasks

### Phase 1: Pre-Cleanup Analysis (15 min)
Analyze the codebase to identify:

1. **Old Design Artifacts**
   - Files with heavy Material Design usage
   - Outdated widget implementations
   - Deprecated patterns

2. **Dead Code**
   - Unused imports
   - Commented-out code
   - Unused variables and functions
   - Old TODOs that are no longer relevant

3. **Formatting Issues**
   - Files not following dart format
   - Inconsistent naming conventions
   - Inconsistent spacing

### Phase 2: Parallel Cleanup (60 min)
As Senior Developer implements new code, clean:

1. **Design Token Files**
   - Ensure consistent naming
   - Remove redundant constants
   - Format with dart format

2. **Theme Files**
   - Clean up unused theme properties
   - Ensure consistent structure
   - Remove Material leakage

3. **Widget Files**
   - Remove unused imports
   - Format code
   - Simplify complex expressions
   - Add missing documentation

4. **Screen Files**
   - Clean up old layout code
   - Remove commented-out widgets
   - Format and organize

### Phase 3: Refactoring (45 min)
Refactor for clarity and performance:

1. **Extract Common Patterns**
   - Repeated widget trees → methods
   - Complex build methods → smaller widgets
   - Repeated animations → utilities

2. **Optimize Performance**
   - const constructors where possible
   - Avoid unnecessary rebuilds
   - Use ValueListenableBuilder appropriately

3. **Improve Readability**
   - Long methods → shorter methods
   - Complex conditions → named booleans
   - Magic numbers → named constants

### Phase 4: Final Cleanup (30 min)
Final pass through entire codebase:

1. **Run dart format**
   - All .dart files in lib/
   - All .dart files in test/

2. **Remove Unused Imports**
   - Use IDE analysis or dart analyze
   - Remove package:material imports where not needed

3. **Update Documentation**
   - Remove outdated comments
   - Update class/method documentation
   - Add missing documentation

4. **Clean TODOs**
   - Remove completed TODOs
   - Update relevant TODOs
   - Add new TODOs for future improvements

## Output Format

Create file: `agents/reports/cleaner_redesign_report.md`

```markdown
# Code Cleanup Report

## 🧹 Cleanup Summary

### Files Processed
| Directory | Files | Actions |
|-----------|-------|---------|
| lib/design_tokens/ | X | formatted, imports cleaned |
| lib/theme/ | X | formatted, refactored |
| lib/widgets/ | X | formatted, optimized |
| lib/screens/ | X | formatted, cleaned |
| lib/providers/ | X | formatted |
| lib/services/ | X | formatted |
| lib/models/ | X | formatted |

### Total Impact
- **Files Modified:** X
- **Lines Removed:** X
- **Lines Added:** X
- **Imports Removed:** X
- **Methods Extracted:** X

## 🗑️ Removed Artifacts

### Old Design Code
- [File/Pattern]: [What was removed]
- [File/Pattern]: [What was removed]

### Dead Code
- [File]: [Function/Variable removed]
- [File]: [Commented code removed]

### Unused Imports
- [File]: [Import removed]
- [File]: [Import removed]

## ♻️ Refactoring

### Extracted Methods
| File | Before | After | Reason |
|------|--------|-------|--------|
| file.dart | 100 lines | 40 lines | Split build method |

### Optimized Performance
| File | Optimization | Impact |
|------|-------------|--------|
| file.dart | Added const | Reduced rebuilds |

### Improved Readability
| File | Change | Benefit |
|------|--------|---------|
| file.dart | Named boolean | Clearer intent |

## 📋 Formatting

### dart format Applied
```bash
dart format lib/
```

**Result:** All files formatted successfully

### Import Organization
- Sorted imports (alphabetically)
- Removed duplicates
- Grouped by: dart:, package:, relative

## ⚠️ Issues Found

### Code Quality Issues
| Severity | File | Issue | Recommendation |
|----------|------|-------|----------------|
| High | file.dart | Complex method | Extract to smaller method |
| Medium | file.dart | Long parameter list | Use parameter object |

### Material Design Leakage
| File | Material Widget | Status |
|------|----------------|--------|
| file.dart | RaisedButton | ⚠️ Should be replaced |
| file.dart | Card | ✅ Themed beyond recognition |

## ✅ Quality Checks

| Check | Status | Notes |
|-------|--------|-------|
| dart format | ✅/❌ | All files pass |
| dart analyze | ✅/❌ | No errors/warnings |
| Unused imports | ✅/❌ | All removed |
| Dead code | ✅/❌ | All removed |
| Documentation | ✅/❌ | All public APIs documented |

## 📝 Recommendations

For Future Development:
- [Coding pattern to adopt]
- [Anti-pattern to avoid]
- [Performance tip]

For Next Cleanup:
- [Area that needs attention]
- [Technical debt to address]
```

## Integration Points

**You receive from:**
- MrSeniorDeveloper: New code to clean
- MrArchitector: List of files to remove

**You provide to:**
- MrLogger: Clean codebase for logging integration
- MrStupidUser: Clean code for testing

## Tools & Commands

```bash
# Format all Dart files
dart format lib/

# Analyze for issues
dart analyze

# Check for unused imports
dart pub run import_sorter:main

# Run tests (if available)
flutter test
```

## Success Criteria

- [ ] All files formatted with dart format
- [ ] All unused imports removed
- [ ] All dead code removed
- [ ] All commented code removed (unless documentation)
- [ ] Complex code refactored for clarity
- [ ] Performance optimizations applied
- [ ] Documentation updated
- [ ] Report created in `agents/reports/`

## Begin Mission

Work in parallel with Senior Developer. Clean each file immediately after they complete implementation. Run dart format frequently.

**MOTTO:** *Clean Code is Happy Code.*
