import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _artworksKey = 'user_artworks';

  static Future<void> saveArtwork(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> artworks = prefs.getStringList(_artworksKey) ?? [];
    artworks.add(imagePath);
    await prefs.setStringList(_artworksKey, artworks);
  }

  static Future<List<String>> getArtworks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_artworksKey) ?? [];
  }

  static Future<void> clearArtworks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_artworksKey);
  }
}