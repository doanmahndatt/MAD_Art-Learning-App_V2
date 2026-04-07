import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _avatarUrl;
  File? _newAvatarFile;

  @override void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/users/profile');
      if (r.statusCode == 200) {
        _nameController.text = r.data['full_name'] ?? '';
        _bioController.text  = r.data['bio'] ?? '';
        _avatarUrl = r.data['avatar_url'];
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _newAvatarFile = File(p.path));
  }

  Future<void> _save(AppProvider app) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    String? newB64;
    if (_newAvatarFile != null) {
      newB64 = 'data:image/png;base64,${base64Encode(await _newAvatarFile!.readAsBytes())}';
    }
    try {
      final r = await _api.put('/users/profile', {
        'full_name': _nameController.text,
        'bio': _bioController.text,
        'avatar_url': newB64 ?? _avatarUrl,
      });
      if (r.statusCode == 200) {
        // Refresh AuthProvider so HomeScreen and all screens reflect new name/avatar
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false).refreshUser();
        }
        NotificationService.showSuccess(app.t('update_success'));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) { NotificationService.showError('Error: $e'); }
    setState(() => _loading = false);
  }

  ImageProvider<Object>? _getAvatar() {
    if (_newAvatarFile != null) return FileImage(_newAvatarFile!);
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (_avatarUrl!.startsWith('data:image')) {
        return MemoryImage(base64Decode(_avatarUrl!.split(',').last));
      } else {
        return NetworkImage(_avatarUrl!) as ImageProvider<Object>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : Colors.white;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;
    final subColor  = isDark ? AppColors.darkTextLight  : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(app.t('edit_profile'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => _save(app),
            child: Text(app.t('save'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: _getAvatar(),
                child: (_newAvatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                    ? const Icon(Icons.person, size: 60, color: AppColors.primary) : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: app.t('full_name'),
              labelStyle: TextStyle(color: subColor),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
            validator: (v) => v!.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            style: TextStyle(color: textColor),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: app.t('bio'),
              labelStyle: TextStyle(color: subColor),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ])),
      ),
    );
  }
}