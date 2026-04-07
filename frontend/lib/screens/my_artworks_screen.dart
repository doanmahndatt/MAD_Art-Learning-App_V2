import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../utils/colors.dart';
import 'artwork_detail_screen.dart';

class MyArtworksScreen extends StatefulWidget {
  const MyArtworksScreen({super.key});
  @override State<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends State<MyArtworksScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/my-artworks');
      if (res.statusCode == 200) setState(() { _artworks = (res.data as List).map((j) => Artwork.fromJson(j)).toList(); });
    } catch (e) { debugPrint('$e'); }
    setState(() => _loading = false);
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
        title: Text(app.t('my_artworks'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _artworks.isEmpty
          ? Center(child: Text(app.t('no_artworks'), style: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight)))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.66),
        itemCount: _artworks.length,
        itemBuilder: (_, i) => ArtworkCard(artwork: _artworks[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id))).then((_) => _fetch())),
      ),
    );
  }
}