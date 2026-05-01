-- =============================================================================
-- BikeBuddy Initial Schema
-- =============================================================================

-- =============================================================================
-- ENUMS
-- =============================================================================

CREATE TYPE user_role AS ENUM ('owner', 'customer');
CREATE TYPE loyalty_trigger_type AS ENUM ('rides', 'hours');
CREATE TYPE loyalty_reward_type AS ENUM ('free_minutes', 'discount_percent');


-- =============================================================================
-- TABLES
-- =============================================================================

-- Extends Supabase auth.users with app-specific profile data.
CREATE TABLE profiles (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role        user_role   NOT NULL,
  full_name   TEXT        NOT NULL,
  id_number   TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One shop per owner in the MVP.
CREATE TABLE shops (
  id           UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     UUID  NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name         TEXT  NOT NULL,
  address      TEXT  NOT NULL,
  lat          FLOAT8,
  lng          FLOAT8,
  total_bikes  INT   NOT NULL CHECK (total_bikes >= 0),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (owner_id)
);

-- One rate per shop. Rate changes only apply to new rentals.
CREATE TABLE shop_rates (
  id            UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id       UUID  NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  rate_per_hour INT   NOT NULL CHECK (rate_per_hour > 0),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (shop_id)
);

-- Core rental record. customer_id is nullable — no account required to rent.
-- rate_per_hour is snapshotted at checkout so owner rate changes never affect active rentals.
-- available_bikes = total_bikes - SUM(quantity WHERE ended_at IS NULL AND shop_id = ?)
CREATE TABLE rentals (
  id                   UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id              UUID  NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_name        TEXT  NOT NULL,
  customer_id_number   TEXT  NOT NULL,
  customer_id          UUID  REFERENCES profiles(id) ON DELETE SET NULL,
  quantity             INT   NOT NULL CHECK (quantity >= 1),
  rate_per_hour        INT   NOT NULL CHECK (rate_per_hour > 0),
  started_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at             TIMESTAMPTZ,
  amount_due           INT   CHECK (amount_due >= 0),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One loyalty config per shop. Owner can disable without deleting.
CREATE TABLE loyalty_config (
  id             UUID                 PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id        UUID                 NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  trigger_type   loyalty_trigger_type NOT NULL,
  trigger_value  INT                  NOT NULL CHECK (trigger_value > 0),
  reward_type    loyalty_reward_type  NOT NULL,
  reward_value   INT                  NOT NULL CHECK (reward_value > 0),
  enabled        BOOLEAN              NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
  UNIQUE (shop_id)
);

-- One record per customer per shop. Counters reset after a reward is applied.
CREATE TABLE loyalty_records (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id      UUID    NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id  UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  total_rides  INT     NOT NULL DEFAULT 0,
  total_hours  FLOAT8  NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (shop_id, customer_id)
);


-- =============================================================================
-- INDEXES
-- =============================================================================

-- Active rental lookups (available count, active rentals list)
CREATE INDEX idx_rentals_active      ON rentals (shop_id) WHERE ended_at IS NULL;
CREATE INDEX idx_rentals_shop_id     ON rentals (shop_id);
CREATE INDEX idx_rentals_customer_id ON rentals (customer_id);

CREATE INDEX idx_shops_owner_id              ON shops (owner_id);
CREATE INDEX idx_loyalty_records_shop_customer ON loyalty_records (shop_id, customer_id);


-- =============================================================================
-- FUNCTIONS & TRIGGERS
-- =============================================================================

-- Auto-update updated_at columns on row change.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shop_rates_updated_at
  BEFORE UPDATE ON shop_rates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_loyalty_config_updated_at
  BEFORE UPDATE ON loyalty_config
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_loyalty_records_updated_at
  BEFORE UPDATE ON loyalty_records
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile row when a new user signs up.
-- The Flutter client passes role, full_name, and id_number as user metadata.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, role, full_name, id_number)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'role')::user_role,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'id_number'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ---------------------------------------------------------------------------
-- Loyalty processing on check-in.
-- Fires after a rental row is updated with ended_at (i.e. bike returned).
-- Updates the customer's loyalty record and applies a reward to amount_due
-- if the configured threshold is met.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_loyalty_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
  v_config         loyalty_config%ROWTYPE;
  v_record         loyalty_records%ROWTYPE;
  v_duration_hours FLOAT8;
  v_threshold_met  BOOLEAN := FALSE;
  v_discount       INT     := 0;
