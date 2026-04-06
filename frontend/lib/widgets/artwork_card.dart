import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artwork.dart';
import '../utils/colors.dart';

class ArtworkCard extends StatelessWidget {
  final Artwork artwork;
  final VoidCallback onTap;

  const ArtworkCard({super.key, required this.artwork, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: artwork.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Icon(Icons.image_not_supported),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: artwork.authorAvatar != null ? NetworkImage(artwork.authorAvatar!) : null,
                        child: artwork.authorAvatar == null ? Text(artwork.authorName[0]) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          artwork.authorName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artwork.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: AppColors.like),
                      const SizedBox(width: 4),
                      Text('${artwork.likesCount}', style: GoogleFonts.inter(fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${artwork.createdAt.day}/${artwork.createdAt.month}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
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