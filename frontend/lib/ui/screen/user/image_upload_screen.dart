import 'dart:io'; // Import để sử dụng File
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadScreen extends StatefulWidget {
  final String brandId;
  final int modelId;
  final String modelName;
  final String selectedYear;
  final String condition;
  final String origin;
  final int mileage;
  final String fuelType;
  final String transmission;
  final double price;
  final String title;
  final String description;
  final List<XFile>? initialImages; // Changed to List<XFile>?
  final Map<String, dynamic>? initialData;

  const ImageUploadScreen({
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
    required this.price,
    required this.title,
    required this.description,
    this.initialImages, // Updated to initialImages
    this.initialData,
  });

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  List<XFile> _selectedImages = [];
  final int _maxImages = 5; // Giới hạn số lượng ảnh tối đa

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null) {
      _selectedImages = List.from(widget.initialImages!);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    // Cho phép chọn nhiều ảnh
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 80, // Giảm chất lượng ảnh để tối ưu hiệu suất và dung lượng
      maxWidth: 1024, // Giới hạn chiều rộng ảnh
      maxHeight: 768, // Giới hạn chiều cao ảnh
    );

    if (pickedFiles.isNotEmpty) {
      setState(() {
        if (_selectedImages.length + pickedFiles.length <= _maxImages) {
          _selectedImages.addAll(pickedFiles);
        } else {
          final remainingSlots = _maxImages - _selectedImages.length;
          // Chỉ thêm đủ số ảnh còn lại
          _selectedImages.addAll(pickedFiles.sublist(0, remainingSlots));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chỉ có thể chọn tối đa $_maxImages ảnh.'),
              backgroundColor: Colors.red, // Màu nền đỏ cho lỗi
            ),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  bool _isButtonEnabled() {
    return _selectedImages.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tải ảnh lên'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn tối thiểu 1 ảnh và tối đa $_maxImages ảnh để tải lên',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16), // Tăng khoảng cách

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 ảnh mỗi hàng
                  crossAxisSpacing: 10.0, // Khoảng cách ngang giữa các ảnh
                  mainAxisSpacing: 10.0, // Khoảng cách dọc giữa các ảnh
                  childAspectRatio: 1, // Tỷ lệ khung hình vuông
                ),
                itemCount: _selectedImages.length + (_selectedImages.length < _maxImages ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    // Nút "Thêm ảnh"
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200, // Màu nền nhẹ
                          border: Border.all(color: Colors.blue.shade300, width: 2), // Viền xanh
                          borderRadius: BorderRadius.circular(12.0), // Bo tròn góc nhiều hơn
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.blue), // Icon xanh
                            const SizedBox(height: 8),
                            Text(
                              'Thêm ảnh',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '(${_selectedImages.length}/$_maxImages)', // Hiển thị số lượng ảnh
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Hiển thị ảnh đã chọn
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0), // Bo tròn góc ảnh
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4, // Đẩy nút xóa vào trong hơn
                          right: 4, // Đẩy nút xóa vào trong hơn
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade600, // Màu đỏ đậm hơn
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5), // Viền trắng
                              ),
                              padding: const EdgeInsets.all(4), // Tăng padding nút xóa
                              child: const Icon(Icons.close, color: Colors.white, size: 18), // Kích thước icon nhỏ hơn
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24), // Tăng khoảng cách trước nút

            // Nút Tiếp tục
            SizedBox(
              width: double.infinity, // Nút rộng full màn hình
              child: ElevatedButton(
                onPressed: _isButtonEnabled()
                    ? () {
                  context.go(
                    '/sell/confirm-post',
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
                      'price': widget.price,
                      'title': widget.title,
                      'description': widget.description,
                      'selectedImages': _selectedImages, // Pass the list of images
                      'initialData': {
                        ...widget.initialData ?? {},
                        'selectedImages': _selectedImages, // Update initialData with list
                      },
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
            const SizedBox(height: 16), // Khoảng cách sau nút
            Center( // Căn giữa văn bản thông báo
              child: Text(
                'Sau khi chọn ảnh, bạn sẽ được xem lại toàn bộ thông tin trước khi đăng bài.',
                textAlign: TextAlign.center, // Căn giữa văn bản
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}