import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/role_model.dart';
import 'package:online_car_marketplace_app/repositories/role_repository.dart';

class RoleProvider with ChangeNotifier {
  final RoleRepository _roleRepository = RoleRepository();

  List<Role> _roles = [];
  List<Role> get roles => _roles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchRoles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _roles = await _roleRepository.getRoles();
    } catch (e) {
      print('Error fetching roles: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRole(Role role) async {
    try {
      await _roleRepository.addRole(role);
      _roles.add(role);
      notifyListeners();
    } catch (e) {
      print('Error adding role: $e');
    }
  }
}
