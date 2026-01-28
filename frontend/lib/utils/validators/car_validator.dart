class CarValidator {
  static String validateLicensePlate(String plate) {
    if (!RegExp(r'^\d{2}[A-Z]\d{4,5}$').hasMatch(plate)) {
      throw Exception('Biển số xe không hợp lệ. Ví dụ đúng: 30F25658, 36F0987');
    }
    return plate;
  }

  static String validateTransmission(String transmission) {
    const validTransmissions = ['Tự động', 'Số sàn'];
    if (!validTransmissions.contains(transmission.toLowerCase())) {
      throw Exception('Hộp số không hợp lệ (chỉ chấp nhận: tự động, số sàn)');
    }
    return transmission;
  }

  static String validateFuelType(String fuelType) {
    const validFuelTypes = ['Xăng', 'Dầu', 'Điện', 'Hybrid'];
    if (!validFuelTypes.contains(fuelType.toLowerCase())) {
      throw Exception('Loại nhiên liệu không hợp lệ (chỉ chấp nhận: xăng, dầu, điện, hybrid)');
    }
    return fuelType;
  }

  static String validateLocation(String location) {
    if (location.trim().isEmpty) {
      throw Exception('Vị trí không được để trống');
    }
    return location;
  }
}
