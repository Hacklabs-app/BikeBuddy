-- Add M-Pesa payment and operating hours columns to public.shops table
ALTER TABLE public.shops 
ADD COLUMN IF NOT EXISTS phone_number text,
ADD COLUMN IF NOT EXISTS mpesa_till_number text,
ADD COLUMN IF NOT EXISTS mpesa_paybill_number text,
ADD COLUMN IF NOT EXISTS mpesa_account_number text,
ADD COLUMN IF NOT EXISTS operating_hours_open text DEFAULT '08:00',
ADD COLUMN IF NOT EXISTS operating_hours_close text DEFAULT '18:00';
