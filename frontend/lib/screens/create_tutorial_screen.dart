import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class CreateTutorialScreen extends StatefulWidget {
  const CreateTutorialScreen({super.key});

  @override
  State<CreateTutorialScreen> createState() => _CreateTutorialScreenState();
}

class _CreateTutorialScreenState extends State<CreateTutorialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _difficultyController = TextEditingController();
  File? _thumbnailFile;
  List<StepModel> _steps = [];
  List<MaterialModel> _materials = [];
  bool _loading = false;
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  void _addStep() {
    setState(() {
      _steps.add(StepModel(stepOrder: _steps.length + 1, title: '', content: '', imageFile: null));
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      for (int i = 0; i < _steps.length; i++) {
        _steps[i].stepOrder = i + 1;
      }
    });
  }

  void _addMaterial() {
    setState(() {
      _materials.add(MaterialModel(name: '', quantity: '', note: ''));
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _materials.removeAt(index);
    });
  }

  Future<void> _pickThumbnail() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _thumbnailFile = File(picked.path));
  }

  Future<void> _pickStepImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _steps[index].imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitTutorial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnailFile == null) {
      NotificationService.showError('Vui lòng chọn ảnh thumbnail');
      return;
    }
    if (_steps.isEmpty) {
      NotificationService.showError('Thêm ít nhất một bước hướng dẫn');
      return;
    }

    setState(() => _loading = true);

    // Convert thumbnail to base64
    final thumbnailBytes = await _thumbnailFile!.readAsBytes();
    final thumbnailBase64 = 'data:image/png;base64,${base64Encode(thumbnailBytes)}';

    // Convert steps images to base64
    final stepsData = [];
    for (var step in _steps) {
      String? imageBase64;
      if (step.imageFile != null) {
        final bytes = await step.imageFile!.readAsBytes();
        imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      }
      stepsData.add({
        'step_order': step.stepOrder,
        'title': step.title,
        'content': step.content,
        'image_url': imageBase64,
      });
    }

    final materialsData = _materials.map((m) => {
      'name': m.name,
      'quantity': m.quantity,
      'note': m.note,
    }).toList();

    try {
      final res = await _api.post('/tutorials', {
        'title': _titleController.text,
        'category': _categoryController.text,
        'description': _descriptionController.text,
        'thumbnail_url': thumbnailBase64,
        'difficulty_level': _difficultyController.text,
        'steps': stepsData,
        'materials': materialsData,
      });
      if (res.statusCode == 201) {
        NotificationService.showSuccess('Tạo bài hướng dẫn thành công!');
        Navigator.pop(context, true);
      } else {
        NotificationService.showError('Tạo thất bại');
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
        title: const Text('Tạo bài hướng dẫn mới'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildThumbnailSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                validator: (v) => v!.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục (Vẽ, Thủ công, ...)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _difficultyController,
                decoration: const InputDecoration(labelText: 'Độ khó (Dễ, Trung bình, Khó)'),
              ),
              const SizedBox(height: 24),
              _buildStepsSection(),
              const SizedBox(height: 24),
              _buildMaterialsSection(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitTutorial,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.primary),
                child: const Text('Đăng bài hướng dẫn', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return GestureDetector(
      onTap: _pickThumbnail,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          image: _thumbnailFile != null ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover) : null,
        ),
        child: _thumbnailFile == null
            ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image, size: 40),
          Text('Chọn ảnh thumbnail'),
        ])
            : null,
      ),
    );
  }

  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Các bước hướng dẫn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: _addStep, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
          ],
        ),
        ..._steps.asMap().entries.map((entry) {
          int idx = entry.key;
          StepModel step = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Bước ${step.stepOrder}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(onPressed: () => _removeStep(idx), icon: const Icon(Icons.delete, color: Colors.red)),
                    ],
                  ),
                  TextFormField(
                    initialValue: step.title,
                    onChanged: (v) => step.title = v,
                    decoration: const InputDecoration(labelText: 'Tiêu đề bước'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: step.content,
                    onChanged: (v) => step.content = v,
                    decoration: const InputDecoration(labelText: 'Nội dung'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickStepImage(idx),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: step.imageFile != null
                          ? Image.file(step.imageFile!, fit: BoxFit.cover)
                          : const Center(child: Text('Chạm để thêm ảnh minh họa')),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Vật liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(onPressed: _addMaterial, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
          ],
        ),
        ..._materials.asMap().entries.map((entry) {
          int idx = entry.key;
          MaterialModel material = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: material.name,
                      onChanged: (v) => material.name = v,
                      decoration: const InputDecoration(labelText: 'Tên vật liệu'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: material.quantity,
                      onChanged: (v) => material.quantity = v,
                      decoration: const InputDecoration(labelText: 'Số lượng'),
                    ),
                  ),
                  IconButton(onPressed: () => _removeMaterial(idx), icon: const Icon(Icons.delete, color: Colors.red)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class StepModel {
  int stepOrder;
  String title;
  String content;
  File? imageFile;
  StepModel({required this.stepOrder, required this.title, required this.content, this.imageFile});
}

class MaterialModel {
  String name;
  String quantity;
  String note;
  MaterialModel({required this.name, required this.quantity, required this.note});
}