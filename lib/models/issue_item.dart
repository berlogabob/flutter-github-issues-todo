import 'package:hive/hive.dart';
import 'item.dart';

part 'issue_item.g.dart';

/// Issue item representing a GitHub issue
@HiveType(typeId: 2)
class IssueItem extends Item {
  @HiveField(20)
  int? number;

  @HiveField(21)
  String? bodyMarkdown;

  @HiveField(22)
  String? projectColumnName;

  @HiveField(23)
  String? projectItemNodeId;

  IssueItem({
    required String id,
    required String title,
    this.number,
    this.bodyMarkdown,
    this.projectColumnName,
    this.projectItemNodeId,
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
      'number': number,
      'bodyMarkdown': bodyMarkdown,
      'projectColumnName': projectColumnName,
      'projectItemNodeId': projectItemNodeId,
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
  
  factory IssueItem.fromJson(Map<String, dynamic> json) {
    return IssueItem(
      id: json['id'] as String,
      title: json['title'] as String,
      number: json['number'] as int?,
      bodyMarkdown: json['bodyMarkdown'] as String?,
      projectColumnName: json['projectColumnName'] as String?,
      projectItemNodeId: json['projectItemNodeId'] as String?,
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.open,
      ),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      assigneeLogin: json['assigneeLogin'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      children: (json['children'] as List?)
        ?.map((c) => Item.fromJson(c))
        .cast<Item>()
        .toList() ?? [],
      isExpanded: json['isExpanded'] as bool? ?? false,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
      localUpdatedAt: json['localUpdatedAt'] != null
        ? DateTime.parse(json['localUpdatedAt'] as String)
        : null,
    );
  }
}
