# LOGGER AGENT - REDESIGN SPRINT TASK

## Mission
Implement structured logging, error tracking, and performance monitoring for the redesigned app.

## Context
The app has been redesigned with new components and screens. Your role is to:
- Add logging to all new components
- Implement error tracking
- Monitor performance (FPS, build times)
- Create debug tools if needed
- Ensure privacy compliance

## Your Tasks

### Phase 1: Logging Infrastructure (30 min)
Review and enhance logging setup:

1. **Logger Utility Review**
   - Check existing `utils/logger.dart`
   - Ensure it supports all log levels (debug, info, warning, error)
   - Verify context tracking
   - Check timestamp formatting

2. **Log Categories**
   Define logging categories for:
   - Navigation (screen transitions, route changes)
   - User Actions (button taps, form submissions)
   - Data (API calls, cache operations)
   - UI (widget builds, animations)
   - Errors (exceptions, failures)

3. **Log Levels Strategy**
   ```
   DEBUG: Development details (build times, state changes)
   INFO: User-facing actions (screen loads, saves)
   WARNING: Recoverable issues (slow operations, retries)
   ERROR: Failures (API errors, exceptions)
   ```

### Phase 2: Component Logging (60 min)
Add logging to redesigned components:

1. **Design Tokens**
   ```dart
   Logger.d('Design tokens loaded', context: 'Theme');
   ```

2. **Theme System**
   ```dart
   Logger.i('Theme initialized', context: 'Theme');
   Logger.d('Z-level changed: $oldLevel → $newLevel', context: 'Theme');
   ```

3. **Atomic Widgets**
   ```dart
   // Buttons
   Logger.d('Button pressed: $type', context: 'Interaction');
   Logger.d('Button hover state: $isHovered', context: 'Interaction');
   
   // Cards
   Logger.d('Card tapped: $id', context: 'Interaction');
   Logger.d('Card elevation changed', context: 'UI');
   
   // Inputs
   Logger.d('Input focused: $fieldName', context: 'Interaction');
   Logger.d('Input value changed', context: 'Interaction');
   ```

4. **Screens**
   ```dart
   // Auth Screen
   Logger.i('Auth screen loaded', context: 'Navigation');
   Logger.d('Token submitted', context: 'Auth');
   Logger.i('Auth successful', context: 'Auth');
   Logger.e('Auth failed: $error', context: 'Auth');
   
   // Home Screen
   Logger.i('Home screen loaded', context: 'Navigation');
   Logger.d('Issues fetched: $count', context: 'Data');
   Logger.d('Card tapped: $issueId', context: 'Navigation');
   
   // Detail Screen
   Logger.i('Issue detail loaded: $issueId', context: 'Navigation');
   Logger.d('Edit button tapped', context: 'Navigation');
   
   // Edit Screen
   Logger.i('Edit screen loaded: $issueId', context: 'Navigation');
   Logger.d('Field updated: $field', context: 'Data');
   Logger.i('Issue saved: $issueId', context: 'Data');
   ```

### Phase 3: Error Tracking (45 min)
Implement comprehensive error handling:

1. **Global Error Handler**
   ```dart
   FlutterError.onError = (details) {
     Logger.e('Flutter error: ${details.summary}', 
       context: 'Global',
       error: details.exception,
       stackTrace: details.stack,
     );
   };
   
   PlatformDispatcher.instance.onError = (error, stack) {
     Logger.e('Platform error: $error',
       context: 'Global',
       error: error,
       stackTrace: stack,
     );
     return true;
   };
   ```

2. **Provider Error Handling**
   ```dart
   try {
     await operation();
   } catch (error, stackTrace) {
     Logger.e('Operation failed: $error',
       context: 'Provider',
       error: error,
       stackTrace: stackTrace,
     );
     rethrow;
   }
   ```

3. **Network Error Handling**
   ```dart
   try {
     await apiCall();
   } on DioException catch (e) {
     Logger.e('API error: ${e.message}',
       context: 'Network',
       error: e,
     );
   } on SocketException catch (e) {
     Logger.e('Network unavailable',
       context: 'Network',
       error: e,
     );
   }
   ```

### Phase 4: Performance Monitoring (45 min)
Track performance metrics:

1. **Build Time Tracking**
   ```dart
   final stopwatch = Stopwatch()..start();
   // ... build operations
   stopwatch.stop();
   if (stopwatch.elapsedMilliseconds > 16) {
     Logger.w('Slow build: ${stopwatch.elapsedMilliseconds}ms',
       context: 'Performance',
     );
   }
   ```

2. **FPS Monitoring** (debug mode)
   ```dart
   Logger.d('Current FPS: $fps', context: 'Performance');
   ```

3. **Animation Performance**
   ```dart
   Logger.d('Animation started: $name', context: 'Animation');
   Logger.d('Animation completed: $name', context: 'Animation');
   Logger.w('Animation jank detected', context: 'Animation');
   ```

4. **Memory Tracking** (if available)
   ```dart
   Logger.d('Memory usage: ${memoryInfo}', context: 'Performance');
   ```

### Phase 5: Debug Tools (30 min)
Create debug utilities:

1. **Debug Overlay** (debug mode only)
   ```dart
   if (kDebugMode) {
     // Show FPS counter
     // Show Z-level indicators
     // Show touch feedback
   }
   ```

2. **Performance Overlay**
   ```dart
   MaterialApp(
     showPerformanceOverlay: kDebugMode,
     // ...
   )
   ```

