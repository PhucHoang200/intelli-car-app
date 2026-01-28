import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/model_provider.dart';

class ModelListScreen extends StatefulWidget {
  final String brandId;
  final String name;
  final String? selectedModel;
  final Map<String, dynamic>? initialData;

  const ModelListScreen({
    Key? key,
    required this.brandId,
    required this.name,
    this.selectedModel,
    required this.initialData,
  }) : super(key: key);

  @override
  State<ModelListScreen> createState() => _ModelListScreenState();
}

class _ModelListScreenState extends State<ModelListScreen> {
  late Future<void> _fetchFuture;
  String? _highlightedModel;

  @override
  void initState() {
    super.initState();
    _highlightedModel = widget.selectedModel;
    _fetchFuture = Provider.of<ModelProvider>(context, listen: false)
        .fetchModelsByBrandId(widget.brandId);
  }

  @override
  void didUpdateWidget(covariant ModelListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brandId != widget.brandId) {
      // Nếu brandId thay đổi, fetch lại data
      _fetchFuture = Provider.of<ModelProvider>(context, listen: false)
          .fetchModelsByBrandId(widget.brandId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = Provider.of<ModelProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn dòng xe'),
        centerTitle: true,
        actions: const [
        ],
      ),
      body: FutureBuilder<void>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final models = modelProvider.models;
          debugPrint('Models in provider: $models');

          if (models.isEmpty) {
            return const Center(child: Text('No models found.'));
          }

          return ListView.builder(
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              final isHighlighted = model.name == _highlightedModel;

              return ListTile(
                title: Text(
                  model.name,
                  style: TextStyle(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? Theme.of(context).primaryColor : null,
                  ),
                ),
                onTap: () {
                  print('Selected Model: ${model.name}, Brand ID: ${widget.brandId}');
                  context.push(
                    '/sell/year',
                    extra: {
                      'brandId': widget.brandId,
                      'modelId': model.id,
                      'modelName': model.name,
                      'initialYear': widget.initialData?['selectedYear'],
                      'initialData': widget.initialData,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
