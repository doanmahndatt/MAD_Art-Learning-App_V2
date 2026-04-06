import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LikesService {
constructor(private prisma: PrismaService) {}

  async toggleArtworkLike(userId: string, artworkId: string) {
    const existing = await this.prisma.artworkLike.findUnique({
      where: { user_id_artwork_id: { user_id: userId, artwork_id: artworkId } },
    });
    if (existing) {
      await this.prisma.artworkLike.delete({ where: { user_id_artwork_id: { user_id: userId, artwork_id: artworkId } } });
      return { liked: false };
    } else {
      await this.prisma.artworkLike.create({ data: { user_id: userId, artwork_id: artworkId } });
      return { liked: true };
    }
  }
}