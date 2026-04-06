import { IsString, IsNotEmpty } from 'class-validator';

export class CreateTutorialCommentDto {
@IsString()
@IsNotEmpty()
content: string;
}