import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateArtworkDto } from './dto/create-artwork.dto';
import { UpdateArtworkDto } from './dto/update-artwork.dto';

@Injectable()
export class ArtworksService {
  constructor(private prisma: PrismaService) {}

  async findAll(isPublicOnly = true, sortBy: 'latest' | 'popular' = 'latest') {
    let orderBy: any = { created_at: 'desc' };
    if (sortBy === 'popular') {
      orderBy = { likes: { _count: 'desc' } };
    }
    return this.prisma.artwork.findMany({
      where: isPublicOnly ? { is_public: true } : {},
      include: { author: true, likes: true, comments: { take: 3 } },
      orderBy,
    });
  }

  async findOne(id: string) {
    const artwork = await this.prisma.artwork.findUnique({
      where: { id },
      include: {
        author: true,
        likes: true,
        comments: { include: { user: true }, orderBy: { created_at: 'desc' } },
      },
    });
    if (!artwork) throw new NotFoundException('Artwork not found');
    return artwork;
  }

  async create(userId: string, dto: CreateArtworkDto) {
    return this.prisma.artwork.create({
      data: { ...dto, user_id: userId },
      include: { author: true, likes: true, comments: true },
    });
  }

  async update(userId: string, artworkId: string, dto: UpdateArtworkDto) {
    const artwork = await this.prisma.artwork.findFirst({ where: { id: artworkId, user_id: userId } });
    if (!artwork) throw new NotFoundException('Artwork not found or not owned');

    return this.prisma.artwork.update({
      where: { id: artworkId },
      data: {
        title: dto.title,
        description: dto.description,
        image_url: dto.image_url,
        source_type: dto.source_type,
        is_public: dto.is_public,
        updated_at: new Date(),
      },
      include: { author: true, likes: true, comments: true },
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

  async getUserLikedArtworks(userId: string) {
    const likes = await this.prisma.artworkLike.findMany({
      where: { user_id: userId },
      include: { artwork: { include: { author: true, likes: true, comments: true } } },
      orderBy: { created_at: 'desc' },
    });
    return likes.map((like) => like.artwork);
  }
}
