import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tutorial.dart';
import '../utils/colors.dart';

class TutorialCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;

  const TutorialCard({super.key, required this.tutorial, required this.onTap});

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
    }
    if (imageUrl.startsWith('data:image')) {
      final base64String = imageUrl.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: double.infinity, height: 140);
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        placeholder: (_, __) => Container(color: Colors.grey[200]),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImage(tutorial.thumbnailUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tutorial.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tutorial.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tutorial.authorName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.format_list_numbered, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('${tutorial.stepsCount} bước', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                      const SizedBox(width: 12),
                      const Icon(Icons.favorite_border, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text('${tutorial.likesCount}', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
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