import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TutorialsModule } from './tutorials/tutorials.module';
import { ArtworksModule } from './artworks/artworks.module';
import { CommentsModule } from './comments/comments.module';
import { LikesModule } from './likes/likes.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaService } from './prisma/prisma.service';

@Module({
imports: [
ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    UsersModule,
    TutorialsModule,
    ArtworksModule,
    CommentsModule,
    LikesModule,
    NotificationsModule,
  ],
  providers: [PrismaService],
})
export class AppModule {}