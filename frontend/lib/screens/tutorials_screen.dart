import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import '../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tutorial_detail_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final ApiService _api = ApiService();
  List<Tutorial> _tutorials = [];
  bool _loading = true;
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _fetchTutorials();
    _searchController.addListener(() {
      setState(() => _keyword = _searchController.text);
      _fetchTutorials();
    });
  }

  Future<void> _fetchTutorials() async {
    setState(() => _loading = true);
    try {
      final categoryParam = _selectedCategory == 'Tất cả' ? '' : _selectedCategory;
      final res = await _api.get('/tutorials?category=${Uri.encodeComponent(categoryParam)}&keyword=${Uri.encodeComponent(_keyword)}');
      if (res.statusCode == 200) {
        final List data = res.data;
        setState(() {
          _tutorials = data.map((j) => Tutorial.fromJson(j)).toList();
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

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _fetchTutorials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            _loading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tutorials.length,
                itemBuilder: (_, i) => TutorialCard(
                  tutorial: _tutorials[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TutorialDetailScreen(tutorialId: _tutorials[i].id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          else if (index == 2) Navigator.pushReplacementNamed(context, '/art_draw');
          else if (index == 3) Navigator.pushReplacementNamed(context, '/explore');
          else if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bài hướng dẫn...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['Tất cả', 'Vẽ', 'Thủ công', 'Màu nước', 'Chân dung'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(cat, style: GoogleFonts.inter(color: selected ? Colors.white : AppColors.text)),
            ),
          );
        },
      ),
    );
  }
}