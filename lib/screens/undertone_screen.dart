import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../repositories/profile_repository.dart';
import '../services/photo_picker.dart';

class UndertoneScreen extends StatefulWidget {
  const UndertoneScreen({super.key});

  @override
  State<UndertoneScreen> createState() => _UndertoneScreenState();
}

class _UndertoneScreenState extends State<UndertoneScreen> {
  PickedPhoto? _photo;
  bool _isAnalyzing = false;
  String? _errorMessage;
  String? _resultUndertone;
  String? _resultExplanation;

  Future<void> _pickImage(PhotoSource source) async {
    final picked = await PhotoPicker.instance.pick(source);
    if (picked == null || !mounted) return;

    setState(() {
      _photo = picked;
      _resultUndertone = null;
      _resultExplanation = null;
      _errorMessage = null;
    });
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(PhotoSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(PhotoSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    final photo = _photo;
    if (photo == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await ProfileRepository.instance.analyzeUndertone(
        imageBase64: base64Encode(photo.bytes),
        mimeType: photo.mimeType,
      );

      setState(() {
        _resultUndertone = result.undertone;
        _resultExplanation = result.explanation;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skin Undertone')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Take or choose a clear, well-lit photo of your face, neck, or inner wrist. '
              'This is analyzed once and saved - future outfit suggestions will use it automatically.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _showSourcePicker,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                ),
                child: _photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _photo!.bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select a photo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),

            ElevatedButton(
              onPressed: _photo == null || _isAnalyzing ? null : _analyze,
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : const Text('Analyze Undertone'),
            ),

            if (_resultUndertone != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.aiHighlight.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.aiHighlight, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _resultUndertone!.toUpperCase(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.aiHighlight),
                        ),
                      ],
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
    );
  }
}