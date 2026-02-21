# PLANNER AGENT - REDESIGN SPRINT TASK

## Mission
Create detailed implementation roadmap and track sprint progress for the complete app redesign.

## Context
The team is executing an intensive 1-day redesign sprint. Your role is to:
- Break down the sprint plan into hourly tasks
- Track progress throughout the day
- Identify blockers and risks
- Coordinate agent activities
- Ensure sprint goals are met

## Your Tasks

### Phase 1: Sprint Setup (15 min)
Initialize sprint tracking:

1. **Sprint Board**
   - Create task tracking document
   - Set up hourly checkpoints
   - Define success metrics

2. **Agent Assignments**
   - Confirm all agents understand their tasks
   - Verify task files are created
   - Ensure integration points are clear

3. **Baseline Metrics**
   - Document current state of codebase
   - Count existing files/screens/widgets
   - Note current design patterns

### Phase 2: Hourly Planning (Ongoing)
Create and update hourly plans:

**Hour 0-1: Foundation**
- [ ] UX/UI: Design tokens specification
- [ ] Architect: Component architecture
- [ ] SeniorDev: Read specifications

**Hour 1-2: Architecture**
- [ ] Architect: Data flow design
- [ ] UX/UI: Atomic widget designs
- [ ] SeniorDev: Implement design tokens

**Hour 2-3: Core Implementation**
- [ ] SeniorDev: Theme system
- [ ] UX/UI: Screen layouts
- [ ] Architect: Codebase review

**Hour 3-4: Widgets**
- [ ] SeniorDev: Atomic widgets (buttons, cards)
- [ ] UX/UI: Interaction specifications
- [ ] Cleaner: Start cleanup (tokens, theme)

**Hour 4-5: Widgets Continued**
- [ ] SeniorDev: Atomic widgets (inputs, badges, toggles)
- [ ] UX/UI: Accessibility audit prep
- [ ] Cleaner: Continue cleanup (widgets)

**Hour 5-6: Screens**
- [ ] SeniorDev: Auth screen, Home screen
- [ ] UX/UI: Screen layout review
- [ ] Cleaner: Cleanup (screens start)

**Hour 6-7: Screens Continued**
- [ ] SeniorDev: Issue detail, Edit screen
- [ ] UX/UI: Spatial states review
- [ ] Cleaner: Cleanup (screens continue)

**Hour 7-8: Final Screens**
- [ ] SeniorDev: Settings screen, animations
- [ ] UX/UI: Final design review
- [ ] Cleaner: Final cleanup pass

**Hour 8-9: Validation**
- [ ] StupidUser: Usability testing
- [ ] UX/UI: Accessibility audit
- [ ] SeniorDev: Fix issues found

**Hour 9-10: Polish**
- [ ] Logger: Add logging
- [ ] Cleaner: Final format
- [ ] SeniorDev: Final fixes

**Hour 10-11: Review**
- [ ] SeniorDev: Code review
- [ ] StupidUser: Final testing
- [ ] All: Prepare reports

**Hour 11-12: Sprint Close**
- [ ] All: Final reports
- [ ] Planner: Sprint summary
- [ ] Team: Retrospective

### Phase 3: Progress Tracking (Ongoing)
Track progress hourly:

1. **Task Completion**
   - Mark tasks as: ⬜ Not Started → 🔄 In Progress → ✅ Complete
   - Note any blockers
   - Escalate risks

2. **Quality Checks**
   - Verify output quality
   - Ensure guidelines followed
   - Check accessibility compliance

3. **Time Management**
   - Track actual vs estimated time
   - Adjust priorities if behind
   - Reallocate resources if needed

### Phase 4: Risk Management (Ongoing)
Identify and mitigate risks:

1. **Technical Risks**
   - Material Design leakage
   - Performance degradation
   - Accessibility failures

2. **Schedule Risks**
   - Tasks taking longer than estimated
   - Dependencies blocking progress
   - Agent availability

3. **Quality Risks**
   - Inconsistent design implementation
   - Missing accessibility features
   - Incomplete testing

## Output Format

Create file: `agents/reports/planner_redesign_report.md`

