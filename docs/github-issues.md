# GitHub Issues

All issues grouped by milestone. Each issue maps to one PR.

---

## M0: Foundation

---

### Set up Supabase project with schema and RLS policies
`type: backend` · Alex

Create all database tables — profiles, shops, shop_rates, rentals, loyalty_config, loyalty_records — and configure row-level security. Owners access only their own shop data, customers can read all shops and rates, anonymous users have read-only access to shop availability. Export schema SQL to `supabase/migrations/`.

---

### Configure GitHub Actions CI (lint + test on every PR)
`type: devops` · Alex

Set up a workflow that runs `flutter analyze` and `flutter test` on every PR targeting `dev`. Uses FVM for a consistent Flutter version across CI and local environments. PRs cannot be merged if either check fails.

---

### Set up Release Please for automated versioning
`type: devops` · Alex

Configure Release Please to automatically bump the version in `pubspec.yaml` and update `CHANGELOG.md` based on Conventional Commit messages. Add commitlint to reject non-compliant commit messages on PRs. No developer should ever manually edit the app version.

---

### Set up dev build workflow (APK + GitHub Pre-release on merge to dev)
`type: devops` · Alex

On every merge to `dev`, automatically build a signed release APK and publish it as a GitHub Pre-release with the APK attached. Build number is injected from `$GITHUB_RUN_NUMBER`. Release is tagged `v{version}-dev+{build_number}` and marked as pre-release.

---

### Set up Play Store deploy workflow (AAB on merge to main)
`type: devops` · Alex

On every merge to `main`, build a signed AAB and upload it to Google Play Console internal track using the `r0adkll/upload-google-play` action. Create a GitHub Release tagged `v{version}` and marked as latest.

---

### Audit existing codebase — mark what stays vs what gets replaced
`type: devops` · Alex

Review all existing screens and files in `lib/features/`. Tag each as keep, refactor, or out-of-scope (post-MVP). Move premature screens — damage photos, support chat, group booking, maps — to a `_deferred/` folder. Document architecture conventions in `CLAUDE.md`.

---

### Rename app ID to com.bikebuddy.mobile
`type: devops` · Alex

Update the application ID across all Android config files before the first Play Store upload. Change `applicationId` in `build.gradle.kts`, rename the Kotlin package directory from `com/example/bike_buddy` to `com/bikebuddy/mobile`, and update `MainActivity.kt` and `AndroidManifest.xml` to match.

---

### Generate app logo and launcher icon
`type: devops` `type: frontend` · Alex

Design or source the BikeBuddy app logo and generate all required launcher icon sizes using `flutter_launcher_icons`. Add the package to `pubspec.yaml`, configure icon sizes for all Android densities, and confirm the icon appears correctly on device.

---

### Configure branch protection rules and PR template
`type: devops` · Alex

Enforce that no one pushes directly to `dev` or `main`. `dev` requires a PR, CI pass, and 1 approval. `main` requires a PR from `dev`, CI pass, and 1 approval. Add a PR template at `.github/pull_request_template.md` covering what the PR does, linked issue, acceptance criteria checklist, and screenshots.

---

## M1: Auth & Role Routing

---

### Wire up Supabase Auth in Flutter
`type: backend` `type: frontend` · Rodgers

Initialize the Supabase client using environment variables injected via `--dart-define` — no hardcoded keys. Expose auth state via a Riverpod provider so the rest of the app can react to login and logout. Session should persist across app restarts.

---

### Register screen
`type: frontend` · Rodgers

Build the registration screen with fields for full name, national ID number, email, password, and role selection (owner or customer). On success, create the user in Supabase Auth and insert a row in `profiles`. Role cannot be changed after registration.

---

### Login screen
`type: frontend` · Rodgers

Build the login screen with email and password fields. On success, read `profiles.role` and route the user to the correct dashboard — owner to the owner dashboard, customer to customer home. Show inline errors for invalid credentials.

---

### Role-based routing and auth guards
`type: frontend` · Rodgers

Implement route guards in `go_router` so unauthenticated users land on customer home in browse-only mode, owner routes are inaccessible to customers, and customer-specific routes redirect appropriately for owners. Guards live in the router, not in individual screens.

---

### Logout
`type: frontend` `good first issue` · Rodgers

Add a logout option accessible from both the owner dashboard and the customer profile. Clears the Supabase session and redirects the user to customer home in anonymous mode.

---

## M2: Owner — Shop & Inventory Setup

---

### Create shop screen
`type: frontend` `type: backend` · Rodgers

Build the screen for a new owner to set up their shop with fields for name, address, total bikes, and hourly rate in KES. On save, create rows in `shops` and `shop_rates`. An owner can only have one shop in the MVP — if one already exists, redirect to the edit screen instead.

---

### Edit shop details
`type: frontend` `type: backend` · Rodgers

