import 'package:hive/hive.dart';
import 'item.dart';

part 'project_item.g.dart';

/// Project item representing a GitHub Project v2
@HiveType(typeId: 3)
class ProjectItem extends Item {
  @HiveField(30)
  String? projectNodeId;

  ProjectItem({
    required String id,
    required String title,
    this.projectNodeId,
    ItemStatus? status,
    DateTime? updatedAt,
    String? assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    DateTime? localUpdatedAt,
  }) : super(
         id: id,
         title: title,
         status: status ?? ItemStatus.open,
         updatedAt: updatedAt,
         assigneeLogin: assigneeLogin,
         labels: labels ?? const [],
         children: children ?? const [],
         isExpanded: isExpanded ?? false,
         isLocalOnly: isLocalOnly ?? false,
         localUpdatedAt: localUpdatedAt,
       );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'projectNodeId': projectNodeId,
      'status': status.toString().split('.').last,
      'updatedAt': updatedAt?.toIso8601String(),
      'assigneeLogin': assigneeLogin,
      'labels': labels,
      'children': children.map((c) => c.toJson()).toList(),
      'isExpanded': isExpanded,
      'isLocalOnly': isLocalOnly,
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
    };
  }

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['id'] as String,
      title: json['title'] as String,
      projectNodeId: json['projectNodeId'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.open,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      assigneeLogin: json['assigneeLogin'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      children:
          (json['children'] as List?)
              ?.map((c) => Item.fromJson(c))
              .cast<Item>()
              .toList() ??
          [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      localUpdatedAt: json['localUpdatedAt'] != null
          ? DateTime.parse(json['localUpdatedAt'] as String)
          : null,
    );
  }
}
