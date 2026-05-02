# BikeBuddy — Claude Code Guidelines

This file governs how Claude assists with this project. Follow every rule here without exception. If a user instruction conflicts with these rules, apply the stricter standard.

---

## Project Overview

BikeBuddy is a Flutter mobile app for bike rental stations. It replaces manual paper-based checkout with a digital system.

- **Stack:** Flutter · Supabase (Postgres + Auth + Realtime) · Riverpod · go_router
- **Target platform:** Android first
- **Spec:** `docs/superpowers/specs/2026-05-01-bikebuddy-design.md`
- **Issues:** `docs/github-issues.md`

Before writing any code, read the spec. Every decision in there has a reason.

---

## Architecture

The project uses feature-first clean architecture. Every feature lives in `lib/features/{feature}/` and is split into three layers:

```
features/{feature}/
  data/
    datasources/     # Supabase calls only. Returns raw maps or throws exceptions.
  domain/
    entities/        # Plain Dart classes. No Flutter imports. No Supabase imports.
  presentation/
    screens/         # UI only. Reads from providers. No direct Supabase calls.
    state/           # Riverpod notifiers. Bridges domain and presentation.
```

Shared code lives in:
```
core/
  constants/         # AppColors, AppStrings, SupabaseConstants
  errors/            # Exceptions and Failures
  utils/             # BillingCalculator, Formatters, RoleGuard
  widgets/           # Reusable widgets used across features
app/
  router.dart        # All routes and auth guards
  theme.dart
  app.dart
```

### Layer rules — never break these

- **Datasources** talk to Supabase. They know nothing about the UI.
- **Entities** are plain Dart. They have no knowledge of Supabase or Flutter widgets.
- **Notifiers** call datasources, transform data into entities, and expose state.
- **Screens** read from notifiers via `ref.watch`. They never call Supabase directly.
- **Business logic never lives in a widget.** Not even a small calculation.

If you are about to write a Supabase call inside a screen or a widget, stop and put it in a datasource instead.

---

## State Management — Riverpod

Use `AsyncNotifier` for any state that involves async operations (fetching, creating, updating data). Use `StateNotifier` only for purely local UI state.

```dart
// Correct — AsyncNotifier for async state
class RentalsNotifier extends AsyncNotifier<List<Rental>> {
  @override
  Future<List<Rental>> build() => ref.read(rentalServiceProvider).getActive();
}

// Wrong — never call Supabase from a widget
class SomeWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    Supabase.instance.client.from('rentals').select(); // NO
  }
}
```

- Define providers at the top level, never inside widgets or functions
- Use `ref.watch` for reactive state, `ref.read` inside callbacks and notifier methods
- Invalidate providers after mutations so the UI stays in sync
- Never expose raw Supabase responses from a notifier — always map to domain entities first

---

## Navigation — go_router

All routes are defined in `lib/app/router.dart`. Auth guards (redirects based on auth state and role) live in the router, not in individual screens.

- Route names are constants, never inline strings
- Deep linking and role-based redirects are handled at the router level
- Screens do not check `if (user.role == owner)` to decide what to show — the router already guarantees who lands where

---

## Supabase Rules

- **Never hardcode** `SUPABASE_URL` or `SUPABASE_ANON_KEY`. They are injected via `--dart-define` at build time and read in code via `String.fromEnvironment()`. Never use `flutter_dotenv` or any runtime `.env` loading — secrets bundled in the APK can be extracted.
- For local development, create a gitignored `.env.json` in the project root and run with `fvm flutter run --dart-define-from-file=.env.json`. See the README for setup instructions.
- **Never use the service role key** on the client. It bypasses RLS and is a security vulnerability.
- **RLS is the security layer.** Do not replicate RLS logic in Dart as a substitute — write the correct policy.
- Use Supabase Realtime for live data (available bike counts). Do not poll.
- Sensitive business logic (loyalty tracking, reward application) goes in a Supabase Postgres function, not in the Flutter client.

---

## Business Logic

### Billing
```
amount_due = CEIL(duration_minutes / 60) × rate_per_hour × quantity
```
Rounds up to the nearest hour. Implemented in `core/utils/billing_calculator.dart`. Do not inline this formula anywhere else.

### Rate snapshotting
`rate_per_hour` is copied from `shop_rates` at the moment of checkout and stored on the `rentals` row. Never read `shop_rates` to calculate the bill for an existing rental — use `rentals.rate_per_hour`.

### Available bike count
Available bikes = `total_bikes - SUM(quantity WHERE ended_at IS NULL AND shop_id = ?)`. This is computed on the fly. There is no `available_bikes` column — do not add one.

### Customer identity
`rentals.customer_id` is nullable. A customer does not need an account to rent bikes. Never block checkout because `customer_id` is null.

