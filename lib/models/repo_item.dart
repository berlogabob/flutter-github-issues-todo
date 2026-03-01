import 'package:hive/hive.dart';
import 'item.dart';

part 'repo_item.g.dart';

/// Repository item representing a GitHub repository
@HiveType(typeId: 1)
class RepoItem extends Item {
  @HiveField(10)
  String fullName;

  @HiveField(11)
  String? description;

  RepoItem({
    required String id,
    required String title,
    required this.fullName,
    this.description,
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
      'fullName': fullName,
      'description': description,
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

  factory RepoItem.fromJson(Map<String, dynamic> json) {
    return RepoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      fullName: json['fullName'] as String,
      description: json['description'] as String?,
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
