import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateCommentDto {
@IsString()
@IsNotEmpty()
content: string;

@IsOptional()
tutorial_id?: string;

@IsOptional()
artwork_id?: string;
}