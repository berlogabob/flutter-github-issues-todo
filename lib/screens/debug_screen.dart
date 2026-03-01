import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import '../widgets/braille_loader.dart';

/// DebugScreen - Shows app diagnostics and helps identify issues
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Debug Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orangePrimary),
            onPressed: _isTesting ? null : _runDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: _copyLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Test button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isTesting
                    ? BrailleLoader(size: 20)
                    : const Icon(Icons.bug_report),
                label: Text(_isTesting ? 'Testing...' : 'Run Full Diagnostics'),
                onPressed: _isTesting ? null : _runDiagnostics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.orangePrimary.withValues(alpha: 0.3),
                ),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Tap "Run Full Diagnostics" to test\nthe app and identify issues.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.startsWith('❌');
                        final isSuccess = log.startsWith('✅');
                        final isWarning = log.startsWith('⚠️');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.substring(0, 2),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  log.substring(3),
                                  style: TextStyle(
                                    color: isError
                                        ? AppColors.red
                                        : isSuccess
                                        ? Colors.green
                                        : isWarning
                                        ? AppColors.orangePrimary
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _logs.clear();
      _isTesting = true;
    });

    _addLog('🔍 Starting diagnostics...');
    await Future.delayed(const Duration(milliseconds: 100));

    // Test 1: Internet Permission
    _addLog('Testing internet permission...');
    try {
      final result = await _testInternetPermission();
      _addLog(result ? '✅ Internet permission OK' : '❌ No internet permission');
    } catch (e) {
      _addLog('❌ Internet test failed: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // Test 2: Token Storage
    _addLog('Testing token storage...');
    try {
      final result = await _testTokenStorage();
      if (result['exists'] == true) {
        _addLog('✅ Token found (${result['length']} chars)');
      } else {
        _addLog('⚠️ No token saved (user not logged in)');
      }
    } catch (e) {
      _addLog('❌ Token storage test failed: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // Test 3: Network Connectivity
    _addLog('Testing network connectivity...');
    try {
      final result = await _testNetworkConnectivity();
      _addLog(
        result['success'] == true
            ? '✅ Network OK - ${result['host']} reachable'
            : '❌ Cannot reach ${result['host']}',
      );
      if (result['error'] != null) {
        _addLog('   Details: ${result['error']}');
      }
    } catch (e) {
      _addLog('❌ Network test failed: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // Test 4: GitHub API
    _addLog('Testing GitHub API...');
    try {
      final result = await _testGitHubAPI();
      if (result['success'] == true) {
        _addLog('✅ GitHub API OK - User: ${result['user']}');
      } else {
        _addLog('❌ GitHub API failed: ${result['error']}');
      }
    } catch (e) {
      _addLog('❌ GitHub API test failed: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // Test 5: Secure Storage
    _addLog('Testing secure storage...');
    try {
      final result = await _testSecureStorage();
      _addLog(result ? '✅ Secure storage working' : '❌ Secure storage failed');
    } catch (e) {
      _addLog('❌ Secure storage test failed: $e');
    }

    _addLog('🏁 Diagnostics complete');
    setState(() => _isTesting = false);
  }

  void _addLog(String message) {
    setState(() => _logs.add(message));
  }

  Future<bool> _testInternetPermission() async {
    // If we can make any network call, we have permission
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _testTokenStorage() async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(key: 'github_token');
    final authType = await storage.read(key: 'auth_type');

    return {
      'exists': token != null && token.isNotEmpty,
      'length': token?.length ?? 0,
      'authType': authType,
    };
  }

  Future<Map<String, dynamic>> _testNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('api.github.com');
      return {
        'success': result.isNotEmpty && result[0].rawAddress.isNotEmpty,
        'host': 'api.github.com',
      };
    } on SocketException catch (e) {
      return {'success': false, 'host': 'api.github.com', 'error': e.message};
    }
  }

  Future<Map<String, dynamic>> _testGitHubAPI() async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(key: 'github_token');

    if (token == null || token.isEmpty) {
      return {'success': false, 'error': 'No token found'};
    }

    try {
      final response = await http
          .get(
            Uri.parse('https://api.github.com/user'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'user': data['login']};
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _testSecureStorage() async {
    const storage = FlutterSecureStorage();

    // Write test
    await storage.write(key: '_debug_test', value: 'test123');

    // Read test
    final value = await storage.read(key: '_debug_test');

    // Cleanup
    await storage.delete(key: '_debug_test');

    return value == 'test123';
  }

  Future<void> _copyLogs() async {
    if (_logs.isEmpty) return;

    final text = _logs.join('\n');
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied to clipboard'),
          backgroundColor: AppColors.orangePrimary,
        ),
      );
    }
  }
}
