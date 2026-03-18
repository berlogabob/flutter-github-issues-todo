# Sprint 2 Completion Guide

**Goal:** Finish Models & Code Generation to make models safe & immutable

**Estimated Time:** 8-12 hours  
**Difficulty:** Medium  
**Impact:** High (developer experience, type safety)

---

## What Needs to Be Done

### Overview

Sprint 2 requires migrating from **manual JSON serialization** to **code-generated, immutable models** using `freezed` and `hive_generator`.

---

## Step-by-Step Implementation

### Phase 1: Add Dependencies (30 min)

#### 1.1 Update `pubspec.yaml`

Add these packages:

```yaml
dependencies:
  # Add these
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  # Add these
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  hive_generator: ^2.0.1
```

#### 1.2 Install Dependencies

```bash
flutter pub get
```

#### 1.3 Update `analysis_options.yaml`

Enable code generation:

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

---

### Phase 2: Migrate Models to Freezed (4-6 hours)

#### 2.1 Migrate `IssueItem` Model

**Current:** `lib/models/issue_item.dart` (manual JSON)

**New:** 

```dart
// lib/models/issue_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'item.dart';

part 'issue_item.freezed.dart';
part 'issue_item.g.dart';

@freezed
class IssueItem with _$IssueItem {
  const factory IssueItem({
    required String id,
    required String title,
    int? number,
    String? bodyMarkdown,
    String? projectColumnName,
    String? projectItemNodeId,
    DateTime? createdAt,
    String? assigneeAvatarUrl,
    required ItemStatus status,
    DateTime? updatedAt,
    String? assigneeLogin,
    @Default([]) List<String> labels,
    @Default([]) List<Item> children,
    @Default(false) bool isExpanded,
    @Default(false) bool isLocalOnly,
    DateTime? localUpdatedAt,
  }) = _IssueItem;

  factory IssueItem.fromJson(Map<String, dynamic> json) =>
      _$IssueItemFromJson(json);
}
```

