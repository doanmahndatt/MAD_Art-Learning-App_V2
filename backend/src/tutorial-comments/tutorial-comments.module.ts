import { Module } from '@nestjs/common';
import { TutorialCommentsController } from './tutorial-comments.controller';
import { TutorialCommentsService } from './tutorial-comments.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
controllers: [TutorialCommentsController],
providers: [TutorialCommentsService, PrismaService],
})
export class TutorialCommentsModule {}