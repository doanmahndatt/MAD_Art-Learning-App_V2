import 'package:flutter/material.dart';

class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentTile({super.key, required this.comment, required this.isOwner, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundImage: comment['user']?['avatar_url'] != null ? NetworkImage(comment['user']['avatar_url']) : null,
          child: comment['user']?['avatar_url'] == null ? Text(comment['user']?['full_name']?[0] ?? '?') : null,
        ),
        title: Text(comment['user']?['full_name'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(comment['content'] ?? ''),
        trailing: isOwner
            ? PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
            const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) {
            if (value == 'edit') onEdit();
            else if (value == 'delete') onDelete();
          },
        )
            : null,
      ),
    );
  }
}