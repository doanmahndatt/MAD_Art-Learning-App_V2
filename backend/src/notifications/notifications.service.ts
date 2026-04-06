import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNotificationDto } from './dto/create-notification.dto';

@Injectable()
export class NotificationsService {
constructor(private prisma: PrismaService) {}

  async create(dto: CreateNotificationDto, actorId?: string) {
    return this.prisma.notification.create({
      data: {
        receiver_id: dto.receiver_id,
        actor_id: actorId,
        type: dto.type,
        title: dto.title,
        message: dto.message,
        entity_type: dto.entity_type,
        entity_id: dto.entity_id,
      },
    });
  }

  async findByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { receiver_id: userId },
      orderBy: { created_at: 'desc' },
    });
  }

  async markAsRead(notificationId: string) {
    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { is_read: true },
    });
  }
}