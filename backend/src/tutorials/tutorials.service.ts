import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTutorialDto } from './dto/create-tutorial.dto';

// Canonical category values — must match exactly what frontend sends and what's stored in DB
const VALID_CATEGORIES = ['Vẽ', 'Thủ công', 'Màu nước', 'Chân dung'];

@Injectable()
export class TutorialsService {
constructor(private prisma: PrismaService) {}

  async findAll(category?: string, keyword?: string) {
    const conditions: any[] = [];

    // Category filter
    // Frontend sends canonical Vietnamese value ('Vẽ', 'Thủ công', etc.) or empty string for "All"
    const cat = (category ?? '').trim();
    if (cat !== '') {
      conditions.push({
        category: {
          equals: cat,
          mode: 'insensitive',  // handle any accidental case mismatch
        },
      });
    }

    // Keyword filter — AND with category (not OR)
    const kw = (keyword ?? '').trim();
    if (kw !== '') {
      conditions.push({
        OR: [
          { title:       { contains: kw, mode: 'insensitive' } },
          { description: { contains: kw, mode: 'insensitive' } },
        ],
      });
    }

    const where = conditions.length > 0 ? { AND: conditions } : {};

    return this.prisma.tutorial.findMany({
      where,
      include: {
        author: true,
        steps:     { orderBy: { step_order: 'asc' }, select: { image_url: true } },
        materials: true,
        comments:  true,
        favorites: true,
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async findOne(id: string) {
    const tutorial = await this.prisma.tutorial.findUnique({
      where: { id },
      include: {
        author: true,
        steps:     { orderBy: { step_order: 'asc' } },
        materials: true,
        reviews:   { include: { user: true }, orderBy: { created_at: 'desc' } },
        favorites: true,
        comments:  { include: { user: true }, orderBy: { created_at: 'desc' } },
      },
    });
    if (!tutorial) throw new NotFoundException('Tutorial not found');
    return tutorial;
  }

  async create(userId: string, dto: CreateTutorialDto) {
    const { steps, materials, ...tutorialData } = dto;

    // Normalize category to canonical form before saving
    const normalizedCategory = VALID_CATEGORIES.find(
      (c) => c.toLowerCase() === dto.category.trim().toLowerCase()
    ) ?? dto.category.trim();

    return this.prisma.tutorial.create({
      data: {
        ...tutorialData,
        category: normalizedCategory,
        slug: dto.title.toLowerCase().replace(/\s+/g, '-') + '-' + Date.now(),
        created_by: userId,
        steps:     { create: steps },
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