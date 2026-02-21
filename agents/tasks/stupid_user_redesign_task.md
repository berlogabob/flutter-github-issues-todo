# STUPID USER AGENT - REDESIGN SPRINT TASK

## Mission
Test the redesigned app from a naive user perspective and identify all usability issues.

## Context
The app has been completely redesigned with Industrial Minimalism. Your role is to:
- Test as a first-time user
- Find confusing elements and flows
- Identify accessibility issues
- Report usability problems
- Validate fixes

## Your Tasks

### Phase 1: First Impressions (15 min)
Open the app with fresh eyes:

1. **Initial Load**
   - What do you see first?
   - Is it clear what this app does?
   - Does it look inviting or intimidating?

2. **Visual Hierarchy**
   - What draws your attention?
   - Is the primary action clear?
   - Are important elements easy to find?

3. **Industrial Aesthetic**
   - Does it feel too technical/cold?
   - Are the controls intuitive?
   - Is the monochrome palette working?

### Phase 2: Core Flow Testing (60 min)
Test all primary user flows:

1. **Authentication Flow**
   ```
   Open app → See auth screen → Enter token → Submit → Land on home
   ```
   - Is it clear where to put the token?
   - Is the button obviously clickable?
   - Is feedback clear when submitting?
   - Does the transition feel smooth?

2. **Browse Issues Flow**
   ```
   Home screen → See issue cards → Scroll → Tap issue → See details
   ```
   - Are cards obviously tappable?
   - Is the list easy to scan?
   - Is important info visible at a glance?
   - Does hover/press feedback work?

3. **Edit Issue Flow**
   ```
   Detail screen → Tap edit → Modify fields → Save → See changes
   ```
   - Are controls intuitive?
   - Is it clear how to save/cancel?
   - Do the hardware-like controls make sense?
   - Is validation clear?

4. **Navigation Flow**
   ```
   Home → Detail → Back → Settings → Back → Home
   ```
   - Is it clear how to go back?
   - Are navigation elements consistent?
   - Do you know where you are in the app?

### Phase 3: Interaction Testing (45 min)
Test all interactive elements:

1. **Buttons**
   - Primary button: Does it look clickable?
   - Hover effect: Does it feel responsive?
   - Press effect: Does it feel tactile?
   - Loading state: Is it clear something is happening?

2. **Cards**
   - Hover: Does it emerge nicely?
   - Tap: Is feedback immediate?
   - Content: Is it readable?

3. **Inputs**
   - Focus: Is it clear which is active?
   - Typing: Is text visible?
   - Labels: Are they clear?
   - Validation: Are errors obvious?

4. **Toggles/Sliders**
   - Do they look like controls?
   - Is the interaction obvious?
   - Does state change feel physical?
   - Is the current state clear?

### Phase 4: Accessibility Testing (30 min)
Test accessibility features:

1. **Screen Reader** (if available)
   - Are elements read correctly?
   - Is the order logical?
   - Are purposes clear?

2. **Keyboard Navigation** (web)
   - Can you tab through everything?
   - Is focus visible?
   - Can you activate everything?

3. **Touch Targets**
   - Are buttons easy to tap?
   - Are cards easy to select?
   - Is there enough spacing?

4. **Contrast**
   - Is all text readable?
   - Are borders visible?
   - Do icons stand out?

### Phase 5: Edge Cases (30 min)
Test unusual scenarios:

1. **Empty States**
   - No issues: What do you see?
   - Offline: What do you see?
   - Error: What do you see?

2. **Long Content**
   - Long titles: Do they break layout?
   - Long descriptions: Do they scroll?
   - Many issues: Does performance suffer?

3. **State Changes**
   - Quick tapping: Does it handle?
   - Slow connection: Is feedback clear?
   - Orientation change: Does layout adapt?

## Output Format

Create file: `agents/reports/stupid_user_redesign_report.md`

