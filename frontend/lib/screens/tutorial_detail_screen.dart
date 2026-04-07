import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';

class TutorialDetailScreen extends StatefulWidget {
  final String tutorialId;
  const TutorialDetailScreen({super.key, required this.tutorialId});

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _tutorial;
  bool _loading = true;
  late TabController _tabController;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetail();
    _fetchComments();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/tutorials/${widget.tutorialId}');
      if (response.statusCode == 200) {
        setState(() {
          _tutorial = response.data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print(e);
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await _api.get('/tutorials/${widget.tutorialId}/comments');
      if (response.statusCode == 200) {
        setState(() => _comments = response.data);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      final response = await _api.post('/tutorials/${widget.tutorialId}/comments', {
        'content': _commentController.text,
      });
      if (response.statusCode == 201) {
        setState(() {
          _comments.insert(0, response.data);
          _commentController.clear();
        });
        NotificationService.showSuccess('Đã bình luận');
      }
    } catch (e) {
      NotificationService.showError('Lỗi: $e');
    }
  }

  Future<void> _editComment(String commentId, String oldContent) async {
    final controller = TextEditingController(text: oldContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bình luận'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) return;
              try {
                final response = await _api.put('/tutorials/${widget.tutorialId}/comments/$commentId', {
                  'content': newContent,
                });
                if (response.statusCode == 200) {
                  setState(() {
                    final index = _comments.indexWhere((c) => c['id'] == commentId);
                    if (index != -1) _comments[index]['content'] = newContent;
                  });
                  NotificationService.showSuccess('Đã sửa');
                  Navigator.pop(context);
                }
              } catch (e) {
                NotificationService.showError('Lỗi sửa');
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.delete('/tutorials/${widget.tutorialId}/comments/$commentId');
        setState(() {
          _comments.removeWhere((c) => c['id'] == commentId);
        });
        NotificationService.showSuccess('Đã xóa bình luận');
      } catch (e) {
        NotificationService.showError('Lỗi xóa');
      }
    }
  }

  Widget _buildImage(String? imageUrl, {double height = 200}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(color: Colors.grey[200], height: height, child: const Icon(Icons.image_not_supported));
    }
    if (imageUrl.startsWith('data:image')) {
      final base64 = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64), height: height, width: double.infinity, fit: BoxFit.cover);
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.id;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_tutorial?['title'] ?? '', style: const TextStyle(fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(_tutorial?['thumbnail_url']),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tutorial?['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_tutorial?['description'] ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildTabContent(currentUserId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        tabs: [
          const Tab(text: 'Hướng dẫn'),
          const Tab(text: 'Vật liệu'),
          Tab(child: Text('Bình luận (${_comments.length})')),
        ],
      ),
    );
  }

  Widget _buildTabContent(String? currentUserId) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSteps(),
          _buildMaterials(),
          _buildComments(currentUserId),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    final steps = _tutorial?['steps'] ?? [];
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final step = steps[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(child: Text('${step['step_order']}', style: const TextStyle(color: Colors.white))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step['title'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                if (step['image_url'] != null && step['image_url'].isNotEmpty)
                  _buildImage(step['image_url'], height: 150),
                const SizedBox(height: 8),
                Text(step['content']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterials() {
    final materials = _tutorial?['materials'] ?? [];
    return ListView.builder(
      itemCount: materials.length,
      itemBuilder: (_, i) {
        final m = materials[i];
        return ListTile(
          leading: Icon(Icons.brush, color: AppColors.primary),
          title: Text(m['name']),
          subtitle: m['quantity'] != null ? Text(m['quantity']) : null,
        );
      },
    );
  }

  Widget _buildComments(String? currentUserId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            IconButton(onPressed: _addComment, icon: const Icon(Icons.send, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _comments.length,
            itemBuilder: (_, i) {
              final c = _comments[i];
              final isOwner = c['user_id'] == currentUserId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: c['user']?['full_name'] != null ? Text(c['user']['full_name'][0]) : const Icon(Icons.person),
                  ),
                  title: Text(c['user']?['full_name'] ?? 'Anonymous'),
                  subtitle: Text(c['content']),
                  trailing: isOwner
                      ? PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') _editComment(c['id'], c['content']);
                      else if (value == 'delete') _deleteComment(c['id']);
                    },
                  )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}