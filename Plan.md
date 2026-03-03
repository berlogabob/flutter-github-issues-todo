# GitDoIt Implementation Plan

**Version:** 1.0  
**Date:** March 2, 2026  
**Status:** Ready for Execution  
**Priority:** CRITICAL - Offline Mode Completion

---

## Core Prohibitions (Strictly Enforced)

🚫 **NO NEW FEATURES** - Only implement what's in the brief  
🚫 **NO VERSION CHANGES** - Don't change pubspec.yaml without user prompt  
🚫 **NO COMMENTS** - Excluded from MVP per brief section 14.2  
🚫 **NO LIGHT THEME** - Dark theme only per brief  
🚫 **NO PUSH NOTIFICATIONS** - Excluded from MVP  

---

## Sprint 10: Operation Queue Integration

**Duration:** Week 1 (5 days)  
**Priority:** CRITICAL  
**Goal:** Complete pending operations queue integration across all screens

### Tasks

| № | Task | Owner | Files | Status |
|---|------|-------|-------|--------|
| 10.1 | Add `addComment`, `updateLabels`, `updateAssignee` to OperationType enum | Flutter Developer | `lib/models/pending_operation.dart` | ⏳ Pending |
| 10.2 | Add factory constructors for new operation types | Flutter Developer | `lib/models/pending_operation.dart` | ⏳ Pending |
| 10.3 | Update `toJson()` and `fromJson()` for new operation types | Flutter Developer | `lib/models/pending_operation.dart` | ⏳ Pending |
| 10.4 | Add offline check before showing labels dialog | Flutter Developer | `lib/screens/issue_detail_screen.dart` | ⏳ Pending |
| 10.5 | Queue label update operation when offline | Flutter Developer | `lib/screens/issue_detail_screen.dart` | ⏳ Pending |
| 10.6 | Add offline check before showing assignee dialog | Flutter Developer | `lib/screens/issue_detail_screen.dart` | ⏳ Pending |
| 10.7 | Queue assignee update operation when offline | Flutter Developer | `lib/screens/issue_detail_screen.dart` | ⏳ Pending |
| 10.8 | Fix edit_issue_screen.dart to queue label changes | Flutter Developer | `lib/screens/edit_issue_screen.dart` | ⏳ Pending |
| 10.9 | Fix edit_issue_screen.dart to queue assignee changes | Flutter Developer | `lib/screens/edit_issue_screen.dart` | ⏳ Pending |
| 10.10 | Add pending operations count to dashboard filters | Flutter Developer | `lib/widgets/dashboard_filters.dart` | ⏳ Pending |

### Acceptance Criteria

- [ ] All 7 operation types defined in PendingOperation model
- [ ] Issue detail screen queues operations when offline
- [ ] Edit issue screen queues operations when offline
- [ ] Dashboard shows pending operations count badge
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter test`: all pass
- [ ] `flutter build`: success

---

## Sprint 11: Enhanced Sync Processing

**Duration:** Week 2 (5 days)  
**Priority:** CRITICAL  
**Goal:** Implement operation handlers and retry logic in SyncService

### Tasks

| № | Task | Owner | Files | Status |
|---|------|-------|-------|--------|
| 11.1 | Implement `_executeCreateIssue()` handler | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 11.2 | Implement `_executeUpdateIssue()` handler | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 11.3 | Implement `_executeUpdateLabels()` handler | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 11.4 | Implement `_executeUpdateAssignee()` handler | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 11.5 | Add retry logic with exponential backoff (1s, 2s, 4s, 8s, 16s) | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 11.6 | Add operation status enum (pending/syncing/failed/completed) | Flutter Developer | `lib/models/pending_operation.dart` | ⏳ Pending |
| 11.7 | Add status tracking to PendingOperation model | Flutter Developer | `lib/models/pending_operation.dart` | ⏳ Pending |
| 11.8 | Update PendingOperationsService to track status | Flutter Developer | `lib/services/pending_operations_service.dart` | ⏳ Pending |
| 11.9 | Create pending operations list widget | Flutter Developer | `lib/widgets/pending_operations_list.dart` | ⏳ Pending |
| 11.10 | Add pending operations list to settings screen | Flutter Developer | `lib/screens/settings_screen.dart` | ⏳ Pending |

### Acceptance Criteria

- [ ] All 4 operation handlers implemented
- [ ] Retry logic with 5 attempts and exponential backoff
- [ ] Operation status tracked in model and service
- [ ] Pending operations list visible in settings
- [ ] Failed operations show error message
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter test`: all pass
- [ ] `flutter build`: success

