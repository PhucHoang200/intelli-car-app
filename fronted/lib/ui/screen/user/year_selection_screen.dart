import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class YearSelectionScreen extends StatefulWidget {
  final String brandId;
  final int modelId;
  final String modelName;
  final String? initialYear;
  final Map<String, dynamic>? initialData;

  const YearSelectionScreen({
    super.key,
    required this.brandId,
    required this.modelId,
    required this.modelName,
    this.initialYear,
    this.initialData,
  });

  @override
  State<YearSelectionScreen> createState() => _YearSelectionScreenState();
}

class _YearSelectionScreenState extends State<YearSelectionScreen> {
  String? _selectedYear;
  final List<String> _years =
  List.generate(50, (index) => (DateTime.now().year - index).toString());

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn năm sản xuất'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Nút quay lại
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder( // Directly use ListView.builder as the body
        itemCount: _years.length,
        itemBuilder: (context, index) {
          final year = _years[index];
          final isSelected = year == _selectedYear;
          return ListTile(
            title: Text(
              year,
              style: TextStyle(
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedYear = year; // Update selected year immediately
              });

              // Navigate to the next screen, passing all data
              final updatedInitialData =
              Map<String, dynamic>.from(widget.initialData ?? {});
              updatedInitialData['selectedYear'] = year; // Pass the selected year directly
              updatedInitialData['brandId'] = widget.brandId;
              updatedInitialData['modelId'] = widget.modelId;
              updatedInitialData['modelName'] = widget.modelName;

              context.push(
                '/sell/condition-origin',
                extra: updatedInitialData,
              );
            },
          );
        },
      ),
    );
  }
}