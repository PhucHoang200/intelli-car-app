import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/car_type_model.dart';
import 'package:online_car_marketplace_app/repositories/car_type_repository.dart';

class CarTypeProvider extends ChangeNotifier {
  final CarTypeRepository _carTypeRepository = CarTypeRepository();

  List<CarType> _carTypes = [];
  List<CarType> get carTypes => _carTypes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCarTypes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _carTypes = await _carTypeRepository.getCarTypes();
    } catch (e) {
      print('Error fetching car types: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCarType(CarType carType) async {
    try {
      await _carTypeRepository.addCarType(carType);
      _carTypes.add(carType);
      notifyListeners();
    } catch (e) {
      print('Error adding car type: $e');
    }
  }
}
