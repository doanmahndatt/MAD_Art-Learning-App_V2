import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/colors.dart';

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  ImageProvider? _buildAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    if (avatarUrl.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(avatarUrl.split(',').last));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final avatarUrl = comment['user']?['avatar_url']?.toString();
    final avatarProvider = _buildAvatarProvider(avatarUrl);
    final fullName = comment['user']?['full_name']?.toString();

    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: avatarProvider,
          child: avatarProvider == null
              ? Text(
            (fullName != null && fullName.isNotEmpty) ? fullName[0] : '?',
            style: const TextStyle(color: AppColors.primary),
          )
              : null,
        ),
        title: Text(
          fullName ?? 'Anonymous',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          comment['content'] ?? '',
          style: TextStyle(
            color: isDark ? AppColors.darkTextLight : AppColors.textLight,
          ),
        ),
        trailing: isOwner
            ? PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(app.t('save'))),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                app.t('delete'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          onSelected: (v) {
            if (v == 'edit') {
              onEdit();
            } else if (v == 'delete') {
              onDelete();
            }
          },
        )
            : null,
      ),
    );
  }
}
