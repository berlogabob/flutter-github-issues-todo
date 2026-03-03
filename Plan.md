# GitDoIt Implementation Plan v2.0

**Version:** 2.0  
**Date:** March 3, 2026  
**Status:** Ready for Execution  
**Priority:** CRITICAL - GitHub Issues #20-23

---

## Core Prohibitions (Strictly Enforced)

🚫 **NO NEW FEATURES** - Only fix documented GitHub issues  
🚫 **NO VERSION CHANGES** - Don't change pubspec.yaml without user prompt  
🚫 **NO SCOPE CREEP** - Stick to issues #20-23 only  

---

## GitHub Issues Scope

| # | Title | Description | Priority |
|---|-------|-------------|----------|
| 23 | КЭШ | Cache implementation issues | HIGH |
| 22 | CREATE ISSUE | Create issue flow problems | HIGH |
| 21 | ГЛАВНЫЙ ЭКРАН | Main dashboard issues | HIGH |
| 20 | МЕНЮ РЕПОЗИТОРИИ И ПРОЕКТЫ | Repository/Project menu | MEDIUM |
| 17 | APP VERSION | ✅ COMPLETED (v0.5.0+71) | DONE |
| 16 | DEFAULT SATE | Default state issues | MEDIUM |

---

## Sprint 19: GitHub Issues #23-22 (HIGH Priority)

**Duration:** Week 1 (5 days)  
**Priority:** CRITICAL

### Tasks

| № | Task | Owner | Status |
|---|------|-------|--------|
| 19.1 | Investigate cache issues (#23) | Flutter Developer | ⏳ |
| 19.2 | Fix cache invalidation logic | Flutter Developer | ⏳ |
| 19.3 | Test cache with offline mode | Technical Tester | ⏳ |
| 19.4 | Investigate create issue flow (#22) | Flutter Developer | ⏳ |
| 19.5 | Fix create issue bugs | Flutter Developer | ⏳ |
| 19.6 | Test create issue flow end-to-end | Technical Tester | ⏳ |
| 19.7 | Add error handling for cache misses | Flutter Developer | ⏳ |
| 19.8 | Document cache behavior | Documentation | ⏳ |

**Acceptance Criteria:**
- [ ] Cache works correctly offline/online
- [ ] Create issue flow completes successfully
- [ ] All tests pass
- [ ] 0 analyzer errors

---

## Sprint 20: GitHub Issues #21-20 (HIGH/MEDIUM Priority)

**Duration:** Week 2 (5 days)  
**Priority:** HIGH

### Tasks

| № | Task | Owner | Status |
|---|------|-------|--------|
| 20.1 | Investigate main dashboard issues (#21) | Flutter Developer | ⏳ |
| 20.2 | Fix dashboard loading problems | Flutter Developer | ⏳ |
| 20.3 | Fix dashboard filter behavior | Flutter Developer | ⏳ |
| 20.4 | Test dashboard with large datasets | Technical Tester | ⏳ |
| 20.5 | Investigate repo/project menu (#20) | Flutter Developer | ⏳ |
| 20.6 | Fix repo/project picker dialog | Flutter Developer | ⏳ |
| 20.7 | Add default repo/project selection | Flutter Developer | ⏳ |
| 20.8 | Test repo/project selection flow | Technical Tester | ⏳ |

**Acceptance Criteria:**
- [ ] Dashboard loads correctly
- [ ] Filters work as expected
- [ ] Repo/project picker functional
- [ ] All tests pass
- [ ] 0 analyzer errors

---

## Sprint 21: GitHub Issue #16 + Polish (MEDIUM Priority)

**Duration:** Week 3 (5 days)  
**Priority:** MEDIUM

### Tasks

| № | Task | Owner | Status |
|---|------|-------|--------|
| 21.1 | Investigate default state issues (#16) | Flutter Developer | ⏳ |
| 21.2 | Fix default repo/state persistence | Flutter Developer | ⏳ |
| 21.3 | Test state restoration after restart | Technical Tester | ⏳ |
| 21.4 | Fix remaining 3 analyzer warnings | Code Quality | ⏳ |
| 21.5 | Update user documentation | Documentation | ⏳ |
| 21.6 | Run full test suite | Technical Tester | ⏳ |
| 21.7 | Performance regression test | Technical Tester | ⏳ |
| 21.8 | Create release notes | Documentation | ⏳ |

**Acceptance Criteria:**
- [ ] Default state persists correctly
- [ ] 0 analyzer warnings
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Release ready

---

## Verification Checklist

### Per Sprint
- [ ] `flutter analyze`: 0 errors, 0 warnings
- [ ] `flutter test`: all tests pass
- [ ] `flutter build apk --release`: success
- [ ] GitHub issue closed with comment

### Sprint 19 Specific
- [ ] Issue #23 tested and closed
- [ ] Issue #22 tested and closed
- [ ] Cache behavior documented

### Sprint 20 Specific
- [ ] Issue #21 tested and closed
- [ ] Issue #20 tested and closed
- [ ] Dashboard performance verified

### Sprint 21 Specific
- [ ] Issue #16 tested and closed
- [ ] All analyzer warnings fixed
- [ ] Release notes created

---

## Out of Scope (Per MVP Brief)

- ❌ Comments to issues (excluded per brief section 14.2)
- ❌ Light theme (dark only per brief)
- ❌ Push notifications (excluded)
- ❌ Home screen widgets (excluded)
- ❌ Share sheet (excluded)
- ❌ Multi-account support (excluded)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| GitHub Issues Closed | 6/6 (100%) |
| Analyzer Errors | 0 |
| Analyzer Warnings | 0 |
| Test Pass Rate | 100% |
| Build Success | ✅ |

---

**Approved by:** Project Coordinator  
**Ready for immediate execution**  
**Total Sprints:** 3 (15 days)  
**Estimated Completion:** 3 weeks
