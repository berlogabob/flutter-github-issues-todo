import 'package:flutter/foundation.dart';

/// Repository configuration model for multi-repo support
///
/// Represents a single GitHub repository with its configuration state.
class RepositoryConfig {
  final String owner;
  final String name;
  final bool isEnabled;
  final DateTime? lastSynced;
  final int? issueCount;

  RepositoryConfig({
    required this.owner,
    required this.name,
    this.isEnabled = true,
    this.lastSynced,
    this.issueCount,
  });

  /// Get full repository identifier (owner/name)
  String get fullName => '$owner/$name';

  /// Check if repository has been synced
  bool get hasSynced => lastSynced != null;

  /// Create a copy with updated fields
  RepositoryConfig copyWith({
    String? owner,
    String? name,
    bool? isEnabled,
    DateTime? lastSynced,
    int? issueCount,
  }) {
    return RepositoryConfig(
      owner: owner ?? this.owner,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSynced: lastSynced ?? this.lastSynced,
      issueCount: issueCount ?? this.issueCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryConfig &&
          runtimeType == other.runtimeType &&
          owner == other.owner &&
          name == other.name &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => owner.hashCode ^ name.hashCode ^ isEnabled.hashCode;

  @override
  String toString() => 'RepositoryConfig($fullName, enabled: $isEnabled)';
}

/// Multi-repository configuration manager
///
/// Manages a list of repositories with enable/disable state.
class MultiRepositoryConfig extends ChangeNotifier {
  final List<RepositoryConfig> _repositories = [];
  String? _activeRepository;

  /// Get all configured repositories
  List<RepositoryConfig> get repositories => List.unmodifiable(_repositories);

  /// Get enabled repositories only
  List<RepositoryConfig> get enabledRepositories =>
      _repositories.where((r) => r.isEnabled).toList();

  /// Get disabled repositories only
  List<RepositoryConfig> get disabledRepositories =>
      _repositories.where((r) => !r.isEnabled).toList();

  /// Get the currently active repository
  String? get activeRepository => _activeRepository;

  /// Check if any repositories are configured
  bool get hasRepositories => _repositories.isNotEmpty;

  /// Check if multiple repositories are enabled
  bool get hasMultipleRepos => enabledRepositories.length > 1;

  /// Get repository by full name
  RepositoryConfig? getRepository(String fullName) {
    try {
      return _repositories.firstWhere((r) => r.fullName == fullName);
    } catch (_) {
      return null;
    }
  }

  /// Add a new repository
  void addRepository(String owner, String name) {
    final config = RepositoryConfig(owner: owner, name: name);
    _repositories.add(config);
    _activeRepository ??= config.fullName;
    notifyListeners();
  }

  /// Remove a repository
  void removeRepository(String fullName) {
    final index = _repositories.indexWhere((r) => r.fullName == fullName);
    if (index != -1) {
      _repositories.removeAt(index);
      if (_activeRepository == fullName) {
        _activeRepository = _repositories.isNotEmpty
            ? _repositories.first.fullName
            : null;
      }
      notifyListeners();
    }
  }

  /// Toggle repository enabled state
  void toggleRepository(String fullName) {
    final index = _repositories.indexWhere((r) => r.fullName == fullName);
    if (index != -1) {
      final repo = _repositories[index];
      _repositories[index] = repo.copyWith(isEnabled: !repo.isEnabled);
      notifyListeners();
    }
  }

  /// Set repository enabled state
  void setRepositoryEnabled(String fullName, bool enabled) {
    final index = _repositories.indexWhere((r) => r.fullName == fullName);
    if (index != -1) {
      final repo = _repositories[index];
      if (repo.isEnabled != enabled) {
        _repositories[index] = repo.copyWith(isEnabled: enabled);
        notifyListeners();
      }
    }
  }

  /// Update repository sync state
  void updateSyncState(
    String fullName, {
    DateTime? lastSynced,
    int? issueCount,
  }) {
    final index = _repositories.indexWhere((r) => r.fullName == fullName);
    if (index != -1) {
      final repo = _repositories[index];
      _repositories[index] = repo.copyWith(
        lastSynced: lastSynced,
        issueCount: issueCount,
      );
      notifyListeners();
    }
  }

  /// Set active repository
  void setActiveRepository(String? fullName) {
    if (fullName == null || _repositories.any((r) => r.fullName == fullName)) {
      _activeRepository = fullName;
      notifyListeners();
    }
  }

  /// Clear all repositories
  void clear() {
    _repositories.clear();
    _activeRepository = null;
    notifyListeners();
  }

  /// Load from list of full names (owner/repo format)
  void loadFromList(List<String> fullNames) {
    _repositories.clear();
    for (final fullName in fullNames) {
      final parts = fullName.split('/');
      if (parts.length == 2) {
        _repositories.add(RepositoryConfig(owner: parts[0], name: parts[1]));
      }
    }
    if (_repositories.isNotEmpty) {
      _activeRepository = _repositories.first.fullName;
    }
    notifyListeners();
  }

  /// Export to list of full names
  List<String> exportToList() {
    return _repositories.map((r) => r.fullName).toList();
  }
}
