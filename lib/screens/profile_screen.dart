import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import 'face_shape_screen.dart';
import 'body_shape_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _faceShape;
  String? _bodyShape;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedShapes();
  }

  Future<void> _loadSavedShapes() async {
    final results = await Future.wait([
      ApiService.getSavedFaceShape(),
      ApiService.getSavedBodyShape(),
    ]);
    if (!mounted) return;
    setState(() {
      _faceShape = results[0];
      _bodyShape = results[1];
      _isLoading = false;
    });
  }

  Future<void> _openFaceShape() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FaceShapeScreen()),
    );
    _loadSavedShapes(); // refresh in case it was just calculated
  }

  Future<void> _openBodyShape() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BodyShapeScreen()),
    );
    _loadSavedShapes();
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
