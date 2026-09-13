import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';

class FaceShapeScreen extends StatefulWidget {
  const FaceShapeScreen({super.key});

  @override
  State<FaceShapeScreen> createState() => _FaceShapeScreenState();
}

class _FaceShapeScreenState extends State<FaceShapeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foreheadController = TextEditingController();
  final _cheekboneController = TextEditingController();
  final _jawlineController = TextEditingController();
  final _lengthController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _resultShape;
  String? _resultExplanation;

  @override
  void dispose() {
    _foreheadController.dispose();
    _cheekboneController.dispose();
    _jawlineController.dispose();
    _lengthController.dispose();
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
      final result = await ApiService.calculateFaceShape(
        foreheadWidth: double.parse(_foreheadController.text),
        cheekboneWidth: double.parse(_cheekboneController.text),
        jawlineWidth: double.parse(_jawlineController.text),
        faceLength: double.parse(_lengthController.text),
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
      appBar: AppBar(title: const Text('Face Shape Calculator')),
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
                controller: _foreheadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Forehead width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cheekboneController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cheekbone width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _jawlineController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Jawline width (cm)'),
                validator: _validateMeasurement,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lengthController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Face length (cm)'),
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
                    : const Text('Calculate Face Shape'),
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
