import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/notifications');
      if (res.statusCode == 200) {
        setState(() {
          _items = (res.data as List?) ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    final isRead = item['is_read'] == true;
    final entityType = item['entity_type']?.toString();
    final entityId = item['entity_id']?.toString();

    if (id != null && !isRead) {
      try {
        await _api.patch('/notifications/$id/read', {});
        if (mounted) {
          context.read<NotificationProvider>().decrementUnreadIfNeeded();
        }
        item['is_read'] = true;
      } catch (_) {}
    }

    if (!mounted || entityId == null) return;

    if (entityType == 'artwork') {
      await Navigator.pushNamed(
        context,
        '/artwork_detail',
        arguments: entityId,
      );
      if (mounted) _fetch();
      return;
    }

    if (entityType == 'tutorial') {
      await Navigator.pushNamed(
        context,
        '/tutorial_detail',
        arguments: entityId,
      );
      if (mounted) _fetch();
    }
  }

  ImageProvider? _avatar(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:image')) {
        return MemoryImage(base64Decode(url.split(',').last));
      }
      return NetworkImage(url);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final bgColor =
    isDark ? AppColors.darkBackground : AppColors.background;
    final surfColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final subColor =
    isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfColor,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetch,
        child: _items.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: subColor),
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i] as Map<String, dynamic>;
            final actor = item['actor'] as Map<String, dynamic>?;
            final name =
                actor?['full_name']?.toString() ?? 'Someone';
            final avatar = _avatar(
              actor?['avatar_url']?.toString(),
            );

            return Card(
              color: item['is_read'] == true
                  ? surfColor
                  : AppColors.primary.withOpacity(0.08),
              child: ListTile(
                onTap: () => _openNotification(item),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                    ),
                  )
                      : null,
                ),
                title: Text(
                  item['title'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '$name • ${item['message'] ?? ''}',
                  style: TextStyle(color: subColor),
                ),
                trailing: item['is_read'] == true
                    ? null
                    : const Icon(
                  Icons.circle,
                  size: 10,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}