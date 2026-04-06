import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Nhận thông báo'),
            value: true,
            onChanged: (_) {},
          ),
          ListTile(
            title: const Text('Chế độ tối'),
            trailing: const Icon(Icons.dark_mode),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}