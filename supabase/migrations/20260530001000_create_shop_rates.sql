-- Create shop_rates table
CREATE TABLE IF NOT EXISTS public.shop_rates (
    shop_id uuid PRIMARY KEY REFERENCES public.shops(id) ON DELETE CASCADE,
    rate_per_hour integer NOT NULL DEFAULT 0,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.shop_rates ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Shop rates are viewable by everyone" 
    ON public.shop_rates FOR SELECT 
    USING (true);

CREATE POLICY "Owners can manage their own shop rates" 
    ON public.shop_rates FOR ALL 
    USING (EXISTS (
        SELECT 1 FROM public.shops 
        WHERE id = shop_rates.shop_id AND owner_id = auth.uid()
    ));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shop_rates TO authenticated;
GRANT SELECT ON public.shop_rates TO anon;
