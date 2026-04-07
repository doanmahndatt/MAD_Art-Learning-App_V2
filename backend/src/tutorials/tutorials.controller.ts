import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { TutorialsService } from './tutorials.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { CreateTutorialDto } from './dto/create-tutorial.dto';
import { UpdateTutorialDto } from './dto/update-tutorial.dto';

@Controller('tutorials')
export class TutorialsController {
  constructor(private tutorialsService: TutorialsService) {}

  @Get()
  findAll(@Query('category') category?: string, @Query('keyword') keyword?: string) {
    return this.tutorialsService.findAll(category, keyword);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tutorialsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@GetUser() user: any, @Body() dto: CreateTutorialDto) {
    return this.tutorialsService.create(user.id, dto);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  update(@GetUser() user: any, @Param('id') id: string, @Body() dto: UpdateTutorialDto) {
    return this.tutorialsService.update(user.id, id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  delete(@GetUser() user: any, @Param('id') id: string) {
    return this.tutorialsService.delete(user.id, id);
  }

  @Post(':id/favorite')
  @UseGuards(JwtAuthGuard)
  toggleFavorite(@GetUser() user: any, @Param('id') id: string) {
    return this.tutorialsService.toggleFavorite(user.id, id);
  }
}
