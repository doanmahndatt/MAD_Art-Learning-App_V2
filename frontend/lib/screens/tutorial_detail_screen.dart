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
import 'edit_tutorial_screen.dart';

class TutorialDetailScreen extends StatefulWidget {
  final String tutorialId;
  const TutorialDetailScreen({super.key, required this.tutorialId});

  @override
  State<TutorialDetailScreen> createState() => _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends State<TutorialDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _tutorial;
  bool _loading = true;
  late TabController _tabController;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  bool get _isOwner {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    return userId != null && _tutorial?['created_by'] == userId;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetail();
    _fetchComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get('/tutorials/${widget.tutorialId}');
      if (r.statusCode == 200) {
        setState(() {
          _tutorial = r.data;
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

  Future<void> _fetchComments() async {
    try {
      final r = await _api.get('/tutorials/${widget.tutorialId}/comments');
      if (r.statusCode == 200) setState(() => _comments = r.data);
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _addComment(AppProvider app) async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      final r = await _api.post('/tutorials/${widget.tutorialId}/comments', {'content': _commentController.text});
      if (r.statusCode == 201) {
        setState(() {
          _comments.insert(0, r.data);
          _commentController.clear();
        });
        await _fetchComments();
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
                final r = await _api.put('/tutorials/${widget.tutorialId}/comments/$id', {'content': c});
                if (r.statusCode == 200) {
                  setState(() {
                    final i = _comments.indexWhere((x) => x['id'] == id);
                    if (i != -1) _comments[i] = r.data;
                  });
                  await _fetchComments();
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
        await _api.delete('/tutorials/${widget.tutorialId}/comments/$id');
        await _fetchComments();
        await _fetchDetail();
        NotificationService.showSuccess(app.t('deleted'));
      } catch (e) {
        NotificationService.showError('Error');
      }
    }
  }

  Future<void> _openEdit() async {
    if (_tutorial == null) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditTutorialScreen(tutorial: _tutorial!)),
    );
    if (changed == true) {
      await _fetchDetail();
      await _fetchComments();
    }
  }

  Future<void> _deleteTutorial(AppProvider app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete tutorial'),
        content: const Text('This tutorial will be removed from the database and disappear for all users after refresh.'),
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
      final res = await _api.delete('/tutorials/${widget.tutorialId}');
      if (res.statusCode == 200 && mounted) {
        NotificationService.showSuccess('Tutorial deleted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Widget _buildImage(String? url, {double h = 200}) {
    if (url == null || url.isEmpty) {
      return Container(color: Colors.grey[100], height: h, child: const Icon(Icons.image_not_supported));
    }
    if (url.startsWith('data:image')) {
      return Image.memory(base64Decode(url.split(',').last), height: h, width: double.infinity, fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: h,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[100]),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final surfColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_tutorial?['title'] ?? '', style: TextStyle(fontSize: 16, color: textColor)),
        actions: _isOwner
            ? [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEdit();
              } else if (value == 'delete') {
                _deleteTutorial(app);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ]
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildImage(_tutorial?['thumbnail_url']),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_tutorial?['title'] ?? '',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text(_tutorial?['description'] ?? '',
                  style: TextStyle(
                      color: isDark ? AppColors.darkTextLight : AppColors.textLight)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border))),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? AppColors.darkTextLight : AppColors.textLight,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: app.t('steps_tab')),
                    Tab(text: app.t('materials_tab')),
                    Tab(text: '${app.t("comments_tab")} (${_comments.length})'),
                  ],
                ),
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSteps(isDark, textColor),
                    _buildMaterials(isDark, textColor),
                    _buildComments(auth.user?.id, app, isDark, textColor),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildSteps(bool isDark, Color textColor) {
    final steps = _tutorial?['steps'] ?? [];
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final s = steps[i];
        return Card(
          color: isDark ? AppColors.darkSurface : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${s['step_order']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(s['title'],
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              ]),
              if (s['image_url'] != null && s['image_url'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildImage(s['image_url'], h: 150)
              ],
              const SizedBox(height: 8),
              Text(s['content'], style: TextStyle(color: textColor)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildMaterials(bool isDark, Color textColor) {
    final mats = _tutorial?['materials'] ?? [];
    return ListView.builder(
      itemCount: mats.length,
      itemBuilder: (_, i) {
        final m = mats[i];
        return ListTile(
          leading: const Icon(Icons.brush, color: AppColors.primary),
          title: Text(m['name'], style: TextStyle(color: textColor)),
          subtitle: m['quantity'] != null
              ? Text(m['quantity'],
              style: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight))
              : null,
        );
      },
    );
  }

  Widget _buildComments(String? uid, AppProvider app, bool isDark, Color textColor) {
    return Column(children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: app.t('write_comment'),
              hintStyle: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
          ),
        ),
        IconButton(onPressed: () => _addComment(app), icon: const Icon(Icons.send_rounded, color: AppColors.primary)),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          itemCount: _comments.length,
          itemBuilder: (_, i) {
            final c = _comments[i];
            final isOwner = c['user_id'] == uid;
            return CommentTile(
              comment: Map<String, dynamic>.from(c),
              isOwner: isOwner,
              onEdit: () => _editComment(c['id'], c['content'], app),
              onDelete: () => _deleteComment(c['id'], app),
            );
          },
        ),
      ),
    ]);
  }
}
