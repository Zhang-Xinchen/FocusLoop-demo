/// Task category.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.color = 0xFF4A90D9,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final String name;

  /// ARGB color value.
  final int color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone; used for multi-device sync.
  final bool deleted;

  Category copyWith({
    String? id,
    String? name,
    int? color,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
