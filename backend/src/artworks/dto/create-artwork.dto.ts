import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';

export class CreateArtworkDto {
@IsString()
title: string;

@IsOptional()
description?: string;

@IsString()
image_url: string;

@IsOptional()
source_type?: string;

@IsOptional()
@IsBoolean()
is_public?: boolean;
}