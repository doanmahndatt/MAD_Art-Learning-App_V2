import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { vi, en }

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.vi;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppLanguage get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;

  String t(String key) => _strings[_language]?[key] ?? key;

  static const _strings = {
    AppLanguage.vi: {
      // Profile
      'profile': 'Cá nhân', 'settings': 'Cài đặt',
      'my_artworks': 'Tác phẩm của tôi', 'my_tutorials': 'Bài học của tôi',
      'upload_artwork': 'Đăng tác phẩm mới', 'create_tutorial': 'Tạo bài hướng dẫn mới',
      'draw': 'Vẽ sáng tạo', 'liked': 'Bài viết đã thích', 'logout': 'Đăng xuất',
      'tutorials_label': 'Bài học', 'artworks_label': 'Tác phẩm', 'likes_label': 'Yêu thích',
      // Settings
      'notifications': 'Nhận thông báo', 'dark_mode': 'Chế độ tối',
      'language': 'Ngôn ngữ', 'appearance': 'Giao diện', 'general': 'Tổng quát',
      // Home
      'hello': 'Xin chào,',
      // Explore
      'explore': 'Khám phá', 'latest': 'Mới nhất', 'popular': 'Phổ biến',
      // Tutorials screen
      'tutorials': 'Hướng dẫn', 'search_tutorials': 'Tìm kiếm bài hướng dẫn...',
      // Category chips (canonical key → display label)
      'cat_all':        'Tất cả',
      'cat_draw':       'Vẽ',
      'cat_craft':      'Thủ công',
      'cat_watercolor': 'Màu nước',
      'cat_portrait':   'Chân dung',
      // Tutorial detail
      'steps_tab': 'Hướng dẫn', 'materials_tab': 'Vật liệu', 'comments_tab': 'Bình luận',
      'write_comment': 'Viết bình luận...',
      'edit_comment': 'Sửa bình luận', 'delete_comment': 'Xóa bình luận',
      'confirm_delete': 'Bạn có chắc chắn muốn xóa?',
      'cancel': 'Hủy', 'save': 'Lưu', 'delete': 'Xóa',
      'commented': 'Đã bình luận', 'edited': 'Đã sửa', 'deleted': 'Đã xóa bình luận',
      'liked_msg': 'Đã thích', 'unliked_msg': 'Bỏ thích',
      // Nav
      'nav_home': 'Trang chủ', 'nav_tutorials': 'Hướng dẫn',
      'nav_draw': 'Vẽ', 'nav_explore': 'Khám phá', 'nav_profile': 'Cá nhân',
      // Artwork detail
      'comments': 'Bình luận',
      // Liked / My screens
      'liked_posts': 'Bài viết đã thích', 'no_liked': 'Chưa thích bài viết nào',
      'no_artworks': 'Chưa có tác phẩm nào', 'no_tutorials': 'Chưa có bài học nào',
      // Edit profile
      'edit_profile': 'Chỉnh sửa hồ sơ', 'full_name': 'Họ tên', 'bio': 'Giới thiệu',
      'update_success': 'Cập nhật thành công',
      // Art draw
      'art_studio': 'Art Studio', 'no_strokes': 'Chưa có nét vẽ nào',
      'saved_artwork': 'Đã lưu tác phẩm', 'save_failed': 'Lưu thất bại',
      // Upload artwork
      'upload_title': 'Đăng tác phẩm mới', 'select_image': 'Chạm để chọn ảnh',
      'title_field': 'Tiêu đề *', 'desc_field': 'Mô tả', 'public_toggle': 'Công khai',
      'upload_btn': 'Đăng', 'upload_success': 'Đăng tác phẩm thành công!',
      'upload_fail': 'Đăng thất bại, vui lòng thử lại', 'please_select_img': 'Vui lòng chọn ảnh',
      // Create tutorial
      'create_tut_title': 'Tạo bài hướng dẫn mới',
      'tut_title_field': 'Tiêu đề *',
      'tut_category_label': 'Danh mục *',
      'tut_desc': 'Mô tả',
      'tut_difficulty_label': 'Độ khó',
      'tut_steps': 'Các bước hướng dẫn',
      'tut_step_n': 'Bước',
      'tut_step_title': 'Tiêu đề bước', 'tut_step_content': 'Nội dung',
      'tut_step_img': 'Thêm ảnh minh họa',
      'tut_materials': 'Vật liệu', 'mat_name': 'Tên vật liệu', 'mat_qty': 'Số lượng',
      'tut_submit': 'Đăng bài hướng dẫn',
      'select_thumbnail': 'Chọn ảnh thumbnail',
      'tut_success': 'Tạo bài hướng dẫn thành công!', 'tut_fail': 'Tạo thất bại',
      'need_thumbnail': 'Vui lòng chọn ảnh thumbnail',
      'need_steps': 'Thêm ít nhất một bước hướng dẫn',
      'diff_easy': 'Dễ', 'diff_medium': 'Trung bình', 'diff_hard': 'Khó',
      'need_category': 'Vui lòng chọn danh mục',
    },
    AppLanguage.en: {
      // Profile
      'profile': 'Profile', 'settings': 'Settings',
      'my_artworks': 'My Artworks', 'my_tutorials': 'My Tutorials',
      'upload_artwork': 'Upload New Artwork', 'create_tutorial': 'Create New Tutorial',
      'draw': 'Creative Drawing', 'liked': 'Liked Posts', 'logout': 'Log Out',
      'tutorials_label': 'Tutorials', 'artworks_label': 'Artworks', 'likes_label': 'Likes',
      // Settings
      'notifications': 'Notifications', 'dark_mode': 'Dark Mode',
      'language': 'Language', 'appearance': 'Appearance', 'general': 'General',
      // Home
      'hello': 'Hello,',
      // Explore
      'explore': 'Explore', 'latest': 'Latest', 'popular': 'Popular',
      // Tutorials screen
      'tutorials': 'Tutorials', 'search_tutorials': 'Search tutorials...',
      // Category chips
      'cat_all':        'All',
      'cat_draw':       'Drawing',
      'cat_craft':      'Crafts',
      'cat_watercolor': 'Watercolor',
      'cat_portrait':   'Portrait',
      // Tutorial detail
      'steps_tab': 'Steps', 'materials_tab': 'Materials', 'comments_tab': 'Comments',
      'write_comment': 'Write a comment...',
      'edit_comment': 'Edit comment', 'delete_comment': 'Delete comment',
      'confirm_delete': 'Are you sure you want to delete?',
      'cancel': 'Cancel', 'save': 'Save', 'delete': 'Delete',
      'commented': 'Commented', 'edited': 'Edited', 'deleted': 'Comment deleted',
      'liked_msg': 'Liked', 'unliked_msg': 'Unliked',
      // Nav
      'nav_home': 'Home', 'nav_tutorials': 'Tutorials',
      'nav_draw': 'Draw', 'nav_explore': 'Explore', 'nav_profile': 'Profile',
      // Artwork detail
      'comments': 'Comments',
      // Liked / My screens
      'liked_posts': 'Liked Posts', 'no_liked': 'No liked posts yet',
      'no_artworks': 'No artworks yet', 'no_tutorials': 'No tutorials yet',
      // Edit profile
      'edit_profile': 'Edit Profile', 'full_name': 'Full Name', 'bio': 'Bio',
      'update_success': 'Updated successfully',
      // Art draw
      'art_studio': 'Art Studio', 'no_strokes': 'No strokes yet',
      'saved_artwork': 'Artwork saved', 'save_failed': 'Save failed',
      // Upload artwork
      'upload_title': 'Upload New Artwork', 'select_image': 'Tap to select image',
      'title_field': 'Title *', 'desc_field': 'Description', 'public_toggle': 'Public',
      'upload_btn': 'Post', 'upload_success': 'Artwork posted successfully!',
      'upload_fail': 'Post failed, please try again', 'please_select_img': 'Please select an image',
      // Create tutorial
      'create_tut_title': 'Create New Tutorial',
      'tut_title_field': 'Title *',
      'tut_category_label': 'Category *',
      'tut_desc': 'Description',
      'tut_difficulty_label': 'Difficulty',
      'tut_steps': 'Tutorial Steps',
      'tut_step_n': 'Step',
      'tut_step_title': 'Step title', 'tut_step_content': 'Content',
      'tut_step_img': 'Add step image',
      'tut_materials': 'Materials', 'mat_name': 'Material name', 'mat_qty': 'Quantity',
      'tut_submit': 'Post Tutorial',
      'select_thumbnail': 'Select thumbnail image',
      'tut_success': 'Tutorial created successfully!', 'tut_fail': 'Creation failed',
      'need_thumbnail': 'Please select a thumbnail image',
      'need_steps': 'Add at least one step',
      'diff_easy': 'Easy', 'diff_medium': 'Medium', 'diff_hard': 'Hard',
      'need_category': 'Please select a category',
    },
  };

  AppProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getBool('isDark') ?? false) ? ThemeMode.dark : ThemeMode.light;
    _language = (prefs.getString('lang') ?? 'vi') == 'en' ? AppLanguage.en : AppLanguage.vi;
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode; notifyListeners();
    (await SharedPreferences.getInstance()).setBool('isDark', mode == ThemeMode.dark);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang; notifyListeners();
    (await SharedPreferences.getInstance()).setString('lang', lang == AppLanguage.en ? 'en' : 'vi');
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value; notifyListeners();
    (await SharedPreferences.getInstance()).setBool('notifications', value);
  }
}