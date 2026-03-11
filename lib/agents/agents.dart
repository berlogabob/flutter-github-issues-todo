/// GitDoIt Multi-Agent System
/// 
/// This library provides a team of autonomous agents that work together
/// to develop, maintain, and improve the GitDoIt application.
/// 
/// ## Agents
/// 
/// - [ProjectManagerAgent] - Coordinates all agents, assigns tasks
/// - [FlutterDeveloperAgent] - Writes code, implements features
/// - [UiDesignerAgent] - Designs interfaces, ensures design compliance
/// - [TestingQualityAgent] - Runs tests, validates code quality
/// - [DocumentationAgent] - Maintains docs, prepares releases
/// - [RulesComplianceAgent] - PROACTIVE: Checks project rules and conventions
/// 
/// ## Coordinator
/// 
/// The [AgentCoordinator] controls all agents, facilitates communication,
/// and monitors agent health.
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:gitdoit/agents/agents.dart';
/// 
/// void main() async {
///   // Get coordinator (singleton)
///   final coordinator = get coordinator;
///   
///   // Start all agents
///   await coordinator.startAll();
///   
///   // Check status
///   print(coordinator.getAgentStatus());
///   
///   // Get compliance report
///   print(coordinator.getComplianceStatus());
///   
///   // Stop all agents
///   await coordinator.stopAll();
/// }
/// ```
library agents;

export 'base_agent.dart';
export 'project_manager_agent.dart';
export 'flutter_developer_agent.dart';
export 'ui_designer_agent.dart';
export 'testing_quality_agent.dart';
export 'documentation_agent.dart';
export 'rules_compliance_agent.dart';
export 'coordinator_agent.dart';
