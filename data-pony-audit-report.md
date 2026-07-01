# Ponytail Audit Report

Graph snapshot: 2,436 nodes, 3,169 edges.

1. `delete:` Five custom empty-state painters. Replace with Material icons. [`lib/widgets/empty_state_illustrations.dart`](lib/widgets/empty_state_illustrations.dart)
2. `native:` Shimmer skeleton system. Replace with the existing loader; remove `shimmer`. [`lib/widgets/loading_skeleton.dart`](lib/widgets/loading_skeleton.dart)
3. `native:` App-wide scaling dependency. Use `MediaQuery` and `LayoutBuilder`; remove `flutter_screenutil`. [`lib/main.dart`](lib/main.dart)
4. `native:` Custom braille animation. Replace with `CircularProgressIndicator`. [`lib/widgets/braille_loader.dart`](lib/widgets/braille_loader.dart)
5. `shrink:` Network service maintains an unused stream and online state. Keep only `checkConnectivity()`. [`lib/services/network_service.dart`](lib/services/network_service.dart)
6. `delete:` Test-only `RepoHeaderSkeleton`. Replacement: nothing. [`lib/widgets/loading_skeleton.dart`](lib/widgets/loading_skeleton.dart)
7. `delete:` Unused cache timestamp and `isStale`. Replacement: nothing. [`lib/models/cached_dashboard_data.dart`](lib/models/cached_dashboard_data.dart)
8. `delete:` Production-unused `ItemStatusExtension`. Use enum comparisons. [`lib/models/item.dart`](lib/models/item.dart)

**Net:** approximately 900 fewer lines and 2 fewer dependencies possible.

## Scope

This audit covers over-engineering and complexity only. Correctness, security, and performance require separate review passes.