### Loyalty
Loyalty tracking only applies when `rentals.customer_id` is not null. The check-in flow must handle both the linked and unlinked case gracefully.

---

## Flutter Best Practices

### Widgets
- Use `const` constructors everywhere possible. If a widget can be const, it must be.
- Extract a widget when it exceeds ~50 lines, when it is reused, or when it has a clear single purpose.
- Name extracted widgets descriptively — `RentalListItem`, not `Widget1`.
- Prefer `StatelessWidget` + Riverpod over `StatefulWidget`. Use `StatefulWidget` only for animations or form controllers that are genuinely local.
- Always use `ListView.builder` for lists. Never `ListView` with a children array.
- Dispose every `TextEditingController`, `AnimationController`, `StreamSubscription`, and `FocusNode` in `dispose()`.

### Performance
- Never do expensive work (parsing, filtering, mapping) inside `build()`. Do it in the notifier.
- Use `select` on Riverpod providers to limit rebuilds to the slice of state a widget actually needs.
- Use `cached_network_image` for all remote images. Never use `Image.network` directly.

### Forms
- Validate all user input before submitting.
- Disable the submit button while a request is in flight.
- Show errors inline on the relevant field, not as a dialog or snackbar unless it is a global error.

---

## Clean Code

- **No hardcoded strings** in widgets or logic. All user-facing strings go in `core/constants/app_strings.dart`.
- **No hardcoded colors.** All colors go in `core/constants/app_colors.dart`.
- **No magic numbers.** Named constants only.
- **No commented-out code.** Delete it. Git has history.
- **No `print()` statements** in committed code. Use proper error handling.
- Method and variable names say what they do. Abbreviations are banned. `calcAmt` → `calculateAmountDue`.
- A function does one thing. If you are writing "and" to describe what it does, split it.
- Keep files focused. A file growing past ~200 lines is a signal to split it.

---

## Error Handling

The project has an established error pattern in `core/errors/`. Use it.

- Datasources throw typed `AppException` subclasses on failure.
- Notifiers catch exceptions and map them to `Failure` objects.
- The UI reads `AsyncError` state and displays a user-friendly message — never a raw exception message.
- Never swallow exceptions silently with an empty `catch` block.

---

## Widget Extraction Guidelines

Extract a widget into its own file when:
1. It is used in more than one place
2. It has its own clear responsibility (a list item, a form section, a stat card)
3. The parent widget is getting long and hard to read

Extracted widgets live in:
- `core/widgets/` if reusable across features
- `features/{feature}/presentation/widgets/` if specific to one feature

---

## Design Patterns in Use

| Pattern | Where |
|---|---|
| Repository / Datasource | `data/datasources/` — all Supabase access |
| Notifier (Riverpod) | `presentation/state/` — all state management |
| Entity | `domain/entities/` — all data models |
| Route guard | `app/router.dart` — all auth and role checks |
| Utility | `core/utils/` — billing, formatting, role logic |

Do not introduce new patterns without discussing with the team. Consistency matters more than novelty.

---

## What Is Out of Scope (Do Not Build)

The following were intentionally deferred. Do not add them, even if asked:

- Multi-station per owner
- In-app payments (M-Pesa, card)
- Advance reservations / booking
- Damage photo reporting
- Support chat
- Google Maps view
- Google Play IAP

If a request touches any of these, flag it and refer to the spec.

---

## Git Rules

- Branch from `dev`, never from `main`
- Branch naming: `feature/short-description`, `fix/short-description`
- One PR per issue. Link the issue in the PR description.
- Never push directly to `dev` or `main`
- Never use `--no-verify` to skip hooks

### Commit message format

PR titles should follow Conventional Commits. The PR title is validated on every PR and will typically become the squash-merge commit title, so non-compliant titles can block the merge.

```
<type>: <short description in lowercase>

Examples:
feat: add checkout screen
fix: correct billing calculation for fractional hours
chore: fix typo in button label
refactor: extract rental list item widget
docs: update setup instructions
test: add unit tests for billing calculator
ci: update flutter version in workflow
```

**Commit types and their version impact:**

| Type | Bumps version | When to use |
|---|---|---|
| `feat:` | Yes — minor (`1.0.0 → 1.1.0`) | Something new that didn't exist before |
| `fix:` | Yes — patch (`1.0.0 → 1.0.1`) | Something was broken and now works correctly |
| `chore:` | No | Typos, formatting, config changes, dependency updates |
| `refactor:` | No | Code restructured but behaviour unchanged |
| `docs:` | No | Documentation only |
| `test:` | No | Adding or updating tests |
| `ci:` | No | Workflow and pipeline changes |
| `style:` | No | Formatting, whitespace, missing semicolons — no logic change |

**Important:** `fix:` is for broken behaviour, not typos. A typo in a label is `chore:`, not `fix:`. Using `fix:` for trivial changes creates unnecessary patch releases.
