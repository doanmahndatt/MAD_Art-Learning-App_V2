import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import '../utils/colors.dart';
import 'tutorial_detail_screen.dart';

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});
  @override State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  final ApiService _api = ApiService();
  List<Tutorial> _tutorials = [];
  bool _loading = true;

  @override void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users/my-tutorials');
      if (res.statusCode == 200) setState(() { _tutorials = (res.data as List).map((j) => Tutorial.fromJson(j)).toList(); });
    } catch (e) { debugPrint('$e'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor   = isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface    : AppColors.surface;
    final textColor = isDark ? AppColors.darkText       : AppColors.text;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(app.t('my_tutorials'), style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
          : _tutorials.isEmpty
          ? Center(child: Text(app.t('no_tutorials'), style: TextStyle(color: isDark ? AppColors.darkTextLight : AppColors.textLight)))
          : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _tutorials.length,
        itemBuilder: (_, i) => TutorialCard(tutorial: _tutorials[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TutorialDetailScreen(tutorialId: _tutorials[i].id))).then((_) => _fetch())),
      ),
    );
  }
}