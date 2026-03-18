# GitDoIt Multi-Agent System - Mr* Series

GitDoIt uses a **multi-agent system** for autonomous development, quality control, and project management.

**Version:** 3.0.0 (Mr* Series)  
**Last Updated:** March 18, 2026  
**Location:** `lib/agents/`  
**Naming Convention:** All agents prefixed with "Mr" for consistency

---

## 🤖 Agent Team (Mr* Series)

### Core Agents (Dart Implementation)

| Agent | Class | File | Role |
|-------|-------|------|------|
| **MrPlanner** | `MrPlanner` | `MrPlanner.dart` | Project Manager (PMA) |
| **MrDeveloper** | `MrDeveloper` | `MrDeveloper.dart` | Flutter Developer (FDA) |
| **MrDesigner** | `MrDesigner` | `MrDesigner.dart` | UI/UX Designer (UDA) |
| **MrTester** | `MrTester` | `MrTester.dart` | Testing & Quality (TQA) |
| **MrLogger** | `MrLogger` | `MrLogger.dart` | Documentation (DDA) |
| **MrCompliance** | `MrCompliance` | `MrCompliance.dart` | Rules & Compliance (RCA) |
| **MrCoordinator** | `MrCoordinator` | `MrCoordinator.dart` | Agent Coordinator (COORD) |

### Specialist Agents (Markdown Specs)

| Agent | File | Role | Integration |
|-------|------|------|-------------|
| **MrArchitect** | `MrArchitect.md` | Architecture | → MrCompliance |
| **MrSync** | `MrSync.md` | Coordination | → MrPlanner |
| **MrSupervisor** | `MrSupervisor.md` | Supervision | → MrCoordinator |
| **MrSeniorDeveloper** | `MrSeniorDeveloper.md` | Code Review | → MrDeveloper |
| **MrCleaner** | `MrCleaner.md` | Code Quality | → MrDeveloper |
| **MrRepetitive** | `MrRepetitive.md` | Templates | → MrDeveloper |
| **MrOptimization** | `MrOptimization.md` | Performance | → MrDeveloper |
| **MrAndroid** | `MrAndroid.md` | Android Debug | → MrDeveloper |
| **MrAndroidDebug** | `MrAndroidDebug.md` | Android Telemetry | → MrDeveloper |
| **MrUX** | `MrUX.md` | UX Design | → MrDesigner |
| **MrThemeGuardian** | `MrThemeGuardian.md` | Theme Compliance | → MrDesigner |
| **MrWidgetCrafter** | `MrWidgetCrafter.md` | Widget Creation | → MrDesigner |
| **MrCreativeDirector** | `MrCreativeDirector.md` | User Journeys | → MrDesigner |
| **MrTesterSpec** | `MrTesterSpec.md` | Testing Spec | → MrTester |
| **MrQualityControl** | `MrQualityControl.md` | Quality Gate | → MrTester |
| **MrStupidUser** | `MrStupidUser.md` | UX Validation | → MrTester |
| **MrLoggerSpec** | `MrLoggerSpec.md` | Logging Spec | → MrLogger |
| **MrRelease** | `MrRelease.md` | Releases | → MrLogger |
| **MrMemory** | `MrMemory.md` | Memory | → MrCompliance |

---

## 📋 Agent Responsibilities

### MrPlanner (Project Manager)
**Role:** Team coordination and task management

**Responsibilities:**
- Coordinates all other agents
- Assigns tasks based on priorities
- Tracks sprint progress
- Makes architectural decisions
- Resolves conflicts between agents
- Manages task queue

**Usage:**
```dart
final planner = MrPlanner();
await planner.start();
planner.addTask(AgentTask(...));
```

---

### MrDeveloper (Flutter Developer)
**Role:** Code implementation and feature development

**Responsibilities:**
- Writes code and implements features
- Follows project conventions
- Runs code generation (build_runner)
- Fixes bugs
- Refactors code
- Implements agent tasks

**Usage:**
```dart
final developer = MrDeveloper();
await developer.start();
await developer.execute();
```

---

### MrDesigner (UI/UX Designer)
**Role:** Design system compliance and UI design

