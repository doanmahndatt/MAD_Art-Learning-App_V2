import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tutorial.dart';
import '../widgets/tutorial_card.dart';
import 'tutorial_detail_screen.dart';

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
        final List data = res.data;
        setState(() => _tutorials = data.map((j) => Tutorial.fromJson(j)).toList());
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
        title: const Text('Bài học của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tutorials.isEmpty
          ? const Center(child: Text('Chưa có bài học nào'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _tutorials.length,
        itemBuilder: (_, i) => TutorialCard(
          tutorial: _tutorials[i],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TutorialDetailScreen(tutorialId: _tutorials[i].id),
              ),
            ).then((_) => _fetch());
          },
        ),
      ),
    );
  }
}