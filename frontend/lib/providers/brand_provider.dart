import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/brand_model.dart';
import 'package:online_car_marketplace_app/repositories/brand_repository.dart';

class BrandProvider extends ChangeNotifier {
  final BrandRepository _brandRepository = BrandRepository();

  List<Brand> _brands = [];
  List<Brand> get brands => _brands;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchBrands() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedBrands = await _brandRepository.getBrands();
      Future.microtask(() {
        _brands = fetchedBrands;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> addBrand(Brand brand) async {
    try {
      await _brandRepository.addBrand(brand);
      _brands.add(brand);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