**Responsibilities:**
- Designs interface components
- Ensures design system compliance
- Creates responsive layouts
- Validates color usage
- Checks accessibility
- Monitors dark theme compliance

**Usage:**
```dart
final designer = MrDesigner();
await designer.start();
designer.checkDesignCompliance();
```

---

### MrTester (Testing & Quality)
**Role:** Quality assurance and testing

**Responsibilities:**
- Validates code quality
- Runs tests
- Checks code coverage
- Enforces linting rules
- Reports issues
- Monitors test coverage

**Usage:**
```dart
final tester = MrTester();
await tester.start();
final report = tester.getQualityReport();
```

---

### MrLogger (Documentation)
**Role:** Documentation and deployment

**Responsibilities:**
- Maintains documentation
- Updates README
- Generates API docs
- Prepares releases
- Manages changelog
- Tracks version updates

**Usage:**
```dart
final logger = MrLogger();
await logger.start();
await logger.updateChangelog();
```

---

### MrCompliance (Rules & Compliance)
**Role:** Proactive rule monitoring and enforcement

**Responsibilities:**
- **PROACTIVE:** Continuously monitors for rule violations
- Checks naming conventions
- Validates offline-first architecture
- Ensures dark theme compliance
- Monitors error handling
- Checks secure storage usage
- Validates responsive design
- Prevents shortcut engineering

**Usage:**
```dart
final compliance = MrCompliance();
await compliance.start();
final report = compliance.getComplianceReport();
```

**Loaded Rules:** 10 active rules
- `naming_convention` - PascalCase classes, camelCase variables
- `offline_first` - All features must work offline
- `dark_theme_only` - Use only dark theme colors
- `no_shortcuts` - No quick and dirty solutions
- `trailing_commas` - Use trailing commas
- `single_quotes` - Use single quotes for strings
- `responsive_design` - Use ScreenUtil
- `error_handling` - All async ops need error handling
- `secure_storage` - Tokens in flutter_secure_storage
- `no_env_commit` - Never commit .env file

---

### MrCoordinator (Agent Coordinator)
**Role:** Central control and orchestration

**Responsibilities:**
- **CONTROLLER:** Central control system
- Registers and manages all agents
- Facilitates inter-agent communication
- Monitors agent health
- Coordinates parallel execution
- Provides centralized control
- Restarts inactive agents
- Routes messages between agents

**Usage:**
```dart
final coordinator = get coordinator; // Singleton
await coordinator.startAll();

// Check status
print(coordinator.getAgentStatus());
print(coordinator.getComplianceStatus());

await coordinator.stopAll();
```

---

## 🚀 Usage

### Initialize All Agents

```dart
import 'package:gitdoit/agents/agents.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... other initialization code ...
  
  // Initialize and start all agents
  final coordinator = get coordinator;
  await coordinator.startAll();
  
  debugPrint('All agents started');
  
  runApp(MyApp());
}
```

### Get Agent Status

```dart
// Get all agents status
final status = coordinator.getAgentStatus();
print('Active agents: ${status['active']}/${status['total']}');

// Get compliance report
final compliance = coordinator.getComplianceStatus();
print('Compliance: ${compliance['status']}');
print('Violations: ${compliance['violations']}');

// Get quality report
final quality = coordinator.getQualityStatus();
print('Tests: ${quality['tests_passed']}/${quality['tests_run']}');
print('Issues: ${quality['issues']}');
```

### Send Message to Agent

```dart
// Send task to specific agent
coordinator.sendMessageTo('MrDeveloper', AgentMessage(
  from: 'User',
  type: AgentMessageType.task,
  subject: 'implement_feature',
  content: 'Add dark mode toggle',
));

// Broadcast to all agents
coordinator.broadcastMessage(AgentMessage(
  from: 'MrPlanner',
  type: AgentMessageType.broadcast,
  subject: 'Sprint Started',
  content: 'Sprint 1 has begun',
));
```

### Stop All Agents

```dart
await coordinator.stopAll();
coordinator.dispose();
```

---

## 📡 Agent Communication

Agents communicate through a **message bus** system:

