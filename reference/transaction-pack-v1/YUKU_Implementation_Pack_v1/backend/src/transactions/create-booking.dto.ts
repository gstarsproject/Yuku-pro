import { IsDateString, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';
import { BookingMode } from './transaction.types';

export class CreateBookingDto {
  @IsString() serviceId!: string;
  @IsEnum(['INSTANT', 'REQUEST']) mode!: BookingMode;
  @IsDateString() scheduledStartAt!: string;
  @IsOptional() @IsString() locationText?: string;
  @IsOptional() @IsString() @MinLength(2) customerNote?: string;
  // Customer identity and price MUST be derived server-side from auth + database.
}
