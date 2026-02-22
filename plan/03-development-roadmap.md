# GitDoIt Development Roadmap

**Date:** 2026-02-21
**Current Version:** v0.2.1-industrial-fix
**Target Version:** v0.3.0-sync-queue

---

## Vision

Create the definitive GitHub Issues TODO app for developers who value:
- **Offline-first** - Works anywhere, syncs when possible
- **Industrial Minimalism** - Clean, focused, distraction-free
- **Agent-based Development** - Automated quality and consistency

---

## Version History

### v0.1.0 - Initial Release (Completed)
- Basic GitHub authentication
- Issue list view
- Simple Material Design

### v0.2.0 - Industrial Redesign (Completed)
- Industrial Minimalism UI
- Custom theme system
- Design tokens
- Agent system setup

### v0.2.1 - Critical Fixes (Current - ✅ Completed)
**Status:** Main screen fixes implemented

**Fixed Issues:**
- ✅ GitHub token authentication (Bearer → token)
- ✅ Repository configuration persistence
- ✅ Offline-first issue creation
- ✅ JSON serialization generation
- ✅ Logger error handling

**Remaining:**
- ⏳ Hive adapter registration (low priority)
- ⏳ Deprecation warnings cleanup

---

## User Feedback Integration (ToDo.md)

**Priority:** All P0 items must be completed before any new features

### Critical Blocking Issues
- ❌ Login screen missing "CONTINUE" button after token entry
- ❌ Settings → Repository configuration unclear if it works
- ❌ Settings → Appearance toggles (dark/light/system) not functional
- ❌ Settings → Logout flow broken (no way to login after logout)
- ❌ Version displays "industrial" (should be removed)

### Medium Priority
- ⚠️ Settings → Offline Storage needs info dialog
- ⚠️ Settings → Clear Cache needs proper confirmation dialog
- ⚠️ Attribution needed: "by BerlogaBob with love from Portugal"

### Core Requirement
- ✅ App works offline (verified in v0.2.1)
- ⏳ Sync when internet available (planned for v0.3.0)

**See:** `06-prioritized-development-plan.md` for full breakdown

---

## v0.2.2 - User Feedback Fixes (Next Sprint)

**Priority:** CRITICAL
**Estimated:** 2-3 days
**Status:** Planning
**Target Date:** 2026-02-28

**Source:** ToDo.md user feedback + `06-prioritized-development-plan.md`

### Critical Fixes (P0)

1. **Authentication Flow**
   - [ ] Add "CONTINUE" button on AuthScreen after token entry
   - [ ] Fix logout flow (navigate to AuthScreen, not HomeScreen)
   - [ ] Clear auth state on logout

2. **Settings Screen - Repository**
   - [ ] Visual confirmation after saving repository
   - [ ] Display current repository config
   - [ ] Verify persistence across restarts

3. **Settings Screen - Theme**
   - [ ] Connect theme toggle buttons to theme provider
   - [ ] Implement dark/light/system theme switching
   - [ ] Persist theme preference
   - [ ] Verify immediate theme application

4. **Settings Screen - Dialogs**
   - [ ] Offline Storage info dialog
   - [ ] Clear Cache confirmation dialog (Cancel/Clear/Clear All)
   - [ ] Logout confirmation dialog (Cancel/Logout)

5. **Version Display**
   - [ ] Remove "industrial" from version string
   - [ ] Link version to pubspec.yaml dynamically
   - [ ] Add attribution: "by BerlogaBob with love from Portugal"

### Polish & Stability (P1)

2. **Hive Adapter Implementation**
   - [ ] Create IssueAdapter, LabelAdapter, MilestoneAdapter, UserAdapter
   - [ ] Register adapters in main.dart
   - [ ] Test cache persistence
   - [ ] Verify performance

3. **Deprecation Cleanup**
   - [ ] Replace `withOpacity` with `withValues()`
   - [ ] Fix unused variable warnings
   - [ ] Remove unnecessary library names
   - [ ] Target: < 10 lint warnings

4. **Error Handling Improvements**
   - [ ] Better error messages for users
   - [ ] Retry logic for failed operations
   - [ ] Network status indicator
   - [ ] Graceful degradation

5. **Performance Optimization**
   - [ ] Profile app startup time (target: < 2 seconds)
   - [ ] Optimize issue list rendering
   - [ ] Reduce memory footprint
   - [ ] Ensure 60fps scrolling

### Acceptance Criteria
- ✅ All ToDo.md blocking issues resolved
- ✅ Settings screen fully functional
- ✅ Login/logout flows work correctly
- ✅ Theme switching works
- ✅ < 10 lint warnings
- ✅ App launches in < 2 seconds
- ✅ Zero compilation errors

