import 'package:flutter/material.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết đã lưu')),
      body: const Center(child: Text('Chưa có bài viết nào được lưu')),
    );
  }
}