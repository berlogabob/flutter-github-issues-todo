/// Base abstract class for all GitDoIt items
/// Supports offline-first with local tracking
abstract class Item {
  String id;
  String title;
  ItemStatus status;
  DateTime? updatedAt;
  String? assigneeLogin;
  List<String> labels;
  List<Item> children;
  bool isExpanded;
  bool isLocalOnly;
  DateTime? localUpdatedAt;
  
  Item({
    required this.id,
    required this.title,
    this.status = ItemStatus.open,
    this.updatedAt,
    this.assigneeLogin,
    this.labels = const [],
    this.children = const [],
    this.isExpanded = false,
    this.isLocalOnly = false,
    this.localUpdatedAt,
  });
  
  Map<String, dynamic> toJson();
  
  factory Item.fromJson(Map<String, dynamic> json) {
    // This is a factory that should never be called directly
    // Use specific item type factories instead
    throw UnimplementedError('Use specific item type factories');
  }
}

/// Item status enum
enum ItemStatus {
  open,
  closed,
}

/// Extension for convenient status checks
extension ItemStatusExtension on ItemStatus {
  bool get isOpen => this == ItemStatus.open;
  bool get isClosed => this == ItemStatus.closed;
}
