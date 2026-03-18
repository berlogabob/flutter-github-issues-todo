# 🚀 GITDOIT REIMAGINED PLAN - Mr* Series Edition

**Project:** GitDoIt v0.6.0  
**Date:** March 18, 2026  
**Based On:** Deep Scan Report (Health Score: 77/100)  
**Team:** Full Mr* Series Agent Team  
**Timeline:** 8 Weeks (4 Sprints × 2 Weeks)

---

## 📊 Current State (Post-Scan)

### Codebase:
- **76 Dart files** | **25,049 lines**
- **14 screens** | **20 widgets** | **14 services**
- **36 test files** | **~65% coverage**

### Issues Identified:
- 🔴 **122 setState calls** (should be Riverpod)
- 🟡 **7 print() statements** (should be debugPrint)
- 🟡 **100+ missing API docs**
- 🟡 **File naming violations** (Mr*.dart vs mr_*.dart)
- 🟡 **Limited service tests**

---

## 🎯 Vision: GitDoIt v0.6.0

### Target Health Score: **95/100** ✅

### Key Improvements:
1. **100% Riverpod** state management
2. **90%+ test coverage**
3. **Complete API documentation**
4. **Optimized performance** (SliverList, lazy loading)
5. **Mr* agent integration** (enhanced capabilities)

---

## 📋 Sprint Plan

### **Sprint 1: Code Quality & Naming (Week 1-2)**
**Lead:** MrCleaner + MrCompliance

#### Goals:
- Fix all naming convention violations
- Replace print() with debugPrint()
- Implement TODO items
- Add critical API docs

#### Tasks:

**Week 1: Naming & Conventions**
- [ ] **Task 1.1:** Rename Mr*.dart → mr_*.dart (9 files)
  - Owner: MrCleaner
  - Effort: S
  - Impact: Compliance +10%

- [ ] **Task 1.2:** Fix variable naming (_MrCoordinatorLoop → _coordinatorLoop)
  - Owner: MrCleaner
  - Effort: XS
  - Impact: Compliance +5%

- [ ] **Task 1.3:** Add curly braces to all for loops
  - Owner: MrCleaner
  - Effort: S
  - Impact: Compliance +3%

**Week 2: Code Hygiene**
- [ ] **Task 2.1:** Replace 7 print() → debugPrint()
  - Owner: MrDeveloper
  - Effort: XS
  - Impact: Quality +5%

- [ ] **Task 2.2:** Implement TODO: Trigger sync
  - Owner: MrDeveloper
  - Effort: M
  - Impact: Feature complete

- [ ] **Task 2.3:** Add API docs to public members (priority: agents, services)
  - Owner: MrLogger
  - Effort: M
  - Impact: Docs +20%

#### Deliverables:
- ✅ All naming conventions fixed
- ✅ Zero print() statements
- ✅ TODO items implemented
- ✅ API docs for critical files

#### Success Metrics:
- Compliance Score: 72 → 90
- Code Quality: 80 → 90

---

### **Sprint 2: State Management Migration (Week 3-4)**
**Lead:** MrDeveloper + MrArchitect

#### Goals:
- Migrate 50% setState to Riverpod
- Convert 5 screens to ConsumerWidget
- Add missing Riverpod providers

#### Tasks:

**Week 3: Riverpod Foundation**
- [ ] **Task 3.1:** Create providers for remaining state
  - Owner: MrArchitect
  - Effort: M
  - Files: providers/app_providers.dart

- [ ] **Task 3.2:** Migrate main_dashboard_screen.dart setState → Riverpod
  - Owner: MrDeveloper
  - Effort: L
  - Impact: 25 setState calls eliminated

- [ ] **Task 3.3:** Migrate issue_detail_screen.dart setState → Riverpod
  - Owner: MrDeveloper
  - Effort: L
  - Impact: 20 setState calls eliminated

