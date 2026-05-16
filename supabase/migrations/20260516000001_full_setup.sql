-- ==========================================
-- BIKEBUDDY CORE SCHEMA SETUP (V4 - TERMINOLOGY UPDATE)
-- ==========================================

-- 1. SCHEMATIC PERMISSIONS
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;

-- 2. CUSTOM TYPES (Idempotent update)
DO $$ 
BEGIN
    -- We'll add 'pending' and keep 'guest' for backwards compatibility if needed, 
    -- but our trigger will use 'pending'.
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM ('owner', 'customer', 'pending');
    ELSE
        -- If it exists, we might need to add the new value
        BEGIN
            ALTER TYPE public.user_role ADD VALUE 'pending';
        EXCEPTION
            WHEN duplicate_object THEN null;
        END;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bike_status') THEN
        CREATE TYPE public.bike_status AS ENUM ('available', 'rented', 'maintenance');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'rental_status') THEN
        CREATE TYPE public.rental_status AS ENUM ('ongoing', 'completed', 'cancelled');
    END IF;
END $$;

-- 3. TABLES
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email text UNIQUE NOT NULL,
    full_name text,
    role public.user_role DEFAULT 'pending'::public.user_role,
    id_number text,
    phone_number text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.shops (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    name text NOT NULL,
    address text NOT NULL,
    total_bikes integer DEFAULT 0,
    latitude double precision,
    longitude double precision,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.bikes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    shop_id uuid REFERENCES public.shops(id) ON DELETE CASCADE NOT NULL,
    identifier text NOT NULL,
    status public.bike_status DEFAULT 'available'::public.bike_status,
    category text DEFAULT 'mountain',
    hourly_rate numeric(10,2) DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(shop_id, identifier)
);

CREATE TABLE IF NOT EXISTS public.rentals (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id) NOT NULL,
    bike_id uuid REFERENCES public.bikes(id) NOT NULL,
    shop_id uuid REFERENCES public.shops(id) NOT NULL,
    start_time timestamptz DEFAULT now(),
    end_time timestamptz,
    total_price numeric(10,2),
    status public.rental_status DEFAULT 'ongoing'::public.rental_status,
    created_at timestamptz DEFAULT now()
);

-- 4. GRANT TABLE PERMISSIONS
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shops TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bikes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.rentals TO authenticated;

-- 5. ENABLE RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bikes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
CREATE POLICY "Users can manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Shops are viewable by everyone" ON public.shops;
CREATE POLICY "Shops are viewable by everyone" ON public.shops FOR SELECT USING (true);

DROP POLICY IF EXISTS "Owners can manage their own shop" ON public.shops;
CREATE POLICY "Owners can manage their own shop" ON public.shops FOR ALL USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Bikes are viewable by everyone" ON public.bikes;
CREATE POLICY "Bikes are viewable by everyone" ON public.bikes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Owners can manage shop bikes" ON public.bikes;
CREATE POLICY "Owners can manage shop bikes" ON public.bikes FOR ALL 
USING (EXISTS (SELECT 1 FROM public.shops WHERE id = shop_id AND owner_id = auth.uid()));

DROP POLICY IF EXISTS "Users can view their own rentals" ON public.rentals;
CREATE POLICY "Users can view their own rentals" ON public.rentals FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Owners can view their station rentals" ON public.rentals;
CREATE POLICY "Owners can view their station rentals" ON public.rentals FOR SELECT 
USING (EXISTS (SELECT 1 FROM public.shops WHERE id = shop_id AND owner_id = auth.uid()));

-- 7. AUTOMATION TRIGGERS

-- Updated Trigger to use 'pending' role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    'pending'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated At Helper
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_profiles_updated ON public.profiles;
CREATE TRIGGER tr_profiles_updated BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_shops_updated ON public.shops;
CREATE TRIGGER tr_shops_updated BEFORE UPDATE ON public.shops FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_bikes_updated ON public.bikes;
CREATE TRIGGER tr_bikes_updated BEFORE UPDATE ON public.bikes FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