---

## v0.3.0 - Sync Queue (Critical Infrastructure)

**Priority:** CRITICAL
**Estimated:** 1 week
**Status:** Backlog
**Target Date:** 2026-03-07

**Source:** `06-prioritized-development-plan.md` P2 items

### Features

1. **Change Queue System**
   - [ ] Queue offline changes (create, update, close, reopen)
   - [ ] Persist queue to disk
   - [ ] Queue status indicator in UI
   - [ ] Manual sync trigger button

2. **Background Sync**
   - [ ] Sync on app resume
   - [ ] Sync on network reconnect
   - [ ] Auto-sync when online
   - [ ] Retry logic with exponential backoff

3. **Conflict Resolution**
   - [ ] Last-write-wins (initial strategy)
   - [ ] Conflict detection algorithm
   - [ ] Change history/audit log (future)
   - [ ] Manual conflict resolution UI (future)

4. **Sync Status UI**
   - [ ] Sync indicator in header
   - [ ] Pending changes count
   - [ ] Sync error notifications
   - [ ] Network status indicator

### Technical Requirements
- Queue data structure (`lib/services/sync_queue_service.dart`)
- Background task scheduling
- Conflict detection algorithm
- Retry logic with exponential backoff

### Acceptance Criteria
- ✅ Offline changes sync automatically
- ✅ No data loss during sync failures
- ✅ Clear user feedback on sync status
- ✅ Handles network interruptions gracefully
- ✅ Works offline with local changes

---

## v0.3.1 - Kanban Board (Major Feature)

**Priority:** High
**Estimated:** 1-2 weeks
**Status:** Planning
**Target Date:** 2026-03-21

**Source:** `06-prioritized-development-plan.md` P3 items

### Features

1. **Kanban Board View**
   - [ ] Column-based layout (Open, In Progress, Done)
   - [ ] Drag-and-drop issues between columns
   - [ ] Column customization
   - [ ] WIP limits (optional)

2. **Issue Status Workflow**
   - [ ] Custom status labels
   - [ ] Status transition rules
   - [ ] Visual status indicators
   - [ ] Status-based filtering

3. **Enhanced Issue Management**
   - [ ] Bulk operations (select multiple)
   - [ ] Quick edit from kanban
   - [ ] Issue preview on hover
   - [ ] Label management

4. **UX Improvements**
   - [ ] View switcher (List/Kanban)
   - [ ] Column collapse/expand
   - [ ] Search within columns
   - [ ] Column sorting options

### Technical Requirements
- Drag-and-drop package integration
- Optimized rendering for large boards
- State persistence for board layout
- Offline support for kanban operations

### Acceptance Criteria
- Smooth drag-and-drop at 60fps
- Support 100+ issues without lag
- Board layout persists across sessions
- Works offline with local changes

---

## v0.3.1 - Sync Queue (Critical Infrastructure)

**Priority:** Critical  
**Estimated:** 1 week  
**Status:** Planning

### Features

1. **Change Queue System**
   - [ ] Queue offline changes
   - [ ] Persist queue to disk
   - [ ] Queue status indicator
   - [ ] Manual sync trigger

2. **Background Sync**
   - [ ] Sync on app resume
   - [ ] Periodic background sync
   - [ ] Sync on network reconnect
   - [ ] Conflict detection

3. **Conflict Resolution**
   - [ ] Last-write-wins (initial)
   - [ ] Manual conflict resolution UI
   - [ ] Change history/audit log
   - [ ] Merge strategies

4. **Sync Status UI**
   - [ ] Sync indicator in header
   - [ ] Pending changes count
   - [ ] Sync error notifications
   - [ ] Sync history view

### Technical Requirements
- Queue data structure
- Background task scheduling
- Conflict detection algorithm
- Retry logic with exponential backoff

### Acceptance Criteria
- Offline changes sync automatically
- No data loss during sync failures
- Clear user feedback on sync status
- Handles network interruptions gracefully

---

## v0.4.0 - Calendar & Notifications (Productivity)

**Priority:** Medium  
**Estimated:** 2 weeks  
**Status:** Backlog

### Features

1. **Calendar View**
   - [ ] Month/week/day views
   - [ ] Issue due dates
   - [ ] Milestone deadlines
   - [ ] Drag to reschedule

2. **Notifications**
   - [ ] Local push notifications
   - [ ] Due date reminders
   - [ ] Mention notifications
   - [ ] Custom notification rules

3. **Smart Features**
   - [ ] Issue suggestions
   - [ ] Auto-categorization
   - [ ] Priority scoring
   - [ ] Smart filters

### Technical Requirements
- Calendar widget integration
- Local notification system
- Background fetch for updates
- Smart algorithm implementation

