import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'artwork_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override void initState() { super.initState(); _fetchArtworks(); }

  Future<void> _fetchArtworks() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks?sort=latest');
      if (res.statusCode == 200) {
        setState(() { _artworks = (res.data as List).map((j) => Artwork.fromJson(j)).toList(); _loading = false; });
      } else { setState(() => _loading = false); }
    } catch (e) { debugPrint('$e'); setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app  = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : AppColors.surface;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(child: Column(children: [
        _buildHeader(auth.user?.fullName ?? 'User', auth.user?.avatarUrl, app, isDark, surfColor, textColor),
        const SizedBox(height: 4),
        _loading
            ? Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)))
            : Expanded(child: RefreshIndicator(
          color: AppColors.primary, onRefresh: _fetchArtworks,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.65),
            itemCount: _artworks.length,
            itemBuilder: (_, i) => ArtworkCard(artwork: _artworks[i], onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id))).then((_) => _fetchArtworks())),
          ),
        )),
      ])),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (i) {
        if (i == 0) return;
        if (i == 1) Navigator.pushReplacementNamed(context, '/tutorials');
        else if (i == 2) Navigator.pushReplacementNamed(context, '/art_draw');
        else if (i == 3) Navigator.pushReplacementNamed(context, '/explore');
        else if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
      }),
    );
  }

  Widget _buildHeader(String name, String? avatarUrl, AppProvider app, bool isDark, Color surfColor, Color textColor) {
    return Container(
      color: surfColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.t('hello'), style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextLight : AppColors.textLight)),
            Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
          ]),
        ]),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? (avatarUrl.startsWith('data:image') ? MemoryImage(base64Decode(avatarUrl.split(',').last)) : NetworkImage(avatarUrl) as ImageProvider)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
          ),
        ),
      ]),
    );
  }
}