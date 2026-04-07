import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        tutorials: true,
        artworks: { where: { is_public: true }, include: { likes: true } },
        tutorial_favorites: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const totalLikesReceived = user.artworks.reduce((sum, a) => sum + a.likes.length, 0);
    const { password_hash, ...result } = user;
    return { ...result, totalTutorials: user.tutorials.length, totalLikesReceived };
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        full_name: dto.full_name,
        bio: dto.bio,
        avatar_url: dto.avatar_url,
        email: dto.email,
        phone: dto.phone,
        gender: dto.gender,
        date_of_birth: dto.date_of_birth ? new Date(dto.date_of_birth) : undefined,
      },
    });
    const { password_hash, ...result } = user;
    return result;
  }

  async getUserLikedArtworks(userId: string) {
    const likes = await this.prisma.artworkLike.findMany({
      where: { user_id: userId },
      include: {
        artwork: {
          include: { author: true, likes: true, comments: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });
    return likes.map(like => like.artwork);
  }

  async getUserTutorials(userId: string) {
      return this.prisma.tutorial.findMany({
        where: { created_by: userId },
        include: { author: true, steps: true, materials: true, comments: true, favorites: true },
        orderBy: { created_at: 'desc' },
      });
  }

  async getUserArtworks(userId: string) {
      return this.prisma.artwork.findMany({
        where: { user_id: userId, is_public: true },
        include: { author: true, likes: true, comments: true },
        orderBy: { created_at: 'desc' },
      });
  }
}