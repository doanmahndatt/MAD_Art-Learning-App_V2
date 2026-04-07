import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'artwork_detail_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtworks();
  }

  Future<void> _fetchArtworks() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks?sort=latest');
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
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth.user?.fullName ?? 'User', auth.user?.avatarUrl),
            const SizedBox(height: 8),
            _loading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchArtworks,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _artworks.length,
                  itemBuilder: (_, i) => ArtworkCard(
                    artwork: _artworks[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id),
                        ),
                      ).then((_) => _fetchArtworks());
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/tutorials');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/art_draw');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/explore');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildHeader(String name, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào,', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
                  Text(name, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? (avatarUrl.startsWith('data:image')
                  ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                  : NetworkImage(avatarUrl) as ImageProvider)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: Colors.white))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}