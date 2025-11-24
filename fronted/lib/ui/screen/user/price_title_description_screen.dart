import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PriceTitleDescriptionScreen extends StatefulWidget {
  final String brandId;
  final int modelId;
  final String modelName;
  final String selectedYear;
  final String condition;
  final String origin;
  final int mileage;
  final String fuelType;
  final String transmission;
  final Map<String, dynamic>? initialData;
  final double? initialPrice;
  final String? initialTitle;
  final String? initialDescription;

  const PriceTitleDescriptionScreen({
    super.key,
    required this.brandId,
    required this.modelId,
    required this.modelName,
    required this.selectedYear,
    required this.condition,
    required this.origin,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    this.initialData,
    this.initialPrice,
    this.initialTitle,
    this.initialDescription,
  });

  @override
  State<PriceTitleDescriptionScreen> createState() => _PriceTitleDescriptionScreenState();
}

class _PriceTitleDescriptionScreenState extends State<PriceTitleDescriptionScreen> {
  TextEditingController priceController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrice != null) {
      // Hiển thị giá dưới dạng số nguyên
      priceController.text = widget.initialPrice!.toStringAsFixed(0);
    }
    titleController.text = widget.initialTitle ?? '';
    descriptionController.text = widget.initialDescription ?? '';

    // Add listeners to text controllers to update button state
    priceController.addListener(_updateButtonState);
    titleController.addListener(_updateButtonState);
    descriptionController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    priceController.removeListener(_updateButtonState);
    titleController.removeListener(_updateButtonState);
    descriptionController.removeListener(_updateButtonState);
    priceController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      // Rebuild the UI to re-evaluate the onPressed condition for the button
    });
  }

  bool _isButtonEnabled() {
    // Kiểm tra giá phải là số và lớn hơn 0
    final double? price = double.tryParse(priceController.text);
    return price != null &&
        price > 0 &&
        titleController.text.trim().isNotEmpty && // Sử dụng trim() để loại bỏ khoảng trắng
        descriptionController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giá bán & Mô tả'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Sử dụng SingleChildScrollView để tránh tràn màn hình khi bàn phím hiện lên
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trường nhập Giá bán
            Text(
              'Giá bán*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nhập giá bán',
                hintText: 'Ví dụ: 350', // Thêm hint text
                border: const OutlineInputBorder(),
                suffixText: 'TRIỆU VND',
                // Đặt màu cho viền khi focus và màu label khi focus
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.blue), // Màu của label text khi focus
              ),
              cursorColor: Colors.blue, // Màu của con trỏ khi nhập
              onChanged: (value) {
                _updateButtonState(); // Cập nhật trạng thái nút khi giá thay đổi
              },
            ),
            const SizedBox(height: 24),

            // Trường nhập Tiêu đề
            Text(
              'Tiêu đề*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Nhập tiêu đề tin rao',
                hintText: 'Ví dụ: Bán xe ABC đời 2022 chính chủ', // Thêm hint text
                border: const OutlineInputBorder(),
                // Đặt màu cho viền khi focus và màu label khi focus
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.blue),
              ),
              cursorColor: Colors.blue,
              onChanged: (value) {
                _updateButtonState(); // Cập nhật trạng thái nút khi tiêu đề thay đổi
              },
            ),
            const SizedBox(height: 24),

            // Trường nhập Mô tả
            Text(
              'Mô tả*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              minLines: 3, // Giới hạn số dòng tối thiểu để mô tả không bị quá nhỏ
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết về xe',
                hintText: 'Ví dụ: Xe còn mới, ít đi, bảo dưỡng định kỳ...', // Thêm hint text
                border: const OutlineInputBorder(),
                // Đặt màu cho viền khi focus và màu label khi focus
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.blue),
                alignLabelWithHint: true, // Căn chỉnh label với hint text khi maxLines > 1
              ),
              cursorColor: Colors.blue,
              onChanged: (value) {
                _updateButtonState(); // Cập nhật trạng thái nút khi mô tả thay đổi
              },
            ),
            const SizedBox(height: 32),

            // Nút Tiếp tục
            SizedBox(
              width: double.infinity, // Nút rộng full màn hình
              child: ElevatedButton(
                onPressed: _isButtonEnabled()
                    ? () {
                  double? price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập giá bán hợp lệ (lớn hơn 0).'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  context.go(
                    '/sell/image-upload',
                    extra: {
                      'brandId': widget.brandId,
                      'modelId': widget.modelId,
                      'modelName': widget.modelName,
                      'selectedYear': widget.selectedYear,
                      'condition': widget.condition,
                      'origin': widget.origin,
                      'mileage': widget.mileage,
                      'fuelType': widget.fuelType,
                      'transmission': widget.transmission,
                      'price': price,
                      'title': titleController.text.trim(), // Lưu trữ giá trị đã trim
                      'description': descriptionController.text.trim(), // Lưu trữ giá trị đã trim
                      'initialData': {
                        ...widget.initialData ?? {},
                        'price': price,
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                      },
                      'initialImage': widget.initialData?['selectedImage'],
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