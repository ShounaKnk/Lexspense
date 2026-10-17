/// A client matter / case that expenses are logged against.
class ClientMatter {
  final int? id;
  final String caseTitle;
  final int? forumId;
  final String? forumName; // Populated from JOINs, not stored directly
  final String status;    // 'Active' or 'Archived'
  final String? createdAt;

  const ClientMatter({
    this.id,
    required this.caseTitle,
    this.forumId,
    String? forum,
    String? forumName,
    this.status = 'Active',
    this.createdAt,
  }) : forumName = forumName ?? forum;

  bool get isActive => status == 'Active';
  String? get forum => forumName;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'case_title': caseTitle,
        'forum_id': forumId,
        'status': status,
      };

  factory ClientMatter.fromMap(Map<String, dynamic> map) => ClientMatter(
        id: map['id'] as int?,
        caseTitle: map['case_title'] as String,
        forumId: map['forum_id'] as int?,
        forumName: (map['forum_name'] ?? map['forum']) as String?,
        status: map['status'] as String? ?? 'Active',
        createdAt: map['created_at'] as String?,
      );

  ClientMatter copyWith({
    int? id,
    String? caseTitle,
    int? forumId,
    String? forumName,
    String? status,
  }) =>
      ClientMatter(
        id: id ?? this.id,
        caseTitle: caseTitle ?? this.caseTitle,
        forumId: forumId ?? this.forumId,
        forumName: forumName ?? this.forumName,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  /// Create a copy that clears the forum association.
  ClientMatter clearForum() => ClientMatter(
        id: id,
        caseTitle: caseTitle,
        forumId: null,
        forumName: null,
        status: status,
        createdAt: createdAt,
      );
}
