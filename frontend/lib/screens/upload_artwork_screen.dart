import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class UploadArtworkScreen extends StatefulWidget {
  const UploadArtworkScreen({super.key});
  @override State<UploadArtworkScreen> createState() => _UploadArtworkScreenState();
}

class _UploadArtworkScreenState extends State<UploadArtworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;
  bool _isPublic = true, _loading = false;
  final ApiService _api = ApiService();

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _imageFile = File(p.path));
  }

  Future<void> _upload(AppProvider app) async {
    if (_imageFile == null) { NotificationService.showError(app.t('please_select_img')); return; }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final b64 = 'data:image/png;base64,${base64Encode(await _imageFile!.readAsBytes())}';
      final res = await _api.post('/artworks', {'title': _titleController.text, 'description': _descController.text, 'image_url': b64, 'is_public': _isPublic, 'source_type': 'upload'});
      if (res.statusCode == 201) { NotificationService.showSuccess(app.t('upload_success')); Navigator.pop(context, true); }
      else NotificationService.showError(app.t('upload_fail'));
    } catch (e) { NotificationService.showError('Error: $e'); }
    finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : Colors.white;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(app.t('upload_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
        GestureDetector(onTap: _pickImage, child: Container(height: 200, width: double.infinity,
            decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[100], borderRadius: BorderRadius.circular(14),
                image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null),
            child: _imageFile == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_rounded, size: 50, color: isDark ? AppColors.darkTextLight : AppColors.textLight),
              const SizedBox(height: 8),
              // user-generated text — not translated
              Text(app.t('select_image'), style: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight)),
            ]) : null)),
        const SizedBox(height: 16),
        TextFormField(controller: _titleController, style: TextStyle(color: textColor),
            decoration: InputDecoration(labelText: app.t('title_field'), labelStyle: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary))),
            validator: (v) => v!.isNotEmpty ? null : 'Required'),
        const SizedBox(height: 16),
        TextFormField(controller: _descController, style: TextStyle(color: textColor), maxLines: 3,
            decoration: InputDecoration(labelText: app.t('desc_field'), labelStyle: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)))),
        const SizedBox(height: 12),
        SwitchListTile(title: Text(app.t('public_toggle'), style: TextStyle(color: textColor)), value: _isPublic, activeColor: AppColors.primary, onChanged: (v) => setState(() => _isPublic = v)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => _upload(app),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(app.t('upload_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      ]))),
    );
  }
}