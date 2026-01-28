class CarType {
  final int id;
  final String name;

  CarType({required this.id, required this.name});

  factory CarType.fromMap(Map<String, dynamic> map) {
    return CarType(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };
}