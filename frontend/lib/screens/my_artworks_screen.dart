import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/artwork.dart';
import '../widgets/artwork_card.dart';
import 'artwork_detail_screen.dart';

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
        final List data = res.data;
        setState(() => _artworks = data.map((j) => Artwork.fromJson(j)).toList());
      }
    } catch (e) {
      print(e);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tác phẩm của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _artworks.isEmpty
          ? const Center(child: Text('Chưa có tác phẩm nào'))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.66,
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
            ).then((_) => _fetch());
          },
        ),
      ),
    );
  }
}