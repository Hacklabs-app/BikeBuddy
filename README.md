# 🚲 Bike Buddy

**The Minimalist, Offline-First Bike Rental Ledger.**

Bike Buddy is an open-source project designed to replace the old-fashioned "logbook" at bike rental shops. It focuses on speed, reliability in dead zones, and a zero-friction workflow for the "Bike Guy" and the renter.

---

## 🚀 Getting Started

Follow these steps to set up the project on your local machine.

### 1. Prerequisites
Before you begin, ensure you have the following installed:
- [Git](https://git-scm.com/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (The global version doesn't matter much as we use FVM)
- [FVM (Flutter Version Management)](https://fvm.app/documentation/getting-started/installation) 
  - Install it by running: `dart pub global activate fvm`

### 2. Clone the Repository
Open your terminal and run:
```bash
git clone git@github.com:Hacklabs-app/BikeBuddy.git
cd BikeBuddy
```

### 3. Project Setup (The FVM Way)
We use **FVM** to ensure every contributor is using the exact same Flutter version (**3.41.7**).
```bash
# Install the specific Flutter version for this project
fvm install

# Fetch the project dependencies
fvm flutter pub get
```

### 4. Set Up Local Environment Variables

Supabase credentials are injected at build time and are never committed to the repo. Create a `.env.json` file in the project root (it is gitignored):

```json
{
  "SUPABASE_URL": "your_supabase_url",
  "SUPABASE_ANON_KEY": "your_anon_key"
}
```

Get these values from your Supabase project dashboard under **Project Settings → API**.

Then run the app with:
```bash
fvm flutter run --dart-define-from-file=.env.json
```

### 5. Configure Your IDE
To ensure your IDE uses the correct Flutter version, you **must** manually configure your workspace:

#### For VS Code:
1. Create a folder named `.vscode` in the root.
2. Create a file named `settings.json` inside it and add:
   ```json
   {
     "dart.flutterSdkPath": ".fvm/flutter_sdk",
     "search.exclude": {
       "**/.fvm": true
     },
     "files.watcherExclude": {
       "**/.fvm": true
     }
   }
   ```
*Note: This file is git-ignored to prevent personal settings conflicts.*

---

## 🛠 How to Contribute

### The Workflow:
1. **Find an Issue:** Look at the [GitHub Issues](https://github.com/Hacklabs-app/BikeBuddy/issues) for something to work on.
2. **Create a Branch:** Never work directly on `main`.
   ```bash
   git checkout -b feature/your-feature-name
   # OR
   git checkout -b fix/your-bug-name
   ```
3. **Write Code:** Focus on performance and reliability.
4. **Update the Changelog:** Add a line about your changes to [CHANGELOG.md](./CHANGELOG.md) under the `[Unreleased]` section.
5. **Run Local Checks:**
   ```bash
   fvm flutter analyze  # Ensure no errors
   fvm flutter test     # Ensure tests pass
   ```
6. **Push and PR:**
   ```bash
   git add .
   git commit -m "feat: described what you did"
   git push origin feature/your-feature-name
   ```
   Then, open a **Pull Request** on GitHub!

---

### Contributors

<a href="https://github.com/Hacklabs-app/BikeBuddy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Hacklabs-app/BikeBuddy" />
</a>

---
Built with ❤️ by [Hacklabs](https://hacklabs.app)
