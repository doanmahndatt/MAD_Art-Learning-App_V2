import { IsEmail, IsNotEmpty, MinLength, IsOptional, IsString } from 'class-validator';

export class RegisterDto {
@IsEmail()
email: string;

@IsNotEmpty()
@MinLength(6)
password: string;

@IsNotEmpty()
full_name: string;

@IsOptional()
@IsString()
avatar_url?: string;

@IsOptional()
@IsString()
bio?: string;
}

export class LoginDto {
@IsEmail()
email: string;

@IsNotEmpty()
password: string;
}