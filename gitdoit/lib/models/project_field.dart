import 'package:flutter/material.dart';

import '../../design_tokens/tokens.dart';
import '../../theme/industrial_theme.dart';

/// Project Custom Field Types
enum ProjectFieldType {
  text,
  number,
  singleSelect,
  iteration,
  date,
}

/// Project Custom Field Model
class ProjectField {
  final String id;
  final String name;
  final ProjectFieldType dataType;
  final List<FieldOption>? options; // For single select

  const ProjectField({
    required this.id,
    required this.name,
    required this.dataType,
    this.options,
  });

  /// Create from GraphQL response
  factory ProjectField.fromGraphQL(Map<String, dynamic> data) {
    final dataTypeStr = data['dataType'] as String;
    
    ProjectFieldType dataType;
    switch (dataTypeStr) {
      case 'TEXT':
        dataType = ProjectFieldType.text;
        break;
      case 'NUMBER':
        dataType = ProjectFieldType.number;
        break;
      case 'SINGLE_SELECT':
        dataType = ProjectFieldType.singleSelect;
        break;
      case 'ITERATION':
        dataType = ProjectFieldType.iteration;
        break;
      case 'DATE':
        dataType = ProjectFieldType.date;
        break;
      default:
        dataType = ProjectFieldType.text;
    }

    List<FieldOption>? options;
    if (data['options'] != null) {
      options = (data['options'] as List<dynamic>)
          .map((opt) => FieldOption.fromGraphQL(opt as Map<String, dynamic>))
          .toList();
    }

    return ProjectField(
      id: data['id'] as String,
      name: data['name'] as String,
      dataType: dataType,
      options: options,
    );
  }

  /// Check if this is the Status field
  bool get isStatus => name.toLowerCase() == 'status';

  /// Check if this is the Priority field
  bool get isPriority => 
      name.toLowerCase() == 'priority' || 
      name.toLowerCase() == 'severity';

  /// Check if this is the Estimate field
  bool get isEstimate => 
      name.toLowerCase() == 'estimate' || 
      name.toLowerCase() == 'story points';
}

/// Field Option for Single Select fields
class FieldOption {
  final String id;
  final String name;
  final String? color;

  const FieldOption({
    required this.id,
    required this.name,
    this.color,
  });

  /// Create from GraphQL response
  factory FieldOption.fromGraphQL(Map<String, dynamic> data) {
    return FieldOption(
      id: data['id'] as String,
      name: data['name'] as String,
      color: data['color'] as String?,
    );
  }

  /// Get color as Color object
  Color get colorValue {
    if (color == null) return Colors.grey;
    try {
      return Color(int.parse(color!.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Field Value - represents actual field data for an item
class FieldValue {
  final String fieldId;
  final String fieldName;
  final ProjectFieldType dataType;
  final dynamic value;

  const FieldValue({
    required this.fieldId,
    required this.fieldName,
    required this.dataType,
    this.value,
  });

  /// Create from GraphQL response
  factory FieldValue.fromGraphQL(Map<String, dynamic> data) {
    final field = data['field'] as Map<String, dynamic>;
    final fieldId = field['id'] as String;
    final fieldName = field['name'] as String;
    
    final dataTypeStr = data['dataType'] as String? ?? 'TEXT';
    ProjectFieldType dataType;
    switch (dataTypeStr) {
      case 'NUMBER':
        dataType = ProjectFieldType.number;
        break;
      case 'SINGLE_SELECT':
        dataType = ProjectFieldType.singleSelect;
        break;
      case 'ITERATION':
        dataType = ProjectFieldType.iteration;
        break;
      case 'DATE':
        dataType = ProjectFieldType.date;
        break;
      default:
        dataType = ProjectFieldType.text;
    }

    dynamic value;
    switch (dataType) {
      case ProjectFieldType.number:
        value = data['number'] as num?;
        break;
      case ProjectFieldType.singleSelect:
        value = {
          'name': data['name'] as String?,
          'color': data['color'] as String?,
        };
        break;
      case ProjectFieldType.iteration:
        value = {
          'title': data['title'] as String?,
          'startDate': data['startDate'] as String?,
          'duration': data['duration'] as int?,
        };
        break;
      case ProjectFieldType.date:
        value = data['date'] as String?;
        break;
      case ProjectFieldType.text:
        value = data['text'] as String?;
        break;
    }

    return FieldValue(
      fieldId: fieldId,
      fieldName: fieldName,
      dataType: dataType,
      value: value,
    );
  }

  /// Get display value as string
  String get displayValue {
    if (value == null) return '';
    
    switch (dataType) {
      case ProjectFieldType.number:
        return value.toString();
      case ProjectFieldType.singleSelect:
        return (value as Map<String, dynamic>?)?['name'] ?? '';
      case ProjectFieldType.iteration:
        return (value as Map<String, dynamic>?)?['title'] ?? '';
      case ProjectFieldType.date:
        final dateStr = value as String?;
        if (dateStr == null) return '';
        try {
          final date = DateTime.parse(dateStr);
          return '${date.day}/${date.month}/${date.year}';
        } catch (e) {
          return dateStr;
        }
      case ProjectFieldType.text:
        return value as String? ?? '';
    }
  }

  /// Get color for single select
  Color? get color {
    if (dataType != ProjectFieldType.singleSelect) return null;
    final colorHex = (value as Map<String, dynamic>?)?['color'] as String?;
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return null;
    }
  }
}
