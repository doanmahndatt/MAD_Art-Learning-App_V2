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
        tutorials: { take: 5, orderBy: { created_at: 'desc' } },
        artworks: { where: { is_public: true }, take: 10, orderBy: { created_at: 'desc' } },
        tutorial_favorites: { include: { tutorial: true } },
        tutorial_reviews: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    const { password_hash, ...result } = user;
    return result;
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
    const { password_hash, ...result } = user;
    return result;
  }
}