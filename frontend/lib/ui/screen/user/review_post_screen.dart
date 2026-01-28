import 'package:flutter/material.dart';

class ReviewPostScreen extends StatelessWidget {
  // You'll need to pass the data collected so far to this screen
  final Map<String, dynamic> formData;

  const ReviewPostScreen({super.key, required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem lại nội dung tin đăng'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // For now, just go back
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin xe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildInfoRow('Hãng xe:', formData['brand'] ?? ''),
            _buildInfoRow('Dòng xe:', formData['model'] ?? ''),
            _buildInfoRow('Năm SX:', formData['year'] ?? ''),
            // Add more info rows based on your form data
            const SizedBox(height: 16),
            const Text('Giá bán & Mô tả', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildInfoRow('Giá bán:', formData['price'] ?? ''),
            _buildInfoRow('Tiêu đề:', formData['title'] ?? ''),
            _buildInfoRow('Mô tả:', formData['description'] ?? ''),
            // Add more sections as needed
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}