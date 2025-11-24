import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('car_types').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final car_types = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("Tên loại xe")),
            ],
            rows: car_types.map((cartype) {
              final data = cartype.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(cartype.id)),
                DataCell(Text(data['name'] ?? '')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
