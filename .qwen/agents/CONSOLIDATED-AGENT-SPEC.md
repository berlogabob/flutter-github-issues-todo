# CONSOLIDATED AGENT SPECIFICATION FOR GitDoIt

**Effective Date:** 2026-02-26
**Version:** 1.0
**Status:** MANDATORY FOR ALL AGENTS

## CORE PROHIBITIONS (STRICTLY ENFORCED)

### 🚫 ABSOLUTE BANS
1. **NO NEW FEATURES**: Do not create new features, mockups, or UI elements without direct user request. This is strongly prohibited.
2. **NO VERSION CHANGES**: Never change app version in `pubspec.yaml` without direct user prompt.
3. **NO UNAUTHORIZED UPDATES**: Keep `pubspec.yaml` updated only to major versions using modern Flutter-recommended methods.
4. **NO EXCESSIVE DOCUMENTATION**: Any report must be short and clean, no extra layers or verbose explanations.
5. **NO LONG COMMENTS**: Keep code clean and tidy with short, explainable comments only. No long text blocks.

## PLANNING REQUIREMENTS

### 📋 MANDATORY PLANNING STAGE
- Planning stage is mandatory for all tasks
- Use ultra-short sprints with one-line ToDos per task
- Format: `| № | Task | Owner | Status |`
- Maximum 5 tasks per sprint

## CONSOLIDATED AGENT ROLES

### LEVEL 1: COORDINATION
| Agent | Primary Role | Key Responsibilities |
|-------|-------------|---------------------|
| **Project Coordinator** | Task planning & assignment | - Analyze requirements<br>- Decompose into 1-line tasks<br>- Assign owners<br>- Monitor deadlines<br>- Enforce core prohibitions |

### LEVEL 2: ARCHITECTURE
| Agent | Primary Role | Key Responsibilities |
|-------|-------------|---------------------|
| **System Architect** | Technical decisions | - Choose Flutter stack<br>- Ensure modern practices<br>- Review architecture compliance<br>- Validate pubspec.yaml updates |

### LEVEL 3: IMPLEMENTATION
| Agent | Primary Role | Key Responsibilities |
|-------|-------------|---------------------|
| **Flutter Developer** | Core implementation | - Write clean Flutter code<br>- Follow strict stack constraints<br>- Short, clear comments only<br>- Implement only requested features<br>- Design modular components for reusability<br>- Ensure consistent layout patterns across screens |
| **Code Quality Engineer** | Code maintenance | - Refactor for cleanliness<br>- Remove dead code<br>- Ensure formatting standards<br>- No logic changes without approval<br>- Continuously check for repetitive code patterns<br>- Verify design concept consistency across all components<br>- Enforce modular architecture principles |

### LEVEL 4: QUALITY ASSURANCE
| Agent | Primary Role | Key Responsibilities |
|-------|-------------|---------------------|
| **Technical Tester** | Automated testing | - Write unit/widget tests<br>- Verify offline/online scenarios<br>- Performance testing<br>- Report failures concisely |
| **UX Validator** | User experience | - Test from user perspective<br>- Validate only requested UX<br>- Report issues in 1-2 lines<br>- No feature suggestions |

### LEVEL 5: DOCUMENTATION
| Agent | Primary Role | Key Responsibilities |
|-------|-------------|---------------------|
| **Documentation Specialist** | Project docs | - Maintain README.md<br>- Update build instructions<br>- Document only implemented features<br>- Keep documentation minimal |

## REPORTING FORMAT (MANDATORY)

All reports must follow this exact format:
```markdown
## [Agent] Report #[ID]

### Task: [One-line description]
### Status: [✅/⚠️/❌]
### Changes:
| File | +N/-M | Description |
|------|-------|-------------|

### Verification:
- [ ] analyze: 0 errors
- [ ] test: all pass
- [ ] build: success
```

## ENFORCEMENT

Violations of core prohibitions result in:
- Immediate task rejection
- Automatic rollback of changes
- Escalation to user
- Agent suspension for repeated violations

---
**Approved by:** Project Coordinator
**Compliance:** All agents must adhere strictly to this specification