Allow an owner to update their shop name, address, total bikes, and hourly rate. Block saving if the new total bikes count is less than the number of bikes currently out on active rentals. Rate changes only apply to new rentals going forward.

---

### Owner dashboard shell
`type: frontend` · Rodgers

Build the owner's home screen showing shop name, current available bike count, and today's revenue total. Include navigation to checkout, active rentals, rental history, and shop settings. If the owner has no shop yet, show a prompt to set one up.

---

## M3: Owner — Checkout & Check-in

---

### Checkout screen — manual entry
`type: frontend` `type: backend` · Rodgers

Build the checkout screen where the owner enters a customer's name, ID number, and quantity of bikes. Quantity is capped at the current available count and the submit button is disabled when no bikes are available. On confirm, create a rental row with `started_at = now()` and snapshot `rate_per_hour` from `shop_rates`.

---

### QR scan at checkout to auto-fill customer details
`type: frontend` · Rodgers

Add a "Scan QR" option on the checkout screen that opens the camera via `mobile_scanner`. Scanning a logged-in customer's profile QR auto-fills their name and ID number and links their account to the rental via `customer_id`. Falls back to manual entry if the scan fails.

---

### Active rentals list
`type: frontend` · Rodgers

Build a screen listing all ongoing rentals for the shop. Each item shows the customer name, quantity, time elapsed updating live, and running cost. Tapping a rental opens the check-in flow. Show an empty state when there are no active rentals.

---

### Check-in flow — end rental and show bill
`type: frontend` `type: backend` · Rodgers

Let the owner end an active rental from the active rentals list. On confirm, set `ended_at = now()`, calculate `amount_due` using `CEIL(duration_minutes / 60) × rate_per_hour × quantity`, and save it. Show a bill screen with the full breakdown. If a loyalty reward applies, show the original amount, discount, and final total.

---

### Rental history screen
`type: frontend` · Rodgers

Build a screen listing all completed rentals for the shop with customer name, date, duration, quantity, and amount paid per row. Include filters for today, this week, this month, and a custom date range. Show the total revenue for the selected period.

---

## M4: Customer — Station Discovery

---

### Customer home — station list
`type: frontend` `type: backend` · Rodgers

Build the default customer home screen listing all shops with name, address, available bike count, and rate. Available counts update in real-time via a Supabase Realtime subscription on the `rentals` table. Fully functional without authentication.

---

### Station detail screen
`type: frontend` · Rodgers

Build the detail screen for a tapped station showing its name, address, rate per hour, and current available count updating in real-time. Show a clear "No bikes available" state when count is zero.

---

### Customer QR code screen
`type: frontend` · Rodgers

Build a screen where a logged-in customer can view their profile QR code to show the owner at checkout. The QR encodes the customer's profile UUID and is generated client-side using `qr_flutter` so it works without internet. Only visible to logged-in customers.

---

### Active rental screen
`type: frontend` · Rodgers

Build a screen for a logged-in customer linked to an active rental. Shows the shop name, quantity rented, a live timer updating every minute, and a running cost estimate. Only appears when the customer has an active rental linked to their account. Dismissed automatically when the owner checks them in.

---

### Anonymous user upsell banner
`type: frontend` `good first issue` · Rodgers

Add a subtle dismissible banner on the customer home screen nudging anonymous users to sign up — "Sign up to track rides & earn rewards." Tapping opens the register screen. Once dismissed, does not show again, persisted via `shared_preferences`.

---

## M5: Loyalty Program

---

### Owner loyalty config screen
`type: frontend` `type: backend` · Rodgers

Build a screen in shop settings where the owner configures their loyalty program. Fields include trigger type (rides or hours), trigger value, reward type (free minutes or discount percentage), and reward value. Include a toggle to enable or disable without losing the config. Upserts a row in `loyalty_config`.

---

### Track loyalty on check-in
`type: backend` · Rodgers

On check-in, if the rental has a linked `customer_id`, upsert the customer's `loyalty_records` row for that shop — increment `total_rides` by 1 and `total_hours` by the rental duration. Check if the loyalty threshold is met and flag the rental for reward application. Implement via a Supabase Postgres function to avoid client-side trust issues.

---

### Apply loyalty reward at check-in
`type: frontend` `type: backend` · Rodgers

When the loyalty threshold is met at check-in, apply the configured discount or free minutes to `amount_due` before saving. The bill screen shows the original amount, the reward label, and the final amount. Reset the customer's loyalty counters to zero after applying the reward.

---

### Customer loyalty progress screen
`type: frontend` · Rodgers

Build a screen where a logged-in customer can see their loyalty progress at each shop — the reward on offer and how many rides or hours they have toward it. Show "No loyalty programme at this station" if the shop has no active config. Accessible from the customer profile.
