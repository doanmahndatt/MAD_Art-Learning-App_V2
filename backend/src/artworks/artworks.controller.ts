import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ArtworksService } from './artworks.service';
import { UsersService } from '../users/users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { CreateArtworkDto } from './dto/create-artwork.dto';

@Controller('artworks')
export class ArtworksController {
constructor(
    private artworksService: ArtworksService,
    private usersService: UsersService,
  ) {}

  @Get()
  findAll(@Query('sort') sort: 'latest' | 'popular' = 'latest') {
    return this.artworksService.findAll(true, sort);
  }

  @Get('liked')
  @UseGuards(JwtAuthGuard)
  async getUserLiked(@GetUser() user: any) {
    return this.usersService.getUserLikedArtworks(user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.artworksService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  create(@GetUser() user: any, @Body() dto: CreateArtworkDto) {
    return this.artworksService.create(user.id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  delete(@GetUser() user: any, @Param('id') id: string) {
    return this.artworksService.delete(user.id, id);
  }

  @Post(':id/like')
  @UseGuards(JwtAuthGuard)
  toggleLike(@GetUser() user: any, @Param('id') id: string) {
    return this.artworksService.toggleLike(user.id, id);
  }
}