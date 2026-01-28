class CarModel {
  final int id;
  final int brandId;
  final int carTypeId;
  final String name;
  
  CarModel(
      {required this.id, required this.brandId, required this.carTypeId, required this.name});

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      brandId: map['brandId'] is int ? map['brandId'] : int.parse(map['brandId'].toString()),
      name: map['name'] ?? '',
      carTypeId: map['carTypeId'] is int ? map['carTypeId'] : int.parse(map['carTypeId'].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'brandId': brandId,
    'carTypeId': carTypeId,
    'name': name,
  };
}