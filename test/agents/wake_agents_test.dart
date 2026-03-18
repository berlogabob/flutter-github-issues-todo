import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/agents/agents.dart';

void main() {
  group('Agent System Wake Up', () {
    late MrCoordinator coordinator;

    setUp(() async {
      coordinator = MrCoordinator();
      await coordinator.startAll();
    });

    tearDown(() async {
      await coordinator.stopAll();
      coordinator.dispose();
    });

    test('All agents start successfully', () async {
      // Start all agents
      await coordinator.startAll();

      // Get status
      final status = coordinator.getAgentStatus();
      
      // Verify all agents are active
      expect(status['total'], equals(6));
      expect(status['active'], equals(6));
      
      // Verify each agent individually
      final agents = status['agents'] as Map<String, dynamic>;
      expect(agents['MrPlanner']['active'], isTrue);
      expect(agents['MrDeveloper']['active'], isTrue);
      expect(agents['MrDesigner']['active'], isTrue);
      expect(agents['MrTester']['active'], isTrue);
      expect(agents['MrLogger']['active'], isTrue);
      expect(agents['MrCompliance']['active'], isTrue);
    });

    test('Compliance status is available', () async {
      await coordinator.startAll();
      
      final compliance = coordinator.getComplianceStatus();
      
      expect(compliance.containsKey('rules_checked'), isTrue);
      expect(compliance.containsKey('violations'), isTrue);
      expect(compliance.containsKey('status'), isTrue);
    });

    test('Quality status is available', () async {
      await coordinator.startAll();
      
      final quality = coordinator.getQualityStatus();
      
      expect(quality.containsKey('tests_run'), isTrue);
      expect(quality.containsKey('tests_passed'), isTrue);
      expect(quality.containsKey('issues'), isTrue);
    });

    test('Agents can receive and process messages', () async {
      await coordinator.startAll();
      
      // Send a broadcast message
      coordinator.broadcastMessage(AgentMessage(
        from: 'TestRunner',
        type: AgentMessageType.status,
        subject: 'Test Status',
        content: 'All systems operational',
      ));
      
      // Give agents time to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // All agents should still be active
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(6));
    });

    test('Coordinator can execute tasks', () async {
      await coordinator.startAll();
      
      // Create a test task
      final task = AgentTask(
        id: 'test_task_1',
        assignedTo: 'MrDeveloper',
        title: 'Test Task',
        description: 'This is a test task',
        priority: TaskPriority.normal,
      );
      
      // Execute the task
      await coordinator.executeTask(task);
      
      // Give agents time to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Task should be in progress
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(6));
    });
  });
}
