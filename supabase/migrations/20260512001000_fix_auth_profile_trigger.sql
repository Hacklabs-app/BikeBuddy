-- Make auth profile creation resilient and explicit about the public schema.
-- Without a fixed search_path, hosted Supabase auth triggers can fail with
-- "Database error saving new user" when resolving user_role.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
  v_id_number TEXT;
BEGIN
  v_role := COALESCE(NULLIF(NEW.raw_user_meta_data->>'role', ''), 'customer');
  v_full_name := COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), 'New user');
  v_id_number := COALESCE(NULLIF(NEW.raw_user_meta_data->>'id_number', ''), 'pending');

  IF v_role NOT IN ('owner', 'customer') THEN
    v_role := 'customer';
  END IF;

  INSERT INTO public.profiles (id, role, full_name, id_number)
  VALUES (
    NEW.id,
    v_role::public.user_role,
    v_full_name,
    v_id_number
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
