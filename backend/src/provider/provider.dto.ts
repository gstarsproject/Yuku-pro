import { IsBoolean, IsDateString, IsEnum, IsInt, IsOptional, IsString, IsUUID, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateProviderServiceDto {
  @IsUUID() categoryId!: string;
  @IsString() @MinLength(5) @MaxLength(120) title!: string;
  @IsString() @MinLength(20) @MaxLength(5000) description!: string;
  @IsEnum(['ONLINE', 'OFFLINE', 'BOTH']) mode!: 'ONLINE' | 'OFFLINE' | 'BOTH';
  @IsInt() @Min(1) @Max(1000000000) priceAmount!: number;
  @IsOptional() @IsString() @MaxLength(3) currency?: string;
  @IsEnum(['HOUR', 'SESSION', 'DAY', 'FIXED']) priceUnit!: 'HOUR' | 'SESSION' | 'DAY' | 'FIXED';
  @IsOptional() @IsInt() @Min(15) @Max(1440) durationMinutes?: number;
  @IsOptional() @IsString() @MaxLength(100) city?: string;
  @IsOptional() @IsString() @MaxLength(100) province?: string;
}

export class UpdateProviderServiceDto {
  @IsOptional() @IsString() @MinLength(5) @MaxLength(120) title?: string;
  @IsOptional() @IsString() @MinLength(20) @MaxLength(5000) description?: string;
  @IsOptional() @IsEnum(['ONLINE', 'OFFLINE', 'BOTH']) mode?: 'ONLINE' | 'OFFLINE' | 'BOTH';
  @IsOptional() @IsInt() @Min(1) @Max(1000000000) priceAmount?: number;
  @IsOptional() @IsString() @MaxLength(3) currency?: string;
  @IsOptional() @IsEnum(['HOUR', 'SESSION', 'DAY', 'FIXED']) priceUnit?: 'HOUR' | 'SESSION' | 'DAY' | 'FIXED';
  @IsOptional() @IsInt() @Min(15) @Max(1440) durationMinutes?: number;
  @IsOptional() @IsString() @MaxLength(100) city?: string;
  @IsOptional() @IsString() @MaxLength(100) province?: string;
  @IsOptional() @IsBoolean() isPublished?: boolean;
}

export class CreateAvailabilityDto {
  @IsDateString() startsAt!: string;
  @IsDateString() endsAt!: string;
  @IsOptional() @IsBoolean() isBlocked?: boolean;
}
