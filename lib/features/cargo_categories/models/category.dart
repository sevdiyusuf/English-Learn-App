class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final String color; // Hex color string

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['label_tr'] as String? ?? json['name'] as String? ?? json['id'] as String,
      color: json['color'] as String? ?? '#F4A261', // Default color if not provided
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label_tr': name,
      'color': color,
    };
  }
}

