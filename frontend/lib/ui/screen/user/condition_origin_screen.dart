import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConditionOriginScreen extends StatefulWidget {
  final String brandId;
  final int modelId;
  final String modelName;
  final String selectedYear;
  final Map<String, dynamic>? initialData;
  final String? initialCondition;
  final String? initialOrigin;
  final int? initialMileage;

  const ConditionOriginScreen({
    super.key,
    required this.brandId,
    required this.modelId,
    required this.modelName,
    required this.selectedYear,
    this.initialData,
    this.initialCondition,
    this.initialOrigin,
    this.initialMileage,
  });

  @override
  State<ConditionOriginScreen> createState() => _ConditionOriginScreenState();
}

class _ConditionOriginScreenState extends State<ConditionOriginScreen> {
  String? condition;
  String? origin;
  TextEditingController mileageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    condition = widget.initialCondition;
    origin = widget.initialOrigin;
    if (widget.initialMileage != null && widget.initialMileage != 0) {
      mileageController.text = widget.initialMileage.toString();
    }
    mileageController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    mileageController.removeListener(_updateButtonState);
    mileageController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool _isButtonEnabled() {
    if (condition == null || origin == null) {
      return false;
    }
    if (condition == 'Cũ' && mileageController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tình trạng & Xuất xứ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần Tình trạng xe
            Text(
              'Tình trạng xe*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Xe cũ'),
                    value: 'Cũ',
                    groupValue: condition,
                    onChanged: (value) {
                      setState(() {
                        condition = value;
                      });
                    },
                    activeColor: Colors.blue, // Đặt màu cho radio button khi được chọn
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Xe mới'),
                    value: 'Mới',
                    groupValue: condition,
                    onChanged: (value) {
                      setState(() {
                        condition = value;
                      });
                    },
                    activeColor: Colors.blue, // Đặt màu cho radio button khi được chọn
                  ),
                ],
              ),
            ),
            if (condition == 'Cũ')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: mileageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số km đã đi*',
                    hintText: 'Ví dụ: 50000',
                    border: OutlineInputBorder(),
                    suffixText: 'km',
                    // Đặt màu cho viền khi focus và màu label khi focus
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    labelStyle: TextStyle(color: Colors.blue), // Màu của label text khi focus
                  ),
                  cursorColor: Colors.blue, // Màu của con trỏ khi nhập
                ),
              ),
            const SizedBox(height: 24),
            // Phần Xuất xứ
            Text(
              'Xuất xứ*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Trong nước'),
                    value: 'Trong nước',
                    groupValue: origin,
                    onChanged: (value) {
                      setState(() {
                        origin = value;
                      });
                    },
                    activeColor: Colors.blue, // Đặt màu cho radio button khi được chọn
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Nhập khẩu'),
                    value: 'Nhập khẩu',
                    groupValue: origin,
                    onChanged: (value) {
                      setState(() {
                        origin = value;
                      });
                    },
                    activeColor: Colors.blue, // Đặt màu cho radio button khi được chọn
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled()
                    ? () {
                  String selectedCondition = condition!;
                  String selectedOrigin = origin!;
                  int? mileage = condition == 'Cũ'
                      ? int.tryParse(mileageController.text) : 0;
                  if (condition == 'Cũ' && (mileage == null || mileage <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập số km đã đi hợp lệ.')),
                    );
                    return;
                  }

                  context.go(
                    '/sell/fuel-transmission',
                    extra: {
                      'brandId': widget.brandId,
                      'modelId': widget.modelId,
                      'modelName': widget.modelName,
                      'selectedYear': widget.selectedYear,
                      'condition': selectedCondition,
                      'origin': selectedOrigin,
                      'mileage': mileage ?? 0,
                      'initialData': {
                        ...widget.initialData ?? {},
                        'condition': selectedCondition,
                        'origin': selectedOrigin,
                        'mileage': mileage ?? 0,
                      },
                      'initialFuelType': widget.initialData?['fuelType'],
                      'initialTransmission': widget.initialData?['transmission'],
                    },
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}