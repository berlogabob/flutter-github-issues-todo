import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing search history
class SearchHistoryService {
  static final SearchHistoryService _instance =
      SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _historyKey = 'search_history';
  static const int _maxHistory = 10;

  /// Get search history
  Future<List<String>> getHistory() async {
    final historyJson = await _storage.read(key: _historyKey);
    if (historyJson == null) return [];

    try {
      final history = (jsonDecode(historyJson) as List).cast<String>();
      return history;
    } catch (e) {
      return [];
    }
  }

  /// Add query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    final history = await getHistory();
    history.remove(query); // Remove if exists
    history.insert(0, query); // Add to beginning

    if (history.length > _maxHistory) {
      history.removeLast();
    }

    await _storage.write(key: _historyKey, value: jsonEncode(history));
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _storage.delete(key: _historyKey);
  }

  /// Remove specific query from history
  Future<void> removeFromHistory(String query) async {
    final history = await getHistory();
    history.remove(query);
    await _storage.write(key: _historyKey, value: jsonEncode(history));
  }
}
