# 🚲 Bike Buddy

**The Minimalist, Offline-First Bike Rental Ledger.**

Bike Buddy is an open-source project designed to replace the old-fashioned "logbook" at bike rental shops. It focuses on speed, reliability in dead zones, and a zero-friction workflow for the "Bike Guy" and the renter.

This project is part of the **Hacklabs Project-Based Learning** initiative. It is designed to be a collaborative space for beginners to learn Flutter, Git, and open-source workflows while building a real-world tool.

---

## 🚀 Getting Started

Follow these steps to set up the project on your local machine.

### 1. Prerequisites
Before you begin, ensure you have the following installed:
- [Git](https://git-scm.com/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (The global version doesn't matter much as we use FVM)
- [FVM (Flutter Version Management)](https://fvm.app/docs/getting_started/installation) 
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


### 4. Configure Your IDE
To make sure your editor uses the correct Flutter version, you must point it to the local project SDK:

#### For VS Code:
1. Create a folder named `.vscode` in the root (if it doesn't exist).
2. Create a file named `settings.json` and add:
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

#### For Android Studio:
1. Go to **Settings** > **Languages & Frameworks** > **Flutter**.
2. Set the **Flutter SDK path** to `[Your_Project_Path]/.fvm/flutter_sdk`.

---

## 🛠 How to Contribute

We use a "Shared Repository" workflow. Since this is a learning project, don't be afraid to make mistakes!

### The Workflow:
1. **Find an Issue:** Look at the [GitHub Issues](https://github.com/Hacklabs-app/BikeBuddy/issues) for something to work on.
2. **Create a Branch:** Never work directly on `main`.
   ```bash
   git checkout -b feature/your-feature-name
   # OR
   git checkout -b fix/your-bug-name
   ```
3. **Write Code:** Keep it **minimalist** and **offline-first**.
4. **Update the Changelog:** Add a line about your changes to `CHANGELOG.md` under the `[Unreleased]` section.
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

## 📜 Coding Standards

- **Offline-First:** Assume there is NO internet. Use local storage for all primary actions.
- **Ksh Rate Calculation:** All price math must happen on-device based on the timer.
- **Minimalist UI:** High contrast, big buttons, no clutter. If the "Bike Guy" can't use it with one thumb while holding a wrench, it's too complex.

---

## 👥 Contributors

This project is built by the community. Join us!

<a href="https://github.com/Hacklabs-app/BikeBuddy/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Hacklabs-app/BikeBuddy" />
</a>

---
Built with ❤️ by [Hacklabs](https://github.com/Hacklabs-app)
