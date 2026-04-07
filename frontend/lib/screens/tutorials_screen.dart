import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tutorial_detail_screen.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});
  @override State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  final ApiService _api = ApiService();
  List<Tutorial> _tutorials = [];
  bool _loading = true;

  // Category stored as Vietnamese DB value — always sent to backend as-is
  // '' means "All"
  String _selectedCategoryDb = '';

  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';
  Timer? _debounce;

  // Mapping: display key (i18n) → actual DB category value stored in PostgreSQL
  // These must match exactly what was saved when creating tutorials
  static const _categoryMap = [
    {'key': 'cat_all',        'db': ''},
    {'key': 'cat_draw',       'db': 'Vẽ'},
    {'key': 'cat_craft',      'db': 'Thủ công'},
    {'key': 'cat_watercolor', 'db': 'Màu nước'},
    {'key': 'cat_portrait',   'db': 'Chân dung'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTutorials();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce 400ms — don't fire API on every keystroke
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _keyword = _searchController.text.trim());
        _fetchTutorials();
      }
    });
  }

  Future<void> _fetchTutorials() async {
    setState(() => _loading = true);
    try {
      // Send DB value for category, trim keyword
      final catParam = Uri.encodeComponent(_selectedCategoryDb);
      final kwParam  = Uri.encodeComponent(_keyword);
      final res = await _api.get('/tutorials?category=$catParam&keyword=$kwParam');
      if (res.statusCode == 200) {
        setState(() {
          _tutorials = (res.data as List).map((j) => Tutorial.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('fetchTutorials error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : AppColors.surface;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;
    final subColor  = isDark ? AppColors.darkTextLight  : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(child: Column(children: [
        // ── Search bar ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: surfColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [if (!isDark) BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 10)],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: app.t('search_tutorials'),
                hintStyle: TextStyle(color: subColor),
                prefixIcon: Icon(Icons.search, color: subColor),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(
                    icon: Icon(Icons.clear, color: subColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _keyword = '');
                      _fetchTutorials();
                    })
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),

        // ── Category chips ────────────────────────────────────────
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categoryMap.length,
            itemBuilder: (_, i) {
              final entry = _categoryMap[i];
              final dbVal = entry['db']!;
              final isSelected = _selectedCategoryDb == dbVal;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategoryDb = dbVal);
                  _fetchTutorials();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : surfColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                  ),
                  child: Text(
                    app.t(entry['key']!),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : subColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Tutorial list ─────────────────────────────────────────
        _loading
            ? Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)))
            : _tutorials.isEmpty
            ? Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48, color: subColor),
          const SizedBox(height: 12),
          Text(app.t('no_tutorials'), style: TextStyle(color: subColor)),
        ])))
            : Expanded(child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchTutorials,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _tutorials.length,
            itemBuilder: (_, i) => TutorialCard(
              tutorial: _tutorials[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TutorialDetailScreen(tutorialId: _tutorials[i].id)),
              ),
            ),
          ),
        )),
      ])),
      bottomNavigationBar: BottomNavBar(currentIndex: 1, onTap: (i) {
        if (i == 1) return;
        if (i == 0) Navigator.pushReplacementNamed(context, '/');
        else if (i == 2) Navigator.pushReplacementNamed(context, '/art_draw');
        else if (i == 3) Navigator.pushReplacementNamed(context, '/explore');
        else if (i == 4) Navigator.pushReplacementNamed(context, '/profile');
      }),
    );
  }
}