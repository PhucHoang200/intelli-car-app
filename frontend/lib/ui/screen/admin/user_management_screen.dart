import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Vai trò")),
            ],
            rows: users.map((user) {
              final data = user.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(user.id)),
                DataCell(Text(data['email'] ?? '')),
                DataCell(Text(data['role'] ?? '')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
