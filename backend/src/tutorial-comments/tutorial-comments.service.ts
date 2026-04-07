import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialCommentDto } from './dto/create-tutorial-comment.dto';
import { NotificationsService } from '../notifications/notifications.service';

const userSelect = {
  id: true,
  full_name: true,
  avatar_url: true,
};

@Injectable()
export class TutorialCommentsService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async create(userId: string, tutorialId: string, dto: CreateTutorialCommentDto) {
    const tutorial = await this.prisma.tutorial.findUnique({
      where: { id: tutorialId },
      select: { id: true, title: true, created_by: true },
    });
    if (!tutorial) throw new NotFoundException('Tutorial not found');

    const comment = await this.prisma.tutorialComment.create({
      data: {
        content: dto.content,
        user_id: userId,
        tutorial_id: tutorialId,
      },
      include: { user: { select: userSelect } },
    });

    if (tutorial.created_by && tutorial.created_by !== userId) {
      await this.notificationsService.createIfEnabled(
        tutorial.created_by,
        {
          type: 'tutorial_comment',
          title: 'New tutorial comment',
          message: 'Someone commented on your tutorial.',
          entity_type: 'tutorial',
          entity_id: tutorial.id,
        },
        userId,
      );
    }

    return comment;
  }

  async findByTutorial(tutorialId: string) {
    return this.prisma.tutorialComment.findMany({
      where: { tutorial_id: tutorialId },
      include: { user: { select: userSelect } },
      orderBy: { created_at: 'desc' },
    });
  }

  async update(userId: string, commentId: string, content: string) {
    const comment = await this.prisma.tutorialComment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.user_id !== userId) throw new ForbiddenException('Forbidden');
    return this.prisma.tutorialComment.update({
      where: { id: commentId },
      data: { content, updated_at: new Date() },
      include: { user: { select: userSelect } },
    });
  }

  async delete(userId: string, commentId: string) {
    const comment = await this.prisma.tutorialComment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.user_id !== userId) throw new ForbiddenException('Forbidden');
    return this.prisma.tutorialComment.delete({ where: { id: commentId } });
  }
}
