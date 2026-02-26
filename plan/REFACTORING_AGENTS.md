# 🤖 АГЕНТЫ РЕФАКТОРИНГА GITDOIT

**Дата:** 2026-02-24  
**Версия:** 2.0

---

## 📋 СПИСОК АГЕНТОВ

### 1. **CodeQualityAgent** (CQA)
**Ответственность:** Статический анализ, поиск code smells
**Инструменты:** flutter analyze, custom_lint, dart_code_metrics
**Фокус:**
- God Classes detection
- Code duplication
- SOLID violations
- Naming conventions

### 2. **ArchitectureAgent** (ARA)
**Ответственность:** Модульность, зависимости, структура
**Инструменты:** Dependency graph analyzer
**Фокус:**
- Circular dependencies
- Module boundaries
- Layer violations
- Import patterns

### 3. **WidgetReuseAgent** (WRA)
**Ответственность:** Переиспользование UI компонентов
**Инструменты:** Widget tree analyzer
**Фокус:**
- Duplicate widgets
- Private widget extraction
- Design system compliance
- Component library

### 4. **ServiceLayerAgent** (SLA)
**Ответственность:** Service layer оптимизация
**Инструменты:** API call analyzer
**Фокус:**
- Service abstraction
- API call deduplication
- Error handling patterns
- Caching strategies

### 5. **ProviderAgent** (PRA)
**Ответственность:** State management оптимизация
**Инструменты:** Provider scope analyzer
**Фокус:**
- Provider boundaries
- State normalization
- Dependency injection
- Testability

### 6. **DesignSystemAgent** (DSA)
**Ответственность:** Дизайн-система и консистентность
**Инструменты:** Theme usage analyzer
**Фокус:**
- Token usage
- Style consistency
- Component variants
- Accessibility

### 7. **DocumentationAgent** (DOA)
**Ответственность:** Документация кода
**Инструменты:** dartdoc analyzer
**Фокус:**
- API documentation
- README updates
- Architecture diagrams
- Changelog

### 8. **TestingAgent** (TEA)
**Ответственность:** Test coverage
**Инструменты:** flutter test, coverage
**Фокус:**
- Unit tests
- Widget tests
- Integration tests
- Coverage reports

### 9. **PerformanceAgent** (PEA)
**Ответственность:** Производительность
**Инструменты:** DevTools, benchmark
**Фокус:**
- Build optimization
- Memory usage
- Frame timing
- Bundle size

### 10. **SecurityAgent** (SEA)
**Ответственность:** Безопасность
**Инструменты:** Security scanner
**Фокус:**
- Token handling
- API security
- Data encryption
- Vulnerability scanning

---

## 🔄 WORKFLOW

```
┌─────────────────────────────────────────────────────┐
│              CODE CHANGE COMMIT                     │
└─────────────────┬───────────────────────────────────┘
                  │
         ┌────────▼────────┐
         │ CodeQualityAgent │
         │   (Static Analysis)│
         └────────┬────────┘
                  │
         ┌────────▼────────┐
         │ ArchitectureAgent│
         │  (Module Check)  │
         └────────┬────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐   ┌────▼────┐   ┌───▼───┐
│Widget │   │ Service │   │Provider│
│ Agent │   │  Agent  │   │ Agent │
└───┬───┘   └────┬────┘   └───┬───┘
    │            │             │
    └────────────┼─────────────┘
                 │
        ┌────────▼────────┐
        │DesignSystemAgent│
        │  (UI Consistency)│
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │ DocumentationAgent│
        │   (Auto-docs)    │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Testing Agent   │
        │  (Test Generation)│
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │ PerformanceAgent │
        │   (Benchmark)    │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Security Agent  │
        │   (Security Scan)│
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  MERGE REQUEST  │
        │   (All Passed)   │
        └─────────────────┘
```

---

## 📊 АГЕНТ ОТЧЁТЫ

### Формат отчёта

```markdown
# [AGENT_NAME] Report

**Date:** YYYY-MM-DD
**Scope:** [Files/Modules analyzed]

## Findings

### Critical (N)
- [ ] Issue description
  - File: `path/to/file.dart`
  - Lines: XX-YY
  - Impact: Description
  - Fix: Recommendation

### High (N)
...

### Medium (N)
...

## Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| ... | ... | ... | ... |

## Recommendations

1. Priority 1 tasks
2. Priority 2 tasks
3. Priority 3 tasks
```

---

## 🎯 KPI АГЕНТОВ

| Агент | KPI | Target |
|-------|-----|--------|
| **CQA** | God Classes | 0 |
| **CQA** | Code duplication | < 5% |
| **ARA** | Circular deps | 0 |
| **ARA** | Module coupling | < 10% |
| **WRA** | Widget reuse rate | > 80% |
| **WRA** | Private widgets | < 5/file |
| **SLA** | API call duplication | 0 |
| **SLA** | Error handling coverage | 100% |
| **PRA** | Provider testability | 100% |
| **PRA** | DI coverage | 100% |
| **DSA** | Token usage | 100% |
| **DSA** | Style consistency | 100% |
| **DOA** | API docs coverage | 100% |
| **TEA** | Test coverage | > 70% |
| **PEA** | Build time | < 2 min |
| **PEA** | App size | < 50 MB |
| **SEA** | Security issues | 0 |

---

## 🚀 ACTIVATION COMMANDS

```bash
# Run all agents
make agents-run

# Run specific agent
make agent-cqa    # Code Quality
make agent-ara    # Architecture
make agent-wra    # Widget Reuse
make agent-sla    # Service Layer
make agent-pra    # Provider
make agent-dsa    # Design System
make agent-doa    # Documentation
make agent-tea    # Testing
make agent-pea    # Performance
make agent-sea    # Security

# Run agent on specific file
make agent-cqa FILE=lib/screens/settings_screen.dart

# Generate agent report
make agent-report AGENT=cqa

# Auto-fix with agent
make agent-fix AGENT=cqa SCOPE=critical
```

---

## 📈 AGENT HISTORY

### Session 1 (2026-02-22)
- **Agents:** 8 general-purpose
- **Tasks:** Initial audit, mock fixes
- **Result:** 43→0 errors

### Session 2 (2026-02-24)
- **Agents:** 10 specialized
- **Tasks:** Architecture audit, refactoring
- **Result:** 13→0 God Classes (target)

### Session 3 (Current)
- **Agents:** 10 + 2 new (Refactoring, Optimization)
- **Tasks:** Full refactoring, optimization
- **Target:** Production ready

---

**Агенты готовы к работе!** 🤖