3. **Logging Debug Screen** (optional)
   - View recent logs
   - Filter by category
   - Export logs

## Output Format

Create file: `agents/reports/logger_redesign_report.md`

```markdown
# Logger Integration Report

## 📊 Logging Infrastructure

### Logger Configuration
**Log Levels Enabled:**
- Debug: ✅/❌
- Info: ✅/❌
- Warning: ✅/❌
- Error: ✅/❌

**Log Categories:**
- Navigation: ✅/❌
- Interaction: ✅/❌
- Data: ✅/❌
- UI: ✅/❌
- Error: ✅/❌
- Performance: ✅/❌

### Log Output Example
```
[INFO] [Navigation] Home screen loaded
[DEBUG] [Data] Issues fetched: 25
[DEBUG] [Interaction] Card tapped: issue-123
[WARNING] [Performance] Slow build: 24ms
[ERROR] [Network] API error: 404
```

## 🏷️ Component Logging

### Design Tokens & Theme
| Component | Log Points | Example |
|-----------|-----------|---------|
| Colors | X | "Colors loaded" |
| Typography | X | "Typography applied" |
| Theme | X | "Theme initialized" |

### Atomic Widgets
| Widget | Log Points | Examples |
|--------|-----------|----------|
| Button | X | "Pressed", "Hovered" |
| Card | X | "Tapped", "Elevated" |
| Input | X | "Focused", "Changed" |
| Badge | X | "Rendered" |
| Toggle | X | "Toggled" |
| Slider | X | "Slid" |

### Screens
| Screen | Log Points | Examples |
|--------|-----------|----------|
| Auth | X | "Loaded", "Submitted", "Success", "Failed" |
| Home | X | "Loaded", "Fetched", "Navigated" |
| Detail | X | "Loaded", "Edited" |
| Edit | X | "Loaded", "Saved", "Cancelled" |
| Settings | X | "Loaded", "Changed" |

## 🐛 Error Tracking

### Global Error Handlers
| Handler | Status | Coverage |
|---------|--------|----------|
| FlutterError | ✅/❌ | All Flutter errors |
| PlatformDispatcher | ✅/❌ | All platform errors |
| Provider Errors | ✅/❌ | All provider errors |
| Network Errors | ✅/❌ | All API errors |

### Error Categories
| Category | Count | Example |
|----------|-------|---------|
| Network | X | API timeout |
| Auth | X | Invalid token |
| Data | X | Parse error |
| UI | X | Build failure |

## ⚡ Performance Monitoring

### Metrics Tracked
| Metric | How | Threshold |
|--------|-----|-----------|
| Build Time | Stopwatch | 16ms |
| FPS | [Method] | 60 |
| Animation | Listener | Jank detection |
| Memory | [Method] | 100MB |

### Performance Issues Found
| Issue | Location | Impact | Recommendation |
|-------|----------|--------|----------------|
| [issue] | [file] | High/Med/Low | [fix] |

## 🛠️ Debug Tools

### Debug Overlay
**Status:** ✅ Implemented / ❌ Not Implemented

**Features:**
- [ ] FPS counter
- [ ] Z-level indicators
- [ ] Touch feedback
- [ ] Build time overlay

### Performance Overlay
**Status:** ✅ Enabled (debug) / ❌ Not enabled

### Log Viewer
**Status:** ✅ Implemented / ❌ Not Implemented

**Features:**
- [ ] View recent logs
- [ ] Filter by category
- [ ] Export logs
- [ ] Search logs

## 📈 Logging Statistics

| Metric | Count |
|--------|-------|
| Total Log Points | X |
| Debug Logs | X |
| Info Logs | X |
| Warning Logs | X |
| Error Logs | X |
| Files Modified | X |

## 🔒 Privacy & Security

### Sensitive Data Handling
| Data Type | Masked? | How |
|-----------|---------|-----|
| Auth Token | ✅/❌ | [method] |
| User Data | ✅/❌ | [method] |
| API Keys | ✅/❌ | [method] |

### Compliance
- [ ] No sensitive data in logs
- [ ] Tokens masked
- [ ] Personal data protected
- [ ] Logs disabled in production (if needed)

## 📝 Recommendations

### For Production
- [Log level to use]
- [What to disable]
- [What to monitor]

### For Development
- [Useful debug tools]
- [Recommended log levels]
- [Performance tips]

## ✅ Quality Checks

| Check | Status | Notes |
|-------|--------|-------|
| All components logged | ✅/❌ | [notes] |
| Error handling complete | ✅/❌ | [notes] |
| Performance monitoring | ✅/❌ | [notes] |
| Debug tools functional | ✅/❌ | [notes] |
| Privacy compliant | ✅/❌ | [notes] |
```

## Integration Points

**You receive from:**
- SeniorDeveloper: New components to log
- Architect: Error handling architecture

**You provide to:**
- SeniorDeveloper: Error reports, performance issues
- StupidUser: Debug tools for testing

## Tools & Commands

```bash
# Run with logging
flutter run --verbose

# View logs
flutter logs

# Performance profile
flutter pub run dart_devtools
```

## Success Criteria

- [ ] Logger infrastructure reviewed
- [ ] All components have logging
- [ ] All screens have logging
- [ ] Error handling implemented
- [ ] Performance monitoring active
- [ ] Debug tools available
- [ ] Privacy compliant
- [ ] Report created in `agents/reports/`

## Begin Mission

Wait for Senior Developer to implement components. Add logging as each component is completed. Test error handling by triggering errors.

**MOTTO:** *Log Everything. Learn Everything.*