BEGIN
  -- Only fire when ended_at transitions from NULL to a value.
  IF OLD.ended_at IS NOT NULL OR NEW.ended_at IS NULL THEN
    RETURN NEW;
  END IF;

  -- Only process if a customer account is linked.
  IF NEW.customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Check if this shop has an active loyalty config.
  SELECT * INTO v_config
  FROM loyalty_config
  WHERE shop_id = NEW.shop_id AND enabled = TRUE;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Calculate rental duration in hours.
  v_duration_hours := EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 3600.0;

  -- Upsert loyalty record and return the updated row.
  INSERT INTO loyalty_records (shop_id, customer_id, total_rides, total_hours)
  VALUES (NEW.shop_id, NEW.customer_id, 1, v_duration_hours)
  ON CONFLICT (shop_id, customer_id) DO UPDATE
    SET
      total_rides = loyalty_records.total_rides + 1,
      total_hours = loyalty_records.total_hours + v_duration_hours,
      updated_at  = NOW()
  RETURNING * INTO v_record;

  -- Check if the threshold is met.
  IF v_config.trigger_type = 'rides' AND v_record.total_rides >= v_config.trigger_value THEN
    v_threshold_met := TRUE;
  ELSIF v_config.trigger_type = 'hours' AND v_record.total_hours >= v_config.trigger_value THEN
    v_threshold_met := TRUE;
  END IF;

  IF NOT v_threshold_met THEN
    RETURN NEW;
  END IF;

  -- Calculate the discount value.
  IF v_config.reward_type = 'discount_percent' THEN
    v_discount := CEIL(NEW.amount_due * v_config.reward_value / 100.0);
  ELSIF v_config.reward_type = 'free_minutes' THEN
    -- Value of free minutes = (free_minutes / 60) * rate * quantity
    v_discount := CEIL((v_config.reward_value / 60.0) * NEW.rate_per_hour * NEW.quantity);
  END IF;

  -- Apply discount, floor at 0.
  NEW.amount_due := GREATEST(0, NEW.amount_due - v_discount);

  -- Reset loyalty counters.
  UPDATE loyalty_records
  SET total_rides = 0, total_hours = 0, updated_at = NOW()
  WHERE shop_id = NEW.shop_id AND customer_id = NEW.customer_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_rental_checkin
  BEFORE UPDATE ON rentals
  FOR EACH ROW EXECUTE FUNCTION process_loyalty_on_checkin();


-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE profiles       ENABLE ROW LEVEL SECURITY;
ALTER TABLE shops          ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_rates     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals        ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_records ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
CREATE POLICY "profiles: read own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: insert own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: update own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- shops
-- ---------------------------------------------------------------------------
CREATE POLICY "shops: public read"
  ON shops FOR SELECT
  USING (TRUE);

CREATE POLICY "shops: owner insert"
  ON shops FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "shops: owner update"
  ON shops FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "shops: owner delete"
  ON shops FOR DELETE
  USING (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- shop_rates
-- ---------------------------------------------------------------------------
CREATE POLICY "shop_rates: public read"
  ON shop_rates FOR SELECT
  USING (TRUE);

CREATE POLICY "shop_rates: owner insert"
  ON shop_rates FOR INSERT
  WITH CHECK (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "shop_rates: owner update"
  ON shop_rates FOR UPDATE
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- rentals
-- ---------------------------------------------------------------------------
CREATE POLICY "rentals: owner all"
  ON rentals FOR ALL
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "rentals: customer read own"
  ON rentals FOR SELECT
  USING (customer_id = auth.uid());

-- ---------------------------------------------------------------------------
-- loyalty_config
-- ---------------------------------------------------------------------------
CREATE POLICY "loyalty_config: public read"
  ON loyalty_config FOR SELECT
  USING (TRUE);

CREATE POLICY "loyalty_config: owner insert"
  ON loyalty_config FOR INSERT
  WITH CHECK (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "loyalty_config: owner update"
  ON loyalty_config FOR UPDATE
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- loyalty_records
-- ---------------------------------------------------------------------------
CREATE POLICY "loyalty_records: owner read"
  ON loyalty_records FOR SELECT
  USING (
    shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
  );

CREATE POLICY "loyalty_records: customer read own"
  ON loyalty_records FOR SELECT
  USING (customer_id = auth.uid());
