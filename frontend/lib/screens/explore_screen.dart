import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchArtworks();
  }

  Future<void> _fetchArtworks({String sort = 'latest'}) async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks?sort=$sort');
      if (res.statusCode == 200) {
        final List data = res.data;
        setState(() {
          _artworks = data.map((j) => Artwork.fromJson(j)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Khám phá'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          tabs: const [
            Tab(text: 'Mới nhất'),
            Tab(text: 'Phổ biến'),
          ],
          onTap: (index) {
            if (index == 0) _fetchArtworks(sort: 'latest');
            else _fetchArtworks(sort: 'popular');
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
        itemCount: _artworks.length,
        itemBuilder: (_, i) => ArtworkCard(artwork: _artworks[i], onTap: () {}),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: (index) {}),
    );
  }
}