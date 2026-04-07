import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

// ── Canonical category values ─────────────────────────────────────────────────
// These are the ONLY values stored in the DB.
// The filter screen uses the same list to build chips.
// Never change these unless you also migrate existing DB rows.
const List<String> kCategoryDbValues = [
  'Vẽ',
  'Thủ công',
  'Màu nước',
  'Chân dung',
];

// Matching i18n keys — same order as kCategoryDbValues
const List<String> kCategoryI18nKeys = [
  'cat_draw',
  'cat_craft',
  'cat_watercolor',
  'cat_portrait',
];

// ── Canonical difficulty values ───────────────────────────────────────────────
const List<String> kDifficultyDbValues = ['Dễ', 'Trung bình', 'Khó'];
const List<String> kDifficultyI18nKeys = ['diff_easy', 'diff_medium', 'diff_hard'];

// ─────────────────────────────────────────────────────────────────────────────

class CreateTutorialScreen extends StatefulWidget {
  const CreateTutorialScreen({super.key});
  @override
  State<CreateTutorialScreen> createState() => _CreateTutorialScreenState();
}

class _CreateTutorialScreenState extends State<CreateTutorialScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();

  // Dropdown selections — always one of the canonical values above
  String? _selectedCategory;
  String? _selectedDifficulty;

  File? _thumb;
  final List<_StepModel>     _steps = [];
  final List<_MaterialModel> _mats  = [];
  bool _loading = false;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Image pickers ───────────────────────────────────────────────────────────

  Future<void> _pickThumb() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null && mounted) setState(() => _thumb = File(p.path));
  }

  Future<void> _pickStepImg(int index) async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null && mounted) setState(() => _steps[index].imageFile = File(p.path));
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit(AppProvider app) async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumb == null) {
      NotificationService.showError(app.t('need_thumbnail'));
      return;
    }
    if (_steps.isEmpty) {
      NotificationService.showError(app.t('need_steps'));
      return;
    }
    // _selectedCategory is guaranteed non-null by the dropdown validator,
    // but guard here for safety.
    if (_selectedCategory == null) {
      NotificationService.showError(app.language == AppLanguage.en
          ? 'Please select a category'
          : 'Vui lòng chọn danh mục');
      return;
    }

    setState(() => _loading = true);

    try {
      final thumbB64 = 'data:image/png;base64,${base64Encode(await _thumb!.readAsBytes())}';

      final stepsData = <Map<String, dynamic>>[];
      for (final s in _steps) {
        String? imgB64;
        if (s.imageFile != null) {
          imgB64 = 'data:image/png;base64,${base64Encode(await s.imageFile!.readAsBytes())}';
        }
        stepsData.add({
          'step_order': s.stepOrder,
          'title':      s.title,
          'content':    s.content,
          'image_url':  imgB64,
        });
      }

      final materialsData = _mats.map((m) => {
        'name':     m.name,
        'quantity': m.quantity,
        'note':     m.note,
      }).toList();

      final res = await _api.post('/tutorials', {
        'title':            _titleCtrl.text.trim(),
        'category':         _selectedCategory,    // canonical Vietnamese DB value
        'description':      _descCtrl.text.trim(),
        'thumbnail_url':    thumbB64,
        'difficulty_level': _selectedDifficulty,  // canonical Vietnamese DB value or null
        'steps':            stepsData,
        'materials':        materialsData,
      });

      if (res.statusCode == 201) {
        NotificationService.showSuccess(app.t('tut_success'));
        if (mounted) Navigator.pop(context, true);
      } else {
        NotificationService.showError(app.t('tut_fail'));
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final app         = context.watch<AppProvider>();
    final isDark      = app.isDarkMode;
    final bgColor     = isDark ? AppColors.darkBackground   : AppColors.background;
    final surfColor   = isDark ? AppColors.darkSurface      : Colors.white;
    final textColor   = isDark ? AppColors.darkText         : AppColors.text;
    final subColor    = isDark ? AppColors.darkTextLight    : AppColors.textLight;
    final borderColor = isDark ? AppColors.darkBorder       : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          app.t('create_tut_title'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
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
              _buildThumbnail(app, isDark, subColor, borderColor),
              const SizedBox(height: 16),

              _field(app.t('tut_title_field'), _titleCtrl, textColor, subColor, surfColor, borderColor,
                  validator: (v) => v!.trim().isNotEmpty ? null : 'Required'),
              const SizedBox(height: 12),

              _buildCategoryDropdown(app, surfColor, textColor, subColor, borderColor),
              const SizedBox(height: 12),

              _field(app.t('tut_desc'), _descCtrl, textColor, subColor, surfColor, borderColor, maxLines: 3),
              const SizedBox(height: 12),

              _buildDifficultyDropdown(app, surfColor, textColor, subColor, borderColor),
              const SizedBox(height: 24),

              _sectionHeader(app.t('tut_steps'), textColor,
                  onAdd: () => setState(() =>
                      _steps.add(_StepModel(stepOrder: _steps.length + 1)))),
              ..._steps.asMap().entries.map((e) =>
                  _buildStepCard(e.key, e.value, app, surfColor, textColor, subColor, borderColor)),

              const SizedBox(height: 16),

              _sectionHeader(app.t('tut_materials'), textColor,
                  onAdd: () => setState(() => _mats.add(_MaterialModel()))),
              ..._mats.asMap().entries.map((e) =>
                  _buildMaterialCard(e.key, e.value, app, surfColor, textColor, subColor, borderColor)),

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
                  child: Text(
                    app.t('tut_submit'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildThumbnail(AppProvider app, bool isDark, Color subColor, Color borderColor) {
    return GestureDetector(
      onTap: _pickThumb,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          image: _thumb != null
              ? DecorationImage(image: FileImage(_thumb!), fit: BoxFit.cover)
              : null,
        ),
        child: _thumb == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_rounded, size: 40, color: subColor),
          const SizedBox(height: 4),
          Text(app.t('select_thumbnail'), style: TextStyle(color: subColor, fontSize: 13)),
        ])
            : null,
      ),
    );
  }

  Widget _buildCategoryDropdown(
      AppProvider app, Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _deco(app.t('tut_category_label'), subColor, surfColor, borderColor),
      dropdownColor: surfColor,
      style: TextStyle(color: textColor, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
      // Build items directly from the two parallel lists — no external class needed
      items: List.generate(kCategoryDbValues.length, (i) {
        return DropdownMenuItem<String>(
          value: kCategoryDbValues[i],
          child: Text(app.t(kCategoryI18nKeys[i]), style: TextStyle(color: textColor)),
        );
      }),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v != null
          ? null
          : (app.language == AppLanguage.en ? 'Required' : 'Vui lòng chọn'),
    );
  }

  Widget _buildDifficultyDropdown(
      AppProvider app, Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: _deco(app.t('tut_difficulty_label'), subColor, surfColor, borderColor),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
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

  Widget _buildStepCard(
      int idx, _StepModel s, AppProvider app,
      Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return Card(
      color: surfColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 0.5)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Center(child: Text('${s.stepOrder}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 8),
            Text('${app.t("tut_step_n")} ${s.stepOrder}',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              onPressed: () => setState(() {
                _steps.removeAt(idx);
                for (int j = 0; j < _steps.length; j++) _steps[j].stepOrder = j + 1;
              }),
            ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: s.title,
            onChanged: (v) => s.title = v,
            style: TextStyle(color: textColor),
            decoration: _deco(app.t('tut_step_title'), subColor, surfColor, borderColor),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: s.content,
            onChanged: (v) => s.content = v,
            style: TextStyle(color: textColor),
            maxLines: 3,
            decoration: _deco(app.t('tut_step_content'), subColor, surfColor, borderColor),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickStepImg(idx),
            child: Container(
              height: 90, width: double.infinity,
              decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor)),
              child: s.imageFile != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(s.imageFile!, fit: BoxFit.cover))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_rounded, size: 18, color: subColor),
                const SizedBox(width: 6),
                Text(app.t('tut_step_img'), style: TextStyle(color: subColor, fontSize: 12)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMaterialCard(
      int idx, _MaterialModel m, AppProvider app,
      Color surfColor, Color textColor, Color subColor, Color borderColor) {
    return Card(
      color: surfColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 0.5)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(children: [
          Expanded(child: TextFormField(
            initialValue: m.name,
            onChanged: (v) => m.name = v,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: _deco(app.t('mat_name'), subColor, surfColor, borderColor),
          )),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: TextFormField(
            initialValue: m.quantity,
            onChanged: (v) => m.quantity = v,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: _deco(app.t('mat_qty'), subColor, surfColor, borderColor),
          )),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            onPressed: () => setState(() => _mats.removeAt(idx)),
          ),
        ]),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _StepModel {
  int stepOrder;
  String title   = '';
  String content = '';
  File? imageFile;
  _StepModel({required this.stepOrder});
}

class _MaterialModel {
  String name     = '';
  String quantity = '';
  String note     = '';
}