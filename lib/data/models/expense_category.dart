/// An expense category (Court Fees, Printing, etc.)
class ExpenseCategory {
  final int? id;
  final String name;
  final String? icon;     // Icon key string, resolved via IconMap
  final bool isActive;
  final String? createdAt;

  const ExpenseCategory({
    this.id,
    required this.name,
    this.icon,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'is_active': isActive ? 1 : 0,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        isActive: (map['is_active'] as int? ?? 1) == 1,
        createdAt: map['created_at'] as String?,
      );

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isActive,
  }) =>
      ExpenseCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
