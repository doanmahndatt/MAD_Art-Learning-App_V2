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
    final imageUrl = artwork.imageUrl;
    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      imageWidget = Image.memory(base64Decode(imageUrl.split(',').last), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl, fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[100]),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Always white — artwork card keeps original bg regardless of dark mode
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 1, child: imageWidget),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: artwork.authorAvatar != null && !artwork.authorAvatar!.startsWith('data:')
                          ? NetworkImage(artwork.authorAvatar!) : null,
                      child: artwork.authorAvatar == null || artwork.authorAvatar!.startsWith('data:')
                          ? Text(artwork.authorName.isNotEmpty ? artwork.authorName[0] : '?',
                          style: const TextStyle(fontSize: 10, color: AppColors.primary)) : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(artwork.authorName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Text(artwork.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.favorite, size: 14, color: AppColors.like),
                    const SizedBox(width: 2),
                    Text('${artwork.likesCount}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(width: 8),
                    const Icon(Icons.comment, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 2),
                    Text('${artwork.commentsCount}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const Spacer(),
                    Text('${artwork.createdAt.day}/${artwork.createdAt.month}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}