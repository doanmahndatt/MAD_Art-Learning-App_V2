import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import '../utils/colors.dart';
import 'tutorial_detail_screen.dart';
import 'edit_tutorial_screen.dart';

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});
  @override
  State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  final ApiService _api = ApiService();
  List<Tutorial> _tutorials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/my-tutorials');
      if (res.statusCode == 200) {
        setState(() {
          _tutorials = (res.data as List).map((j) => Tutorial.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint('$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteTutorial(Tutorial tutorial, AppProvider app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete tutorial'),
        content: const Text('This tutorial will be removed from the database and disappear for all users after refresh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(app.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final res = await _api.delete('/tutorials/${tutorial.id}');
      if (res.statusCode == 200) {
        setState(() => _tutorials.removeWhere((item) => item.id == tutorial.id));
        NotificationService.showSuccess('Tutorial deleted successfully');
      }
    } catch (e) {
      NotificationService.showError('Error: $e');
    }
  }

  Future<void> _openEdit(Tutorial tutorial) async {
    final detail = await _api.get('/tutorials/${tutorial.id}');
    if (!mounted || detail.statusCode != 200) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditTutorialScreen(tutorial: detail.data)),
    );
    if (changed == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text(app.t('my_tutorials'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _tutorials.isEmpty
          ? Center(
          child: Text(app.t('no_tutorials'),
              style: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight)))
          : RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _tutorials.length,
          itemBuilder: (_, i) {
            final tutorial = _tutorials[i];
            return Stack(
              children: [
                TutorialCard(
                  tutorial: tutorial,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TutorialDetailScreen(tutorialId: tutorial.id)),
                  ).then((_) => _fetch()),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEdit(tutorial);
                        } else if (value == 'delete') {
                          _deleteTutorial(tutorial, app);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
