import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/image_model.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/repositories/car_repository.dart';
import 'package:online_car_marketplace_app/services/storage_service.dart';
import 'package:online_car_marketplace_app/repositories/image_repository.dart';

import '../../../repositories/user_repository.dart';

class ConfirmPostScreen extends StatefulWidget {
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
  final List<XFile>? selectedImages;
  final Map<String, dynamic>? initialData; // Dữ liệu khởi tạo cho chế độ sửa

  const ConfirmPostScreen({
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
    this.selectedImages,
    this.initialData, // Nhận initialData
  });

  @override
  State<ConfirmPostScreen> createState() => _ConfirmPostScreenState();
}

class _ConfirmPostScreenState extends State<ConfirmPostScreen> {
  // Biến để lưu trữ ảnh mới chọn (XFile) và ảnh cũ (URL)
  List<XFile> _newSelectedImages = [];
  List<String> _existingImageUrls = []; // Các URL ảnh đã có trên Firestore/Storage
  List<String> _imageUrlsToDelete = []; // Các URL ảnh cần xóa khỏi Storage/Firestore

  bool _isUploading = false;

  // Các biến này sẽ được cập nhật từ widget.initialData hoặc widget.parameters
  late int _modelId;
  late String _modelName;
  late String _selectedYear;
  late String _condition;
  late String _origin;
  late int _mileage;
  late String _fuelType;
  late String _transmission;
  late double _price;
  late String _title;
  late String _description;
  late String _brandId;

  // User information variables
  String _userName = '';
  String _userPhoneNumber = '';
  String _userAddress = '';

  // Biến để xác định chế độ (tạo mới hay sửa)
  bool _isEditing = false;
  int? _postIdToEdit;
  int? _carIdToEdit;

  // Controllers cho TextFormField
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _mileageController;
  late TextEditingController _priceController;

  // THÊM: Một phương thức để tạo Map từ trạng thái hiện tại của ConfirmPostScreen
  Map<String, dynamic> _getCurrentConfirmPostData() {
    return {
      'brandId': _brandId,
      'modelId': _modelId,
      'modelName': _modelName,
      'selectedYear': _selectedYear,
      'condition': _condition,
      'origin': _origin,
      'mileage': _mileage,
      'fuelType': _fuelType,
      'transmission': _transmission,
      'price': _price,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'isEditing': _isEditing,
      'postId': _postIdToEdit,
      'carId': _carIdToEdit,
      // Chuyển đổi List<XFile> thành List<String> paths để truyền
      'newSelectedImagePaths': _newSelectedImages.map((xfile) => xfile.path).toList(),
      'existingImageUrls': _existingImageUrls,
      'imageUrlsToDelete': _imageUrlsToDelete,
    };
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _mileageController = TextEditingController();
    _priceController = TextEditingController();

    // Kiểm tra initialData để xác định chế độ
    if (widget.initialData != null && widget.initialData!['isEditing'] == true) {
      _isEditing = true;
      _postIdToEdit = widget.initialData!['postId'] as int?; // Make nullable
      _carIdToEdit = widget.initialData!['carId'] as int?; // Make nullable
      // Đảm bảo ép kiểu an toàn cho List<String>
      if (widget.initialData!['existingImageUrls'] != null) {
        _existingImageUrls =
        List<String>.from(widget.initialData!['existingImageUrls']);
      }

      // Gán dữ liệu ban đầu từ initialData khi sửa
      _brandId = widget.brandId;
      _modelId = widget.modelId;
      _modelName = widget.modelName;
      _selectedYear = widget.selectedYear;
      _condition = widget.condition;
      _origin = widget.origin;
      _mileage = widget.mileage;
      _fuelType = widget.fuelType;
      _transmission = widget.transmission;
      _price = widget.price;
      _title = widget.title;
      _description = widget.description;

    } else {
      // Chế độ tạo mới
      _brandId = widget.brandId;
      _modelId = widget.modelId;
      _modelName = widget.modelName;
      _selectedYear = widget.selectedYear;
      _condition = widget.condition;
      _origin = widget.origin;
      _mileage = widget.mileage;
      _fuelType = widget.fuelType;
      _transmission = widget.transmission;
      _price = widget.price;
      _title = widget.title;
      _description = widget.description;
      if (widget.selectedImages != null) {
        _newSelectedImages = List.from(widget.selectedImages!);
      }
    }

    // Gán giá trị ban đầu cho các Controller
    _titleController.text = _title;
    _descriptionController.text = _description;
    _mileageController.text = _mileage.toString();
    _priceController.text = _price.toString();

    // Lấy thông tin người dùng
    _fetchCurrentUserInfo();
  }

