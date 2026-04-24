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

# Run the project
fvm flutter run
```


### 4. Configure Your IDE
The project comes pre-configured for VS Code, but you should verify your settings:

#### For VS Code:
The `.vscode/settings.json` file should already exist with the following settings. If it doesn't, create it:
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
*Note: Using `.fvm/flutter_sdk` ensures your IDE always uses the version defined by FVM, even after upgrades.*

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

## 👥 Contributors

This project is built by the community. Join us!

<a href="https://github.com/Hacklabs-app/BikeBuddy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Hacklabs-app/BikeBuddy" />
</a>

---
Built with ❤️ by [Hacklabs](https://hacklabs.app)
