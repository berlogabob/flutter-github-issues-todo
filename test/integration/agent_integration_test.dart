import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/agents/agents.dart';

/// Integration test for agent system
/// Verifies that all agents can work together
void main() {
  group('Agent System Integration', () {
    late MrCoordinator coordinator;

    setUp(() async {
      coordinator = MrCoordinator();
      await coordinator.startAll();
    });

    tearDown(() async {
      await coordinator.stopAll();
      coordinator.dispose();
    });

    test('all agents start and communicate', () async {
      // Verify all agents are active
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(status['total']));
      
      // Send broadcast message
      coordinator.broadcastMessage(AgentMessage(
        from: 'TestRunner',
        type: AgentMessageType.status,
        subject: 'Integration Test',
        content: 'All systems operational',
      ));
      
      // Give agents time to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify agents still active
      final status2 = coordinator.getAgentStatus();
      expect(status2['active'], equals(status2['total']));
    });

    test('compliance checks run continuously', () async {
      // Wait for compliance checks
      await Future.delayed(const Duration(seconds: 2));
      
      final compliance = coordinator.getComplianceStatus();
      expect(compliance.containsKey('status'), isTrue);
      expect(compliance.containsKey('violations'), isTrue);
    });

    test('quality checks run continuously', () async {
      // Wait for quality checks
      await Future.delayed(const Duration(seconds: 2));
      
      final quality = coordinator.getQualityStatus();
      expect(quality.containsKey('tests_run'), isTrue);
      expect(quality.containsKey('tests_passed'), isTrue);
    });

    test('tasks can be assigned and tracked', () async {
      final task = AgentTask(
        id: 'integration_test_task',
        assignedTo: 'MrDeveloper',
        title: 'Integration Test Task',
        description: 'Test task assignment',
        priority: TaskPriority.normal,
      );
      
      coordinator.executeTask(task);
      
      // Give time to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify task was assigned
      final status = coordinator.getAgentStatus();
      expect(status['active'], greaterThan(0));
    });

    test('agents recover from stop', () async {
      // Stop all agents
      await coordinator.stopAll();
      
      // Restart
      await coordinator.startAll();
      
      // Verify all agents active
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(status['total']));
    });

    test('multiple messages can be processed', () async {
      // Send multiple messages
      for (int i = 0; i < 5; i++) {
        coordinator.sendMessageTo('MrPlanner', AgentMessage(
          from: 'TestRunner',
          type: AgentMessageType.task,
          subject: 'Test Task $i',
          content: 'Test content $i',
        ));
      }
      
      // Give time to process
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Verify agents still active
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(status['total']));
    });

    test('error messages are handled', () async {
      coordinator.sendMessageTo('MrCompliance', AgentMessage(
        from: 'TestRunner',
        type: AgentMessageType.error,
        subject: 'Test Error',
        content: 'Test error content',
      ));
      
      // Give time to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify agents still active
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(status['total']));
    });

    test('coordinator health check works', () async {
      // Wait for health check cycle (5 seconds)
      await Future.delayed(const Duration(seconds: 6));
      
      final status = coordinator.getAgentStatus();
      expect(status['active'], equals(status['total']));
    });

    test('statistics are available', () async {
      final compliance = coordinator.getComplianceStatus();
      final quality = coordinator.getQualityStatus();
      
      expect(compliance, isNotEmpty);
      expect(quality, isNotEmpty);
    });
  });
}
