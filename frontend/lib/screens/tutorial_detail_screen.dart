import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
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
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/tutorials/${widget.tutorialId}');
      if (res.statusCode == 200) {
        setState(() {
          _tutorial = res.data;
          _comments = _tutorial?['reviews'] ?? [];
          _isFavorite = (_tutorial?['favorites'] as List?)?.isNotEmpty ?? false;
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

  Future<void> _toggleFavorite() async {
    try {
      final res = await _api.post('/tutorials/${widget.tutorialId}/favorite', {});
      if (res.statusCode == 201) {
        setState(() {
          _isFavorite = !_isFavorite;
          if (_isFavorite) {
            _tutorial?['favorites'] = [{}];
          } else {
            _tutorial?['favorites'] = [];
          }
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null), onPressed: _toggleFavorite),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildThumbnail(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_tutorial?['title'] ?? '', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundImage: _tutorial?['author']?['avatar_url'] != null ? NetworkImage(_tutorial!['author']['avatar_url']) : null),
                            const SizedBox(width: 8),
                            Text(_tutorial?['author']?['full_name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_tutorial?['description'] ?? '', style: GoogleFonts.inter(color: AppColors.textLight)),
                        const SizedBox(height: 24),
                        _buildTabs(),
                        const SizedBox(height: 16),
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return CachedNetworkImage(
      imageUrl: _tutorial?['thumbnail_url'] ?? '',
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[200]),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textLight,
        tabs: const [
          Tab(text: 'Hướng dẫn'),
          Tab(text: 'Vật liệu'),
          Tab(text: 'Bình luận'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSteps(),
          _buildMaterials(),
          _buildComments(),
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
              children: [
                Row(
                  children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: Center(child: Text('${step['step_order']}'))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step['title'], style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 8),
                if (step['image_url'] != null)
                  CachedNetworkImage(imageUrl: step['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover),
                const SizedBox(height: 8),
                Text(step['content'], style: GoogleFonts.inter(color: AppColors.textLight)),
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

  Widget _buildComments() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(hintText: 'Add a comment...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))),
              ),
            ),
            IconButton(icon: Icon(Icons.send, color: AppColors.primary), onPressed: () {}),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _comments.length,
            itemBuilder: (_, i) {
              final c = _comments[i];
              return ListTile(
                leading: CircleAvatar(child: Text(c['user']?['full_name']?[0] ?? '?')),
                title: Text(c['user']?['full_name'] ?? 'Anonymous'),
                subtitle: Text(c['comment'] ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }
}