**Benefits:**
- ✅ Immutable (can't accidentally modify)
- ✅ `copyWith()` auto-generated
- ✅ Type-safe JSON serialization
- ✅ No manual `fromJson`/`toJson` bugs

#### 2.2 Migrate `Item` Base Class

```dart
// lib/models/item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

enum ItemStatus { open, closed }

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String title,
    required ItemStatus status,
    DateTime? updatedAt,
    String? assigneeLogin,
    @Default([]) List<String> labels,
    @Default([]) List<Item> children,
    @Default(false) bool isExpanded,
    @Default(false) bool isLocalOnly,
    DateTime? localUpdatedAt,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}
```

#### 2.3 Migrate `RepoItem` Model

```dart
// lib/models/repo_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'item.dart';

part 'repo_item.freezed.dart';
part 'repo_item.g.dart';

@freezed
class RepoItem with _$RepoItem {
  const factory RepoItem({
    required String id,
    required String name,
    required String fullName,
    String? description,
    bool? private,
    String? htmlUrl,
    DateTime? updatedAt,
    @Default([]) List<Item> children,
    @Default(false) bool isExpanded,
  }) = _RepoItem;

  factory RepoItem.fromJson(Map<String, dynamic> json) =>
      _$RepoItemFromJson(json);
}
```

#### 2.4 Migrate `ProjectItem` Model

```dart
// lib/models/project_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_item.freezed.dart';
part 'project_item.g.dart';

@freezed
class ProjectItem with _$ProjectItem {
  const factory ProjectItem({
    required String id,
    required String title,
    String? description,
    String? url,
    @Default([]) List<String> columnNames,
  }) = _ProjectItem;

  factory ProjectItem.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemFromJson(json);
}
```

#### 2.5 Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `issue_item.freezed.dart` - Immutable copy, copyWith()
- `issue_item.g.dart` - JSON serialization
- Same for all other models

---

### Phase 3: Add Hive Generator (2-3 hours)

#### 3.1 Add Hive Annotations

Update models with `@HiveType`:

```dart
// lib/models/issue_item.dart
import 'package:hive_ce/hive_ce.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_item.freezed.dart';
part 'issue_item.g.dart';
part 'issue_item.hive.g.dart'; // NEW

@HiveType(typeId: 0) // Unique ID for each model
@freezed
class IssueItem with _$IssueItem implements HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final int? number;
  
  @HiveField(3)
  final String? bodyMarkdown;
  
  // ... all other fields with @HiveField(n)
  
  const factory IssueItem({
    // ... fields
  }) = _IssueItem;

  factory IssueItem.fromJson(Map<String, dynamic> json) =>
      _$IssueItemFromJson(json);
}
```

#### 3.2 Register Adapters in `main.dart`

```dart
// lib/main.dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'models/issue_item.dart';
import 'models/item.dart';
import 'models/repo_item.dart';
import 'models/project_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(IssueItemAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(RepoItemAdapter());
  Hive.registerAdapter(ProjectItemAdapter());
  Hive.registerAdapter(ItemStatusAdapter()); // Enum adapter

  // ... rest of initialization
}
```

#### 3.3 Create Enum Adapter

```dart
// lib/models/item_status_adapter.dart
import 'package:hive_ce/hive_ce.dart';
import 'item.dart';

class ItemStatusAdapter extends TypeAdapter<ItemStatus> {
  @override
  final int typeId = 100; // Unique ID

  @override
  ItemStatus read(BinaryReader reader) {
    return ItemStatus.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, ItemStatus obj) {
    writer.writeInt(obj.index);
  }
}
```

#### 3.4 Run Code Generation Again

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `issue_item.hive.g.dart` - Hive adapter
- Same for all models

---

### Phase 4: Update Usage Sites (2-3 hours)

#### 4.1 Update `copyWith` Usage

**Before:**
```dart
final updated = issue.copyWith(
  title: 'New Title',
  status: ItemStatus.closed,
);
```

**After:** (same syntax, but type-safe!)
```dart
final updated = issue.copyWith(
  title: 'New Title',
  status: ItemStatus.closed,
);
// ✅ Compiler catches errors now
```

#### 4.2 Update JSON Parsing

**Before:**
```dart
final issue = IssueItem.fromJson(json);
```

**After:** (same syntax, but safer)
```dart
final issue = IssueItem.fromJson(json);
// ✅ Throws JsonSerializableError if invalid
```

#### 4.3 Update Hive Boxes

**Before:**
```dart
final box = await Hive.openBox('issues');
await box.put('issue_1', issue.toJson()); // Store as JSON string
```

**After:**
```dart
final box = await Hive.openBox('issues');
await box.put('issue_1', issue); // Store as object
// ✅ Type-safe, no manual serialization
```

#### 4.4 Fix All Compilation Errors

After migration, you'll have compilation errors in:
- `lib/services/github_api_service.dart`
- `lib/services/local_storage_service.dart`
- `lib/services/sync_service.dart`
- `lib/screens/*.dart` (all screens using models)

**Fix them by:**
1. Updating `.toJson()` calls (now auto-generated)
2. Updating `.fromJson()` calls (now auto-generated)
3. Updating Hive read/write (now stores objects directly)

---

### Phase 5: Testing & Verification (1-2 hours)

#### 5.1 Run Tests

```bash
flutter test
```

Fix any failing tests (likely JSON parsing tests).

#### 5.2 Test Offline Mode

1. Create issue offline
2. Verify saved to Hive
3. Reconnect
4. Verify syncs to GitHub

#### 5.3 Test App

- [ ] Login works
- [ ] Dashboard loads
- [ ] Create issue works
- [ ] Edit issue works
- [ ] Close issue works
- [ ] Offline mode works
- [ ] Sync works

---

## Acceptance Criteria Checklist

### ✅ Must Have for Sprint 2 Complete

- [ ] All models use `@freezed`
- [ ] All models have `@HiveType` and `@HiveField`
- [ ] No manual `fromJson`/`toJson` implementations
- [ ] All `copyWith` calls use generated method
- [ ] Hive boxes store objects (not JSON strings)
- [ ] No `UnimplementedError` in fromJson
- [ ] All tests pass
- [ ] App compiles without errors
- [ ] Offline mode still works
- [ ] Sync still works

---

## Files to Create/Modify

### Create (New Files)

```
lib/models/
├── item.freezed.dart          # Generated
├── item.g.dart                # Generated
├── item.hive.g.dart           # Generated
├── issue_item.freezed.dart    # Generated
├── issue_item.g.dart          # Generated
├── issue_item.hive.g.dart     # Generated
├── repo_item.freezed.dart     # Generated
├── repo_item.g.dart           # Generated
├── repo_item.hive.g.dart      # Generated
├── project_item.freezed.dart  # Generated
├── project_item.g.dart        # Generated
├── project_item.hive.g.dart   # Generated
└── item_status_adapter.dart   # Manual (enum adapter)
```

### Modify (Existing Files)

```
lib/models/
├── item.dart                  # Add @freezed, @HiveType
├── issue_item.dart            # Add @freezed, @HiveType
├── repo_item.dart             # Add @freezed, @HiveType
└── project_item.dart          # Add @freezed, @HiveType

lib/main.dart                  # Register Hive adapters

lib/services/
├── github_api_service.dart    # Update JSON usage
├── local_storage_service.dart # Update Hive usage
└── sync_service.dart          # Update model usage

lib/screens/
├── *.dart                     # Update copyWith usage
```

---

## Common Issues & Solutions

### Issue 1: "Type has already been used"

**Error:** `The typeId 0 has already been used`

**Solution:** Each `@HiveType` needs a unique `typeId`:

```dart
@HiveType(typeId: 0) class IssueItem {}
@HiveType(typeId: 1) class RepoItem {}
@HiveType(typeId: 2) class ProjectItem {}
@HiveType(typeId: 3) class Item {}
```

### Issue 2: "Could not generate `fromJson`"

**Error:** Missing `@JsonSerializable` or wrong imports

**Solution:** Ensure imports:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'your_model.freezed.dart';
part 'your_model.g.dart';
```

### Issue 3: Hive adapter not found

**Error:** `Error: Couldn't resolve constructor`

**Solution:** Register adapter in `main.dart`:

```dart
Hive.registerAdapter(IssueItemAdapter());
```

### Issue 4: Build runner conflicts

**Error:** `Bad state: Conflicting outputs`

**Solution:**

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Migration Order (Recommended)

### Week 1: Core Models (4-6 hours)

**Day 1:**
- Add dependencies
- Migrate `Item` base class
- Test compilation

**Day 2:**
- Migrate `IssueItem`
- Update usage in services
- Test

**Day 3:**
- Migrate `RepoItem` and `ProjectItem`
- Update all screens
- Test

### Week 2: Hive Integration (4-6 hours)

**Day 1:**
- Add `@HiveType` to all models
- Create enum adapters
- Register in main.dart

**Day 2:**
- Update Hive storage code
- Run code generation
- Fix compilation errors

**Day 3:**
- Test offline mode
- Test sync
- Run all tests
- Fix any issues

---

## Benefits After Completion

### Developer Experience

- ✅ **Type Safety:** Compiler catches JSON errors
- ✅ **Immutability:** Can't accidentally modify models
- ✅ **copyWith:** Auto-generated, type-safe
- ✅ **Less Boilerplate:** No manual fromJson/toJson

### Code Quality

- ✅ **Fewer Bugs:** No manual JSON typos
- ✅ **Better Testing:** Models are predictable
- ✅ **Easier Refactoring:** Change model, see all usages
- ✅ **Clearer Intent:** Immutable = thread-safe

### Performance

- ✅ **Faster Serialization:** Generated code is optimized
- ✅ **Less Memory:** No intermediate JSON strings
- ✅ **Type Adapters:** Hive reads directly to objects

---

## Should You Do It Before v1.0.0?

### Pros ✅

- Catches bugs at compile-time
- Better developer experience
- More maintainable long-term
- Professional code quality

### Cons ❌

- 8-12 hours of work
- Risk of breaking existing features
- Can be done incrementally
- Not user-visible improvement

### Recommendation 🎯

**Defer to v1.1.0**

**Why:**
1. App works fine with manual JSON
2. Not user-visible improvement
3. Risk of breaking stable code before release
4. Can be done incrementally post-release

**Ship v1.0.0 now, add freezed in v1.1.0**

---

## Quick Start (If You Decide to Do It)

```bash
# 1. Add dependencies
flutter pub add freezed_annotation json_annotation
flutter pub add --dev freezed json_serializable hive_generator build_runner

# 2. Start with one model (IssueItem)
# Edit lib/models/issue_item.dart (see example above)

# 3. Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Test
flutter test

# 5. Repeat for other models
```

---

## Summary

**To finish Sprint 2:**

1. ✅ Add freezed + json_serializable + hive_generator
2. ✅ Migrate all models to @freezed
3. ✅ Add @HiveType to all models
4. ✅ Register Hive adapters
5. ✅ Update all usage sites
6. ✅ Test everything

**Time:** 8-12 hours  
**Risk:** Medium (breaking changes possible)  
**Recommendation:** Do it post-v1.0.0 in v1.1.0

---

Built with ❤️ using the GitDoIt Agent System
