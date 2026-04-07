import { Controller, Get, Put, Body, UseGuards, Param } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { GetUser } from '../common/decorators/get-user.decorator';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
constructor(private usersService: UsersService) {}

  @Get('profile')
  getProfile(@GetUser() user: any) {
    return this.usersService.getProfile(user.id);
  }

  @Put('profile')
  updateProfile(@GetUser() user: any, @Body() dto: UpdateUserDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Get('my-artworks')
    @UseGuards(JwtAuthGuard)
    async getMyArtworks(@GetUser() user: any) {
      return this.usersService.getUserArtworks(user.id);
  }

  @Get('my-tutorials')
    @UseGuards(JwtAuthGuard)
    async getMyTutorials(@GetUser() user: any) {
      return this.usersService.getUserTutorials(user.id);
  }
}