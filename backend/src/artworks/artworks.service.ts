import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateArtworkDto } from './dto/create-artwork.dto';

@Injectable()
export class ArtworksService {
constructor(private prisma: PrismaService) {}

  async findAll(isPublicOnly = true, sortBy: 'latest' | 'popular' = 'latest') {
    // Tạm thời bỏ qua sortBy popular, chỉ dùng latest
    return this.prisma.artwork.findMany({
      where: isPublicOnly ? { is_public: true } : {},
      include: { author: true, likes: true, comments: { take: 3 } },
      orderBy: { created_at: 'desc' },
    });
  }

  async findOne(id: string) {
    const artwork = await this.prisma.artwork.findUnique({
      where: { id },
      include: { author: true, likes: true, comments: { include: { user: true }, orderBy: { created_at: 'desc' } } },
    });
    if (!artwork) throw new NotFoundException('Artwork not found');
    return artwork;
  }

  async create(userId: string, dto: CreateArtworkDto) {
    return this.prisma.artwork.create({
      data: { ...dto, user_id: userId },
      include: { author: true },
    });
  }

  async delete(userId: string, artworkId: string) {
    const artwork = await this.prisma.artwork.findFirst({ where: { id: artworkId, user_id: userId } });
    if (!artwork) throw new NotFoundException('Artwork not found or not owned');
    return this.prisma.artwork.delete({ where: { id: artworkId } });
  }

  async toggleLike(userId: string, artworkId: string) {
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