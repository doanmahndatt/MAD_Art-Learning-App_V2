import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class EditArtworkScreen extends StatefulWidget {
  final Map<String, dynamic> artwork;
  const EditArtworkScreen({super.key, required this.artwork});

  @override
  State<EditArtworkScreen> createState() => _EditArtworkScreenState();
}

class _EditArtworkScreenState extends State<EditArtworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;
  String? _existingImageUrl;
  bool _isPublic = true;
  bool _loading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.artwork['title'] ?? '';
    _descController.text = widget.artwork['description'] ?? '';
    _existingImageUrl = widget.artwork['image_url'];
    _isPublic = widget.artwork['is_public'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null && mounted) setState(() => _imageFile = File(p.path));
  }

  Future<String?> _resolveImageData() async {
    if (_imageFile != null) {
      return 'data:image/png;base64,${base64Encode(await _imageFile!.readAsBytes())}';
    }
    return _existingImageUrl;
  }

  Future<void> _update(AppProvider app) async {
    if (!_formKey.currentState!.validate()) return;
    final imageData = await _resolveImageData();
    if (imageData == null || imageData.isEmpty) {
      NotificationService.showError(app.t('please_select_img'));
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _api.put('/artworks/${widget.artwork['id']}', {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'image_url': imageData,
        'is_public': _isPublic,
        'source_type': widget.artwork['source_type'] ?? 'upload',
      });
      if (res.statusCode == 200) {
        NotificationService.showSuccess('Artwork updated successfully');
        if (mounted) Navigator.pop(context, true);
      } else {
        NotificationService.showError('Failed to update artwork');
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DecorationImage _buildImagePreview() {
    if (_imageFile != null) {
      return DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover);
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      if (_existingImageUrl!.startsWith('data:image')) {
        return DecorationImage(
          image: MemoryImage(base64Decode(_existingImageUrl!.split(',').last)),
          fit: BoxFit.cover,
        );
      }
      return DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover);
    }
    throw StateError('No image available');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    final hasImage = _imageFile != null || ((_existingImageUrl ?? '').isNotEmpty);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit artwork', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
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
                    color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    image: hasImage ? _buildImagePreview() : null,
                  ),
                  child: !hasImage
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 50,
                          color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                      const SizedBox(height: 8),
                      Text('Select image',
                          style: TextStyle(
                              color: isDark ? AppColors.darkTextLight : AppColors.textLight)),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle:
                  TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary)),
                ),
                validator: (v) => v!.trim().isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                style: TextStyle(color: textColor),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle:
                  TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text('Public artwork', style: TextStyle(color: textColor)),
                value: _isPublic,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isPublic = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _update(app),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Update artwork',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
