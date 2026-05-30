# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] (Unreleased)

### Features

* **manual-rental:** Implement offline-first Manual Rental Management system (Issue #42) for station owners, including real-time rates/duration billing calculation, dynamic inventory updates (available/active counters), persistent local state, and translucent premium dark UX components.
* **manual-rental-ux-refinement:** Enhance manual-rental UX/UI: replace "Clock out" jargon with context-friendly "End Rental" & "Active Rentals" terminology, standardize user unique identifier field to "ID/Admission Number", localize currency exclusively to Kenyan Shillings (Ksh), and add interactive user details sheet for direct calling (using url_launcher). Remove redundant "Hourly Rate" fields from check-in forms since rate is a global default, remove copy clipboard buttons in favor of clean vertical detail layouts, use simply "Bike" or "Bicycle" instead of "Manual Bike", make activity cards on the main dashboard clickable to open the detail drawers, and hook up the "See all" navigation link.
* **quick-lease-and-swipe-to-delete:** Convert the "Quick Lease" button in the bottom sheet to a standalone, large, tactile green QR icon, and remove the subtitle text to maximize vertical screen space. Implement a modern swipe-left-to-delete gesture (using `Dismissible`) on the recent activity logs list with a custom red background and an elegant confirmation dialog.

## [1.3.1](https://github.com/Hacklabs-app/BikeBuddy/compare/bike_buddy-v1.3.0...bike_buddy-v1.3.1) (2026-05-23)


### Bug Fixes

* update deep link domain from hacklabs.com to hacklabs.app ([#65](https://github.com/Hacklabs-app/BikeBuddy/issues/65)) ([94f2d77](https://github.com/Hacklabs-app/BikeBuddy/commit/94f2d77ea72fe4e75524f07e7682aa73cbfaedca))

## [1.3.0](https://github.com/Hacklabs-app/BikeBuddy/compare/bike_buddy-v1.2.0...bike_buddy-v1.3.0) (2026-05-16)


### Features

* add shop setup screen and update routing for admin dashboard ([#61](https://github.com/Hacklabs-app/BikeBuddy/issues/61)) ([cfa3ba2](https://github.com/Hacklabs-app/BikeBuddy/commit/cfa3ba2c0fb50d6160316d304dcc5cd80f8750f7))
* add validation for email and password fields in login screen ([#58](https://github.com/Hacklabs-app/BikeBuddy/issues/58)) ([e4443ed](https://github.com/Hacklabs-app/BikeBuddy/commit/e4443ed080134200c8e58a6d152c7a46b7a8d1d6))
* **auth:** add role selection and rider signup screens; update user model and auth state management ([63a8a5c](https://github.com/Hacklabs-app/BikeBuddy/commit/63a8a5c15647eebc599ad5ca58b45da446b0c8c0))
* **discovery:** implement discovery state management and UI components ([17286ee](https://github.com/Hacklabs-app/BikeBuddy/commit/17286ee059e924973a3cfb08df6745361c9dfddc))
* enhance authentication and discovery features ([f7be688](https://github.com/Hacklabs-app/BikeBuddy/commit/f7be6886cb9051b973c1c2bde3d2848ee2fb40fa))
* Implement authentication and password management features ([243bd77](https://github.com/Hacklabs-app/BikeBuddy/commit/243bd77e5841a87e0b5df3923126c895962dff1d))
* Implement billing calculator and location service ([7c7aee3](https://github.com/Hacklabs-app/BikeBuddy/commit/7c7aee3a6f7413bf9c236849d580463491b38694))
* Implement billing calculator and location service ([#62](https://github.com/Hacklabs-app/BikeBuddy/issues/62)) ([8f3bde8](https://github.com/Hacklabs-app/BikeBuddy/commit/8f3bde802726966e4ad285a27e862742a87ee951))
* implement role-based routing and loading screen for user authentication ([#59](https://github.com/Hacklabs-app/BikeBuddy/issues/59)) ([05e4443](https://github.com/Hacklabs-app/BikeBuddy/commit/05e444314fdeb731bf13804d8dbe9924d85dfd6b))
* **onboarding:** add onboarding flow with animated transitions ([17286ee](https://github.com/Hacklabs-app/BikeBuddy/commit/17286ee059e924973a3cfb08df6745361c9dfddc))
* redirect unauthenticated users to home and update profile sheet action ([#60](https://github.com/Hacklabs-app/BikeBuddy/issues/60)) ([54615de](https://github.com/Hacklabs-app/BikeBuddy/commit/54615de09638186c4666ae4686b7396da5ad486e))
* refactor authentication flow and enhance UI components for user registration ([2f3d2df](https://github.com/Hacklabs-app/BikeBuddy/commit/2f3d2df0d828914270eb18196008c1abd6929d7d))
* **tests:** add integration and unit tests for onboarding, login, and discovery features ([624807a](https://github.com/Hacklabs-app/BikeBuddy/commit/624807a63921d48d232900475caa77a6799061ba))
* update user roles to owner and add national ID input in login screen ([#56](https://github.com/Hacklabs-app/BikeBuddy/issues/56)) ([edf177c](https://github.com/Hacklabs-app/BikeBuddy/commit/edf177caba810454377a6713f405b56b0cc9acfb))


### Bug Fixes

* **onboarding:** update button text from 'Ride Along now' to 'Ride Along' ([a7d3377](https://github.com/Hacklabs-app/BikeBuddy/commit/a7d337723f0f63da6fbc0b87a7c53563a48baa47))
* update geolocator dependency and adjust location request settings ([810f239](https://github.com/Hacklabs-app/BikeBuddy/commit/810f239a2264f213bf3882bc6a6ab9407c340ff9))

## [1.2.0](https://github.com/Hacklabs-app/BikeBuddy/compare/bike_buddy-v1.1.0...bike_buddy-v1.2.0) (2026-05-02)


### Features

* Set up Supabase project with schema and RLS policies [#10](https://github.com/Hacklabs-app/BikeBuddy/issues/10)  ([#53](https://github.com/Hacklabs-app/BikeBuddy/issues/53)) ([039217d](https://github.com/Hacklabs-app/BikeBuddy/commit/039217d90fc635d236fd051d8846654cb91f0bc7))

## [1.1.0](https://github.com/Hacklabs-app/BikeBuddy/compare/bike_buddy-v1.0.0...bike_buddy-v1.1.0) (2026-05-01)


### Features

* add initial database schema and guidelines for project architecture ([b64cfe5](https://github.com/Hacklabs-app/BikeBuddy/commit/b64cfe51a7e1c84d04d3efe08457a74ee92bd41b))
* add initial database schema and guidelines for project architecture ([#19](https://github.com/Hacklabs-app/BikeBuddy/issues/19)) ([02e8e74](https://github.com/Hacklabs-app/BikeBuddy/commit/02e8e740322e3aa78efe5e7ad15f8f3c1a3251e8))
* added login and Signup feature ([#7](https://github.com/Hacklabs-app/BikeBuddy/issues/7)) ([456e8f1](https://github.com/Hacklabs-app/BikeBuddy/commit/456e8f18b15a82e094395770169225ca20e4b1ed))
* added login and Signup feature ([#9](https://github.com/Hacklabs-app/BikeBuddy/issues/9)) ([b8e8529](https://github.com/Hacklabs-app/BikeBuddy/commit/b8e85299a3c5d8989c980bb28e1336e3eede4382))
* enhance CI workflow with concurrency and caching for Flutter SDK and pub dependencies ([#22](https://github.com/Hacklabs-app/BikeBuddy/issues/22)) ([324b47b](https://github.com/Hacklabs-app/BikeBuddy/commit/324b47b2ddc88ef3c07b9f94796eeb4a33d7aecd))
* implement CI workflow for building and releasing APK on push to dev branch ([#24](https://github.com/Hacklabs-app/BikeBuddy/issues/24)) ([1f7b3ee](https://github.com/Hacklabs-app/BikeBuddy/commit/1f7b3ee1cb10b3a582e852f0d392cedc5d110e0d))
* initial project setup for Bike Buddy PBL ([66024cf](https://github.com/Hacklabs-app/BikeBuddy/commit/66024cf108183148e1890a922f6af0fd7696a90a))
* rename application ID and update MainActivity package structure ([#21](https://github.com/Hacklabs-app/BikeBuddy/issues/21)) ([142ec71](https://github.com/Hacklabs-app/BikeBuddy/commit/142ec71553d68d3ca9e54f7e4732f10a5ce4ea85))

## [Unreleased]

### Added
- Initial project setup with Flutter 3.41.7 and FVM.
- Minimalist README and Contributing guidelines.
- Offline-first architectural foundation.
