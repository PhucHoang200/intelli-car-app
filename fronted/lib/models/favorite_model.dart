class Favorite {
  final int id;
  final String? userId;
  final int postId;

  Favorite({
    required this.id,
    required this.userId,
    required this.postId,
  });

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int,
      userId: map['userId'] as String?,
      postId: map['postId'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'postId': postId,
  };
}