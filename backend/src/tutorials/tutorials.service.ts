import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialDto } from './dto/create-tutorial.dto';

@Injectable()
export class TutorialsService {
constructor(private prisma: PrismaService) {}

  async findAll(category?: string, keyword?: string) {
    const where: any = {};
    if (category && category !== 'Tất cả') where.category = category;
    if (keyword) {
      where.OR = [
        { title: { contains: keyword, mode: 'insensitive' } },
        { description: { contains: keyword, mode: 'insensitive' } },
      ];
    }
    return this.prisma.tutorial.findMany({
      where,
      include: { author: true, steps: { orderBy: { step_order: 'asc' } }, materials: true },
      orderBy: { created_at: 'desc' },
    });
  }

  async findOne(id: string) {
    const tutorial = await this.prisma.tutorial.findUnique({
      where: { id },
      include: {
        author: true,
        steps: { orderBy: { step_order: 'asc' } },
        materials: true,
        reviews: { include: { user: true }, orderBy: { created_at: 'desc' } },
        favorites: true,
      },
    });
    if (!tutorial) throw new NotFoundException('Tutorial not found');
    return tutorial;
  }

  async create(userId: string, dto: CreateTutorialDto) {
    const { steps, materials, ...tutorialData } = dto;
    return this.prisma.tutorial.create({
      data: {
        ...tutorialData,
        slug: dto.title.toLowerCase().replace(/ /g, '-') + '-' + Date.now(),
        created_by: userId,
        steps: { create: steps },
        materials: { create: materials },
      },
      include: { steps: true, materials: true },
    });
  }

  async toggleFavorite(userId: string, tutorialId: string) {
    const existing = await this.prisma.tutorialFavorite.findUnique({
      where: { user_id_tutorial_id: { user_id: userId, tutorial_id: tutorialId } },
    });
    if (existing) {
      await this.prisma.tutorialFavorite.delete({ where: { user_id_tutorial_id: { user_id: userId, tutorial_id: tutorialId } } });
      return { favorited: false };
    } else {
      await this.prisma.tutorialFavorite.create({ data: { user_id: userId, tutorial_id: tutorialId } });
      return { favorited: true };
    }
  }
    async getComments(tutorialId: string) {
      return this.prisma.tutorialComment.findMany({
        where: { tutorial_id: tutorialId },
        include: { user: true },
        orderBy: { created_at: 'desc' },
      });
    }
}