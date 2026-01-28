import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostManagementScreen extends StatelessWidget {
  const PostManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("Tiêu đề")),
              DataColumn(label: Text("Giá")),
              DataColumn(label: Text("Trạng thái")),
            ],
            rows: posts.map((post) {
              final data = post.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(post.id)),
                DataCell(Text(data['title'] ?? '')),
                DataCell(Text(data['price']?.toString() ?? '')),
                DataCell(Text(data['status'] ?? 'Chờ duyệt')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
