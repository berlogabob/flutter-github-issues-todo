# GitDoIt Multi-Agent System

GitDoIt uses a **multi-agent system** for autonomous development, quality control, and project management.

---

## 🤖 Agent Team

| Agent | Role | Status |
|-------|------|--------|
| **PMA** | Project Manager | ✅ Active |
| **FDA** | Flutter Developer | ✅ Active |
| **UDA** | UI/UX Designer | ✅ Active |
| **TQA** | Testing & Quality | ✅ Active |
| **DDA** | Documentation & Deployment | ✅ Active |
| **RCA** | Rules & Compliance | 🆕 PROACTIVE |
| **COORD** | Agent Coordinator | 🆕 CONTROLLER |

---

## 📋 Agent Responsibilities

### Project Manager Agent (PMA)
- Coordinates all other agents
- Assigns tasks based on priorities
- Tracks sprint progress
- Makes architectural decisions
- Resolves conflicts between agents

### Flutter Developer Agent (FDA)
- Writes code and implements features
- Follows project conventions
- Runs code generation (build_runner)
- Fixes bugs
- Refactors code

### UI/UX Designer Agent (UDA)
- Designs interface components
- Ensures design system compliance
- Creates responsive layouts
- Validates color usage
- Checks accessibility

### Testing & Quality Agent (TQA)
- Validates code quality
- Runs tests
- Checks code coverage
- Enforces linting rules
- Reports issues

### Documentation & Deployment Agent (DDA)
- Maintains documentation
- Updates README
- Generates API docs
- Prepares releases
- Manages changelog

### Rules & Compliance Agent (RCA) 🆕
**PROACTIVE AGENT** - Continuously monitors for:
- Project rules compliance
- Naming conventions
- Offline-first architecture
- Dark theme compliance
- Error handling
- Secure storage usage
- Responsive design
- No shortcut engineering

### Agent Coordinator (COORD) 🆕
**CONTROLLER** - Central control system:
- Registers and manages all agents
- Facilitates inter-agent communication
- Monitors agent health
- Coordinates parallel execution
- Provides centralized control

---

## 🚀 Usage

### Start All Agents

```dart
import 'package:gitdoit/agents/agents.dart';

void main() async {
  // Get coordinator (singleton)
  final coordinator = get coordinator;
  
  // Start all agents
  await coordinator.startAll();
  
  // Check status
  print(coordinator.getAgentStatus());
  
  // Run your app
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

// Get quality report
final quality = coordinator.getQualityStatus();
print('Tests: ${quality['tests_passed']}/${quality['tests_run']}');
```

### Send Message to Agent

```dart
// Send task to specific agent
coordinator.sendMessageTo('FlutterDeveloperAgent', AgentMessage(
  from: 'User',
  type: AgentMessageType.task,
  subject: 'implement_feature',
  content: 'Add dark mode toggle',
));

// Broadcast to all agents
coordinator.broadcastMessage(AgentMessage(
  from: 'ProjectManagerAgent',
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
PMA → FDA: New Task (implement feature)
FDA → TQA: Request (validate code)
TQA → PMA: Response (quality report)
RCA → PMA: Error (rule violations)
PMA → FDA: Task (fix violations)
```

---

## 🎯 Project Rules (RCA)

The Rules & Compliance Agent enforces these rules:

| Rule | Severity | Description |
|------|----------|-------------|
| `naming_convention` | Warning | PascalCase classes, camelCase variables |
| `offline_first` | **Critical** | All features must work offline |
| `dark_theme_only` | Warning | Use only dark theme colors |
| `no_shortcuts` | Error | No quick and dirty solutions |
| `trailing_commas` | Warning | Use trailing commas |
| `single_quotes` | Warning | Use single quotes for strings |
| `responsive_design` | Warning | Use ScreenUtil |
| `error_handling` | **Critical** | All async ops need error handling |
| `secure_storage` | **Critical** | Tokens in flutter_secure_storage |
| `no_env_commit` | **Critical** | Never commit .env file |

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   AgentCoordinator                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │                 Message Bus                      │    │
│  └─────────────────────────────────────────────────┘    │
│         │         │         │         │         │        │
│    ┌────▼────┐ ┌──▼───┐ ┌───▼──┐ ┌───▼──┐ ┌────▼───┐   │
│    │   PMA   │ │ FDA  │ │ UDA  │ │ TQA  │ │  DDA   │   │
│    └─────────┘ └──────┘ └──────┘ └──────┘ └────────┘   │
│         │                                               │
│    ┌────▼────────────────────────────────────────┐     │
│    │              RCA (Proactive)                 │     │
│    │  - Checks rules                              │     │
│    │  - Monitors compliance                       │     │
│    │  - Reports violations                        │     │
│    └──────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration

### Enable/Disable Agents

```dart
// Start only specific agents
final coordinator = AgentCoordinator();
await coordinator.getAgent<FlutterDeveloperAgent>('FlutterDeveloperAgent').start();
```

### Custom Rules

```dart
// Add custom rule to RCA
final rca = coordinator.getAgent<RulesComplianceAgent>('RulesComplianceAgent');
rca.addViolation(RuleViolation(
  ruleId: 'custom_rule',
  file: 'lib/example.dart',
  line: 42,
  message: 'Custom rule violation',
  severity: RuleSeverity.warning,
));
```

---

## 📈 Monitoring

### Agent Health Check

The coordinator automatically checks agent health every 5 seconds:
- Restarts inactive agents
- Coordinates tasks between agents
- Monitors compliance and quality

### Logs

```
AgentCoordinator: Starting all agents...
ProjectManagerAgent: Started - Coordinating team...
FlutterDeveloperAgent: Started - Waiting for tasks...
RulesComplianceAgent: Started - PROACTIVELY monitoring rules...
AgentCoordinator: All agents started
RulesComplianceAgent: Running compliance checks...
RulesComplianceAgent: PROACTIVE check: lib/services/api.dart
```

---

## 🛠️ Development

### Adding New Agents

1. Create new agent class extending `BaseAgent`
2. Implement required methods: `init()`, `start()`, `execute()`, `handleMessage()`
3. Register with coordinator

```dart
class MyNewAgent extends BaseAgent {
  MyNewAgent() : super(
    name: 'MyNewAgent',
    role: 'My Role',
    responsibilities: ['Task 1', 'Task 2'],
  );
  
  @override
  Future<void> init() async { /* ... */ }
  
  @override
  Future<void> start() async {
    _isActive = true;
    await execute();
  }
  
  @override
  Future<void> execute() async { /* ... */ }
  
  @override
  void handleMessage(AgentMessage message) { /* ... */ }
}
```

---

**Built with ❤️ using the GitDoIt Agent System**
