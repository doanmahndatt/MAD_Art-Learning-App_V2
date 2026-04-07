import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';
import 'artwork_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;
  late TabController _tabController;
  String _sort = 'latest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchArtworks();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) { setState(() => _sort = _tabController.index == 0 ? 'latest' : 'popular'); _fetchArtworks(); }
    });
  }

  Future<void> _fetchArtworks() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks?sort=$_sort');
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
        title: Text(app.t('explore'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextLight : AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: [Tab(text: app.t('latest')), Tab(text: app.t('popular'))],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : RefreshIndicator(
        color: AppColors.primary, onRefresh: _fetchArtworks,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.65),
          itemCount: _artworks.length,
          itemBuilder: (_, i) => ArtworkCard(artwork: _artworks[i], onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id))).then((_) => _fetchArtworks())),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: (i) {
        if (i == 3) return;
        if (i == 0) Navigator.pushReplacementNamed(context, '/');
        else if (i == 1) Navigator.pushReplacementNamed(context, '/tutorials');
        else if (i == 2) Navigator.pushReplacementNamed(context, '/art_draw');
        else if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
      }),
    );
  }
}