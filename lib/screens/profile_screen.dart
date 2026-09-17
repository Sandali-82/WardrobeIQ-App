import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import 'face_shape_screen.dart';
import 'body_shape_screen.dart';
import 'undertone_screen.dart';
import 'styling_guide_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _faceShape;
  String? _bodyShape;
  String? _undertone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFactors();
  }

  Future<void> _loadSavedFactors() async {
    final results = await Future.wait([
      ApiService.getSavedFaceShape(),
      ApiService.getSavedBodyShape(),
      ApiService.getSavedUndertone(),
    ]);
    if (!mounted) return;
    setState(() {
      _faceShape = results[0];
      _bodyShape = results[1];
      _undertone = results[2];
      _isLoading = false;
    });
  }

  Future<void> _openFaceShape() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FaceShapeScreen()),
    );
    _loadSavedFactors();
  }

  Future<void> _openBodyShape() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BodyShapeScreen()),
    );
    _loadSavedFactors();
  }

  Future<void> _openUndertone() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UndertoneScreen()),
    );
    _loadSavedFactors();
  }

  void _openStylingGuide() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StylingGuideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Style Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileFactorTile(
                  icon: Icons.face_retouching_natural,
                  title: 'Face Shape',
                  value: _faceShape,
                  onTap: _openFaceShape,
                ),
                const SizedBox(height: 12),
                _ProfileFactorTile(
                  icon: Icons.accessibility_new,
                  title: 'Body Shape',
                  value: _bodyShape,
                  onTap: _openBodyShape,
                ),
                const SizedBox(height: 12),
                _ProfileFactorTile(
                  icon: Icons.palette,
                  title: 'Skin Undertone',
                  value: _undertone,
                  onTap: _openUndertone,
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.surface,
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome, color: AppColors.aiHighlight),
                    title: const Text('My Styling Guide'),
                    subtitle: const Text('Necklines, hairstyles, colors & more'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: _openStylingGuide,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileFactorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const _ProfileFactorTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(
          value != null ? value!.toUpperCase() : 'Not calculated yet - tap to add',
          style: TextStyle(color: value != null ? AppColors.textPrimary : AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
