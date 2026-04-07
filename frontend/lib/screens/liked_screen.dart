import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import 'artwork_detail_screen.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  final ApiService _api = ApiService();
  List<Artwork> _artworks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiked();
  }

  Future<void> _fetchLiked() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/artworks/liked');
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
      appBar: AppBar(
        title: const Text('Bài viết đã thích'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _artworks.isEmpty
          ? const Center(child: Text('Chưa thích bài viết nào'))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.65,
        ),
        itemCount: _artworks.length,
        itemBuilder: (_, i) => ArtworkCard(
          artwork: _artworks[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArtworkDetailScreen(artworkId: _artworks[i].id)),
          ),
        ),
      ),
    );
  }
}