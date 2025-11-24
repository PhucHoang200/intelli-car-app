class Brand {
  final int id;
  final String name;

  Brand({required this.id, required this.name});

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };
}