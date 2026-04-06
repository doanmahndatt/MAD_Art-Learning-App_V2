import { IsString, IsNotEmpty, IsOptional, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class StepDto {
@IsNotEmpty()
step_order: number;
@IsString()
title: string;
@IsString()
content: string;
@IsOptional()
image_url?: string;
}

class MaterialDto {
@IsString()
name: string;
@IsOptional()
quantity?: string;
@IsOptional()
note?: string;
}

export class CreateTutorialDto {
@IsString()
title: string;
@IsString()
category: string;
@IsString()
description: string;
@IsOptional()
thumbnail_url?: string;
@IsOptional()
difficulty_level?: string;
@IsArray()
@ValidateNested({ each: true })
@Type(() => StepDto)
steps: StepDto[];
@IsArray()
@ValidateNested({ each: true })
@Type(() => MaterialDto)
materials: MaterialDto[];
}