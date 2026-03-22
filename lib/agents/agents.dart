/// GitDoIt Multi-Agent System - Mr* Series
///
/// This library provides a team of autonomous agents that work together
/// to develop, maintain, and improve the GitDoIt application.
///
/// ## Agents (Mr* Series)
///
/// - [MrPlanner] - Project planning and task management (PMA)
/// - [MrDeveloper] - Flutter development (FDA)
/// - [MrDesigner] - UI/UX design (UDA)
/// - [MrTester] - Testing and quality assurance (TQA)
/// - [MrLogger] - Documentation and logging (DDA)
/// - [MrCompliance] - Rules and compliance (RCA)
/// - [MrCoordinator] - Controls all agents (COORD)
///
/// ## Specialist Agents (Reference Specs)
///
/// - MrArchitect, MrSync, MrSupervisor
/// - MrSeniorDeveloper, MrCleaner, MrRepetitive, MrOptimization
/// - MrAndroid, MrAndroidDebug
/// - MrUX, MrThemeGuardian, MrWidgetCrafter, MrCreativeDirector
/// - MrTesterSpec, MrQualityControl, MrStupidUser
/// - MrLoggerSpec, MrRelease, MrMemory
///
/// ## Coordinator
///
/// The [MrCoordinator] controls all agents, facilitates communication,
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
///   // Stop all agents
///   await coordinator.stopAll();
/// }
/// ```
library agents;

export 'base_agent.dart';
export 'mr_planner.dart';
export 'mr_developer.dart';
export 'mr_designer.dart';
export 'mr_tester.dart';
export 'mr_logger.dart';
export 'mr_compliance.dart';
export 'mr_coordinator.dart';
