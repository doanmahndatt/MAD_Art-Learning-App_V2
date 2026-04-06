import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateNotificationDto {
@IsString()
receiver_id: string;
@IsString()
type: string;
@IsString()
title: string;
@IsString()
message: string;
@IsOptional()
entity_type?: string;
@IsOptional()
entity_id?: string;
}