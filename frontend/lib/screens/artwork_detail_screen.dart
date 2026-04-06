import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../widgets/comment_tile.dart';
import 'dart:convert';

class ArtworkDetailScreen extends StatefulWidget {
  final String artworkId;
  const ArtworkDetailScreen({super.key, required this.artworkId});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _artwork;
  bool _loading = true;
  bool _isLiked = false;
  int _likesCount = 0;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks/${widget.artworkId}');
      if (res.statusCode == 200) {
        setState(() {
          _artwork = res.data;
          _likesCount = (_artwork?['likes'] as List?)?.length ?? 0;
          _isLiked = (_artwork?['likes'] as List?)?.any((l) => l['user_id'] == Provider.of<AuthProvider>(context, listen: false).user?.id) ?? false;
          _comments = _artwork?['comments'] ?? [];
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

  Future<void> _toggleLike() async {
    try {
      final res = await _api.post('/artworks/${widget.artworkId}/like', {});
      if (res.statusCode == 201) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
        NotificationService.showSuccess(_isLiked ? 'Đã thích' : 'Bỏ thích');
      }
    } catch (e) {
      NotificationService.showError('Lỗi: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      final res = await _api.post('/comments', {
        'content': _commentController.text,
        'artwork_id': widget.artworkId,
      });
      if (res.statusCode == 201) {
        setState(() {
          _comments.insert(0, res.data);
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
                final res = await _api.put('/comments/$commentId', {'content': newContent});
                if (res.statusCode == 200) {
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
        await _api.delete('/comments/$commentId');
        setState(() {
          _comments.removeWhere((c) => c['id'] == commentId);
        });
        NotificationService.showSuccess('Đã xóa bình luận');
      } catch (e) {
        NotificationService.showError('Lỗi xóa');
      }
    }
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Xử lý base64
      final base64String = imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
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
        title: Text(_artwork?['title'] ?? '', style: const TextStyle(fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(_artwork?['image_url'] ?? ''),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _artwork?['author']?['avatar_url'] != null ? NetworkImage(_artwork!['author']['avatar_url']) : null,
                        child: _artwork?['author']?['avatar_url'] == null
                            ? Text(_artwork?['author']?['full_name']?[0] ?? '?')
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_artwork?['author']?['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_artwork?['created_at'] != null ? _artwork!['created_at'].toString().substring(0, 10) : '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null),
                        onPressed: _toggleLike,
                      ),
                      Text('$_likesCount'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_artwork?['description'] ?? '', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      final isOwner = c['user_id'] == currentUserId;
                      return CommentTile(
                        comment: c,
                        isOwner: isOwner,
                        onEdit: () => _editComment(c['id'], c['content']),
                        onDelete: () => _deleteComment(c['id']),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}