---

## Sprint 12: Sync Status Dashboard

**Duration:** Week 3 (5 days)  
**Priority:** HIGH  
**Goal:** Create detailed sync status dashboard for user visibility

### Tasks

| № | Task | Owner | Files | Status |
|---|------|-------|-------|--------|
| 12.1 | Create `SyncStatusDashboardScreen` scaffold | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.2 | Add last sync time per repository section | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.3 | Add pending operations section with count | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.4 | Add pending operations list with retry/cancel buttons | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.5 | Add sync history log (last 10 syncs) section | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.6 | Add sync statistics (total synced, failed, pending) | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.7 | Add manual sync trigger button with progress | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 12.8 | Add navigation from settings to sync dashboard | Flutter Developer | `lib/screens/settings_screen.dart` | ⏳ Pending |
| 12.9 | Create sync history model for tracking | Flutter Developer | `lib/models/sync_history_entry.dart` | ⏳ Pending |
| 12.10 | Add sync history logging to SyncService | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |

### Acceptance Criteria

- [ ] Sync dashboard screen created with all sections
- [ ] Last sync time shown per repository
- [ ] Pending operations list with retry/cancel actions
- [ ] Sync history log shows last 10 syncs
- [ ] Statistics section with counts
- [ ] Manual sync trigger works
- [ ] Navigation from settings works
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter test`: all pass
- [ ] `flutter build`: success

---

## Sprint 13: Conflict Resolution

**Duration:** Week 4 (5 days)  
**Priority:** MEDIUM  
**Goal:** Implement conflict detection and resolution UI

### Tasks

| № | Task | Owner | Files | Status |
|---|------|-------|-------|--------|
| 13.1 | Create `ConflictDetectionService` with detection logic | System Architect | `lib/services/conflict_detection_service.dart` | ⏳ Pending |
| 13.2 | Add conflict detection to `_resolveIssuesConflict()` | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 13.3 | Create `ConflictResolutionDialog` widget | Flutter Developer | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |
| 13.4 | Add side-by-side comparison UI (local vs remote) | Flutter Developer | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |
| 13.5 | Add "Choose Local" button action | Flutter Developer | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |
| 13.6 | Add "Choose Remote" button action | Flutter Developer | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |
| 13.7 | Add "Merge" button action (simple merge for title/body) | Flutter Developer | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |
| 13.8 | Integrate conflict dialog in sync flow | Flutter Developer | `lib/services/sync_service.dart` | ⏳ Pending |
| 13.9 | Add conflict count indicator to sync dashboard | Flutter Developer | `lib/screens/sync_status_dashboard_screen.dart` | ⏳ Pending |
| 13.10 | Add conflict resolution tutorial tooltip | UX Validator | `lib/widgets/conflict_resolution_dialog.dart` | ⏳ Pending |

### Acceptance Criteria

- [ ] ConflictDetectionService created and working
- [ ] Conflicts detected when same issue edited locally and remotely
- [ ] Resolution dialog shows side-by-side comparison
- [ ] "Choose Local" keeps local changes
- [ ] "Choose Remote" keeps remote changes
- [ ] "Merge" combines changes (title: local, body: local + remote note)
- [ ] Conflict count shown in sync dashboard
- [ ] Tutorial tooltip explains conflict resolution
- [ ] `flutter analyze`: 0 errors
- [ ] `flutter test`: all pass
- [ ] `flutter build`: success

---

## Task Dependencies

```
Sprint 10 (Operation Queue Integration)
├─ 10.1 → 10.2 → 10.3 (Model updates - sequential)
├─ 10.4 → 10.5 (Issue detail labels - sequential)
├─ 10.6 → 10.7 (Issue detail assignee - sequential)
├─ 10.8 → 10.9 (Edit screen fixes - sequential)
└─ 10.10 (Dashboard badge - independent)

Sprint 11 (Enhanced Sync Processing)
├─ 11.1 → 11.2 → 11.3 → 11.4 (Operation handlers - sequential)
├─ 11.5 (Retry logic - depends on handlers)
├─ 11.6 → 11.7 → 11.8 (Status tracking - sequential)
└─ 11.9 → 11.10 (Pending list UI - sequential)

