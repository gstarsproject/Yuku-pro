import { IsDateString, IsInt, IsOptional, IsString, IsUUID, Max, Min, IsIn, MaxLength } from 'class-validator';
export class CreateBookingDto {
  @IsUUID() serviceId: string;
  @IsDateString() startsAt: string;
  @IsDateString() endsAt: string;
  @IsInt() @Min(1) @Max(20) attendeeCount: number;
  @IsOptional() @IsString() @MaxLength(2000) customerNote?: string;
  @IsOptional() @IsInt() @Min(0) travelFee?: number;
  @IsIn(['INSTANT', 'REQUEST']) bookingMode: 'INSTANT' | 'REQUEST';
}
export class BookingActionDto {
  @IsUUID() bookingId: string;
}
