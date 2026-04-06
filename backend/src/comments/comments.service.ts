import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommentsService {
constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateCommentDto) {
    if (dto.artwork_id) {
      return this.prisma.artworkComment.create({
        data: {
          content: dto.content,
          user_id: userId,
          artwork_id: dto.artwork_id,
        },
        include: { user: true },
      });
    } else if (dto.tutorial_id) {
      // Nếu có bảng tutorial_comments thì tương tự, hiện tại chưa có nên có thể bỏ qua
      throw new Error('Tutorial comments not implemented yet');
    }
    throw new Error('Missing target id');
  }

  async findByArtwork(artworkId: string) {
    return this.prisma.artworkComment.findMany({
      where: { artwork_id: artworkId },
      include: { user: true },
      orderBy: { created_at: 'desc' },
    });
  }
}