Sprint 12 (Sync Status Dashboard)
├─ 12.1 (Screen scaffold - first)
├─ 12.2 → 12.3 → 12.4 → 12.5 → 12.6 → 12.7 (Screen sections - can parallel)
├─ 12.8 (Navigation - after scaffold)
└─ 12.9 → 12.10 (History tracking - sequential)

Sprint 13 (Conflict Resolution)
├─ 13.1 (Detection service - first)
├─ 13.2 (Integrate detection - after service)
├─ 13.3 → 13.4 → 13.5 → 13.6 → 13.7 (Dialog UI - sequential)
├─ 13.8 (Integrate dialog - after UI)
└─ 13.9 → 13.10 (Dashboard + tutorial - parallel)
```

---

## Verification Checklist (Per Sprint)

### Sprint 10 Verification
- [ ] PendingOperation model has all 7 operation types
- [ ] Issue detail screen checks network before labels/assignee
- [ ] Operations queued when offline
- [ ] Edit screen queues label/assignee changes
- [ ] Dashboard shows pending count badge
- [ ] All tests pass
- [ ] Build successful

### Sprint 11 Verification
- [ ] All 4 operation handlers implemented
- [ ] Retry logic works (5 attempts, exponential backoff)
- [ ] Operation status tracked correctly
- [ ] Pending operations list in settings
- [ ] Failed operations show errors
- [ ] All tests pass
- [ ] Build successful

### Sprint 12 Verification
- [ ] Sync dashboard screen exists
- [ ] Last sync time per repo shown
- [ ] Pending operations list with actions
- [ ] Sync history log (last 10)
- [ ] Statistics section
- [ ] Manual sync trigger works
- [ ] Navigation from settings works
- [ ] All tests pass
- [ ] Build successful

### Sprint 13 Verification
- [ ] ConflictDetectionService works
- [ ] Conflicts detected correctly
- [ ] Resolution dialog shows comparison
- [ ] All 3 resolution options work
- [ ] Integrated in sync flow
- [ ] Conflict count in dashboard
- [ ] Tutorial tooltip shown
- [ ] All tests pass
- [ ] Build successful

---

## Risk Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Operation handlers fail | HIGH | LOW | Extensive unit tests for each handler |
| Retry logic infinite loop | HIGH | LOW | Max 5 retries with exponential backoff |
| Conflict detection false positives | MEDIUM | MEDIUM | Conservative detection (only exact issue number matches) |
| Sync dashboard performance | LOW | LOW | Lazy loading, pagination for history |
| UI complexity in dialogs | MEDIUM | LOW | Simple side-by-side layout, clear buttons |

---

## Success Metrics

### Sprint 10 Success
- Pending operations queue 100% integrated
- All CRUD operations queue when offline
- Dashboard shows accurate pending count

### Sprint 11 Success
- All operations sync successfully
- Failed operations retry correctly
- Users can see pending operations list

### Sprint 12 Success
- Users can see detailed sync status
- Last sync time visible per repo
- Manual sync trigger works
- Sync history available

### Sprint 13 Success
- Conflicts detected and reported
- Users can resolve conflicts
- No silent data loss
- Clear conflict resolution UI

---

## Post-Sprint Testing

### Offline Mode Test Scenarios

**Scenario A: Pure Offline**
1. Turn off network
2. Create issue → Verify queued
3. Edit issue labels → Verify queued
4. Edit issue assignee → Verify queued
5. Turn on network → Verify all sync

**Scenario B: Network Returns**
1. Create 5 issues offline
2. Edit 3 issues offline
3. Turn on network
4. Verify all 8 operations sync
5. Verify pending count goes to 0

**Scenario C: Sync Conflict**
1. Edit issue offline (change title)
2. Edit same issue on GitHub web
3. Sync
4. Verify conflict detected
5. Resolve conflict
6. Verify resolution applied

---

## Notes

- **Comments excluded** - Per brief section 14.2, comments not in MVP scope
- **Light theme excluded** - Per brief section 10, dark theme only
- **No new features** - Only implement what's documented in brief
- **Version unchanged** - Don't change pubspec.yaml version without user prompt
- **Short comments only** - Keep code comments brief and clear

---

**Approved by:** Project Coordinator  
**Ready for immediate execution**  
**Total Tasks:** 40 (10 per sprint × 4 sprints)  
**Estimated Duration:** 4 weeks (20 work days)

---

**Built with ❤️ using Flutter and the GitDoIt Agent System**
