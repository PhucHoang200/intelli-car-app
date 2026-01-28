class Car {
  final int id;
  final String? userId;
  final int modelId;
  final String fuelType;
  final String transmission;
  final int year;
  final int mileage;
  final String location;
  final double price;
  final String condition;
  final String origin;

  Car({
    required this.id,
    required this.userId,
    required this.modelId,
    required this.fuelType,
    required this.transmission,
    required this.year,
    required this.mileage,
    required this.location,
    required this.price,
    required this.condition,
    required this.origin,
  });

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      userId: map['userId'] as String?,
      modelId: map['modelId'],
      fuelType: map['fuelType'],
      transmission: map['transmission'],
      year: map['year'],
      mileage: map['mileage'],
      location: map['location'],
      price: (map['price'] as num).toDouble(),
      condition: map['condition'],
      origin: map['origin'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'modelId': modelId,
    'fuelType': fuelType,
    'transmission': transmission,
    'year': year,
    'mileage': mileage,
    'location': location,
    'price': price,
    'condition': condition,
    'origin': origin,
  };
}
