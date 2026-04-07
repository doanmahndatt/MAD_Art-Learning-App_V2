import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../utils/colors.dart';
import 'artwork_detail_screen.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});
  @override State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override void initState() { super.initState(); _fetchLiked(); }

  Future<void> _fetchLiked() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks/liked');
      if (res.statusCode == 200) setState(() { _artworks = (res.data as List).map((j) => Artwork.fromJson(j)).toList(); _loading = false; });
      else setState(() => _loading = false);
    } catch (e) { debugPrint('$e'); setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : AppColors.surface;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(app.t('liked_posts'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _artworks.isEmpty
          ? Center(child: Text(app.t('no_liked'), style: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight)))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.65),
        itemCount: _artworks.length,
        itemBuilder: (_, i) => ArtworkCard(artwork: _artworks[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id)))),
      ),
    );
  }
}