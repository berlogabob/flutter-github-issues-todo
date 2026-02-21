# UX/UI AGENT - REDESIGN SPRINT TASK

## Mission
Create complete design system and component library for GitDoIt app using Industrial Minimalism & Spatial Depth guidelines.

## Context
The app is being completely redesigned to follow the new Universal Design Guidelines:
- **Theme:** Industrial Minimalism (Teenage Engineering × Nothing Phone × Notion × Revolut)
- **Palette:** Monochrome (black, white, gray) + Signal Orange (#FF5500)
- **Typography:** Inter (primary) + JetBrains Mono (secondary)
- **Grid:** 8px base unit
- **Depth:** Z-axis translation (Z=0 base, Z=1 interactive, Z=2 attraction)
- **Motion:** Spring physics, tactile feedback

## Your Tasks

### Phase 1: Design Tokens Specification (30 min)
Create detailed specification for:
1. **Color System** - Exact hex codes, usage rules, contrast ratios
2. **Typography Scale** - Font sizes, weights, line heights for all text styles
3. **Spacing Grid** - All margins, padding, gaps (multiples of 8)
4. **Elevation System** - Z-levels, shadow values, lighting angles
5. **Animation Curves** - Spring parameters, durations, easing functions

### Phase 2: Atomic Widget Designs (90 min)
Design specifications for:
1. **Primary Button** - Signal Orange, Z-axis hover, physical press
2. **Secondary Button** - Monochrome, border-focused
3. **Text Button** - Minimal, caption style
4. **Data Card** - Modular block, Z=1, emerging on hover
5. **Interactive Card** - Z=1→Z=2 transition, tactile feedback
6. **Text Input** - Industrial border, focus illumination
7. **Dropdown/Select** - Hardware-like control
8. **Badge/Chip** - Status indicator, dot-matrix style
9. **Toggle Switch** - Physical switch simulation
10. **Slider/Fader** - Teenage Engineering style

### Phase 3: Screen Layouts (120 min)
Create wireframe specifications for:
1. **Auth Screen** - Minimal, focused, industrial
2. **Home Screen** - Modular cards, grid exposed
3. **Issue Detail** - Spatial depth, technical annotations
4. **Edit Issue** - Hardware controls, faders/switches
5. **Settings** - Technical, monospace labels

### Phase 4: Interaction Specifications (60 min)
Define for each component:
1. **Idle State** - Base appearance (Z level, colors)
2. **Hover State** - Z-translation, glow, elevation
3. **Press State** - Physical depression, shadow change
4. **Focus State** - Border illumination, thickening
5. **Disabled State** - Reduced opacity, no interaction
6. **Loading State** - Dot-matrix spinner, glyph style

### Phase 5: Accessibility Audit (30 min)
Verify and document:
1. **Contrast Ratios** - All text passes WCAG AA (4.5:1)
2. **Touch Targets** - Minimum 48x48 dp
3. **Semantic Labels** - All custom elements labeled
4. **Focus Order** - Logical navigation
5. **Color Independence** - Status not color-only

## Output Format

Create file: `agents/reports/ux_ui_redesign_report.md`

```markdown
# UX/UI Redesign Report

## 🎨 Design Tokens

### Color System
[Complete specification with hex codes and usage rules]

### Typography
[Complete scale with sizes, weights, line heights]

### Spacing Grid
[All spacing values as multiples of 8]

### Elevation
[Z-levels with shadow and lighting specs]

### Animation
[Spring parameters and curves]

## 🧩 Component Library

### [Component Name]
**Purpose:** [What it does]
**Z-Level:** [0/1/2]
**States:**
- Idle: [description]
- Hover: [description]
- Press: [description]
- Focus: [description]
- Disabled: [description]

**Visual Spec:**
- Background: [color]
- Border: [color, width]
- Padding: [value]
- Radius: [value]
- Typography: [style]

**Interaction:**
- Spring: [mass, tension, friction]
- Duration: [ms]
- Haptic: [yes/no]

[Repeat for all components]

## 📱 Screen Layouts

### [Screen Name]
**Grid:** [columns, spacing]
**Components:** [list]
**Flow:** [user journey]
**Annotations:** [technical notes]

[Repeat for all screens]

## ♿ Accessibility Audit

| Check | Status | Notes |
|-------|--------|-------|
| Contrast | ✅/❌ | [details] |
| Touch Targets | ✅/❌ | [details] |
| Semantics | ✅/❌ | [details] |
| Focus Order | ✅/❌ | [details] |
| Color Independence | ✅/❌ | [details] |

## 🎯 Design Decisions

| Decision | Rationale | Alternative Rejected |
|----------|-----------|---------------------|
| [decision] | [why] | [what] |

## 📦 Handoff Notes

For Senior Developer:
- [Implementation priorities]
- [Complex interactions]
- [Performance considerations]

For Stupid User:
- [Key flows to test]
- [Potential confusion points]
```

## Integration Points

**You receive from:**
- MrPlanner: Sprint plan and task breakdown
- MrArchitector: Component architecture

**You provide to:**
- MrSeniorDeveloper: Component specifications, screen layouts
- MrStupidUser: Wireframes for usability testing
- MrCleaner: Design consistency guidelines

## Success Criteria

- [ ] All design tokens specified with exact values
- [ ] All atomic components designed with states
- [ ] All screens laid out with grid specifications
- [ ] All interactions defined with spring physics
- [ ] Accessibility audit complete and passing
- [ ] Report created in `agents/reports/`

## Begin Mission

Start by reading the Universal Design Guidelines in `agents/mr_ux_ui_designer.md`, then execute all phases in order. Report progress hourly.

**MOTTO:** *Code is Material. Neutral Base. Tactile Digital.*
