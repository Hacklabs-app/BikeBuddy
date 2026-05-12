-- Public discovery needs aggregate availability, not raw rental rows.
-- Keep the public view security-invoker by reading from a small aggregate table
-- maintained by rental triggers instead of from rentals directly.

CREATE TABLE shop_availability (
  shop_id UUID PRIMARY KEY REFERENCES shops(id) ON DELETE CASCADE,
  active_rental_quantity INT NOT NULL DEFAULT 0 CHECK (active_rental_quantity >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE shop_availability ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shop_availability: public read"
  ON shop_availability FOR SELECT
  USING (TRUE);

CREATE OR REPLACE FUNCTION refresh_shop_availability(p_shop_id UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO shop_availability (shop_id, active_rental_quantity, updated_at)
  VALUES (
    p_shop_id,
    COALESCE((
      SELECT SUM(quantity)::INT
      FROM rentals
      WHERE shop_id = p_shop_id AND ended_at IS NULL
    ), 0),
    NOW()
  )
  ON CONFLICT (shop_id) DO UPDATE
    SET
      active_rental_quantity = EXCLUDED.active_rental_quantity,
      updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION sync_shop_availability_on_rental_change()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM refresh_shop_availability(OLD.shop_id);
    RETURN OLD;
  END IF;

  PERFORM refresh_shop_availability(NEW.shop_id);

  IF TG_OP = 'UPDATE' AND OLD.shop_id <> NEW.shop_id THEN
    PERFORM refresh_shop_availability(OLD.shop_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_sync_shop_availability_on_rental_change
  AFTER INSERT OR UPDATE OR DELETE ON rentals
  FOR EACH ROW EXECUTE FUNCTION sync_shop_availability_on_rental_change();

INSERT INTO shop_availability (shop_id, active_rental_quantity)
SELECT
  shops.id,
  COALESCE(SUM(rentals.quantity) FILTER (WHERE rentals.ended_at IS NULL), 0)::INT
FROM shops
LEFT JOIN rentals ON rentals.shop_id = shops.id
GROUP BY shops.id
ON CONFLICT (shop_id) DO UPDATE
  SET
    active_rental_quantity = EXCLUDED.active_rental_quantity,
    updated_at = NOW();

CREATE OR REPLACE VIEW shop_discovery
WITH (security_invoker = true) AS
SELECT
  shops.id AS shop_id,
  shops.name,
  shops.address,
  shops.lat,
  shops.lng,
  shops.total_bikes,
  COALESCE(shop_rates.rate_per_hour, 0) AS rate_per_hour,
  COALESCE(shop_availability.active_rental_quantity, 0)::INT AS active_rental_quantity,
  GREATEST(
    shops.total_bikes - COALESCE(shop_availability.active_rental_quantity, 0),
    0
  )::INT AS available_bikes
FROM shops
LEFT JOIN shop_rates ON shop_rates.shop_id = shops.id
LEFT JOIN shop_availability ON shop_availability.shop_id = shops.id;

GRANT SELECT ON shop_availability TO anon, authenticated;
GRANT SELECT ON shop_discovery TO anon, authenticated;
