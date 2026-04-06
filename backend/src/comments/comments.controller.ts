import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { CommentsService } from './comments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { CreateCommentDto } from './dto/create-comment.dto';

@Controller('comments')
export class CommentsController {
constructor(private commentsService: CommentsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@GetUser() user: any, @Body() dto: CreateCommentDto) {
    return this.commentsService.create(user.id, dto);
  }

  @Get('artwork/:artworkId')
  findByArtwork(@Param('artworkId') artworkId: string) {
    return this.commentsService.findByArtwork(artworkId);
  }
}