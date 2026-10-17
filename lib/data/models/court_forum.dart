/// A court or forum entity that can be linked to client matters.
class CourtForum {
  final int? id;
  final String name;
  final String status; // 'Active' or 'Archived'
  final String? createdAt;

  const CourtForum({
    this.id,
    required this.name,
    this.status = 'Active',
    this.createdAt,
  });

  bool get isActive => status == 'Active';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'status': status,
      };

  factory CourtForum.fromMap(Map<String, dynamic> map) => CourtForum(
        id: map['id'] as int?,
        name: map['name'] as String,
        status: map['status'] as String? ?? 'Active',
        createdAt: map['created_at'] as String?,
      );

  CourtForum copyWith({
    int? id,
    String? name,
    String? status,
  }) =>
      CourtForum(
        id: id ?? this.id,
        name: name ?? this.name,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
