# BikeBuddy — Product & Architecture Design

**Date:** 2026-05-01
**Status:** Approved

---

## 1. Problem

Bike rental stations manage inventory and customer records manually — paper lists, handwritten names, ID numbers. This makes it hard for customers to know if bikes are available before showing up, and hard for owners to track revenue and reward regulars.

---

## 2. Scope (MVP)

This document covers the MVP only. Features explicitly deferred are listed at the end.

**In scope:**
- Role-based auth (owner / customer)
- Owner: shop setup, inventory count, hourly rate config
- Owner: checkout (name + ID + quantity) with optional QR scan
- Owner: check-in with automatic bill calculation
- Owner: rental history and revenue summary
- Customer: browse stations, see live availability and rates (no login required)
- Customer (logged in): profile QR code, active rental timer
- Loyalty program: owner-configurable trigger and reward per shop
- CI/CD pipeline: automated versioning, APK builds, Play Store deployment

**Deferred (post-MVP):**
- Multi-station per owner (premium feature)
- Google Play IAP / premium tier
- In-app payments (M-Pesa, card)
- Advance reservations
- Damage photo reporting
- Support chat
- Google Maps discovery view

---

## 3. Roles

| Role | Auth required | Description |
|---|---|---|
| Owner | Yes | Manages one shop, does checkouts, views revenue |
| Customer (logged in) | Yes | Browses stations, has QR code, tracks loyalty |
| Customer (anonymous) | No | Browses stations and rates only |

Role is set at registration and cannot be changed.

---

## 4. Data Model

### `profiles`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | FK → auth.users |
| `role` | enum | `owner` or `customer` |
| `full_name` | text | |
| `id_number` | text | National ID |
| `created_at` | timestamptz | |

### `shops`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `owner_id` | uuid | FK → profiles |
| `name` | text | |
| `address` | text | |
| `lat` | float8 | |
| `lng` | float8 | |
| `total_bikes` | int | Owner-managed count |
| `created_at` | timestamptz | |

### `shop_rates`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `shop_id` | uuid | FK → shops |
| `rate_per_hour` | int | KES, integer |
| `updated_at` | timestamptz | |

Rate changes only affect new rentals, not active ones.

### `rentals`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `shop_id` | uuid | FK → shops |
| `customer_name` | text | Always captured manually |
| `customer_id_number` | text | Always captured manually |
| `customer_id` | uuid | nullable, FK → profiles |
| `quantity` | int | Number of bikes taken |
| `rate_per_hour` | int | KES, snapshotted from shop_rates at checkout |
| `started_at` | timestamptz | Set on checkout |
| `ended_at` | timestamptz | nullable, set on check-in |
| `amount_due` | int | KES, set on check-in |

`customer_id` is nullable. Customers do not need an account to rent. If a logged-in customer's QR is scanned at checkout, their account is linked for loyalty tracking.

`rate_per_hour` is copied from `shop_rates` at the moment of checkout. Rate changes by the owner never affect in-progress rentals.

**Available bikes** = `total_bikes - SUM(quantity WHERE ended_at IS NULL AND shop_id = ?)`

### `loyalty_config`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `shop_id` | uuid | FK → shops, unique |
| `trigger_type` | enum | `rides` or `hours` |
| `trigger_value` | int | e.g. 10 (rides or hours) |
| `reward_type` | enum | `free_minutes` or `discount_percent` |
| `reward_value` | int | e.g. 60 (minutes) or 10 (%) |
| `enabled` | bool | Owner can disable without deleting config |

### `loyalty_records`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `shop_id` | uuid | FK → shops |
| `customer_id` | uuid | FK → profiles |
| `total_rides` | int | Resets after reward applied |
| `total_hours` | float8 | Resets after reward applied |

Unique constraint on `(shop_id, customer_id)` — one record per customer per shop.

---

## 5. User Flows

### Owner: Checkout
1. Open checkout screen
2. Optional: tap "Scan QR" → scan customer's profile QR → name + ID auto-filled
3. Enter customer name, ID number (if not auto-filled), quantity
4. Confirm → rental row created, `started_at = now()`
5. Available count decrements immediately

### Owner: Check-in
1. Open active rentals list
2. Tap rental → confirm check-in
3. `ended_at = now()`, `amount_due` calculated
4. Bill shown: duration, quantity, rate, total (KES)
5. Available count increments immediately

**Billing formula:** `CEIL(duration_minutes / 60) × rate_per_hour × quantity`

If loyalty threshold is met: discount applied before showing final amount.

### Owner: Revenue
- List of all completed rentals, filterable by date
- Total revenue for selected period

