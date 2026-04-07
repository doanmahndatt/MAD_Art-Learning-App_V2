import { Module } from '@nestjs/common';
import { TutorialCommentsController } from './tutorial-comments.controller';
import { TutorialCommentsService } from './tutorial-comments.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [TutorialCommentsController],
  providers: [TutorialCommentsService, PrismaService],
})
export class TutorialCommentsModule {}
