import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialDto } from './dto/create-tutorial.dto';
import { UpdateTutorialDto } from './dto/update-tutorial.dto';

const VALID_CATEGORIES = ['Vẽ', 'Thủ công', 'Màu nước', 'Chân dung'];
const publicUserSelect = {
  id: true,
  full_name: true,
  avatar_url: true,
};

@Injectable()
export class TutorialsService {
  constructor(private prisma: PrismaService) {}

  private normalizeCategory(category?: string) {
    const raw = (category ?? '').trim();
    if (!raw) return raw;
    return VALID_CATEGORIES.find((c) => c.toLowerCase() == raw.toLowerCase()) ?? raw;
  }

  async findAll(category?: string, keyword?: string) {
    const conditions: any[] = [];
    const cat = this.normalizeCategory(category);
    const kw = (keyword ?? '').trim();

    if (kw !== '') {
      conditions.push({
        OR: [
          { title: { contains: kw, mode: 'insensitive' } },
          { description: { contains: kw, mode: 'insensitive' } },
        ],
      });
    }

    const tutorials = await this.prisma.tutorial.findMany({
      where: conditions.length > 0 ? { AND: conditions } : {},
      include: {
        author: { select: publicUserSelect },
        steps: { orderBy: { step_order: 'asc' }, select: { image_url: true } },
        materials: true,
        comments: true,
        favorites: true,
      },
      orderBy: { created_at: 'desc' },
    });

    if (!cat) return tutorials;
    return tutorials.filter((tutorial) => this.normalizeCategory(tutorial.category) == cat);
  }

  async findOne(id: string) {
    const tutorial = await this.prisma.tutorial.findUnique({
      where: { id },
      include: {
        author: { select: publicUserSelect },
        steps: { orderBy: { step_order: 'asc' } },
        materials: true,
        reviews: { include: { user: { select: publicUserSelect } }, orderBy: { created_at: 'desc' } },
        favorites: true,
        comments: { include: { user: { select: publicUserSelect } }, orderBy: { created_at: 'desc' } },
      },
    });
    if (!tutorial) throw new NotFoundException('Tutorial not found');
    return tutorial;
  }

  async create(userId: string, dto: CreateTutorialDto) {
    const { steps, materials, ...tutorialData } = dto;
    const normalizedCategory = this.normalizeCategory(dto.category);

    return this.prisma.tutorial.create({
      data: {
        ...tutorialData,
        category: normalizedCategory,
        slug: dto.title.toLowerCase().replace(/\s+/g, '-') + '-' + Date.now(),
        created_by: userId,
        steps: { create: steps },
        materials: { create: materials },
      },
      include: {
        author: { select: publicUserSelect },
        steps: { orderBy: { step_order: 'asc' } },
        materials: true,
        comments: true,
        favorites: true,
      },
    });
  }

  async update(userId: string, tutorialId: string, dto: UpdateTutorialDto) {
    const tutorial = await this.prisma.tutorial.findFirst({ where: { id: tutorialId, created_by: userId } });
    if (!tutorial) throw new NotFoundException('Tutorial not found or not owned');

    const { steps, materials, ...tutorialData } = dto;
    const normalizedCategory = dto.category ? this.normalizeCategory(dto.category) : undefined;

    return this.prisma.$transaction(async (tx) => {
      if (steps) {
        await tx.tutorialStep.deleteMany({ where: { tutorial_id: tutorialId } });
      }
      if (materials) {
        await tx.material.deleteMany({ where: { tutorial_id: tutorialId } });
      }

      return tx.tutorial.update({
        where: { id: tutorialId },
        data: {
          title: tutorialData.title,
          category: normalizedCategory,
          description: tutorialData.description,
          thumbnail_url: tutorialData.thumbnail_url,
          difficulty_level: tutorialData.difficulty_level,
          updated_at: new Date(),
          steps: steps ? { create: steps } : undefined,
          materials: materials ? { create: materials } : undefined,
        },
        include: {
          author: { select: publicUserSelect },
          steps: { orderBy: { step_order: 'asc' } },
          materials: true,
          comments: true,
          favorites: true,
        },
      });
    });
  }

  async delete(userId: string, tutorialId: string) {
    const tutorial = await this.prisma.tutorial.findFirst({ where: { id: tutorialId, created_by: userId } });
    if (!tutorial) throw new NotFoundException('Tutorial not found or not owned');
    return this.prisma.tutorial.delete({ where: { id: tutorialId } });
  }

  async toggleFavorite(userId: string, tutorialId: string) {
    const existing = await this.prisma.tutorialFavorite.findUnique({
      where: { user_id_tutorial_id: { user_id: userId, tutorial_id: tutorialId } },
    });
    if (existing) {
      await this.prisma.tutorialFavorite.delete({
        where: { user_id_tutorial_id: { user_id: userId, tutorial_id: tutorialId } },
      });
      return { favorited: false };
    } else {
      await this.prisma.tutorialFavorite.create({
        data: { user_id: userId, tutorial_id: tutorialId },
      });
      return { favorited: true };
    }
  }
}
