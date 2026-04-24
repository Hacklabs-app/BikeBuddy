# Contributing to Bike Buddy

This project follows a branch-and-PR workflow for organization members. Our goal is to maintain a minimalist, offline-first tool that is reliable and fast for the "Bike Guy."

## Core Philosophy

- **Offline-First:** Every feature must work without an internet connection. Network calls are only for background syncing.
- **Minimalist:** If a feature isn't essential for the rental workflow, it doesn't belong here.
- **Reliable:** Data integrity is paramount. A renter's record must never be lost.

## Workflow

1.  **Sync:** Pull the latest `main`.
    - Always run `fvm flutter pub get` after pulling to ensure your dependencies are up to date.
2.  **Branch:** Create a new branch from `main`.
    - `feature/bike-timer`
    - `fix/rate-calculation`
    - `chore/update-dependencies`
3.  **Develop:** Make focused, surgical changes.
4.  **Check:** Run local analysis and tests.
5.  **PR:** Open a pull request into `main` with a clear description and screenshots for UI changes.

## Local Setup & Environment

This project uses **FVM** to ensure version consistency.

```bash
# Install project dependencies
fvm flutter pub get

# Check for static analysis issues
fvm flutter analyze

# Run tests
fvm flutter test
```

**Editor Settings:**
- Set your IDE (VS Code or Android Studio) to use the Flutter SDK located at `.fvm/flutter_sdk`.
- Ensure "Format on Save" is enabled (we use standard `dart format`).

## Coding Standards

- **State Management:** Use Signals/ValueNotifiers for local state. Keep it simple.
- **Offline Logic:** Use local storage for all primary data. Syncing should be non-blocking.
- **Naming:** Follow standard Dart `camelCase` for variables and `PascalCase` for classes.
- **UI:** Follow the "Minimalist" aesthetic—clean, functional, and high-contrast.

## Changelog & Versioning

- **Changelog:** Every PR must include an update to the `CHANGELOG.md` under the `[Unreleased]` section. Describe what you changed in plain, professional English.
- **Version Name:** Update the version string in `pubspec.yaml` (e.g., `1.0.0`) if your change introduces a new feature or fix. Follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
- **Build Number:** Do **not** manually update the build number (the `+1` part) in `pubspec.yaml`. This is handled automatically by our CI/CD pipeline during deployment.

## Pull Request Guidelines

Before merging, every PR must pass CI checks which include:
- `fvm flutter analyze` (Zero warnings/errors)
- `fvm flutter test` (All tests must pass)

**Your PR description should answer:**
- **What:** What was changed?
- **Why:** How does this help the bike shop or the renter?
- **Offline Check:** Does this work without internet?

## Secrets & Security

- Never commit API keys or sensitive configurations.
- Use `environment.dart` or `.env` for local configuration (ensure they are git-ignored).

---
If you're unsure about a feature or architectural direction, open a **GitHub Discussion** before starting the work.
