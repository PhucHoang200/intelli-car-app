import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/repositories/car_repository.dart';

class CarProvider with ChangeNotifier {
  final CarRepository _carRepository = CarRepository();
  List<Car> _cars = [];
  bool _isLoading = false;

  List<Car> get cars => _cars;
  bool get isLoading => _isLoading;

  Future<void> fetchCars() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cars = await _carRepository.getCars();
    } catch (e) {
      debugPrint('Lỗi khi lấy danh sách xe: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCar(Car car) async {
    try {
      await _carRepository.addCarAutoIncrement(car);
      await fetchCars();
    } catch (e) {
      debugPrint('Lỗi khi thêm xe: $e');
    }
  }

  Car? getCarById(int id) {
    return _cars.firstWhere((car) => car.id == id, orElse: () => null as Car);
  }
}
