import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto, LoginDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
constructor(private prisma: PrismaService, private jwtService: JwtService) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already exists');
    const hash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        password_hash: hash,
        full_name: dto.full_name,
        avatar_url: dto.avatar_url,
        bio: dto.bio,
      },
    });
    const token = this.jwtService.sign({ sub: user.id, email: user.email, role: user.role });
    const { password_hash, ...userWithoutPwd } = user;
    return { user: userWithoutPwd, token };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');
    const valid = await bcrypt.compare(dto.password, user.password_hash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    const token = this.jwtService.sign({ sub: user.id, email: user.email, role: user.role });
    const { password_hash, ...userWithoutPwd } = user;
    return { user: userWithoutPwd, token };
  }

  async forgotPassword(email: string) {
    // In production, send email with reset link. For now just return message.
    return { message: 'If email exists, reset link sent' };
  }
}