---

## v0.5.0 - Multi-Repository (Scale)

**Priority:** Medium  
**Estimated:** 1-2 weeks  
**Status:** Backlog

### Features

1. **Repository Management**
   - [ ] Add/remove repositories
   - [ ] Repository switcher
   - [ ] Multi-repo dashboard
   - [ ] Cross-repo search

2. **Repository Discovery**
   - [ ] List user's repositories
   - [ ] Filter by ownership
   - [ ] Search repositories
   - [ ] Recent repositories

3. **Organization**
   - [ ] Repository groups/folders
   - [ ] Favorites
   - [ ] Custom repository names
   - [ ] Repository-specific settings

---

## v0.6.0 - Team Collaboration (Advanced)

**Priority:** Low  
**Estimated:** 2-3 weeks  
**Status:** Future

### Features

1. **Team Features**
   - [ ] Assign issues to team members
   - [ ] Team dashboard
   - [ ] Activity feed
   - [ ] Team notifications

2. **Comments & Discussion**
   - [ ] View issue comments
   - [ ] Add comments
   - [ ] Comment notifications
   - [ ] Markdown editor

3. **Review Workflow**
   - [ ] PR integration
   - [ ] Review requests
   - [ ] Status checks
   - [ ] Merge capabilities

---

## Technical Debt Backlog

### High Priority
- [ ] Hive adapter registration
- [ ] Sync queue implementation
- [ ] Error handling improvements
- [ ] Performance optimization

### Medium Priority
- [ ] Deprecation warnings cleanup
- [ ] Code documentation
- [ ] Unit test coverage
- [ ] Integration tests

### Low Priority
- [ ] UI polish and animations
- [ ] Accessibility improvements
- [ ] Internationalization
- [ ] Theme customization

---

## Agent System Integration

### Current Agents (Available)
- ✅ MrPlanner - Daily planning
- ✅ MrArchitector - Architecture decisions
- ✅ MrSeniorDeveloper - Code review
- ✅ MrCleaner - Code quality
- ✅ MrLogger - Logging standards
- ✅ MrStupidUser - Usability testing
- ✅ MrUXUIDesigner - UI/UX design
- ✅ MrRepetitive - Repetitive tasks

### Agent Workflow

```
User Request
    ↓
MrPlanner (creates plan)
    ↓
MrArchitector (designs solution)
    ↓
MrUXUIDesigner (designs UI)
    ↓
MrRepetitive (generates code)
    ↓
MrSeniorDeveloper (reviews)
    ↓
MrCleaner (cleans up)
    ↓
MrLogger (adds logging)
    ↓
MrStupidUser (tests UX)
    ↓
User Delivery
```

---

## Success Metrics

### Quality Metrics
- **Test Coverage:** > 80%
- **Lint Warnings:** < 10
- **Build Time:** < 2 minutes
- **App Size:** < 20MB

### Performance Metrics
- **App Launch:** < 2 seconds
- **Issue Load:** < 1 second (cache)
- **Scroll FPS:** 60fps
- **Sync Time:** < 5 seconds

### User Metrics
- **Offline Success Rate:** > 99%
- **Sync Success Rate:** > 95%
- **Crash-free Sessions:** > 99.5%
- **User Satisfaction:** > 4.5 stars

---

## Release Schedule

| Version | Target Date | Status | Focus |
|---------|-------------|--------|-------|
| v0.2.2 | 2026-02-28 | Next | User feedback fixes (ToDo.md P0/P1) |
| v0.3.0 | 2026-03-07 | Planning | Sync queue infrastructure (P2) |
| v0.3.1 | 2026-03-21 | Backlog | Kanban board (P3) |
| v0.4.0 | 2026-04-04 | Backlog | Multi-repository support (P3) |
| v0.5.0 | 2026-05-01 | Backlog | Calendar & notifications (P3) |
| v0.6.0 | 2026-06-01 | Future | Team collaboration |

---

## Risk Assessment

### Technical Risks
- **Hive compatibility:** Medium - May need migration
- **GitHub API changes:** Low - Stable API
- **Flutter updates:** Medium - Deprecation management

### Schedule Risks
- **Scope creep:** Medium - Feature creep potential
- **Complexity:** High - Sync queue is complex
- **Dependencies:** Low - Well-maintained packages

### Mitigation Strategies
- Regular code reviews
- Automated testing
- Incremental releases
- User feedback loops

---

**Roadmap Created:** 2026-02-21
**Last Updated:** 2026-02-21 (Prioritized plan added)
**Next Review:** 2026-02-28
**Owner:** GitDoIt Development Team
**Priority Framework:** See `06-prioritized-development-plan.md`
