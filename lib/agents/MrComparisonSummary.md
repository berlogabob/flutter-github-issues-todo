# AGENT COMPARISON & CONSOLIDATION SUMMARY

## CURRENT STATE (Before Consolidation)
- **5 project-specific agents** in `agents.json`
- **13 framework agents** in `.qwen/agents/`
- **Significant duty overlap** in coordination, design, and testing roles
- **Inconsistent reporting formats** and enforcement rules

## KEY DUTY CLASHES IDENTIFIED

| Area | Overlapping Agents | Conflict Description |
|------|-------------------|---------------------|
| **Coordination** | PMA, MrPlanner, MrSync | Triple responsibility for planning/task assignment |
| **UI/UX Design** | UDA, UXAgent, MrUXUIDesigner | Conflicting scope: screens vs UX vs visual elements |
| **Development** | FDA, MrSeniorDeveloper | Both write core code with different constraints |
| **Testing** | TQA, MrTester, MrStupidUser | Technical testing vs UX validation vs integration |

## CONSOLIDATED STRUCTURE (6 CORE AGENTS)

### 1. Project Coordinator (PMA + MrPlanner + MrSync)
- **Mandatory planning**: Ultra-short sprints with 1-line ToDos
- **Enforces prohibitions**: No new features, no version changes without user request
- **Reporting**: Strict 1-page format only

### 2. System Architect (SystemArchitect)
- **pubspec.yaml management**: Only major version updates, modern Flutter methods
- **Stack validation**: Ensures FDA uses only approved packages
- **Architecture review**: Validates all technical decisions

### 3. Flutter Developer (FDA + MrSeniorDeveloper)
- **Code implementation**: Clean, tidy code with short comments only
- **Feature restriction**: Implements ONLY what user explicitly requests
- **No mockups**: Zero UI elements without direct user approval
- **Modular design**: Design components for reusability across the app
- **Layout consistency**: Ensure consistent layout patterns across all screens

### 4. Code Quality Engineer (MrCleaner + MrRefactorer)
- **Code hygiene**: Formatting, dead code removal, consistency
- **No logic changes**: Only structural improvements
- **Short reports**: One-line status updates
- **Continuous monitoring**: Check for repetitive code patterns throughout development
- **Design consistency**: Verify design concept consistency across all components
- **Modular enforcement**: Enforce modular architecture principles

### 5. Technical Tester (TQA + MrTester)
- **Automated testing**: Unit/widget tests only for implemented features
- **Performance validation**: Large dataset testing (~1000 items)
- **Concise reporting**: Failures reported in 1-2 lines max

### 6. UX Validator (MrStupidUser)
- **User perspective testing**: Only validates requested UX flows
- **No suggestions**: Reports problems but never proposes new features
- **Emotion tracking**: Simple high/medium/low ratings only

## NEW MANDATORY RULES (APPLIED TO ALL)

✅ **Planning Stage Required**: Every task must have ultra-short sprint plan  
✅ **One-Line ToDos**: Maximum 5 tasks per sprint, each as single line  
✅ **No New Features**: Strict prohibition - requires explicit user request  
✅ **Version Control**: pubspec.yaml updates only with user prompt  
✅ **Modern Flutter**: Use only current/recommended Flutter methods  
✅ **Clean Code**: Short, explainable comments only - no long text  
✅ **Minimal Reporting**: Short, clean reports - no extra layers or verbosity  

## IMPLEMENTATION PLAN

1. **Immediate**: All agents adopt CONSOLIDATED-AGENT-SPEC.md
2. **Next Sprint**: Replace overlapping agents with consolidated 6-role structure
3. **Ongoing**: Enforce core prohibitions through automated checks

---
**Status**: Ready for implementation
**Compliance**: 100% alignment with user requirements