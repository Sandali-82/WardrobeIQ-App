import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingDetails = false;
  bool _isSavingPassword = false;
  String? _detailsError;
  String? _detailsSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  bool _outfitReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentInfo();
    _loadNotificationPref();
  }

  Future<void> _loadCurrentInfo() async {
    final info = await ApiService.getSavedUserInfo();
    _nameController.text = info.name ?? '';
    _emailController.text = info.email ?? '';
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _outfitReminderEnabled = prefs.getBool('outfitReminderEnabled') ?? true;
    });
  }

  Future<void> _toggleNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('outfitReminderEnabled', value);
    setState(() => _outfitReminderEnabled = value);

    // Turning reminders off should also clear anything already scheduled,
    // otherwise previously scheduled reminders would still fire.
    if (!value) {
      await NotificationService.cancelAll();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_detailsFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingDetails = true;
      _detailsError = null;
      _detailsSuccess = null;
    });

    try {
      await ApiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      setState(() => _detailsSuccess = 'Profile updated.');
    } catch (e) {
      setState(() => _detailsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSavingDetails = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await ApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      setState(() => _passwordSuccess = 'Password changed.');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() => _passwordError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Account Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Form(
              key: _detailsFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  if (_detailsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_detailsError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  if (_detailsSuccess != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_detailsSuccess!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingDetails ? null : _saveDetails,
                    child: _isSavingDetails
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : const Text('Save Details'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 20),

            Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                    validator: (v) {
                      if (v != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_passwordError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  if (_passwordSuccess != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_passwordSuccess!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _isSavingPassword ? null : _savePassword,
                    child: _isSavingPassword
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Text('Change Password'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            const Divider(),
            const SizedBox(height: 20),

            Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              color: AppColors.surface,
              child: SwitchListTile(
                title: const Text('Outfit reminders'),
                subtitle: const Text('Get a reminder for outfits scheduled on your calendar'),
                value: _outfitReminderEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: _toggleNotificationPref,
              ),
            ),
          ],
        ),
      ),
    );
  }
}