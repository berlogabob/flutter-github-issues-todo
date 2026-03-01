# Changelog

All notable changes to GitDoIt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0+66] - 2026-03-01

### Fixed
- App version now dynamic using package_info_plus
- Labels and assignees loading at issue creation
- Unified repository selector dropdown
- Labels load timing with WidgetsBinding
- Create issue in expanded repository logic
- Version synchronization across files

### Changed
- Dynamic version reading from package_info_plus instead of hardcoded

## [0.5.0+65] - 2026-02-28

### Fixed
- Labels load timing in create issue screen

## [0.5.0+64] - 2026-02-28

### Changed
- Unified repository selector (removed duplicate fields)

## [0.5.0+63] - 2026-02-28

### Fixed
- Labels and assignees loading with better error handling
- Added debug logging for repo data loading

## [0.5.0+62] - 2026-02-28

### Fixed
- Create issue in expanded repository
- Repository selection priority (expanded → default → first)

## [0.5.0+61] - 2026-02-27

### Fixed
- Version synchronization between pubspec.yaml and settings

## [0.5.0+60] - 2026-02-27

### Fixed
- Closed issues removed from list after swipe to close
- Removed close confirmation dialog for faster workflow

## [0.5.0+59] - 2026-02-27

### Changed
- Swipe to close is now instant (no confirmation dialog)

## [0.5.0+58] - 2026-02-27

### Fixed
- Swipe left to close issue functionality
- Implemented _closeIssue method with API integration

## [0.5.0+57] - 2026-02-27

### Fixed
- App version display in settings screen

## [0.5.0+56] - 2026-02-27

### Fixed
- App repository visibility (removed incorrect filter)

## [0.5.0+55] - 2026-02-27

### Fixed
- Library swipe to pin/unpin now properly links to main screen
- Added didChangeDependencies to reload filters

## [0.5.0+54] - 2026-02-27

### Changed
- Unified sync status widget (BrailleLoader or time in same position)

## [0.5.0+53] - 2026-02-27

### Fixed
- BrailleLoader overlay flash issue
- Optimized animation to prevent full app bar redraw

## [0.5.0+52] - 2026-02-27

### Changed
- BrailleLoader smooth rotation (removed ping-pong animation)

## [0.5.0+51] - 2026-02-27

### Fixed
- Library swipe gestures now properly sync with main screen
- Enhanced SnackBar notifications

## [0.5.0+50] - 2026-02-27

### Fixed
- Swipe right to edit issue now navigates to edit screen

## [0.5.0+49] - 2026-02-27

### Changed
- Removed "Showing: repoName" notification from main screen

## [0.5.0+48] - 2026-02-27

### Fixed
- Cloud icon state updates in real-time
- Added listener pattern to SyncService
- Granular last sync time display (seconds)

## [0.5.0+47] - 2026-02-27

### Fixed
- Static cloud icon with separate BrailleLoader
- Sync status text and time display

## [0.5.0+46] - 2026-02-27

### Fixed
- "Showing repo" notification removed

## [0.5.0+45] - 2026-02-27

### Fixed
- Cloud icon state updates
- Increased update frequency

## [0.5.0+44] - 2026-02-27

### Fixed
- All Sprint 1-4 fixes from emergency_problems.md
