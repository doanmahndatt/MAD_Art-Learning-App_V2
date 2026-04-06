import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'saved_screen.dart';
import 'liked_screen.dart';
import 'settings_screen.dart';
import 'art_draw_screen.dart';
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
      print(e);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Cá nhân'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            _fetchProfile();
          }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            _buildMenuItems(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundImage: _profile?['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null, child: const Icon(Icons.person, size: 50)),
          const SizedBox(height: 12),
          Text(_profile?['full_name'] ?? '', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_profile?['bio'] ?? '', style: GoogleFonts.inter(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${_profile?['tutorials']?.length ?? 0}', 'Bài học'),
          Container(height: 30, width: 1, color: AppColors.border),
          _statItem('${_profile?['artworks']?.length ?? 0}', 'Tác phẩm'),
          Container(height: 30, width: 1, color: AppColors.border),
          _statItem('${_profile?['tutorial_favorites']?.length ?? 0}', 'Yêu thích'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildMenuItems(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _menuItem(Icons.color_lens, 'Vẽ sáng tạo', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtDrawScreen()))),
          _menuItem(Icons.bookmark, 'Bài viết đã lưu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScreen()))),
          _menuItem(Icons.favorite, 'Bài viết đã thích', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedScreen()))),
          _menuItem(Icons.settings, 'Cài đặt', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          _menuItem(Icons.logout, 'Đăng xuất', () async {
            await auth.logout();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }, isLogout: true),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : AppColors.primary),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : AppColors.text)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}