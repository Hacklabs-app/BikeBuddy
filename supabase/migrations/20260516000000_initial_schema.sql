-- 1. Create CUSTOM ROLES
CREATE TYPE public.user_role AS ENUM ('owner', 'customer', 'guest');

-- 2. Create PROFILES Table
-- This table stores the extended user data not provided by Supabase Auth
CREATE TABLE public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email text UNIQUE NOT NULL,
    full_name text,
    role public.user_role DEFAULT 'guest'::public.user_role,
    id_number text,
    phone_number text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3. Create SHOPS Table
-- For Station Owners to manage their inventory
CREATE TABLE public.shops (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    name text NOT NULL,
    address text NOT NULL,
    total_bikes integer DEFAULT 0,
    latitude double precision,
    longitude double precision,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

-- 4. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;

-- 5. RLS POLICIES for PROFILES
-- Users can view all profiles (needed for discovery/admin)
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 6. RLS POLICIES for SHOPS
-- Shops are viewable by everyone (for discovery)
CREATE POLICY "Shops are viewable by everyone" 
ON public.shops FOR SELECT USING (true);

-- Only owners can manage their own shop
CREATE POLICY "Owners can manage their own shop" 
ON public.shops FOR ALL USING (auth.uid() = owner_id);

-- 7. AUTOMATED PROFILE CREATION
-- This function runs every time a new user signs up in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    'guest'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- The trigger that calls the function above
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. HELPER FUNCTIONS
-- Function to automatically update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
