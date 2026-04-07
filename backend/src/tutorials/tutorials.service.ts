import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialDto } from './dto/create-tutorial.dto';

const CATEGORY_ALIASES: Record<string, string[]> = {
'Vẽ': ['Vẽ', 'Ve', 'Draw', 'Drawing', 'Sketch', 'Pencil Drawing'],
'Thủ công': ['Thủ công', 'Thu cong', 'Craft', 'Crafts', 'Handicraft', 'DIY'],
'Màu nước': ['Màu nước', 'Mau nuoc', 'Watercolor', 'Watercolour', 'Aquarelle'],
'Chân dung': ['Chân dung', 'Chan dung', 'Portrait', 'Portrait Drawing'],
};

function normalizeText(value?: string | null): string {
  return (value ?? '')
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

function canonicalizeCategory(value?: string | null): string {
  const normalized = normalizeText(value);

  for (const [canonical, aliases] of Object.entries(CATEGORY_ALIASES)) {
    const allCandidates = [canonical, ...aliases];
    if (allCandidates.some((candidate) => normalizeText(candidate) === normalized)) {
      return canonical;
    }
  }

  return (value ?? '').trim();
}

function normalizeTutorialCategory<T extends { category?: string | null }>(tutorial: T): T {
  return {
    ...tutorial,
    category: canonicalizeCategory(tutorial.category),
  };
}

@Injectable()
export class TutorialsService {
  constructor(private prisma: PrismaService) {}

  async findAll(category?: string, keyword?: string) {
    const conditions: any[] = [];

    const kw = (keyword ?? '').trim();
    if (kw !== '') {
      conditions.push({
        OR: [
          { title: { contains: kw, mode: 'insensitive' } },
          { description: { contains: kw, mode: 'insensitive' } },
        ],
      });
    }

    const where = conditions.length > 0 ? { AND: conditions } : {};

    const tutorials = await this.prisma.tutorial.findMany({
      where,
      include: {
        author: true,
        steps: { orderBy: { step_order: 'asc' }, select: { image_url: true } },
        materials: true,
        comments: true,
        favorites: true,
      },
      orderBy: { created_at: 'desc' },
    });

    const normalizedTutorials = tutorials.map((tutorial) =>
      normalizeTutorialCategory(tutorial),
    );

    const selectedCanonicalCategory = canonicalizeCategory(category);
    if (!selectedCanonicalCategory) {
      return normalizedTutorials;
    }

    return normalizedTutorials.filter(
      (tutorial) => tutorial.category === selectedCanonicalCategory,
    );
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
        comments: { include: { user: true }, orderBy: { created_at: 'desc' } },
      },
    });
    if (!tutorial) throw new NotFoundException('Tutorial not found');
    return normalizeTutorialCategory(tutorial);
  }

  async create(userId: string, dto: CreateTutorialDto) {
    const { steps, materials, ...tutorialData } = dto;
    const normalizedCategory = canonicalizeCategory(dto.category);

    return this.prisma.tutorial.create({
      data: {
        ...tutorialData,
        category: normalizedCategory,
        slug: dto.title.toLowerCase().replace(/\s+/g, '-') + '-' + Date.now(),
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