```markdown
# Sprint Planner Report

## 📊 Sprint Status

**Sprint:** Redesign - Industrial Minimalism  
**Date:** 2026-02-21  
**Duration:** 12 hours  
**Current Hour:** X/12  
**Status:** 🟢 On Track / 🟡 At Risk / 🔴 Behind

## 🎯 Sprint Goals

| Goal | Status | Notes |
|------|--------|-------|
| Design tokens implemented | ✅/⚠️/❌ | [notes] |
| Custom theme functional | ✅/⚠️/❌ | [notes] |
| Atomic widgets complete | ✅/⚠️/❌ | [notes] |
| All screens redesigned | ✅/⚠️/❌ | [notes] |
| Accessibility audit pass | ✅/⚠️/❌ | [notes] |
| Code quality maintained | ✅/⚠️/❌ | [notes] |

## ⏰ Hourly Progress

### Hour 1 (Foundation)
**Time:** 00:00 - 01:00  
**Focus:** Design tokens, architecture  
**Status:** ✅ Complete / 🔄 In Progress / ⏳ Pending

| Agent | Task | Status | Notes |
|-------|------|--------|-------|
| UX/UI | Design tokens spec | ✅ | [notes] |
| Architect | Component architecture | ✅ | [notes] |
| SeniorDev | Review specs | ✅ | [notes] |

### Hour 2 (Architecture)
**Time:** 01:00 - 02:00  
**Focus:** Data flow, widget designs  
**Status:** ✅ Complete / 🔄 In Progress / ⏳ Pending

[Continue for all hours]

## 🚧 Blockers & Risks

### Current Blockers
| Blocker | Impact | Owner | Resolution |
|---------|--------|-------|------------|
| [blocker] | High/Med/Low | [agent] | [action] |

### Active Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [risk] | High/Med/Low | High/Med/Low | [action] |

## 📈 Metrics

### Velocity
| Hour | Planned Tasks | Completed | Variance |
|------|--------------|-----------|----------|
| 1 | 3 | 3 | 0 |
| 2 | 3 | 2 | -1 |

### Quality
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Files Changed | 20 | 15 | 🟡 |
| Accessibility Issues | 0 | 2 | 🔴 |
| Code Review Pass | 100% | 80% | 🟡 |

### Agent Workload
| Agent | Tasks Assigned | Tasks Complete | Utilization |
|-------|---------------|----------------|-------------|
| UX/UI | 10 | 8 | 80% |
| Architect | 8 | 8 | 100% |
| SeniorDev | 15 | 12 | 80% |
| Cleaner | 8 | 6 | 75% |
| StupidUser | 5 | 3 | 60% |
| Logger | 4 | 2 | 50% |

## 🎯 Priority Adjustments

### Reprioritized Tasks
| Task | Original Priority | New Priority | Reason |
|------|------------------|--------------|--------|
| [task] | High | Medium | [reason] |

### Scope Changes
| Change | Impact | Approved By |
|--------|--------|-------------|
| [change] | +1 hour | Self |

## 📝 Agent Coordination

### Integration Points Active
- UX/UI → SeniorDev: Design specs delivered ✅
- Architect → SeniorDev: Architecture delivered ✅
- SeniorDev → Cleaner: Code ready for cleanup 🔄
- SeniorDev → StupidUser: Ready for testing ⏳

### Communication Notes
- [Important team communications]
- [Decisions made]
- [Clarifications provided]

## 🏁 Sprint Completion

### Definition of Done Checklist
- [ ] All design tokens implemented
- [ ] Custom theme functional
- [ ] All atomic widgets complete
- [ ] All screens redesigned
- [ ] Accessibility audit passing
- [ ] Code formatted and cleaned
- [ ] All reports submitted
- [ ] Sprint retrospective complete

### Final Summary
**Completed:** X/Y tasks (Z%)  
**Quality:** Pass/Fail  
**Time:** X/12 hours  
**Verdict:** Success/Partial Success/Learning Experience

### Retrospective Notes

**What Went Well:**
- [Success 1]
- [Success 2]

**What Could Improve:**
- [Improvement 1]
- [Improvement 2]

**Action Items for Next Sprint:**
- [Action 1]
- [Action 2]
```

## Integration Points

**You receive from:**
- All Agents: Progress updates, status reports
- Sprint Plan: Original sprint objectives

**You provide to:**
- All Agents: Priority adjustments, timeline updates
- Stakeholders: Sprint status, progress reports

## Tools & Commands

```bash
# Check git status for changed files
git status

# View recent commits
git log --oneline -10

# Check for build errors
flutter analyze
```

## Success Criteria

- [ ] Sprint board created and maintained
- [ ] Hourly plans created for all 12 hours
- [ ] Progress tracked hourly
- [ ] Blockers identified and resolved
- [ ] Risks mitigated
- [ ] Priority adjustments made when needed
- [ ] Final sprint summary complete
- [ ] Report created in `agents/reports/`

## Begin Mission

Start by reading the sprint plan in `plan/REDESIGN_SPRINT_PLAN.md`. Create tracking document. Begin hourly checkpoints.

**MOTTO:** *Plan the Work. Work the Plan.*
