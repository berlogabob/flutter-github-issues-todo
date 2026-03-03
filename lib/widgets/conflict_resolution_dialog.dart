import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../services/conflict_detection_service.dart';
import '../models/issue_item.dart';

/// Dialog for resolving conflicts between local and remote issues
class ConflictResolutionDialog extends StatefulWidget {
  final IssueConflict conflict;
  final Function(ResolutionChoice choice) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ResolutionChoice? _selectedChoice;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600.w,
          maxHeight: 700.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            SizedBox(height: 16.h),

            // Conflict content
            Expanded(
              child: _buildConflictContent(),
            ),

            // Resolution choices
            _buildResolutionChoices(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.orangePrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.orangePrimary,
            size: 24.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Conflict Detected',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Issue #${widget.conflict.issueNumber}: ${widget.conflict.localIssue.title}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conflicting fields summary
          _buildConflictingFieldsSummary(),
          SizedBox(height: 24.h),

          // Side-by-side comparison
          _buildSideBySideComparison(),
        ],
      ),
    );
  }

  Widget _buildConflictingFieldsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflicting Fields:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.conflict.conflictingFields.map((field) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _getFieldName(field),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getFieldName(ConflictField field) {
    switch (field) {
      case ConflictField.title:
        return 'Title';
      case ConflictField.body:
        return 'Body';
      case ConflictField.labels:
        return 'Labels';
      case ConflictField.assignee:
        return 'Assignee';
      case ConflictField.status:
        return 'Status';
    }
  }

  Widget _buildSideBySideComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildComparisonHeader('Local (Your Changes)', Colors.blue),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildComparisonHeader('Remote (GitHub)', Colors.green),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildComparisonContent(
                widget.conflict.localIssue,
                Colors.blue,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildComparisonContent(
                widget.conflict.remoteIssue,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonHeader(String title, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildComparisonContent(IssueItem issue, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldRow(
            'Title:',
            issue.title,
            widget.conflict.conflictingFields.contains(ConflictField.title),
          ),
          SizedBox(height: 8.h),
          _buildFieldRow(
            'Status:',
            issue.status.name.toUpperCase(),
            widget.conflict.conflictingFields.contains(ConflictField.status),
          ),
          SizedBox(height: 8.h),
          _buildFieldRow(
            'Labels:',
            issue.labels.isNotEmpty ? issue.labels.join(', ') : 'None',
            widget.conflict.conflictingFields.contains(ConflictField.labels),
          ),
          SizedBox(height: 8.h),
          _buildFieldRow(
            'Assignee:',
            issue.assigneeLogin ?? 'Unassigned',
            widget.conflict.conflictingFields.contains(ConflictField.assignee),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, bool isConflict) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: isConflict ? AppColors.orangePrimary : Colors.white,
              fontWeight: isConflict ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionChoices() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          Text(
            'Choose how to resolve this conflict:',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildChoiceButton(
                  'Use Local',
                  Icons.cloud_upload,
                  AppColors.orangePrimary,
                  'Keep your changes',
                  ResolutionChoice.useLocal,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildChoiceButton(
                  'Use Remote',
                  Icons.cloud_download,
                  Colors.green,
                  'Keep GitHub version',
                  ResolutionChoice.useRemote,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildChoiceButton(
            'Merge',
            Icons.merge_type,
            Colors.blue,
            'Combine both versions (title: local, body: local + remote note)',
            ResolutionChoice.merge,
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(
    String title,
    IconData icon,
    Color color,
    String description,
    ResolutionChoice choice,
  ) {
    final isSelected = _selectedChoice == choice;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedChoice = choice);
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.w),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.white,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
