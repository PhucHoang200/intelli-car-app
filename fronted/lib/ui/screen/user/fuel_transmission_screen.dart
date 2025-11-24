import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FuelTransmissionScreen extends StatefulWidget {
  final String brandId;
  final int modelId;
  final String modelName;
  final String selectedYear;
  final String condition;
  final String origin;
  final int mileage;
  final Map<String, dynamic>? initialData;
  final String? initialFuelType;
  final String? initialTransmission;

  const FuelTransmissionScreen({
    super.key,
    required this.brandId,
    required this.modelId,
    required this.modelName,
    required this.selectedYear,
    required this.condition,
    required this.origin,
    required this.mileage,
    this.initialData,
    this.initialFuelType,
    this.initialTransmission,
  });

  @override
  State<FuelTransmissionScreen> createState() => _FuelTransmissionScreenState();
}

class _FuelTransmissionScreenState extends State<FuelTransmissionScreen> {
  String? fuelType;
  String? transmission;

  @override
  void initState() {
    super.initState();
    fuelType = widget.initialFuelType;
    transmission = widget.initialTransmission;
  }

  // Helper method to check if the button should be enabled
  bool _isButtonEnabled() {
    return fuelType != null && transmission != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiên liệu & Hộp số'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần loại nhiên liệu
            Text(
              'Loại nhiên liệu*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                // Đặt màu viền và màu label khi focus
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.blue),
                hintText: 'Chọn loại nhiên liệu', // Thêm hint text
              ),
              value: fuelType,
              items: <String>['Xăng', 'Dầu', 'Điện', 'Hybrid'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  fuelType = value;
                });
              },
              // Màu của icon mũi tên xổ xuống
              iconEnabledColor: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Phần Hộp số
            Text(
              'Hộp số*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                // Đặt màu viền và màu label khi focus
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.blue),
                hintText: 'Chọn loại hộp số', // Thêm hint text
              ),
              value: transmission,
              items: <String>['Số sàn', 'Số tự động', 'Bán tự động'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  transmission = value;
                });
              },
              // Màu của icon mũi tên xổ xuống
              iconEnabledColor: Colors.blue,
            ),
            const Spacer(), // Đẩy nút "Tiếp tục" xuống dưới cùng

            // Nút Tiếp tục
            SizedBox(
              width: double.infinity, // Nút rộng full màn hình
              child: ElevatedButton(
                onPressed: _isButtonEnabled()
                    ? () {
                  context.go(
                    '/sell/price-title-description',
                    extra: {
                      'brandId': widget.brandId,
                      'modelId': widget.modelId,
                      'modelName': widget.modelName,
                      'selectedYear': widget.selectedYear,
                      'condition': widget.condition,
                      'origin': widget.origin,
                      'mileage': widget.mileage,
                      'fuelType': fuelType!,
                      'transmission': transmission!,
                      'initialData': {
                        ...widget.initialData ?? {},
                        'fuelType': fuelType,
                        'transmission': transmission,
                      },
                      'initialPrice': widget.initialData?['price'],
                      'initialTitle': widget.initialData?['title'],
                      'initialDescription': widget.initialData?['description'],
                    },
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14), // Tăng kích thước nút
                  backgroundColor: Colors.blue, // Màu nền nút
                  foregroundColor: Colors.white, // Màu chữ nút
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bo tròn góc nút
                  ),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Kích thước chữ nút
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}