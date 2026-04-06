import { Module } from '@nestjs/common';
import { ArtworksController } from './artworks.controller';
import { ArtworksService } from './artworks.service';
import { PrismaService } from '../prisma/prisma.service';

@Module({
controllers: [ArtworksController],
providers: [ArtworksService, PrismaService],
})
export class ArtworksModule {}