### Customer (anonymous)
1. Open app → station list with live available count and rate per shop
2. Tap station → detail view (name, address, rate, available count)
3. Soft nudge to sign up

### Customer (logged in)
1. Same discovery flow as anonymous
2. Profile screen: QR code (encodes profile UUID, generated client-side)
3. If linked to active rental: live timer + running cost estimate
4. Loyalty progress: rides/hours toward next reward at each shop

---

## 6. Architecture

### Stack
| Layer | Choice |
|---|---|
| Frontend | Flutter (mobile, Android first) |
| State management | Riverpod (AsyncNotifier / StateNotifier) |
| Navigation | go_router with auth redirect |
| Backend | Supabase (Postgres + Auth + Realtime) |
| Real-time | Supabase Realtime (subscribe to `rentals` table) |

### Folder structure (clean architecture)
```
lib/
  features/
    auth/
      data/datasources/
      domain/entities/
      presentation/screens/ + state/
    owner/
      data/datasources/
      domain/entities/
      presentation/screens/ + state/
    customer/
      data/datasources/
      domain/entities/
      presentation/screens/ + state/
    loyalty/
      ...
  core/
    constants/
    errors/
    utils/
    widgets/
  app/
    router.dart
    theme.dart
    app.dart
```

### RLS Policy summary
| Table | Owner can | Customer can | Anonymous can |
|---|---|---|---|
| `shops` | CRUD own shop | Read all | Read all |
| `shop_rates` | CRUD own shop's rates | Read all | Read all |
| `rentals` | CRUD own shop's rentals | Read own (customer_id = auth.uid) | None |
| `loyalty_config` | CRUD own shop's config | Read all | Read all |
| `loyalty_records` | Read own shop's records | Read own | None |
| `profiles` | Read/update own | Read/update own | None |

### Real-time availability
Customer home screen subscribes to `rentals` table changes (`INSERT` and `UPDATE` on `ended_at`) for visible shops. Available count is recalculated on each change event. No polling.

---

## 7. CI/CD Pipeline

### Branch strategy
```
feature/* → dev → main
```

### Commit convention
All commits must follow Conventional Commits:
- `feat:` → minor version bump
- `fix:` → patch version bump
- `feat!:` / `BREAKING CHANGE:` → major version bump
- `chore:`, `docs:`, `refactor:` → no version bump

Enforced via commitlint on every PR.

### Automated versioning
Release Please (GitHub Action) reads merged commits and:
1. Auto-opens a "Release PR" bumping `pubspec.yaml` version + updating `CHANGELOG.md`
2. Mentor merges Release PR when ready to ship
3. Merge triggers build and deploy workflows

Build number = `$GITHUB_RUN_NUMBER` (always unique, always incrementing). No manual version bumps by developers.

### Workflow 1 — PR checks (every PR targeting `dev`)
```
flutter analyze → flutter test
```
Required to merge. Uses FVM for consistent Flutter version.

### Workflow 2 — Dev build (on merge to `dev`)
```
flutter build apk --release
→ GitHub Pre-release: v1.1.0-dev+42
→ APK attached
→ marked as pre-release
```

### Workflow 3 — Play Store deploy (on merge to `main`)
```
flutter build appbundle --release
→ Sign AAB (keystore from GitHub Secrets)
→ Upload to Play Console internal track (r0adkll/upload-google-play)
→ GitHub Release: v1.1.0
```

### GitHub Secrets required
| Secret | Purpose |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |
| `KEYSTORE_FILE` | Base64-encoded .jks |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore store password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play Console service account |

### Branch protection
**`dev`:** Require PR, CI pass, 1 approval (mentor)
**`main`:** Require PR from `dev`, CI pass, 1 approval (mentor). No direct pushes.

---

## 8. Milestones

| Milestone | Goal |
|---|---|
| M0: Foundation | Supabase schema, CI/CD, project audit |
| M1: Auth & Role Routing | Login, register, role-based navigation |
| M2: Owner Shop Setup | Shop creation, bike count, rate config |
| M3: Checkout & Check-in | Core rental loop, billing, QR scan |
| M4: Customer Discovery | Station browsing, live availability, customer QR, active rental timer |
| M5: Loyalty Program | Owner loyalty config, reward tracking and application |

---

## 9. Deferred Features

| Feature | Milestone |
|---|---|
| Multi-station per owner | Premium (post-MVP) |
| Google Play IAP | Premium (post-MVP) |
| In-app payments | Future |
| Advance reservations | Future |
| Damage photo reporting | Future |
| Support chat | Future |
| Google Maps discovery | Future |
