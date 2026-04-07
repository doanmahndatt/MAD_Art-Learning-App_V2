import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _avatarUrl;
  File? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/profile');
      if (res.statusCode == 200) {
        _nameController.text = res.data['full_name'] ?? '';
        _bioController.text = res.data['bio'] ?? '';
        _avatarUrl = res.data['avatar_url'];
      }
    } catch (e) { print(e); }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      String? newAvatarBase64;
      if (_newAvatarFile != null) {
        final bytes = await _newAvatarFile!.readAsBytes();
        newAvatarBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      }
      try {
        final res = await _api.put('/users/profile', {
          'full_name': _nameController.text,
          'bio': _bioController.text,
          'avatar_url': newAvatarBase64 ?? _avatarUrl,
        });
        if (res.statusCode == 200) {
          NotificationService.showSuccess('Cập nhật thành công');
          Navigator.pop(context, true);
        }
      } catch (e) {
        NotificationService.showError('Lỗi: $e');
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [TextButton(onPressed: _saveProfile, child: const Text('Lưu'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _getAvatarImage(),
                  child: (_newAvatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) => v!.isNotEmpty ? null : 'Không được trống',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Giới thiệu'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_newAvatarFile != null) {
      return FileImage(_newAvatarFile!);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (_avatarUrl!.startsWith('data:image')) {
        final base64String = _avatarUrl!.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } else {
        return NetworkImage(_avatarUrl!);
      }
    }
    return null;
  }
}