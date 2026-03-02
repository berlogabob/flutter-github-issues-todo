import 'item.dart';

/// Issue item representing a GitHub issue
class IssueItem extends Item {
  int? number;
  String? bodyMarkdown;
  String? projectColumnName;
  String? projectItemNodeId;
  DateTime? createdAt;

  IssueItem({
    required super.id,
    required super.title,
    this.number,
    this.bodyMarkdown,
    this.projectColumnName,
    this.projectItemNodeId,
    this.createdAt,
    ItemStatus? status,
    super.updatedAt,
    super.assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    super.localUpdatedAt,
  }) : super(
         status: status ?? ItemStatus.open,
         labels: labels ?? const [],
         children: children ?? const [],
         isExpanded: isExpanded ?? false,
         isLocalOnly: isLocalOnly ?? false,
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
      'createdAt': createdAt?.toIso8601String(),
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
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

  /// Create a copy of this IssueItem with updated fields
  IssueItem copyWith({
    String? id,
    String? title,
    int? number,
    String? bodyMarkdown,
    String? projectColumnName,
    String? projectItemNodeId,
    DateTime? createdAt,
    ItemStatus? status,
    DateTime? updatedAt,
    String? assigneeLogin,
    List<String>? labels,
    List<Item>? children,
    bool? isExpanded,
    bool? isLocalOnly,
    DateTime? localUpdatedAt,
  }) {
    return IssueItem(
      id: id ?? this.id,
      title: title ?? this.title,
      number: number ?? this.number,
      bodyMarkdown: bodyMarkdown ?? this.bodyMarkdown,
      projectColumnName: projectColumnName ?? this.projectColumnName,
      projectItemNodeId: projectItemNodeId ?? this.projectItemNodeId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeLogin: assigneeLogin ?? this.assigneeLogin,
      labels: labels ?? this.labels,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    );
  }
}
