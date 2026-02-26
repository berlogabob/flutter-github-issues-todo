import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/logging.dart';
import '../design_tokens/tokens.dart';
import '../theme/industrial_theme.dart';
import '../theme/widgets/widgets.dart';

/// Debug Screen - View and export logs for troubleshooting
///
/// Features:
/// - Real-time log viewer with filtering
/// - Journey event timeline
/// - Error summary with details
/// - Performance metrics overview
/// - Export logs to clipboard or share
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> with WidgetsBindingObserver {
  String _filter = 'all'; // all, errors, journey, metrics
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final industrialTheme = context.industrialTheme;

    return Scaffold(
      backgroundColor: industrialTheme.surfacePrimary,
      appBar: AppBar(
        backgroundColor: industrialTheme.surfacePrimary,
        elevation: 0,
        title: Text(
          'DEBUG CONSOLE',
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Export button
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: industrialTheme.textPrimary,
            ),
            onPressed: _exportLogs,
            tooltip: 'Export logs',
          ),
          // Clear button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: industrialTheme.textPrimary,
            ),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          _buildStatusBar(industrialTheme),
          const SizedBox(height: AppSpacing.sm),

          // Filter chips
          _buildFilterBar(industrialTheme),
          const SizedBox(height: AppSpacing.md),

          // Content
          Expanded(child: _buildContent(industrialTheme)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(IndustrialThemeData industrialTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: industrialTheme.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: industrialTheme.borderPrimary, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statusIndicator(
              label: 'LOGS',
              value: Logger.history.length.toString(),
              color: industrialTheme.accentPrimary,
            ),
            const SizedBox(width: AppSpacing.lg),
            _statusIndicator(
              label: 'ERRORS',
              value: Logger.errorHistory.length.toString(),
              color: industrialTheme.statusError,
            ),
            const SizedBox(width: AppSpacing.lg),
            _statusIndicator(
              label: 'JOURNEY',
              value: Logger.journeyHistory.length.toString(),
              color: industrialTheme.statusSuccess,
            ),
            const SizedBox(width: AppSpacing.lg),
            _statusIndicator(
              label: 'METRICS',
              value: Logger.metricsSummary.length.toString(),
              color: industrialTheme.statusWarning,
            ),
            const SizedBox(width: AppSpacing.lg),
            // Auto-scroll toggle
            GestureDetector(
              onTap: () => setState(() => _autoScroll = !_autoScroll),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: _autoScroll
                      ? industrialTheme.accentSubtle
                      : industrialTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: _autoScroll
                        ? industrialTheme.accentPrimary
                        : industrialTheme.borderPrimary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 12,
                      color: _autoScroll
                          ? industrialTheme.accentPrimary
                          : industrialTheme.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'AUTO',
                      style: AppTypography.monoAnnotation.copyWith(
                        fontSize: 9,
                        color: _autoScroll
                            ? industrialTheme.accentPrimary
                            : industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator({
    required String label,
    required String value,
    required Color color,
  }) {
    final industrialTheme = context.industrialTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.monoAnnotation.copyWith(
            fontSize: 9,
            color: industrialTheme.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(IndustrialThemeData industrialTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('ALL', 'all', industrialTheme),
          const SizedBox(width: AppSpacing.xs),
          _filterChip('ERRORS', 'errors', industrialTheme),
          const SizedBox(width: AppSpacing.xs),
          _filterChip('JOURNEY', 'journey', industrialTheme),
          const SizedBox(width: AppSpacing.xs),
          _filterChip('METRICS', 'metrics', industrialTheme),
          const SizedBox(width: AppSpacing.xs),
          _filterChip('LOGS', 'logs', industrialTheme),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    IndustrialThemeData industrialTheme,
  ) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? industrialTheme.accentSubtle
              : industrialTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected
                ? industrialTheme.accentPrimary
                : industrialTheme.borderPrimary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoData.copyWith(
            fontSize: 11,
            color: isSelected
                ? industrialTheme.accentPrimary
                : industrialTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(IndustrialThemeData industrialTheme) {
    switch (_filter) {
      case 'errors':
        return _buildErrorsTab(industrialTheme);
      case 'journey':
        return _buildJourneyTab(industrialTheme);
      case 'metrics':
        return _buildMetricsTab(industrialTheme);
      case 'logs':
        return _buildLogsTab(industrialTheme);
      default:
        return _buildAllTab(industrialTheme);
    }
  }

  Widget _buildAllTab(IndustrialThemeData industrialTheme) {
    final errors = Logger.errorHistory;
    final journey = Logger.journeyHistory;
    final metrics = Logger.metricsSummary;

    if (errors.isEmpty && journey.isEmpty && metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: industrialTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO DEBUG DATA',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Interact with the app to generate logs',
              style: AppTypography.captionSmall.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (errors.isNotEmpty) ...[
          _sectionHeader('RECENT ERRORS', industrialTheme),
          const SizedBox(height: AppSpacing.sm),
          ...errors.take(5).map((e) => _errorCard(e, industrialTheme)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (journey.isNotEmpty) ...[
          _sectionHeader('JOURNEY EVENTS', industrialTheme),
          const SizedBox(height: AppSpacing.sm),
          ...journey.take(10).map((e) => _journeyCard(e, industrialTheme)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (metrics.isNotEmpty) ...[
          _sectionHeader('PERFORMANCE METRICS', industrialTheme),
          const SizedBox(height: AppSpacing.sm),
          ...metrics.map((m) => _metricCard(m, industrialTheme)),
        ],
      ],
    );
  }

  Widget _buildErrorsTab(IndustrialThemeData industrialTheme) {
    final errors = Logger.errorHistory;

    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: industrialTheme.statusSuccess,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO ERRORS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: errors.length,
      itemBuilder: (context, index) {
        final error = errors[index];
        return Column(
          children: [
            _errorCard(error, industrialTheme),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildJourneyTab(IndustrialThemeData industrialTheme) {
    final journey = Logger.journeyHistory;

    if (journey.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: industrialTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO JOURNEY EVENTS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: journey.length,
      itemBuilder: (context, index) {
        final event = journey[journey.length - 1 - index]; // Reverse order
        return Column(
          children: [
            _journeyCard(event, industrialTheme),
            const SizedBox(height: AppSpacing.xs),
          ],
        );
      },
    );
  }

  Widget _buildMetricsTab(IndustrialThemeData industrialTheme) {
    final metrics = Logger.metricsSummary;

    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed_outlined,
              size: 64,
              color: industrialTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO METRICS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Column(
          children: [
            _metricCard(metric, industrialTheme),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }

  Widget _buildLogsTab(IndustrialThemeData industrialTheme) {
    final logs = Logger.history;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_outlined,
              size: 64,
              color: industrialTheme.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO LOGS',
              style: AppTypography.monoAnnotation.copyWith(
                color: industrialTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      reverse: true, // Show newest first
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[logs.length - 1 - index];
        return _logEntry(log, industrialTheme);
      },
    );
  }

  Widget _sectionHeader(String title, IndustrialThemeData industrialTheme) {
    return Row(
      children: [
        Container(width: 3, height: 12, color: industrialTheme.accentPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.monoAnnotation.copyWith(
            color: industrialTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _errorCard(ErrorContext error, IndustrialThemeData industrialTheme) {
    return IndustrialCard(
      type: IndustrialCardType.data,
      backgroundColor: industrialTheme.statusError.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: industrialTheme.statusError,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  error.message,
                  style: AppTypography.labelMedium.copyWith(
                    color: industrialTheme.statusError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                DateFormat('HH:mm:ss').format(error.timestamp),
                style: AppTypography.monoTimestamp.copyWith(
                  color: industrialTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: industrialTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: industrialTheme.borderPrimary,
                    width: 1,
                  ),
                ),
                child: Text(
                  error.context,
                  style: AppTypography.monoAnnotation.copyWith(
                    fontSize: 9,
                    color: industrialTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (error.repository != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: industrialTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: industrialTheme.borderPrimary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    error.repository!,
                    style: AppTypography.monoAnnotation.copyWith(
                      fontSize: 9,
                      color: industrialTheme.textSecondary,
                    ),
                  ),
                ),
              if (error.isOffline) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: industrialTheme.statusWarning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: industrialTheme.statusWarning,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: AppTypography.monoAnnotation.copyWith(
                      fontSize: 9,
                      color: industrialTheme.statusWarning,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (error.error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Type: ${error.error?.runtimeType}',
              style: AppTypography.monoCode.copyWith(
                fontSize: 10,
                color: industrialTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _journeyCard(JourneyEvent event, IndustrialThemeData industrialTheme) {
    final icon = _getJourneyIcon(event.type);
    final color = _getJourneyColor(event.type, industrialTheme);

    return IndustrialCard(
      type: IndustrialCardType.data,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: color, width: 1),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: AppTypography.labelSmall.copyWith(
                    color: industrialTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      event.screen,
                      style: AppTypography.monoAnnotation.copyWith(
                        fontSize: 9,
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '•',
                      style: AppTypography.monoAnnotation.copyWith(
                        fontSize: 9,
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      DateFormat('HH:mm:ss').format(event.timestamp),
                      style: AppTypography.monoTimestamp.copyWith(
                        fontSize: 9,
                        color: industrialTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getJourneyIcon(JourneyEventType type) {
    switch (type) {
      case JourneyEventType.screenView:
        return Icons.visibility_outlined;
      case JourneyEventType.userAction:
        return Icons.touch_app_outlined;
      case JourneyEventType.configChange:
        return Icons.tune_outlined;
      case JourneyEventType.authEvent:
        return Icons.lock_outlined;
      case JourneyEventType.syncEvent:
        return Icons.sync_outlined;
      case JourneyEventType.systemAction:
        return Icons.auto_awesome_outlined;
    }
  }

  Color _getJourneyColor(JourneyEventType type, IndustrialThemeData theme) {
    switch (type) {
      case JourneyEventType.screenView:
        return theme.accentPrimary;
      case JourneyEventType.userAction:
        return theme.statusSuccess;
      case JourneyEventType.configChange:
        return theme.statusWarning;
      case JourneyEventType.authEvent:
        return theme.statusError;
      case JourneyEventType.syncEvent:
        return theme.accentPrimary.withValues(alpha: 0.7);
      case JourneyEventType.systemAction:
        return theme.textTertiary;
    }
  }

  Widget _metricCard(
    OperationMetricSummary metric,
    IndustrialThemeData industrialTheme,
  ) {
    final statusColor = metric.successRatePercent >= 95
        ? industrialTheme.statusSuccess
        : metric.successRatePercent >= 80
        ? industrialTheme.statusWarning
        : industrialTheme.statusError;

    return IndustrialCard(
      type: IndustrialCardType.data,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_outlined, size: 16, color: statusColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  metric.operation,
                  style: AppTypography.labelMedium.copyWith(
                    color: industrialTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(metric.statusEmoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _metricStat(
                'Calls',
                metric.totalCalls.toString(),
                industrialTheme,
              ),
              const SizedBox(width: AppSpacing.md),
              _metricStat(
                'Avg',
                '${metric.averageLatencyMs}ms',
                industrialTheme,
              ),
              const SizedBox(width: AppSpacing.md),
              _metricStat(
                'Success',
                '${metric.successRatePercent}%',
                industrialTheme,
                valueColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricStat(
    String label,
    String value,
    IndustrialThemeData industrialTheme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.monoAnnotation.copyWith(
            fontSize: 9,
            color: industrialTheme.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          value,
          style: AppTypography.monoData.copyWith(
            fontSize: 11,
            color: valueColor ?? industrialTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _logEntry(LogEntry log, IndustrialThemeData industrialTheme) {
    final color = _getLogLevelColor(log.level, industrialTheme);
    final icon = _getLogLevelIcon(log.level);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.toString(),
                  style: AppTypography.monoCode.copyWith(
                    fontSize: 10,
                    color: industrialTheme.textPrimary,
                  ),
                ),
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.metadata.toString(),
                    style: AppTypography.monoAnnotation.copyWith(
                      fontSize: 8,
                      color: industrialTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level, IndustrialThemeData theme) {
    switch (level) {
      case LogLevel.debug:
        return theme.textTertiary;
      case LogLevel.info:
        return theme.accentPrimary;
      case LogLevel.warning:
        return theme.statusWarning;
      case LogLevel.error:
        return theme.statusError;
    }
  }

  IconData _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_outlined;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  Future<void> _exportLogs() async {
    final logs = Logger.exportLogs();

    await SharePlus.instance.share(
      ShareParams(
        text: logs,
        subject: 'GitDoIt Debug Logs - ${DateTime.now().toIso8601String()}',
      ),
    );

    Logger.trackJourney(JourneyEventType.userAction, 'Debug', 'logs_exported');
  }

  Future<void> _clearLogs() async {
    setState(() {
      Logger.clear();
      Logger.clearErrors();
      Logger.clearJourney();
    });

    Logger.i('Logs cleared by user', context: 'Debug');
    Logger.trackJourney(JourneyEventType.userAction, 'Debug', 'logs_cleared');
  }
}