**Week 4: Widget Conversion**
- [ ] **Task 4.1:** Convert 5 StatefulWidget → ConsumerWidget
  - Owner: MrDeveloper
  - Effort: M
  - Files: screens/*.dart

- [ ] **Task 4.2:** Add Riverpod listeners for async operations
  - Owner: MrDeveloper
  - Effort: M
  - Impact: Better error handling

- [ ] **Task 4.3:** Migrate remaining setState (50%)
  - Owner: MrDeveloper
  - Effort: L
  - Impact: 60 setState calls eliminated

#### Deliverables:
- ✅ 60 setState calls migrated to Riverpod
- ✅ 5 screens converted to ConsumerWidget
- ✅ Complete provider coverage

#### Success Metrics:
- setState calls: 122 → 62
- Riverpod calls: 39 → 100+
- Architecture Score: 78 → 90

---

### **Sprint 3: Testing & Quality (Week 5-6)**
**Lead:** MrTester + MrQualityControl

#### Goals:
- Add service layer tests
- Reach 85% test coverage
- Add integration tests

#### Tasks:

**Week 5: Service Tests**
- [ ] **Task 5.1:** CacheService tests (TTL, expiration)
  - Owner: MrTester
  - Effort: M
  - File: test/services/cache_service_test.dart

- [ ] **Task 5.2:** ErrorLoggingService tests
  - Owner: MrTester
  - Effort: M
  - File: test/services/error_logging_service_test.dart

- [ ] **Task 5.3:** SearchHistoryService tests
  - Owner: MrTester
  - Effort: S
  - File: test/services/search_history_service_test.dart

- [ ] **Task 5.4:** ConflictDetectionService tests
  - Owner: MrTester
  - Effort: M
  - File: test/services/conflict_detection_service_test.dart

**Week 6: Integration Tests**
- [ ] **Task 6.1:** Sync flow integration test
  - Owner: MrTester
  - Effort: L
  - File: test/integration/sync_flow_test.dart

- [ ] **Task 6.2:** Offline-first integration test
  - Owner: MrTester
  - Effort: L
  - File: test/integration/offline_first_test.dart

- [ ] **Task 6.3:** Large dataset performance test (~1000 issues)
  - Owner: MrTester + MrOptimization
  - Effort: M
  - File: test/performance/large_dataset_test.dart

- [ ] **Task 6.4:** Agent system integration test
  - Owner: MrTester
  - Effort: S
  - File: test/agents/agent_integration_test.dart

#### Deliverables:
- ✅ 10+ new service tests
- ✅ 4 integration tests
- ✅ 1 performance test
- ✅ Test coverage: 65% → 85%

#### Success Metrics:
- Test Files: 36 → 50
- Coverage: 65% → 85%
- Test Score: 65 → 90

---

### **Sprint 4: Performance Optimization (Week 7-8)**
**Lead:** MrOptimization + MrDesigner

#### Goals:
- Implement SliverList for large lists
- Add lazy loading
- Performance benchmarks
- UI/UX polish

#### Tasks:

**Week 7: List Optimization**
- [ ] **Task 7.1:** Replace ListView.builder → SliverList (repo_list.dart)
  - Owner: MrOptimization
  - Effort: M
  - Impact: 30% faster scrolling

- [ ] **Task 7.2:** Add lazy loading for issues (pagination)
  - Owner: MrDeveloper
  - Effort: L
  - Impact: Faster initial load

- [ ] **Task 7.3:** Implement image caching optimization
  - Owner: MrOptimization
  - Effort: S
  - Impact: Faster image loads

**Week 8: Performance & Polish**
- [ ] **Task 8.1:** Performance benchmarks
  - Owner: MrOptimization
  - Effort: M
  - Metrics: Build time, memory, frame rate

- [ ] **Task 8.2:** UI/UX polish (MrDesigner)
  - Owner: MrDesigner
  - Effort: S
  - Impact: Better user experience

- [ ] **Task 8.3:** Final testing & bug fixes
  - Owner: MrTester
  - Effort: M
  - Impact: Production ready

- [ ] **Task 8.4:** Documentation update
  - Owner: MrLogger
  - Effort: S
  - Impact: User guides updated

#### Deliverables:
- ✅ SliverList implemented
- ✅ Lazy loading working
- ✅ Performance benchmarks established
- ✅ UI/UX polished

#### Success Metrics:
- Performance Score: 82 → 95
- Design Score: 85 → 95

---

## 📊 Overall Success Metrics

### Before → After:

| Metric | Before | Target | Change |
|--------|--------|--------|--------|
| **Health Score** | 77/100 | 95/100 | +18 |
| **Compliance** | 72/100 | 95/100 | +23 |
| **Code Quality** | 80/100 | 95/100 | +15 |
| **Test Coverage** | 65% | 90% | +25% |
| **Architecture** | 78/100 | 95/100 | +17 |
| **Performance** | 82/100 | 95/100 | +13 |
| **setState calls** | 122 | <30 | -92 |
| **Riverpod calls** | 39 | 150+ | +111 |
| **Test Files** | 36 | 50 | +14 |
| **API Docs** | <50% | 95% | +45% |

---

## 🎯 Mr* Agent Responsibilities

### MrPlanner:
- [ ] Track sprint progress
- [ ] Update task board daily
- [ ] Escalate blockers

### MrDeveloper:
- [ ] Implement state migration
- [ ] Fix code quality issues
- [ ] Add lazy loading

### MrDesigner:
- [ ] UI/UX polish
- [ ] Design system compliance
- [ ] Accessibility validation

### MrTester:
- [ ] Write service tests
- [ ] Write integration tests
- [ ] Performance testing

### MrLogger:
- [ ] API documentation
- [ ] CHANGELOG updates
- [ ] User guides

### MrCompliance:
- [ ] Enforce naming conventions
- [ ] Validate patterns
- [ ] Rule compliance

### MrOptimization:
- [ ] Performance benchmarks
- [ ] SliverList implementation
- [ ] Memory optimization

### MrCleaner:
- [ ] Code hygiene
- [ ] Remove dead code
- [ ] Format code

### MrCoordinator:
- [ ] Coordinate all agents
- [ ] Monitor progress
- [ ] Resolve conflicts

### MrRelease:
- [ ] Version management
- [ ] Release notes
- [ ] Deployment

---

## ⚠️ Risk Mitigation

### Risk 1: setState Migration Complexity
**Mitigation:**
- Start with simple screens
- Test each migration
- Rollback plan ready

### Risk 2: Test Coverage Goals
**Mitigation:**
- Prioritize critical services
- Automate test generation
- Focus on integration tests

### Risk 3: Performance Regression
**Mitigation:**
- Benchmark before/after
- Load testing
- Monitor metrics

### Risk 4: Scope Creep
**Mitigation:**
- Strict sprint boundaries
- Priority-based selection
- Defer non-critical items

---

## 📞 Communication Plan

### Daily:
- Agent standup (automated)
- Progress tracking

### Weekly:
- Sprint review (Friday)
- Sprint planning (Monday)

### Milestones:
- Sprint 1 Demo (Week 2)
- Sprint 2 Demo (Week 4)
- Sprint 3 Demo (Week 6)
- Sprint 4 Demo (Week 8)
- **Production Release: Week 9**

---

## 🎉 Expected Outcomes

### Technical:
- ✅ 95/100 health score
- ✅ 90% test coverage
- ✅ Complete API docs
- ✅ Optimized performance

### User-Facing:
- ✅ Faster app (30% improvement)
- ✅ Smoother scrolling
- ✅ Better error handling
- ✅ More reliable offline mode

### Business:
- ✅ App Store rating ≥ 4.5 stars
- ✅ Reduced support tickets
- ✅ Faster development velocity
- ✅ Better code maintainability

---

## 🚀 Getting Started

### Immediate Next Steps:

1. **MrPlanner:** Create sprint board with all tasks
2. **MrCleaner:** Start Task 1.1 (file renaming)
3. **MrCompliance:** Validate naming conventions
4. **MrTester:** Prepare test infrastructure
5. **MrDeveloper:** Review migration strategy

### Week 1 Focus:
- Rename all Mr*.dart → mr_*.dart
- Fix variable naming
- Add curly braces
- Replace print() statements

---

**Plan Created By:** Mr* Series Agent Team  
**Date:** March 18, 2026  
**Version:** 1.0  
**Status:** Ready for Execution  
**First Sprint Starts:** Immediately
