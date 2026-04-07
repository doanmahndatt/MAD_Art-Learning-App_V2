import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';
import 'create_tutorial_screen.dart';

class EditTutorialScreen extends StatefulWidget {
  final Map<String, dynamic> tutorial;
  const EditTutorialScreen({super.key, required this.tutorial});

  @override
  State<EditTutorialScreen> createState() => _EditTutorialScreenState();
}

class _EditTutorialScreenState extends State<EditTutorialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedDifficulty;
  File? _thumb;
  String? _existingThumbUrl;
  final List<_EditStepModel> _steps = [];
  final List<_EditMaterialModel> _mats = [];
  bool _loading = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    final t = widget.tutorial;
    _titleCtrl.text = t['title'] ?? '';
    _descCtrl.text = t['description'] ?? '';
    _selectedCategory = t['category'];
    _selectedDifficulty = t['difficulty_level'];
    _existingThumbUrl = t['thumbnail_url'];

    for (final step in (t['steps'] as List? ?? [])) {
      _steps.add(_EditStepModel(
        stepOrder: step['step_order'] ?? (_steps.length + 1),
        title: step['title'] ?? '',
        content: step['content'] ?? '',
        existingImageUrl: step['image_url'],
      ));
    }
    for (final material in (t['materials'] as List? ?? [])) {
      _mats.add(_EditMaterialModel(
        name: material['name'] ?? '',
        quantity: material['quantity'] ?? '',
        note: material['note'] ?? '',
      ));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumb() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null && mounted) setState(() => _thumb = File(p.path));
  }

  Future<void> _pickStepImg(int index) async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null && mounted) setState(() => _steps[index].imageFile = File(p.path));
  }

  Future<String?> _resolveThumbBase64() async {
    if (_thumb != null) {
      return 'data:image/png;base64,${base64Encode(await _thumb!.readAsBytes())}';
    }
    return _existingThumbUrl;
  }

  Future<void> _submit(AppProvider app) async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      NotificationService.showError(app.t('need_steps'));
      return;
    }
    if (_selectedCategory == null) {
      NotificationService.showError(app.language == AppLanguage.en ? 'Please select a category' : 'Vui lòng chọn danh mục');
      return;
    }

    setState(() => _loading = true);
    try {
      final thumbB64 = await _resolveThumbBase64();
      final stepsData = <Map<String, dynamic>>[];
      for (final s in _steps) {
        String? imgB64 = s.existingImageUrl;
        if (s.imageFile != null) {
          imgB64 = 'data:image/png;base64,${base64Encode(await s.imageFile!.readAsBytes())}';
        }
        stepsData.add({
          'step_order': s.stepOrder,
          'title': s.title,
          'content': s.content,
          'image_url': imgB64,
        });
      }

      final materialsData = _mats
          .map((m) => {
        'name': m.name,
        'quantity': m.quantity,
        'note': m.note,
      })
          .toList();

      final res = await _api.put('/tutorials/${widget.tutorial['id']}', {
        'title': _titleCtrl.text.trim(),
        'category': _selectedCategory,
        'description': _descCtrl.text.trim(),
        'thumbnail_url': thumbB64,
        'difficulty_level': _selectedDifficulty,
        'steps': stepsData,
        'materials': materialsData,
      });

      if (res.statusCode == 200) {
        NotificationService.showSuccess('Tutorial updated successfully');
        if (mounted) Navigator.pop(context, true);
      } else {
        NotificationService.showError('Failed to update tutorial');
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final subColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit tutorial', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(isDark, subColor, borderColor),
              const SizedBox(height: 16),
              _field('Title', _titleCtrl, textColor, subColor, surfColor, borderColor,
                  validator: (v) => v!.trim().isNotEmpty ? null : 'Required'),
              const SizedBox(height: 12),
              _buildCategoryDropdown(app, surfColor, textColor, subColor, borderColor),
              const SizedBox(height: 12),
              _field('Description', _descCtrl, textColor, subColor, surfColor, borderColor,
                  maxLines: 3),
              const SizedBox(height: 12),
              _buildDifficultyDropdown(app, surfColor, textColor, subColor, borderColor),
              const SizedBox(height: 24),
              _sectionHeader('Steps', textColor,
                  onAdd: () => setState(() => _steps.add(_EditStepModel(stepOrder: _steps.length + 1)))),
              ..._steps.asMap().entries.map((e) =>
                  _buildStepCard(e.key, e.value, app, surfColor, textColor, subColor, borderColor)),
              const SizedBox(height: 16),
              _sectionHeader('Materials', textColor,
                  onAdd: () => setState(() => _mats.add(_EditMaterialModel()))),
              ..._mats.asMap().entries.map((e) =>
                  _buildMaterialCard(e.key, e.value, surfColor, textColor, subColor, borderColor)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _submit(app),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Update tutorial',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark, Color subColor, Color borderColor) {
    final imageProvider = _thumb != null
        ? FileImage(_thumb!) as ImageProvider
        : (_existingThumbUrl != null && _existingThumbUrl!.isNotEmpty
        ? (_existingThumbUrl!.startsWith('data:image')
        ? MemoryImage(base64Decode(_existingThumbUrl!.split(',').last))
        : NetworkImage(_existingThumbUrl!)) as ImageProvider
        : null);

    return GestureDetector(
      onTap: _pickThumb,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
        ),
        child: imageProvider == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_rounded, size: 40, color: subColor),
          const SizedBox(height: 4),
          Text('Select thumbnail', style: TextStyle(color: subColor, fontSize: 13)),
        ])
            : null,
      ),
    );
  }

  Widget _buildCategoryDropdown(
      AppProvider app, Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _deco('Category', subColor, surfColor, borderColor),
      dropdownColor: surfColor,
      style: TextStyle(color: textColor, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
      items: List.generate(kCategoryDbValues.length, (i) {
        return DropdownMenuItem<String>(
          value: kCategoryDbValues[i],
          child: Text(app.t(kCategoryI18nKeys[i]), style: TextStyle(color: textColor)),
        );
      }),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v != null ? null : 'Required',
    );
  }

  Widget _buildDifficultyDropdown(
      AppProvider app, Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: _deco('Difficulty', subColor, surfColor, borderColor),
      dropdownColor: surfColor,
      style: TextStyle(color: textColor, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
      items: List.generate(kDifficultyDbValues.length, (i) {
        return DropdownMenuItem<String>(
          value: kDifficultyDbValues[i],
          child: Text(app.t(kDifficultyI18nKeys[i]), style: TextStyle(color: textColor)),
        );
      }),
      onChanged: (v) => setState(() => _selectedDifficulty = v),
    );
  }

  Widget _field(
      String label,
      TextEditingController ctrl,
      Color textColor,
      Color subColor,
      Color surfColor,
      Color borderColor, {
        int maxLines = 1,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: ctrl,
      style: TextStyle(color: textColor),
      maxLines: maxLines,
      decoration: _deco(label, subColor, surfColor, borderColor),
      validator: validator,
    );
  }

  InputDecoration _deco(String label, Color subColor, Color surfColor, Color borderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: subColor),
      filled: true,
      fillColor: surfColor,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  Widget _sectionHeader(String title, Color textColor, {required VoidCallback onAdd}) {
    return Row(children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
      const Spacer(),
      IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
      ),
    ]);
  }

  Widget _buildStepCard(int idx, _EditStepModel s, AppProvider app, Color surfColor, Color textColor,
      Color subColor, Color borderColor) {
    final imageProvider = s.imageFile != null
        ? FileImage(s.imageFile!) as ImageProvider
        : (s.existingImageUrl != null && s.existingImageUrl!.isNotEmpty
        ? (s.existingImageUrl!.startsWith('data:image')
        ? MemoryImage(base64Decode(s.existingImageUrl!.split(',').last))
        : NetworkImage(s.existingImageUrl!)) as ImageProvider
        : null);

    return Card(
      color: surfColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: 0.5)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                  child: Text('${s.stepOrder}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
            Text('Step ${s.stepOrder}', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              onPressed: () => setState(() {
                _steps.removeAt(idx);
                for (int j = 0; j < _steps.length; j++) {
                  _steps[j].stepOrder = j + 1;
                }
              }),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: s.title,
            onChanged: (v) => s.title = v,
            style: TextStyle(color: textColor),
            decoration: _deco('Step title', subColor, surfColor, borderColor),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: s.content,
            onChanged: (v) => s.content = v,
            style: TextStyle(color: textColor),
            maxLines: 3,
            decoration: _deco('Step content', subColor, surfColor, borderColor),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickStepImg(idx),
            child: Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
                image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
              ),
              child: imageProvider == null
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_rounded, size: 18, color: subColor),
                const SizedBox(width: 6),
                Text('Select step image', style: TextStyle(color: subColor, fontSize: 12)),
              ])
                  : null,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMaterialCard(
      int idx, _EditMaterialModel m, Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return Card(
      color: surfColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: 0.5)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(children: [
          Expanded(
            child: TextFormField(
              initialValue: m.name,
              onChanged: (v) => m.name = v,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: _deco('Material', subColor, surfColor, borderColor),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: m.quantity,
              onChanged: (v) => m.quantity = v,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: _deco('Qty', subColor, surfColor, borderColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            onPressed: () => setState(() => _mats.removeAt(idx)),
          ),
        ]),
      ),
    );
  }
}

class _EditStepModel {
  int stepOrder;
  String title;
  String content;
  File? imageFile;
  String? existingImageUrl;
  _EditStepModel({required this.stepOrder, this.title = '', this.content = '', this.existingImageUrl});
}

class _EditMaterialModel {
  String name;
  String quantity;
  String note;
  _EditMaterialModel({this.name = '', this.quantity = '', this.note = ''});
}
