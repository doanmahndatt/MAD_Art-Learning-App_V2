import { Controller, Post, Param, UseGuards } from '@nestjs/common';
import { LikesService } from './likes.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';

@Controller('likes')
@UseGuards(JwtAuthGuard)
export class LikesController {
constructor(private likesService: LikesService) {}

  @Post('artwork/:id')
  toggleArtworkLike(@GetUser() user: any, @Param('id') id: string) {
    return this.likesService.toggleArtworkLike(user.id, id);
  }
}