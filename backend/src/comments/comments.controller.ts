import { Controller, Post, Get, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
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

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  update(@GetUser() user: any, @Param('id') id: string, @Body('content') content: string) {
    return this.commentsService.update(user.id, id, content);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  delete(@GetUser() user: any, @Param('id') id: string) {
    return this.commentsService.delete(user.id, id);
  }
}
