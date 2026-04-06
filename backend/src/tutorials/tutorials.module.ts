import { Module } from '@nestjs/common';
import { TutorialsController } from './tutorials.controller';
import { TutorialsService } from './tutorials.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
controllers: [TutorialsController],
providers: [TutorialsService, PrismaService],
})
export class TutorialsModule {}