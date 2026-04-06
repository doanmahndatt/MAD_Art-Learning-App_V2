import { Controller, Post, Get, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { TutorialCommentsService } from './tutorial-comments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { CreateTutorialCommentDto } from './dto/create-tutorial-comment.dto';

@Controller('tutorials/:tutorialId/comments')
export class TutorialCommentsController {
constructor(private commentsService: TutorialCommentsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@GetUser() user: any, @Param('tutorialId') tutorialId: string, @Body() dto: CreateTutorialCommentDto) {
    return this.commentsService.create(user.id, tutorialId, dto);
  }

  @Get()
  findByTutorial(@Param('tutorialId') tutorialId: string) {
    return this.commentsService.findByTutorial(tutorialId);
  }

  @Put(':commentId')
  @UseGuards(JwtAuthGuard)
  update(@GetUser() user: any, @Param('commentId') commentId: string, @Body('content') content: string) {
    return this.commentsService.update(user.id, commentId, content);
  }

  @Delete(':commentId')
  @UseGuards(JwtAuthGuard)
  delete(@GetUser() user: any, @Param('commentId') commentId: string) {
    return this.commentsService.delete(user.id, commentId);
  }
}