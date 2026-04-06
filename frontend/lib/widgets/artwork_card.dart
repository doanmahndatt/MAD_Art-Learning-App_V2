import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artwork.dart';
import '../utils/colors.dart';

class ArtworkCard extends StatelessWidget {
  final Artwork artwork;
  final VoidCallback onTap;

  const ArtworkCard({super.key, required this.artwork, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final imageUrl = artwork.imageUrl;

    if (imageUrl.startsWith('data:image')) {
      // Xử lý base64
      final base64String = imageUrl.split(',').last;
      final bytes = base64Decode(base64String);
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // URL thường
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: imageWidget,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: artwork.authorAvatar != null && !artwork.authorAvatar!.startsWith('data:')
                            ? NetworkImage(artwork.authorAvatar!)
                            : null,
                        child: artwork.authorAvatar == null || artwork.authorAvatar!.startsWith('data:')
                            ? Text(artwork.authorName.isNotEmpty ? artwork.authorName[0] : '?', style: const TextStyle(fontSize: 10))
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          artwork.authorName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artwork.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: AppColors.like),
                      const SizedBox(width: 2),
                      Text('${artwork.likesCount}', style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 8),
                      Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text('${artwork.commentsCount}', style: const TextStyle(fontSize: 11)),
                      const Spacer(),
                      Text(
                        '${artwork.createdAt.day}/${artwork.createdAt.month}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}