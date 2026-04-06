import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tutorial_detail_screen.dart';
import 'art_draw_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      final res = await _api.get('/tutorials?category=$categoryParam&keyword=$_keyword');
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
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth.user?.fullName ?? 'User'),
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
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            // Navigate to tutorials screen (giữ nguyên home tạm thời)
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtDrawScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontSize: 20))),
              ),
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bài hướng dẫn...',
            hintStyle: GoogleFonts.inter(color: AppColors.textLight),
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
            suffixIcon: _keyword.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: AppColors.textLight), onPressed: () => _searchController.clear())
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
      margin: const EdgeInsets.symmetric(vertical: 16),
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