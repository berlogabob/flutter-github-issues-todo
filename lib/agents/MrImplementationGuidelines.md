# IMPLEMENTATION GUIDELINES FOR GITDOIT CORE TEAM

**Effective Date:** 2026-02-26
**Version:** 1.0
**Status:** MANDATORY FOR ALL AGENTS

## EXECUTION PROTOCOLS FOR NEW RESPONSIBILITIES

### 1. CONTINUOUS MODULAR CODE CHECKING (Code Quality Engineer)

#### Daily Execution Protocol:
```
Every development day, Code Quality Engineer must:
1. Run modular analysis on all changed files
2. Check for repetitive patterns using: 
   - Function duplication (>3 identical lines)
   - Widget repetition (>2 identical widget structures)
   - State management patterns (>2 similar providers)
3. Generate modular report in format:
   | File | Repetition | Location | Suggestion |
   |------|------------|----------|------------|
   | lib/widgets/item.dart | 3x | lines 45-67 | Extract to ReusableItemWidget |
```

#### Tools & Methods:
- **Static Analysis**: Use `flutter analyze` with custom rules for pattern detection
- **Code Metrics**: Track cyclomatic complexity > 10 as potential refactoring candidate
- **Component Catalog**: Maintain `lib/components/catalog.md` listing all reusable components
- **Modular Score**: Calculate score: (reusable_components / total_components) * 100

#### Enforcement Rules:
- Block merge if modular score < 60%
- Flag files with >2 repetitive patterns for immediate refactoring
- Require modular justification for any new complex widget (>50 lines)

### 2. DESIGN CONCEPT CONSISTENCY VERIFICATION (Code Quality Engineer + Flutter Developer)

#### Consistency Checklist (Run before each commit):
```
✅ Layout Patterns: All screens use same spacing system (8px grid)
✅ Color Palette: Only approved colors from design system used
✅ Typography: Consistent font sizes and weights across app
✅ Component Styling: Same button styles, card designs, etc.
✅ Navigation Flow: Consistent back/forward patterns
✅ Empty States: Uniform empty state design across features
✅ Loading States: Consistent spinner/placeholder patterns
```

#### Verification Process:
1. **Pre-commit Hook**: Automated consistency check runs on all modified files
2. **Visual Comparison**: Use ASCII mockups to verify layout consistency
3. **Component Audit**: Weekly review of all UI components for pattern drift
4. **Design System Compliance**: Validate against `design-system.md`

#### Design System Requirements:
- **Spacing**: 8px baseline grid (8, 16, 24, 32, 48, 64)
- **Colors**: Primary (blue), Secondary (orange), Success (green), Error (red), Background (dark gray)
- **Typography**: Headline (24px), Subtitle (18px), Body (16px), Caption (12px)
- **Components**: Standard button, card, list item, expandable item patterns

### 3. MODULAR COMPONENT DESIGN (Flutter Developer)

#### Component Creation Protocol:
```
When creating new widgets/components:
1. Check component catalog for existing similar components
2. If >50% similarity, extend existing component instead of creating new
3. Design for reusability: 
   - Generic type parameters where possible
   - Configurable properties (not hardcoded values)
   - Clear separation of concerns (UI vs logic)
4. Document component in catalog with:
   - Purpose
   - Props interface
   - Usage examples
   - Related components
```

#### Modular Architecture Principles:
- **Single Responsibility**: Each widget does one thing well
- **Composition over Inheritance**: Build complex UI from simple components
- **State Management**: Use Riverpod providers at appropriate levels
- **Dependency Injection**: Pass dependencies explicitly, not through context
- **Testability**: Components should be unit-testable in isolation

### 4. LAYOUT CONSISTENCY ENFORCEMENT (Flutter Developer)

#### Layout Pattern Standards:
```
SCREEN STRUCTURE:
┌─────────────────────────────┐
│ AppBar (consistent height)  │
├─────────────────────────────┤
│ Filter/Navigation Bar       │ ← Consistent across all main screens
├─────────────────────────────┤
│ Main Content Area           │ ← Same padding/margin system
│ • List/GridView             │
│ • Empty State               │
│ • Loading Indicator         │
└─────────────────────────────┘
│ FAB (consistent position)   │
└─────────────────────────────┘
```

#### Consistency Validation Steps:
1. **Before Implementation**: Sketch ASCII layout to verify pattern alignment
2. **During Development**: Compare with existing screens using side-by-side view
3. **Before Review**: Run layout consistency checker script
4. **Final Verification**: UX Validator confirms visual consistency

### 5. AUTOMATED ENFORCEMENT SYSTEM

#### Pre-commit Hooks Configuration:
```bash
# .git/hooks/pre-commit
#!/bin/bash
echo "Running GitDoIt consistency checks..."

# 1. Modular code check
dart run tool/modular_check.dart

# 2. Design consistency check  
dart run tool/design_consistency.dart

# 3. Version control check
dart run tool/version_check.dart

# 4. Prohibition enforcement
dart run tool/prohibition_check.dart

if [ $? -ne 0 ]; then
  echo "❌ Consistency checks failed - commit blocked"
  exit 1
fi

echo "✅ All consistency checks passed"
exit 0
```

#### Tool Scripts Structure:
```
/lib/tools/
├── modular_check.dart
├── design_consistency.dart  
├── version_check.dart
├── prohibition_check.dart
└── component_catalog.dart
```

### 6. REPORTING FORMAT FOR NEW RESPONSIBILITIES

#### Modular Analysis Report:
```markdown
## Code Quality Report #[ID]

### Modular Check Results
| File | Repetitions | Action Required |
|------|-------------|----------------|
| lib/widgets/issue_item.dart | 2 | Extract common parts to BaseIssueWidget |
| lib/screens/project_board.dart | 3 | Refactor list rendering to reusable ListViewBuilder |

### Design Consistency Score: 92/100
- Layout patterns: ✅ consistent
- Color usage: ✅ approved palette
- Typography: ⚠️ 2 instances of non-standard font size
- Component styling: ✅ uniform
```

#### Daily Consistency Dashboard:
```
MODULAR HEALTH: 87% (Target: ≥90%)
DESIGN CONSISTENCY: 94% (Target: ≥95%)
REUSABLE COMPONENTS: 24/32 (75%)
REPETITIVE PATTERNS: 3 (Critical: 0, Warning: 3)
```

## ENFORCEMENT MATRIX

| Responsibility | Owner | Frequency | Tools | Failure Response |
|---------------|-------|-----------|-------|------------------|
| Modular checking | Code Quality Engineer | Daily | Static analysis, catalog | Block merge, require refactoring |
| Design consistency | Code Quality Engineer + Flutter Developer | Per commit | Pre-commit hooks, visual comparison | Block commit, require alignment |
| Layout consistency | Flutter Developer | Per screen | ASCII mockups, pattern library | Reject implementation, redesign |
| Component reusability | Flutter Developer | Per new component | Component catalog, similarity check | Require extension instead of new creation |

## IMPLEMENTATION ROADMAP

### Phase 1 (Immediate):
1. Set up pre-commit hooks with basic consistency checks
2. Create component catalog template
3. Define design system standards
4. Train team on new protocols

### Phase 2 (Next Sprint):
1. Implement automated modular analysis tool
2. Establish weekly consistency audits
3. Integrate with CI/CD pipeline
4. Create dashboard for team visibility

### Phase 3 (Ongoing):
1. Continuous improvement of detection algorithms
2. Expand component catalog coverage
3. Refine consistency scoring metrics
4. Automate remediation suggestions

---
**Approved by:** Project Coordinator
**Compliance:** All agents must execute these guidelines strictly