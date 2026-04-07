import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../utils/colors.dart';
import 'artwork_detail_screen.dart';
import 'edit_artwork_screen.dart';

class MyArtworksScreen extends StatefulWidget {
  const MyArtworksScreen({super.key});
  @override
  State<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends State<MyArtworksScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/my-artworks');
      if (res.statusCode == 200) {
        setState(() {
          _artworks = (res.data as List).map((j) => Artwork.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteArtwork(Artwork artwork, AppProvider app) async {
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
      final res = await _api.delete('/artworks/${artwork.id}');
      if (res.statusCode == 200) {
        setState(() => _artworks.removeWhere((item) => item.id == artwork.id));
        NotificationService.showSuccess('Artwork deleted successfully');
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Future<void> _openEdit(Artwork artwork) async {
    final detail = await _api.get('/artworks/${artwork.id}');
    if (!mounted || detail.statusCode != 200) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditArtworkScreen(artwork: detail.data)),
    );
    if (changed == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text(app.t('my_artworks'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _artworks.isEmpty
          ? Center(
          child: Text(app.t('no_artworks'),
              style: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight)))
          : RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.primary,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.66),
          itemCount: _artworks.length,
          itemBuilder: (_, i) {
            final artwork = _artworks[i];
            return Stack(
              children: [
                Positioned.fill(
                  child: ArtworkCard(
                    artwork: artwork,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ArtworkDetailScreen(artworkId: artwork.id)),
                    ).then((_) => _fetch()),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEdit(artwork);
                        } else if (value == 'delete') {
                          _deleteArtwork(artwork, app);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