  Future<void> _fetchCurrentUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userRepository = Provider.of<UserRepository>(context, listen: false);
        final currentUserData = await userRepository.getUserById(user.uid.toString());
        if (currentUserData != null) {
          setState(() {
            _userName = currentUserData.name;
            _userPhoneNumber = currentUserData.phone;
            _userAddress = currentUserData.address;
          });
        }
      } catch (e) {
        print('Error fetching user info: $e');
        // Handle error, maybe show a snackbar
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mileageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Phương thức chọn ảnh mới
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _newSelectedImages.addAll(images);
      });
    }
  }

  // Phương thức xóa ảnh (cũ hoặc mới)
  void _removeImage(dynamic imageToRemove) {
    setState(() {
      if (imageToRemove is XFile) {
        _newSelectedImages.remove(imageToRemove);
      } else if (imageToRemove is String) {
        _existingImageUrls.remove(imageToRemove);
        _imageUrlsToDelete.add(imageToRemove); // Thêm vào danh sách cần xóa khỏi Storage
      }
    });
  }

  Future<void> _handlePostOrUpdate() async {
    if (_isUploading) return;

    // Cập nhật giá trị từ controller
    _title = _titleController.text;
    _description = _descriptionController.text;
    _mileage = int.tryParse(_mileageController.text) ?? 0;
    _price = double.tryParse(_priceController.text) ?? 0.0;

    // Kiểm tra ảnh tối thiểu
    if (_newSelectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một ảnh.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final postRepository = Provider.of<PostRepository>(context, listen: false);
      final carRepository = Provider.of<CarRepository>(context, listen: false);
      final imageRepository = Provider.of<ImageRepository>(context, listen: false);

      final User? user = FirebaseAuth.instance.currentUser;
      final String? userId = user?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để đăng bài.')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload ảnh mới
      List<String> uploadedNewImageUrls = [];
      for (var imageFile in _newSelectedImages) {
        final url = await storageService.uploadImage(imageFile);
        uploadedNewImageUrls.add(url);
      }

      // Tạo mới Car
      final car = Car(
        id: 0, // ID sẽ được tự động tạo bởi Firestore
        userId: userId,
        modelId: _modelId,
        fuelType: _fuelType,
        transmission: _transmission,
        year: int.parse(_selectedYear),
        mileage: _mileage,
        location: 'Việt Nam', // Bạn có thể thêm logic để lấy địa điểm thực tế
        price: _price,
        condition: _condition,
        origin: _origin,
      );
      final String carIdString = await carRepository.addCarAutoIncrement(car);
      final int carId = int.parse(carIdString);

      // Tạo mới Post
      final post = Post(
        id: 0, // ID sẽ được tự động tạo bởi Firestore
        userId: userId,
        carId: carId,
        title: _title,
        description: _description,
        creationDate: Timestamp.now().toDate(),
      );
      await postRepository.addPostAutoIncrement(post);

      // Thêm ảnh mới vào Firestore liên kết với CarId
      for (var url in uploadedNewImageUrls) {
        final image = ImageModel(
          id: 0, // ID sẽ được tự động tạo bởi Firestore
          carId: carId,
          url: url,
          creationDate: Timestamp.now(),
        );
        await imageRepository.addImageAutoIncrement(image);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng bài thành công!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey,
        ),
      );
      // Điều hướng sau khi đăng bài thành công
      context.go('/sell');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã có lỗi xảy ra: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
    bool isRedText = false,
    Widget? child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child ??
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                      const SizedBox(height: 4.0),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isRedText ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (trailing != null) trailing,
                ],
              ),
        ),
      ),
    );
  }

  bool _isButtonEnabled() {
    return !_isUploading;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Sửa tin đăng' : 'Xem lại nội dung tin đăng',
          style: const TextStyle(color: Colors.white), // Đặt màu chữ trắng
        ),
        centerTitle: true, // Căn giữa tiêu đề
        backgroundColor: Colors.blue, // Màu nền AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Icon màu trắng
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding tổng thể
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thông tin xe section
            _buildSectionHeader(
              title: 'THÔNG TIN XE',
              onTap: () {
                // Logic cho Thu gọn / Mở rộng (nếu bạn muốn triển khai)
              },
            ),
            const SizedBox(height: 8.0), // Khoảng cách
            _buildDetailCard(
              title: 'Hãng xe*',
              value: _brandId,
              onTap: _isEditing
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng sửa hãng xe ở bước đầu tiên.')),
                );
              }
                  : null, // Không cho phép chỉnh sửa khi đang tạo mới
              trailing: _isEditing ? null : Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Dòng xe*',
              value: _modelName,
              onTap: _isEditing
                  ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng sửa dòng xe ở bước đầu tiên.')),
                );
              }
                  : null, // Không cho phép chỉnh sửa khi đang tạo mới
              trailing: _isEditing ? null : Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            if (_isEditing) // Chỉ hiển thị thông báo khi ở chế độ sửa
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '! Vui lòng sửa thông tin hãng xe/dòng xe tại trang quản lý tin đăng của bạn.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 13.0, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            _buildDetailCard(
              title: 'Năm SX*',
              value: _selectedYear,
              onTap: () {
                context.push('/sell/year', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'initialYear': _selectedYear,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'condition': _condition,
                    'origin': _origin,
                    'mileage': _mileage,
                    'fuelType': _fuelType,
                    'transmission': _transmission,
                    'price': _price,
                    'title': _title,
                    'description': _description,
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Tình trạng*',
              value: _condition, // Hiển thị giá trị trực tiếp
              onTap: () {
                context.push('/sell/condition-origin', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'initialCondition': _condition,
                  'initialOrigin': _origin,
                  'initialMileage': _mileage,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'fuelType': _fuelType,
                    'transmission': _transmission,
                    'price': _price,
                    'title': _title,
                    'description': _description,
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            if (_condition == 'Cũ') // Chỉ hiển thị khi tình trạng là xe cũ
              _buildDetailCard(
                title: 'Km đã đi*',
                value: _mileage > 0 ? '${_mileage} km' : 'Chưa cập nhật',
                isRedText: _mileage == 0,
                onTap: () {
                  context.push('/sell/condition-origin', extra: {
                    'brandId': _brandId,
                    'modelId': _modelId,
                    'modelName': _modelName,
                    'selectedYear': _selectedYear,
                    'initialCondition': _condition,
                    'initialOrigin': _origin,
                    'initialMileage': _mileage,
                    'initialData': {
                      ...widget.initialData ?? {},
                      'fuelType': _fuelType,
                      'transmission': _transmission,
                      'price': _price,
                      'title': _title,
                      'description': _description,
                      'selectedImages': _newSelectedImages,
                      'existingImageUrls': _existingImageUrls,
                      'isEditing': _isEditing,
                      'postId': _postIdToEdit,
                      'carId': _carIdToEdit,
                    }
                  });
                },
                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
              ),
            _buildDetailCard(
              title: 'Xuất xứ*',
              value: _origin,
              onTap: () {
                context.push('/sell/condition-origin', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'initialCondition': _condition,
                  'initialOrigin': _origin,
                  'initialMileage': _mileage,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'fuelType': _fuelType,
                    'transmission': _transmission,
                    'price': _price,
                    'title': _title,
                    'description': _description,
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Hộp số*',
              value: _transmission,
              onTap: () {
                context.push('/sell/fuel-transmission', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'condition': _condition,
                  'origin': _origin,
                  'mileage': _mileage,
                  'initialFuelType': _fuelType,
                  'initialTransmission': _transmission,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'price': _price,
                    'title': _title,
                    'description': _description,
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Nhiên liệu*',
              value: _fuelType,
              onTap: () {
                context.push('/sell/fuel-transmission', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'condition': _condition,
                  'origin': _origin,
                  'mileage': _mileage,
                  'initialFuelType': _fuelType,
                  'initialTransmission': _transmission,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'price': _price,
                    'title': _title,
                    'description': _description,
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24.0),

            // Đăng ảnh & Video xe section
            _buildSectionHeader(
              title: 'ĐĂNG ẢNH & VIDEO XE',
              onTap: () {
                // Logic cho Thu gọn / Mở rộng
              },
            ),
            const SizedBox(height: 8.0),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng số ảnh: ${_newSelectedImages.length + _existingImageUrls.length}/5',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10.0, // Khoảng cách giữa các ảnh
                    runSpacing: 10.0, // Khoảng cách giữa các hàng ảnh
                    children: [
                      // Hiển thị ảnh hiện có (từ URL)
                      ..._existingImageUrls.map((imageUrl) {
                        return _buildImageThumbnail(
                          image: Image.network(imageUrl, fit: BoxFit.cover),
                          onRemove: () => _removeImage(imageUrl),
                        );
                      }).toList(),
                      // Hiển thị ảnh mới chọn (từ XFile)
                      ..._newSelectedImages.map((imageFile) {
                        return _buildImageThumbnail(
                          image: Image.file(File(imageFile.path), fit: BoxFit.cover),
                          onRemove: () => _removeImage(imageFile),
                        );
                      }).toList(),
                      // Nút "Thêm ảnh"
                      if ((_newSelectedImages.length + _existingImageUrls.length) < 5)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100, // Kích thước cố định cho ô ảnh
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.blue.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 36, color: Colors.blue),
                                SizedBox(height: 4),
                                Text(
                                  'Thêm ảnh',
                                  style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Thông tin mô tả & Giá bán section
            _buildSectionHeader(
              title: 'THÔNG TIN MÔ TẢ & GIÁ BÁN',
              onTap: () {
                // Logic cho Thu gọn / Mở rộng
              },
            ),
            const SizedBox(height: 8.0),
            _buildDetailCard(
              title: 'Tiêu đề tin rao*',
              value: _title,
              isRedText: _title.trim().isEmpty, // Đổi màu nếu trống
              onTap: () {
                context.push('/sell/price-title-description', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'condition': _condition,
                  'origin': _origin,
                  'mileage': _mileage,
                  'fuelType': _fuelType,
                  'transmission': _transmission,
                  'initialPrice': _price,
                  'initialTitle': _title,
                  'initialDescription': _description,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Mô tả chi tiết*',
              value: _description.trim().isEmpty ? 'Chưa cập nhật' : _description,
              isRedText: _description.trim().isEmpty, // Đổi màu nếu trống
              onTap: () {
                context.push('/sell/price-title-description', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'condition': _condition,
                  'origin': _origin,
                  'mileage': _mileage,
                  'fuelType': _fuelType,
                  'transmission': _transmission,
                  'initialPrice': _price,
                  'initialTitle': _title,
                  'initialDescription': _description,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Giá bán*',
              value: _price > 0 ? '${_price.toStringAsFixed(0)} TRIỆU VND' : 'Chưa cập nhật',
              isRedText: _price == 0.0,
              onTap: () {
                context.push('/sell/price-title-description', extra: {
                  'brandId': _brandId,
                  'modelId': _modelId,
                  'modelName': _modelName,
                  'selectedYear': _selectedYear,
                  'condition': _condition,
                  'origin': _origin,
                  'mileage': _mileage,
                  'fuelType': _fuelType,
                  'transmission': _transmission,
                  'initialPrice': _price,
                  'initialTitle': _title,
                  'initialDescription': _description,
                  'initialData': {
                    ...widget.initialData ?? {},
                    'selectedImages': _newSelectedImages,
                    'existingImageUrls': _existingImageUrls,
                    'isEditing': _isEditing,
                    'postId': _postIdToEdit,
                    'carId': _carIdToEdit,
                  }
                });
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24.0),

            // Thông tin người đăng bài section
            _buildSectionHeader(
              title: 'THÔNG TIN NGƯỜI ĐĂNG BÀI',
              onTap: () {
                // Logic cho Thu gọn / Mở rộng
              },
            ),
            const SizedBox(height: 8.0),
            _buildDetailCard(
              title: 'Tên người đăng',
              value: _userName,
              onTap: () {
                // Chuyển hướng đến màn hình chỉnh sửa thông tin người dùng nếu cần
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Số điện thoại',
              value: _userPhoneNumber,
              onTap: () {
                // Chuyển hướng đến màn hình chỉnh sửa thông tin người dùng nếu cần
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            _buildDetailCard(
              title: 'Địa chỉ',
              value: _userAddress,
              onTap: () {
                // Chuyển hướng đến màn hình chỉnh sửa thông tin người dùng nếu cần
              },
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32.0),

            // Nút Đăng tin / Cập nhật tin đăng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0), // Đảm bảo padding nhất quán
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : (_isButtonEnabled() ? _handlePostOrUpdate : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0), // Bo tròn góc nhiều hơn
                    ),
                    elevation: 5, // Thêm độ nổi cho nút
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isEditing ? 'CẬP NHẬT TIN ĐĂNG' : 'ĐĂNG TIN',
                    style: const TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  // --- Các Widget phụ trợ được sửa đổi ---

  // Helper Widget cho header mỗi section (THÔNG TIN XE, ĐĂNG ẢNH, v.v.)
  Widget _buildSectionHeader({required String title, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // Nền xanh nhạt
        borderRadius: BorderRadius.circular(8.0), // Bo tròn góc
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Colors.blue.shade800, // Màu chữ xanh đậm
            ),
          ),
          if (onTap != null) // Chỉ hiển thị nút nếu có onTap
            GestureDetector(
              onTap: onTap,
              child: Text(
                'Thu gọn ^', // Có thể thay đổi thành "Mở rộng" dựa vào trạng thái
                style: TextStyle(color: Colors.blue.shade700, fontSize: 14.0),
              ),
            ),
        ],
      ),
    );
  }

  // Helper Widget cho thumbnail ảnh trong phần Đăng ảnh & Video xe
  Widget _buildImageThumbnail({required Image image, required VoidCallback onRemove}) {
    return Container(
      width: 100, // Kích thước cố định cho ô ảnh
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: image,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade600, // Màu đỏ đậm
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                padding: const EdgeInsets.all(3), // Padding nhỏ hơn
                child: const Icon(Icons.close, color: Colors.white, size: 16), // Icon nhỏ hơn
              ),
            ),
          ),
        ],
      ),
    );
  }
}