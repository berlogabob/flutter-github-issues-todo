# ARCHITECT AGENT - REDESIGN SPRINT TASK

## Mission
Design new component architecture and data flow for the redesigned GitDoIt app with Industrial Minimalism theme.

## Context
The app is being redesigned with a completely new visual language. You must ensure the architecture supports:
- Custom design tokens (colors, typography, spacing, elevation)
- Atomic widget library (buttons, cards, inputs, badges)
- Spatial depth system (Z-axis translation)
- Spring physics animations
- Offline-first data patterns
- Pure Flutter rendering (no platform-specific adaptations)

## Your Tasks

### Phase 1: Component Architecture (60 min)
Design the new directory structure and component hierarchy:

1. **Design Tokens Layer**
   - How tokens are defined (constants, themes, extensions)
   - How tokens are accessed (static, context-based, provider)
   - Token organization (colors, typography, spacing, elevation, animations)

2. **Theme Layer**
   - Custom theme implementation (not Material)
   - Theme inheritance and overrides
   - Dark/light theme support (if applicable)

3. **Widget Layer**
   - Atomic design structure (atoms → molecules → organisms)
   - Widget composition patterns
   - State management for interactive widgets

4. **Screen Layer**
   - Screen composition from widgets
   - Navigation patterns
   - Route management

### Phase 2: Data Flow Design (45 min)
Map data flow for:

1. **Authentication Flow**
   - Token storage and retrieval
   - Auth state propagation
   - Screen navigation based on auth

2. **Issues Data Flow**
   - GitHub API → Local cache → UI
   - Offline-first sync patterns
   - State management (Provider/Riverpod/Bloc)

3. **User Interaction Flow**
   - Touch input → Animation → Visual feedback
   - Haptic feedback integration
   - Performance optimization (60/120fps)

### Phase 3: Architecture Review (45 min)
Review existing codebase and identify:

1. **What to Keep**
   - Models that are still valid
   - Services that don't need changes
   - Utilities that are theme-agnostic

2. **What to Modify**
   - Widgets that need redesign
   - Screens that need new layouts
   - Providers that need theme integration

3. **What to Remove**
   - Material Design dependencies
   - Dead code and unused imports
   - Outdated patterns

### Phase 4: Technical Specifications (30 min)
Create implementation guides for:

1. **Z-Axis Translation System**
   - How to implement elevation in Flutter
   - Shader usage for lighting effects
   - Performance considerations

2. **Spring Physics Animation**
   - AnimationController setup
   - Spring simulation parameters
   - Reusable animation utilities

3. **Custom Painting Strategy**
   - When to use CustomPainter vs standard widgets
   - Dot-matrix pattern implementation
   - Procedural texture generation

## Output Format

Create file: `agents/reports/architect_redesign_report.md`

```markdown
# Architecture Redesign Report

## 🏗️ Component Architecture

### Directory Structure
```
lib/
├── design_tokens/
│   ├── colors.dart
│   ├── typography.dart
│   ├── spacing.dart
│   ├── elevation.dart
│   └── animations.dart
├── theme/
│   ├── app_theme.dart
│   ├── industrial_theme.dart
│   └── widgets/
├── widgets/
│   ├── atoms/
│   ├── molecules/
│   └── organisms/
├── screens/
├── providers/
├── services/
└── models/
```

### Component Hierarchy
[Diagram showing atom → molecule → organism → screen]

### Design Token System
[How tokens are defined and accessed]

## 🔄 Data Flow

### Authentication Flow
[Sequence diagram or step-by-step flow]

### Issues Data Flow
[Offline-first sync pattern]

### Interaction Flow
[Touch → Animation → Feedback loop]

## 📋 Architecture Decisions

| Decision | Rationale | Impact |
|----------|-----------|--------|
| [decision] | [why] | [what it affects] |

## 🔍 Codebase Review

### Keep
- [List of files/patterns to preserve]

### Modify
- [List of files to update]
- [Required changes]

### Remove
- [List of files/patterns to delete]

## 🛠️ Technical Specifications

### Z-Axis Implementation
[Code examples and patterns]

### Spring Animation Setup
[AnimationController configuration]

### CustomPainter Guidelines
[When and how to use]

## ⚠️ Constraints & Considerations

### Performance
- [Performance targets]
- [Optimization strategies]

### Accessibility
- [Accessibility requirements]
- [Implementation notes]

### Cross-Platform
- [Consistency requirements]
- [Platform-specific handling]

## 📦 Handoff Notes

For Senior Developer:
- [Implementation priorities]
- [Complex architecture decisions]
- [Potential challenges]

For UX/UI:
- [Technical constraints]
- [Performance budgets]

For Cleaner:
- [Files to remove]
- [Refactoring priorities]
```

## Integration Points

**You receive from:**
- MrPlanner: Sprint plan and requirements
- MrUXUIDesigner: Design specifications

**You provide to:**
- MrSeniorDeveloper: Architecture blueprint, implementation guide
- MrCleaner: List of files to remove/refactor
- MrLogger: Logging architecture requirements

## Success Criteria

- [ ] Directory structure defined and documented
- [ ] Component hierarchy clear (atomic design)
- [ ] Data flows mapped for all features
- [ ] Architecture decisions documented with rationale
- [ ] Codebase review complete (keep/modify/remove)
- [ ] Technical specifications provided (Z-axis, springs, painting)
- [ ] Report created in `agents/reports/`

## Begin Mission

Start by analyzing the current codebase structure in `gitdoit/lib/`, then execute all phases. Coordinate with UX/UI agent to ensure architecture supports design requirements.

**MOTTO:** *Structure First. Flow Second. Polish Third.*
