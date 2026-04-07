import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
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

  async createIfEnabled(receiverId: string, dto: Omit<CreateNotificationDto, 'receiver_id'>, actorId?: string) {
    const receiver = await this.prisma.user.findUnique({
      where: { id: receiverId },
      select: { id: true, notification_enabled: true },
    });
    if (!receiver || !receiver.notification_enabled) return null;
    return this.create({ ...dto, receiver_id: receiverId }, actorId);
  }

  async findByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { receiver_id: userId },
      include: {
        actor: {
          select: {
            id: true,
            full_name: true,
            avatar_url: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async markAsRead(notificationId: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id: notificationId } });
    if (!notification) throw new NotFoundException('Notification not found');
    if (notification.receiver_id !== userId) throw new ForbiddenException('Forbidden');
    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { is_read: true },
    });
  }
}
