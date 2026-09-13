import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';

class BodyShapeScreen extends StatefulWidget {
  const BodyShapeScreen({super.key});

  @override
  State<BodyShapeScreen> createState() => _BodyShapeScreenState();
}

class _BodyShapeScreenState extends State<BodyShapeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shoulderController = TextEditingController();
  final _bustController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _resultShape;
  String? _resultExplanation;

  @override
  void dispose() {
    _shoulderController.dispose();
    _bustController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultShape = null;
      _resultExplanation = null;
    });

    try {
      final result = await ApiService.calculateBodyShape(
        shoulderWidth: double.parse(_shoulderController.text),
        bustWidth: double.parse(_bustController.text),
        waistWidth: double.parse(_waistController.text),
        hipWidth: double.parse(_hipController.text),
      );
      setState(() {
        _resultShape = result.shape;
        _resultExplanation = result.explanation;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateMeasurement(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Shape Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Measure with a tape measure (cm) and enter the widths below. '
                'This stays saved so future outfit suggestions can use it automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _shoulderController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Shoulder width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bustController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Bust/Chest width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _waistController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Waist width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hipController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Hip width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 8),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _calculate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                      )
                    : const Text('Calculate Body Shape'),
              ),

              if (_resultShape != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resultShape!.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(_resultExplanation!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
