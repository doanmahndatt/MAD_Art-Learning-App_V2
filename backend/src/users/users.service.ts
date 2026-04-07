import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

const safeUserSelect = {
  id: true,
  email: true,
  full_name: true,
  phone: true,
  gender: true,
  date_of_birth: true,
  avatar_url: true,
  bio: true,
  role: true,
  is_active: true,
  created_at: true,
  updated_at: true,
  notification_enabled: true,
};

const publicUserSelect = {
  id: true,
  full_name: true,
  avatar_url: true,
};

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        ...safeUserSelect,
        tutorials: true,
        artworks: {
          where: { is_public: true },
          include: { likes: true },
        },
        tutorial_favorites: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const totalLikesReceived = user.artworks.reduce((sum, a) => sum + a.likes.length, 0);
    return { ...user, totalTutorials: user.tutorials.length, totalLikesReceived };
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        full_name: dto.full_name,
        bio: dto.bio,
        avatar_url: dto.avatar_url,
        email: dto.email,
        phone: dto.phone,
        gender: dto.gender,
        date_of_birth: dto.date_of_birth ? new Date(dto.date_of_birth) : undefined,
        notification_enabled: dto.notification_enabled,
      },
      select: safeUserSelect,
    });
  }

  async getUserLikedArtworks(userId: string) {
    const likes = await this.prisma.artworkLike.findMany({
      where: { user_id: userId },
      include: {
        artwork: {
          include: { author: { select: publicUserSelect }, likes: true, comments: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });
    return likes.map(like => like.artwork);
  }

  async getUserTutorials(userId: string) {
    return this.prisma.tutorial.findMany({
      where: { created_by: userId },
      include: { author: { select: publicUserSelect }, steps: true, materials: true, comments: true, favorites: true },
      orderBy: { created_at: 'desc' },
    });
  }

  async getUserArtworks(userId: string) {
    return this.prisma.artwork.findMany({
      where: { user_id: userId },
      include: { author: { select: publicUserSelect }, likes: true, comments: true },
      orderBy: { created_at: 'desc' },
    });
  }
}
