import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';
import '../widgets/comment_tile.dart';
import 'edit_artwork_screen.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final String artworkId;
  const ArtworkDetailScreen({super.key, required this.artworkId});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _artwork;
  bool _loading = true, _isLiked = false;
  int _likesCount = 0;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  bool get _isOwner {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    return userId != null && _artwork?['user_id'] == userId;
  }

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks/${widget.artworkId}');
      if (res.statusCode == 200) {
        setState(() {
          _artwork = res.data;
          _likesCount = (_artwork?['likes'] as List?)?.length ?? 0;
          _isLiked = (_artwork?['likes'] as List?)?.any((l) =>
          l['user_id'] == Provider.of<AuthProvider>(context, listen: false).user?.id) ??
              false;
          _comments = _artwork?['comments'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('$e');
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(AppProvider app) async {
    try {
      final res = await _api.post('/artworks/${widget.artworkId}/like', {});
      if (res.statusCode == 201) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
        NotificationService.showSuccess(_isLiked ? app.t('liked_msg') : app.t('unliked_msg'));
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Future<void> _addComment(AppProvider app) async {
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
        await _fetchDetail();
        NotificationService.showSuccess(app.t('commented'));

      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Future<void> _editComment(String id, String old, AppProvider app) async {
    final ctrl = TextEditingController(text: old);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(app.t('edit_comment')),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(app.t('cancel'))),
          TextButton(
            onPressed: () async {
              final c = ctrl.text.trim();
              if (c.isEmpty) return;
              try {
                final r = await _api.put('/comments/$id', {'content': c});
                if (r.statusCode == 200) {
                  setState(() {
                    final i = _comments.indexWhere((x) => x['id'] == id);
                    if (i != -1) _comments[i] = r.data;
                  });
                  await _fetchDetail();
                  NotificationService.showSuccess(app.t('edited'));
                  Navigator.pop(context);
                }
              } catch (e) {
                NotificationService.showError('Error');
              }
            },
            child: Text(app.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String id, AppProvider app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(app.t('delete_comment')),
        content: Text(app.t('confirm_delete')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(app.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _api.delete('/comments/$id');
        await _fetchDetail();
        NotificationService.showSuccess(app.t('deleted'));
      } catch (e) {
        NotificationService.showError('Error');
      }
    }
  }

  Future<void> _openEdit() async {
    if (_artwork == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditArtworkScreen(artwork: _artwork!)),
    );
    if (changed == true) {
      await _fetchDetail();
    }
  }

  Future<void> _deleteArtwork(AppProvider app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete artwork'),
        content: const Text('This artwork will be removed from the database and disappear for all users after refresh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(app.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await _api.delete('/artworks/${widget.artworkId}');
      if (res.statusCode == 200 && mounted) {
        NotificationService.showSuccess('Artwork deleted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:image')) {
      return Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover, width: double.infinity, height: 300);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 300,
      placeholder: (_, __) => Container(color: Colors.grey[100]),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
    );
  }

  ImageProvider? _authorAvatarProvider() {
    final avatar = _artwork?['author']?['avatar_url'];
    if (avatar == null || avatar.toString().isEmpty) return null;
    if (avatar.toString().startsWith('data:image')) {
      return MemoryImage(base64Decode(avatar.toString().split(',').last));
    }
    return NetworkImage(avatar.toString());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final surfColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor: surfColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_artwork?['title'] ?? '', style: TextStyle(fontSize: 16, color: textColor)),
        actions: _isOwner
            ? [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEdit();
              } else if (value == 'delete') {
                _deleteArtwork(app);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          )
        ]
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(color: Colors.white, child: _buildImage(_artwork?['image_url'] ?? '')),
          Container(
            color: surfColor,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _authorAvatarProvider(),
                  child: _authorAvatarProvider() == null
                      ? Text(_artwork?['author']?['full_name']?[0] ?? '?',
                      style: const TextStyle(color: AppColors.primary))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_artwork?['author']?['full_name'] ?? 'Unknown',
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    Text(
                      _artwork?['created_at'] != null
                          ? _artwork!['created_at'].toString().substring(0, 10)
                          : '',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                    ),
                  ]),
                ),
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isLiked
                        ? AppColors.like
                        : (isDark ? AppColors.darkTextLight : AppColors.textLight),
                  ),
                  onPressed: () => _toggleLike(app),
                ),
                Text('$_likesCount', style: TextStyle(color: textColor)),
              ]),
              const SizedBox(height: 8),
              Text(_artwork?['description'] ?? '', style: TextStyle(fontSize: 14, color: textColor)),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.border),
              Text(app.t('comments'),
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: app.t('write_comment'),
                      hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _addComment(app),
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ]),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (_, i) {
                  final c = _comments[i];
                  return CommentTile(
                    comment: c,
                    isOwner: c['user_id'] == auth.user?.id,
                    onEdit: () => _editComment(c['id'], c['content'], app),
                    onDelete: () => _deleteComment(c['id'], app),
                  );
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