### Message Types
- `task` - Assign new task
- `status` - Report status update
- `error` - Report error/violation
- `request` - Request information
- `response` - Respond to request
- `broadcast` - Broadcast to all

### Example Message Flow

```
MrPlanner → MrDeveloper: New Task (implement feature)
MrDeveloper → MrTester: Request (validate code)
MrTester → MrPlanner: Response (quality report)
MrCompliance → MrPlanner: Error (rule violations)
MrPlanner → MrDeveloper: Task (fix violations)
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   MrCoordinator                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │                 Message Bus                      │    │
│  └─────────────────────────────────────────────────┘    │
│         │         │         │         │         │        │
│    ┌────▼────┐ ┌──▼───┐ ┌───▼──┐ ┌───▼──┐ ┌────▼───┐   │
│    │ MrPlanner│ │MrDev │ │MrDes │ │MrTest│ │ MrLog  │   │
│    └─────────┘ └──────┘ └──────┘ └──────┘ └────────┘   │
│         │                                               │
│    ┌────▼────────────────────────────────────────┐     │
│    │          MrCompliance (Proactive)            │     │
│    │  - 10 rules loaded                           │     │
│    │  - Continuous monitoring                     │     │
│    │  - Compliance reports                        │     │
│    │  - Violation detection                       │     │
│    └──────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 File Structure

```
lib/agents/
├── agents.dart                      # Library exports
├── base_agent.dart                  # Base class
├── MrCoordinator.dart               # Central coordinator
├── MrPlanner.dart                   # Project manager
├── MrDeveloper.dart                 # Flutter developer
├── MrDesigner.dart                  # UI/UX designer
├── MrTester.dart                    # Testing & quality
├── MrLogger.dart                    # Documentation
├── MrCompliance.dart                # Rules & compliance
│
└── [Specialist Specs - Markdown]
    ├── MrArchitect.md
    ├── MrSync.md
    ├── MrSupervisor.md
    ├── MrSeniorDeveloper.md
    ├── MrCleaner.md
    ├── MrRepetitive.md
    ├── MrOptimization.md
    ├── MrAndroid.md
    ├── MrAndroidDebug.md
    ├── MrUX.md
    ├── MrThemeGuardian.md
    ├── MrWidgetCrafter.md
    ├── MrCreativeDirector.md
    ├── MrTesterSpec.md
    ├── MrQualityControl.md
    ├── MrStupidUser.md
    ├── MrLoggerSpec.md
    ├── MrRelease.md
    ├── MrMemory.md
    │
    └── [Documentation]
        ├── MrRegulament.md
        ├── MrConsolidatedSpec.md
        ├── MrComparisonSummary.md
        ├── MrBuildVerification.md
        ├── MrImplementationGuidelines.md
        ├── MrVerificationStatus.md
        ├── MrProtectedFilesRule.md
        └── MrREADME.md
```

---

## 🧪 Testing

### Wake Agents Test

```bash
flutter test test/agents/wake_agents_test.dart
```

**Expected Output:**
```
AgentCoordinator: Registered MrPlanner
AgentCoordinator: Registered MrDeveloper
AgentCoordinator: Registered MrDesigner
AgentCoordinator: Registered MrTester
AgentCoordinator: Registered MrLogger
AgentCoordinator: Registered MrCompliance
AgentCoordinator: All agents started
MrCompliance: Running compliance checks...
MrCompliance: Checking rule: Naming Convention
...
00:11 +5: All tests passed!
```

---

## ✅ Naming Convention

All agents follow the **Mr* Series** naming convention:

- **Prefix:** "Mr" (consistent across all agents)
- **Format:** PascalCase (e.g., `MrPlanner`, `MrDeveloper`)
- **Files:** Match class names (e.g., `MrPlanner.dart` contains `class MrPlanner`)
- **Variables:** camelCase (e.g., `mrPlanner`, `coordinator`)

This ensures:
- ✅ Consistent naming across all agents
- ✅ Easy to identify agent classes
- ✅ Clear distinction from other classes
- ✅ Professional team identity

---

**Built with ❤️ using the GitDoIt Mr* Series Agent System**
