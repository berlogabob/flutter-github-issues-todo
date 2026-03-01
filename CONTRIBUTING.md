# Contributing to GitDoIt

Thank you for your interest in contributing to GitDoIt! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/flutter-github-issues-todo.git`
3. Install dependencies: `flutter pub get`
4. Create a branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites
- Flutter SDK 3.11.0 or higher
- Dart 3.11.0 or higher
- GitHub Personal Access Token or OAuth App

### Environment Setup
1. Copy `.env.example` to `.env`
2. Add your GitHub OAuth Client ID to `.env`
3. Run with: `make run-with-env`

## Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format lib/` before committing
- Run `flutter analyze` to catch issues
- Add dartdoc comments to public APIs

## Testing

- Write tests for new features
- Run tests: `flutter test`
- Maintain or improve code coverage

## Pull Request Process

1. Update README.md if needed
2. Update CHANGELOG.md with your changes
3. Ensure all tests pass
4. Request review from maintainers
5. Squash commits before merging

## Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
style: Format code
refactor: Refactor code
test: Add tests
chore: Update dependencies
```

## Architecture

GitDoIt uses:
- **Riverpod** for state management
- **Hive** for local storage
- **GitHub REST API** for data
- **Offline-first** architecture

See [PROJECT_MASTER.md](PROJECT_MASTER.md) for detailed architecture.

## Questions?

Open an issue for questions or discussions.
