import { Module } from '@nestjs/common';
import { ArtworksController } from './artworks.controller';
import { ArtworksService } from './artworks.service';
import { UsersModule } from '../users/users.module';
import { PrismaService } from '../prisma/prisma.service';

@Module({
imports: [UsersModule],
controllers: [ArtworksController],
providers: [ArtworksService, PrismaService],
})
export class ArtworksModule {}