```markdown
# Stupid User Testing Report

## 🤔 First Impressions

### Initial Reaction
**What I thought when I opened the app:**
[Your honest reaction]

**What I thought the app does:**
[Your understanding]

**Emotional response:**
- Inviting / Intimidating
- Clear / Confusing
- Modern / Dated

## 🎯 Core Flow Testing

### Authentication Flow
**Path:** Open app → Auth screen → Enter token → Home

| Step | Status | Confusion | Suggestion |
|------|--------|-----------|------------|
| See auth screen | ✅/❌ | [what was confusing] | [suggestion] |
| Enter token | ✅/❌ | [what was confusing] | [suggestion] |
| Submit | ✅/❌ | [what was confusing] | [suggestion] |
| Land on home | ✅/❌ | [what was confusing] | [suggestion] |

**Overall:** Pass / Fail  
**Issues Found:** X

### Browse Issues Flow
**Path:** Home → Scroll → Tap issue → Detail

| Step | Status | Confusion | Suggestion |
|------|--------|-----------|------------|
| See cards | ✅/❌ | [what was confusing] | [suggestion] |
| Understand tappable | ✅/❌ | [what was confusing] | [suggestion] |
| Read info | ✅/❌ | [what was confusing] | [suggestion] |
| Navigate back | ✅/❌ | [what was confusing] | [suggestion] |

**Overall:** Pass / Fail  
**Issues Found:** X

### Edit Issue Flow
**Path:** Detail → Edit → Modify → Save

| Step | Status | Confusion | Suggestion |
|------|--------|-----------|------------|
| Find edit button | ✅/❌ | [what was confusing] | [suggestion] |
| Understand controls | ✅/❌ | [what was confusing] | [suggestion] |
| Know how to save | ✅/❌ | [what was confusing] | [suggestion] |
| See confirmation | ✅/❌ | [what was confusing] | [suggestion] |

**Overall:** Pass / Fail  
**Issues Found:** X

## 🎮 Interaction Testing

### Buttons
| Type | Looks Clickable | Hover Works | Press Works | Loading Clear |
|------|----------------|-------------|-------------|---------------|
| Primary | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |
| Secondary | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |
| Text | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |

**Notes:** [Your observations]

### Cards
| Behavior | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Hover emerge | Lifts slightly | [what happened] | ✅/❌ |
| Press feedback | Depresses | [what happened] | ✅/❌ |
| Tap navigation | Goes to detail | [what happened] | ✅/❌ |

**Notes:** [Your observations]

### Inputs
| Behavior | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Focus visible | Border lights up | [what happened] | ✅/❌ |
| Text readable | Clear contrast | [what happened] | ✅/❌ |
| Label clear | Purpose obvious | [what happened] | ✅/❌ |

**Notes:** [Your observations]

### Toggles/Sliders
| Control | Looks Interactive | State Clear | Feels Physical | Pass/Fail |
|---------|------------------|-------------|----------------|-----------|
| Toggle 1 | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |
| Slider 1 | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ |

**Notes:** [Your observations]

## ♿ Accessibility Testing

### Screen Reader
| Element | Label Clear | Purpose Clear | Order Logical |
|---------|-------------|---------------|---------------|
| Buttons | ✅/❌ | ✅/❌ | ✅/❌ |
| Cards | ✅/❌ | ✅/❌ | ✅/❌ |
| Inputs | ✅/❌ | ✅/❌ | ✅/❌ |

**Notes:** [Your observations]

### Keyboard Navigation
| Behavior | Expected | Actual | Pass/Fail |
|----------|----------|--------|-----------|
| Tab order | Logical | [what happened] | ✅/❌ |
| Focus visible | Clear indicator | [what happened] | ✅/❌ |
| Enter activates | Works on buttons | [what happened] | ✅/❌ |

**Notes:** [Your observations]

### Touch Targets
| Element | Size Adequate | Spacing Adequate | Easy to Tap |
|---------|--------------|------------------|-------------|
| Buttons | ✅/❌ | ✅/❌ | ✅/❌ |
| Cards | ✅/❌ | ✅/❌ | ✅/❌ |
| Icons | ✅/❌ | ✅/❌ | ✅/❌ |

**Notes:** [Your observations]

### Contrast
| Element | Text Readable | Borders Visible | Icons Clear |
|---------|--------------|-----------------|-------------|
| Headlines | ✅/❌ | N/A | N/A |
| Body text | ✅/❌ | N/A | N/A |
| Captions | ✅/❌ | N/A | N/A |
| Borders | N/A | ✅/❌ | N/A |
| Icons | N/A | N/A | ✅/❌ |

**Notes:** [Your observations]

## 🐛 Issues Summary

### Critical Issues (Break the flow)
| ID | Issue | Steps to Reproduce | Severity | Suggestion |
|----|-------|-------------------|----------|------------|
| 1 | [issue] | [steps] | Critical | [fix] |

### Major Issues (Confusing but works)
| ID | Issue | Steps to Reproduce | Severity | Suggestion |
|----|-------|-------------------|----------|------------|
| 1 | [issue] | [steps] | Major | [fix] |

### Minor Issues (Annoyances)
| ID | Issue | Steps to Reproduce | Severity | Suggestion |
|----|-------| [steps] | Minor | [fix] |

## 🎨 Design Feedback

### What Works Well
- [Thing 1]: Why it's good
- [Thing 2]: Why it's good
- [Thing 3]: Why it's good

### What Needs Improvement
- [Thing 1]: Why it's confusing
- [Thing 2]: Why it's confusing
- [Thing 3]: Why it's confusing

### What's Missing
- [Feature/Element]: Why it's needed
- [Feature/Element]: Why it's needed

## ✅ Overall Verdict

**Would I use this app again:** Yes / No / Maybe

**Biggest Strength:** [One thing]

**Biggest Weakness:** [One thing]

**One thing to fix:** [Most important fix]

**Rating:** ⭐⭐⭐⭐⭐ (1-5 stars)
```

## Integration Points

**You receive from:**
- SeniorDeveloper: Features to test
- UX/UI: Expected behaviors

**You provide to:**
- SeniorDeveloper: Issues to fix
- UX/UI: Design feedback

## Success Criteria

- [ ] All core flows tested
- [ ] All interactions tested
- [ ] Accessibility tested
- [ ] Edge cases explored
- [ ] Issues documented with steps
- [ ] Suggestions provided
- [ ] Overall verdict given
- [ ] Report created in `agents/reports/`

## Begin Mission

Wait for Senior Developer to complete screen implementations. Then test everything with fresh eyes. Be honest - you're the user's advocate.

**MOTTO:** *If It's Confusing, It's Broken.*
