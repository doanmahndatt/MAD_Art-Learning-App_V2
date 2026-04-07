import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { NotificationsService } from '../notifications/notifications.service';

const userSelect = {
  id: true,
  full_name: true,
  avatar_url: true,
};

@Injectable()
export class CommentsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async create(userId: string, dto: CreateCommentDto) {
    if (!dto.artwork_id) {
      throw new NotFoundException('artwork_id is required');
    }

    const artwork = await this.prisma.artwork.findUnique({
      where: { id: dto.artwork_id },
      select: { id: true, title: true, user_id: true },
    });
    if (!artwork) throw new NotFoundException('Artwork not found');

    const comment = await this.prisma.artworkComment.create({
      data: {
        content: dto.content,
        user_id: userId,
        artwork_id: dto.artwork_id,
      },
      include: { user: { select: userSelect } },
    });

    if (artwork.user_id !== userId) {
      await this.notificationsService.createIfEnabled(
        artwork.user_id,
        {
          type: 'artwork_comment',
          title: 'New artwork comment',
          message: 'Someone commented on your artwork.',
          entity_type: 'artwork',
          entity_id: artwork.id,
        },
        userId,
      );
    }

    return comment;
  }

  async findByArtwork(artworkId: string) {
    return this.prisma.artworkComment.findMany({
      where: { artwork_id: artworkId },
      include: { user: { select: userSelect } },
      orderBy: { created_at: 'desc' },
    });
  }

  async update(userId: string, commentId: string, content: string) {
    const comment = await this.prisma.artworkComment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.user_id !== userId) throw new ForbiddenException('Forbidden');

    return this.prisma.artworkComment.update({
      where: { id: commentId },
      data: { content, updated_at: new Date() },
      include: { user: { select: userSelect } },
    });
  }

  async delete(userId: string, commentId: string) {
    const comment = await this.prisma.artworkComment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.user_id !== userId) throw new ForbiddenException('Forbidden');
    return this.prisma.artworkComment.delete({ where: { id: commentId } });
  }
}
