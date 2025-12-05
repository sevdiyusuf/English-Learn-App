class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.difficulty = 'easy', // Default difficulty
  });

  final String id;
  final String name;
  final String color; // Hex color string
  final String difficulty; // easy, medium, or hard

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['label_tr'] as String? ?? json['name'] as String? ?? json['id'] as String,
      color: json['color'] as String? ?? '#F4A261', // Default color if not provided
      difficulty: json['difficulty'] as String? ?? 'easy', // Default difficulty
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

