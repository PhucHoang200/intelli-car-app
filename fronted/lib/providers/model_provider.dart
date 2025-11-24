import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/model_model.dart';
import 'package:online_car_marketplace_app/repositories/model_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModelProvider with ChangeNotifier {
  final ModelRepository _modelRepository = ModelRepository();
  List<CarModel> _models = [];
  List<CarModel> get models => _models;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchModels() async {
    _models = await _modelRepository.getModels();
    notifyListeners();
  }

  Future<void> addModelAutoIncrement(CarModel model) async {
    await _modelRepository.addModelAutoIncrement(model);
    await fetchModels(); // Refresh list
  }

  void clearModels() {
    _models = [];
    notifyListeners();
  }

  Future<void> fetchModelsByBrandId(String brandId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('models')
          .where('brandId', isEqualTo: int.parse(brandId)) // Lọc theo brandId
          .get();

      _models = snapshot.docs.map((doc) => CarModel.fromMap(doc.data())).toList();
    } catch (error) {
      _errorMessage = 'Failed to fetch models: $error';
      _models = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
