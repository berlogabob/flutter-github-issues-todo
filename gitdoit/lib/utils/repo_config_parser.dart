/// Repository configuration utilities
///
/// Provides helpers for parsing and validating GitHub repository references.
library;

/// Extracts owner and repository name from various input formats
///
/// Supports:
/// - Plain text: "owner/repo" -> {owner: "owner", repo: "repo"}
/// - Full URL: "https://github.com/owner/repo" -> {owner: "owner", repo: "repo"}
/// - URL with trailing: "https://github.com/owner/repo/issues" -> {owner: "owner", repo: "repo"}
/// - SSH URL: "git@github.com:owner/repo.git" -> {owner: "owner", repo: "repo"}
///
/// Returns null if the input cannot be parsed
RepoOwnerRepo? parseRepositoryInput(String input) {
  if (input.isEmpty) {
    return null;
  }

  final trimmed = input.trim();

  // Try to parse as URL first
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return _parseFromHttpsUrl(trimmed);
  }

  // Try SSH/git URL format: git@github.com:owner/repo.git
  if (trimmed.startsWith('git@')) {
    return _parseFromSshUrl(trimmed);
  }

  // Try plain owner/repo format
  return _parseFromOwnerRepo(trimmed);
}

RepoOwnerRepo? _parseFromHttpsUrl(String url) {
  try {
    final uri = Uri.parse(url);

    // Must be github.com
    if (uri.host != 'github.com') {
      return null;
    }

    // Path should be /owner/repo or /owner/repo/...
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      return null;
    }

    final owner = pathSegments[0];
    // Remove .git extension if present
    var repo = pathSegments[1];
    if (repo.endsWith('.git')) {
      repo = repo.substring(0, repo.length - 4);
    }

    if (owner.isEmpty || repo.isEmpty) {
      return null;
    }

    return RepoOwnerRepo(owner: owner, repo: repo);
  } catch (e) {
    return null;
  }
}

RepoOwnerRepo? _parseFromSshUrl(String url) {
  // Format: git@github.com:owner/repo.git
  final pattern = RegExp(r'git@github\.com:([^/]+)/([^/]+?)(?:\.git)?$');
  final match = pattern.firstMatch(url);

  if (match != null && match.groupCount >= 2) {
    final owner = match.group(1);
    final repo = match.group(2);

    if (owner != null && owner.isNotEmpty && repo != null && repo.isNotEmpty) {
      return RepoOwnerRepo(owner: owner, repo: repo);
    }
  }

  return null;
}

RepoOwnerRepo? _parseFromOwnerRepo(String input) {
  // Format: owner/repo
  final parts = input.split('/');

  if (parts.length != 2) {
    return null;
  }

  final owner = parts[0].trim();
  final repo = parts[1].trim();

  if (owner.isEmpty || repo.isEmpty) {
    return null;
  }

  return RepoOwnerRepo(owner: owner, repo: repo);
}

/// Simple data class to hold owner and repository
class RepoOwnerRepo {
  final String owner;
  final String repo;

  RepoOwnerRepo({required this.owner, required this.repo});

  @override
  String toString() => '$owner/$repo';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepoOwnerRepo && other.owner == owner && other.repo == repo;
  }

  @override
  int get hashCode => Object.hash(owner, repo);
}
