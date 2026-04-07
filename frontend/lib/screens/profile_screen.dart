import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'liked_screen.dart';
import 'settings_screen.dart';
import 'art_draw_screen.dart';
import 'upload_artwork_screen.dart';
import 'create_tutorial_screen.dart';
import 'my_artworks_screen.dart';
import 'my_tutorials_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/profile');
      if (res.statusCode == 200) {
        setState(() {
          _profile = res.data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
      setState(() => _loading = false);
    }
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
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          app.t('profile'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                _fetchProfile();
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      )
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(isDark, textColor, app),
              const SizedBox(height: 12),
              _buildStats(isDark, textColor, app),
              const SizedBox(height: 12),
              _buildMenuItems(auth, app, isDark, textColor),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;
          if (index == 0) Navigator.pushReplacementNamed(context, '/');
          else if (index == 1) Navigator.pushReplacementNamed(context, '/tutorials');
          else if (index == 2) Navigator.pushReplacementNamed(context, '/art_draw');
          else if (index == 3) Navigator.pushReplacementNamed(context, '/explore');
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color textColor, AppProvider app) {
    final String? avatarUrl = _profile?['avatar_url'];
    final String fullName   = _profile?['full_name'] ?? '';
    final String bio        = _profile?['bio'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.darkHeaderGradient
            : AppColors.headerGradient,
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? (avatarUrl.startsWith('data:image')
                      ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                      : NetworkImage(avatarUrl) as ImageProvider)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fullName,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.darkTextLight : AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats(bool isDark, Color textColor, AppProvider app) {
    final surfColor = isDark ? AppColors.darkSurface : AppColors.surface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: surfColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${_profile?['totalTutorials'] ?? 0}', app.t('tutorials_label'), Icons.school_rounded, const Color(0xFF9B8FFF), isDark, textColor),
          _statDivider(isDark),
          _statItem('${_profile?['artworks']?.length ?? 0}', app.t('artworks_label'), Icons.photo_library_rounded, const Color(0xFFFFABC8), isDark, textColor),
          _statDivider(isDark),
          _statItem('${_profile?['totalLikesReceived'] ?? 0}', app.t('likes_label'), Icons.favorite_rounded, const Color(0xFFFF7BAC), isDark, textColor),
        ],
      ),
    );
  }

  Widget _statDivider(bool isDark) => Container(
    height: 36,
    width: 1,
    color: isDark ? AppColors.darkBorder : AppColors.border,
  );

  Widget _statItem(String value, String label, IconData icon, Color color, bool isDark, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? AppColors.darkTextLight : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu items ────────────────────────────────────────────────
  Widget _buildMenuItems(AuthProvider auth, AppProvider app, bool isDark, Color textColor) {
    final surfColor = isDark ? AppColors.darkSurface : AppColors.surface;

    final items = [
      _MenuItem(Icons.photo_library_rounded,  app.t('my_artworks'),    const Color(0xFF9B8FFF), const Color(0xFFEDE9FF), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyArtworksScreen()));
      }),
      _MenuItem(Icons.school_rounded,          app.t('my_tutorials'),   const Color(0xFF8FD9C8), const Color(0xFFDFF7F2), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTutorialsScreen()));
      }),
      _MenuItem(Icons.add_photo_alternate_rounded, app.t('upload_artwork'), const Color(0xFFFFABC8), const Color(0xFFFFEDF4), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadArtworkScreen()))
            .then((_) => _fetchProfile());
      }),
      _MenuItem(Icons.add_circle_rounded,      app.t('create_tutorial'), const Color(0xFFFFCF77), const Color(0xFFFFF8E1), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTutorialScreen()))
            .then((_) => _fetchProfile());
      }),
      _MenuItem(Icons.brush_rounded,           app.t('draw'),           const Color(0xFFFF7BAC), const Color(0xFFFFE4EE), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtDrawScreen()));
      }),
      _MenuItem(Icons.favorite_rounded,        app.t('liked'),          const Color(0xFFFF7BAC), const Color(0xFFFFE4EE), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedScreen()));
      }),
      _MenuItem(Icons.settings_rounded,        app.t('settings'),       const Color(0xFF9B8FFF), const Color(0xFFEDE9FF), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
            .then((_) => setState(() {}));
      }),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return _menuTile(
              item.icon, item.label, item.iconColor, item.iconBg,
              item.onTap, isDark, textColor,
              showDivider: i < items.length - 1,
            );
          }),
          // Logout — separate style
          _menuTile(
            Icons.logout_rounded, app.t('logout'),
            Colors.red.shade300, Colors.red.shade50,
                () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            isDark, Colors.red.shade400,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
      IconData icon,
      String title,
      Color iconColor,
      Color iconBg,
      VoidCallback onTap,
      bool isDark,
      Color titleColor, {
        required bool showDivider,
      }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? iconColor.withOpacity(0.15) : iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextLight : AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 70,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.iconColor, this.iconBg, this.onTap);
}