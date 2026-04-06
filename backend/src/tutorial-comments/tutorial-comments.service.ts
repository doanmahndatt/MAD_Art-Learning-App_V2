import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialCommentDto } from './dto/create-tutorial-comment.dto';

@Injectable()
export class TutorialCommentsService {
constructor(private prisma: PrismaService) {}

  async create(userId: string, tutorialId: string, dto: CreateTutorialCommentDto) {
    // Kiểm tra tutorial tồn tại
    const tutorial = await this.prisma.tutorial.findUnique({ where: { id: tutorialId } });
    if (!tutorial) throw new NotFoundException('Tutorial not found');

    return this.prisma.tutorialComment.create({
      data: {
        content: dto.content,
        user_id: userId,
        tutorial_id: tutorialId,
      },
      include: { user: true },
    });
  }

  async findByTutorial(tutorialId: string) {
    return this.prisma.tutorialComment.findMany({
      where: { tutorial_id: tutorialId },
      include: { user: true },
      orderBy: { created_at: 'desc' },
    });
  }

  async update(userId: string, commentId: string, content: string) {
    const comment = await this.prisma.tutorialComment.findFirst({
      where: { id: commentId, user_id: userId },
    });
    if (!comment) throw new NotFoundException('Comment not found or not owned');
    return this.prisma.tutorialComment.update({
      where: { id: commentId },
      data: { content },
      include: { user: true },
    });
  }

  async delete(userId: string, commentId: string) {
    const comment = await this.prisma.tutorialComment.findFirst({
      where: { id: commentId, user_id: userId },
    });
    if (!comment) throw new NotFoundException('Comment not found or not owned');
    return this.prisma.tutorialComment.delete({ where: { id: commentId } });
  }
}