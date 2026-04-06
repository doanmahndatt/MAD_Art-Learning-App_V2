import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class UploadArtworkScreen extends StatefulWidget {
  const UploadArtworkScreen({super.key});

  @override
  State<UploadArtworkScreen> createState() => _UploadArtworkScreenState();
}

class _UploadArtworkScreenState extends State<UploadArtworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hashtagController = TextEditingController();
  File? _imageFile;
  bool _isPublic = true;
  bool _loading = false;
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _uploadArtwork() async {
    if (_imageFile == null) {
      NotificationService.showError('Vui lòng chọn ảnh');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Chuyển ảnh sang base64 (tạm thời, nên dùng multipart trong thực tế)
    String base64Image = '';
    if (_imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = 'data:image/png;base64,${base64Encode(imageBytes)}';
    }

    try {
      final res = await _api.post('/artworks', {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'image_url': base64Image,
        'is_public': _isPublic,
        'source_type': 'upload',
      });
      if (res.statusCode == 201) {
        NotificationService.showSuccess('Đăng tác phẩm thành công!');
        Navigator.pop(context, true);
      } else {
        NotificationService.showError('Đăng thất bại, vui lòng thử lại');
      }
    } catch (e) {
      NotificationService.showError('Lỗi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tác phẩm mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Chạm để chọn ảnh'),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                validator: (v) => v!.isNotEmpty ? null : 'Không được để trống',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hashtagController,
                decoration: const InputDecoration(labelText: 'Hashtag (cách nhau bằng dấu cách)'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Công khai'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _uploadArtwork,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Đăng', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}