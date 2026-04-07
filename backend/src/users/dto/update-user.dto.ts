import { IsOptional, IsString, IsEmail } from 'class-validator';

export class UpdateUserDto {
@IsOptional() @IsString() full_name?: string;
@IsOptional() @IsString() avatar_url?: string;
@IsOptional() @IsString() bio?: string;
@IsOptional() @IsEmail() email?: string;
@IsOptional() @IsString() phone?: string;
@IsOptional() @IsString() gender?: string;
@IsOptional() date_of_birth?: string; // ISO string
}