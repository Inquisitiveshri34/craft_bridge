# PR04 – Firebase Introduction — Project Setup + Configuration

**Project:** CraftBridge
**PR Number:** 04 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Firebase project creation, Auth and Firestore enablement, FlutterFire CLI configuration, and `main.dart` updated with `Firebase.initializeApp()`.

---

## Section 2 – Assignments Covered

- Assignment 3.4 — Firebase Introduction — Project Setup + Configuration

---

## Section 3 – Objective

This PR connects CraftBridge to Firebase by creating the Firebase project in the console, enabling Email/Password Authentication and Cloud Firestore, running the FlutterFire CLI to generate `firebase_options.dart`, and adding all required Firebase dependencies to `pubspec.yaml`. `main.dart` is updated to call `Firebase.initializeApp()` before `runApp()`, making Firebase available to every widget in the tree. This PR is the infrastructure prerequisite for every Firebase-dependent PR that follows — nothing in PRs 10 through 51 can function without the foundation established here.

---

## Section 4 – Architecture Context

```
Firebase Console (browser)
    │
    ├── Authentication → Email/Password enabled
    ├── Cloud Firestore → database created (test mode)
    └── Storage → bucket created

FlutterFire CLI (terminal)
    │
    └── flutterfire configure
            │
            └── generates lib/firebase_options.dart

pubspec.yaml
    │
    └── firebase_core, firebase_auth, cloud_firestore,
        firebase_storage, provider added

main.dart
    │
    └── async main()
          └── WidgetsFlutterBinding.ensureInitialized()
                └── Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
                      └── runApp(CraftBridgeApp())
```

This PR sits between the Dart fundamentals established in PR03 and the model/service layer coming in PR07. It is the only PR that touches Firebase Console configuration and FlutterFire CLI. All Firebase SDK usage — Auth calls, Firestore reads and writes — begins in PR10 and later.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders from PR01.

**Allowed file modification:**
- `lib/firebase_options.dart` — replaced by FlutterFire CLI output
- `lib/main.dart` — updated with async init and Firebase.initializeApp()
- `pubspec.yaml` — Firebase and Provider dependencies added

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify any screen or widget placeholder files.
- Do NOT modify `analysis_options.yaml`.

---

## Section 6 – Technical Requirements

### `pubspec.yaml`

Add the following dependencies under the `dependencies:` section. All version constraints use `^` (caret) for compatible-version pinning:

```
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.3
  provider: ^6.1.2
```

No other dependencies are added in this PR. `google_maps_flutter`, `geolocator`, `image_picker`, and `firebase_messaging` are added in later PRs.

The `flutter:` section must retain `uses-material-design: true`. No assets block is added yet.

---

### `lib/firebase_options.dart`

This file is generated entirely by the FlutterFire CLI in Part 1 of Section 8. The agent does NOT write this file — it is produced by running `flutterfire configure` in the terminal. The agent's only responsibility is to confirm the file exists and is non-empty after the manual setup step has been completed.

The generated file will contain:
- A `DefaultFirebaseOptions` class
- A `currentPlatform` static getter
- Platform-specific `FirebaseOptions` instances for Android and iOS at minimum

The placeholder comment from PR01 will be fully replaced by the CLI output. The agent must not overwrite or modify this file.

---

### `lib/main.dart`

Replace the PR03 content entirely. The file must contain:

**Imports:**
- `package:flutter/material.dart`
- `package:firebase_core/firebase_core.dart`
- `package:craft_bridge/firebase_options.dart`
- `package:craft_bridge/core/theme/app_theme.dart`
- `package:craft_bridge/core/constants/app_constants.dart`

**`main()` function:**
- Must be `async`
- First line: `WidgetsFlutterBinding.ensureInitialized()`
- Second line: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- Third line: `runApp(const CraftBridgeApp())`

**`class CraftBridgeApp extends StatelessWidget`:**
- `const` constructor
- `build` returns `MaterialApp` with:
  - `title: AppConstants.appName`
  - `debugShowCheckedModeBanner: false`
  - `theme: AppTheme.lightTheme`
  - `home: const CraftBridgeHome()`

**`class CraftBridgeHome extends StatefulWidget`:**
- Retained from PR03 as a temporary home screen demo
- `const` constructor
- `createState()` returns `_CraftBridgeHomeState()`

**`class _CraftBridgeHomeState extends State<CraftBridgeHome>`:**
- `build` returns `Scaffold` with:
  - `appBar`: `AppBar` with `title: const Text(AppConstants.appName)`
  - `body`: `Center` containing `Column` with `mainAxisAlignment: MainAxisAlignment.center` and children:
    1. `Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium)`
    2. `const SizedBox(height: 8)`
    3. `Text(AppConstants.appTagline, style: Theme.of(context).textTheme.bodyLarge)`
    4. `const SizedBox(height: 24)`
    5. `Text('Firebase connected ✓', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green))`

The fifth child in the `Column` — `'Firebase connected ✓'` — is a visual confirmation item. It is not connected to any live Firebase call. It is a static `Text` widget that confirms the file compiles and runs with Firebase initialized. It will be removed in PR08 when `main.dart` is fully replaced.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/firebase_options.dart` | Generated by FlutterFire CLI — contains `DefaultFirebaseOptions` with platform-specific Firebase config |
| 2 | `lib/main.dart` | Updated with async `main()`, `WidgetsFlutterBinding.ensureInitialized()`, and `Firebase.initializeApp()` |
| 3 | `pubspec.yaml` | All Firebase dependencies and Provider added with caret version constraints |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete every step below in order before handing off to the agent. Every command is written for macOS.

**Step 1 — Confirm PR03 is merged to main**

Open your GitHub repository and confirm the `pr03-fundamentals` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR04 branch**
```
git checkout -b pr04-firebase-setup
```

**Step 4 — Verify Node.js is installed (required for Firebase CLI)**
```
node --version
```
Node.js 18+ is required. If not installed, run:
```
brew install node
```

**Step 5 — Install the Firebase CLI globally**
```
npm install -g firebase-tools
```
If already installed, update it:
```
npm update -g firebase-tools
```

**Step 6 — Log in to Firebase CLI**
```
firebase login
```
This opens a browser. Sign in with the Google account you will use for this project. Confirm the terminal shows `Success! Logged in as your@email.com`.

**Step 7 — Install the FlutterFire CLI**
```
dart pub global activate flutterfire_cli
```
Confirm by running:
```
flutterfire --version
```

**Step 8 — Create the Firebase project in the console**

Open https://console.firebase.google.com in your browser.

- Click "Add project"
- Project name: `CraftBridge`
- Disable Google Analytics (not needed for this project)
- Click "Create project"
- Wait for provisioning to complete, then click "Continue"

**Step 9 — Enable Email/Password Authentication**

In the Firebase Console for your new project:
- Click "Authentication" in the left sidebar
- Click "Get started"
- Under "Sign-in method", click "Email/Password"
- Toggle "Enable" to on
- Click "Save"

**Step 10 — Create the Firestore database**

In the Firebase Console:
- Click "Firestore Database" in the left sidebar
- Click "Create database"
- Select "Start in test mode" (security rules will be tightened in PR39)
- Choose a region closest to your users — recommended: `asia-south1` (Mumbai) for India
- Click "Enable"
- Wait for the database to provision

**Step 11 — Create the Firebase Storage bucket**

In the Firebase Console:
- Click "Storage" in the left sidebar
- Click "Get started"
- Accept the default security rules (will be updated in PR39)
- Select the same region as Firestore: `asia-south1`
- Click "Done"

**Step 12 — Register Android and iOS apps in Firebase Console**

For Android:
- In the Firebase Console, click the Android icon on the project overview page
- Android package name: `com.craftbridge.craft_bridge`
- App nickname: `CraftBridge Android`
- Click "Register app"
- Download `google-services.json` — save it somewhere accessible but do NOT place it in the project manually; FlutterFire CLI will handle placement
- Click through the remaining steps and click "Continue to console"

For iOS:
- Click the iOS icon on the project overview page
- iOS bundle ID: `com.craftbridge.craftBridge`
- App nickname: `CraftBridge iOS`
- Click "Register app"
- Download `GoogleService-Info.plist` — save it somewhere accessible
- Click through the remaining steps and click "Continue to console"

**Step 13 — Run FlutterFire CLI to configure the project**

In your terminal, ensure you are in the project root:
```
cd ~/Developer/craft_bridge
```

Run:
```
flutterfire configure
```

When prompted:
- Select the `CraftBridge` Firebase project you just created
- Select both `android` and `ios` platforms
- Confirm the Android package name: `com.craftbridge.craft_bridge`
- Confirm the iOS bundle ID: `com.craftbridge.craftBridge`

The CLI will:
- Generate `lib/firebase_options.dart` (replaces the PR01 placeholder)
- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`
- Update `android/build.gradle` and `android/app/build.gradle`
- Update `ios/Runner.xcodeproj` configuration

**Step 14 — Verify `firebase_options.dart` was generated**
```
cat lib/firebase_options.dart
```
Confirm the file contains a `DefaultFirebaseOptions` class and is not the PR01 placeholder comment. If it still shows the placeholder, re-run `flutterfire configure`.

**Step 15 — Verify `google-services.json` is in place**
```
ls android/app/google-services.json
```
Confirm the file exists.

---

Manual setup for this PR is now complete.
Open `docs/PR04_Firebase_Introduction.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must perform the following tasks. `firebase_options.dart` has already been generated by the FlutterFire CLI in Part 1 — the agent must NOT overwrite it.

---

**Task 1 — Update `pubspec.yaml`**

Open `pubspec.yaml`. Under the `dependencies:` section, add the following packages below the `flutter: sdk: flutter` line:

```yaml
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.3
  provider: ^6.1.2
```

Do not remove any existing entries. Do not modify the `dev_dependencies:` section. Do not modify the `flutter:` section. Retain `uses-material-design: true`.

After editing `pubspec.yaml`, run:
```
flutter pub get
```
Confirm it completes with no resolution errors. If any dependency conflict is reported, check that the version constraints match exactly what is specified above.

---

**Task 2 — Update `lib/main.dart`**

Replace the entire PR03 content of `lib/main.dart` with a new implementation as specified in Section 6.

The critical changes from PR03 are:
- `main()` becomes `async`
- Add `WidgetsFlutterBinding.ensureInitialized()` as the first line of `main()`
- Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` as the second line
- Add imports for `firebase_core` and `firebase_options.dart`
- Retain `AppTheme` and `AppConstants` imports and usage
- Retain `CraftBridgeHome` as a temporary demo screen
- Add the `'Firebase connected ✓'` static text as the fifth child in the `Column` body, styled with `Colors.green`

Ensure all `const` constructors are used wherever valid. Ensure no unused imports exist.

---

**Task 3 — Verify `firebase_options.dart` is intact**

Run:
```
cat lib/firebase_options.dart
```
Confirm the file contains a `DefaultFirebaseOptions` class with a `currentPlatform` getter. Confirm it is NOT the PR01 placeholder comment (`// firebase_options.dart — generated by FlutterFire CLI in PR04`). Do not modify this file under any circumstances.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Required result: resolves all packages with no errors. Confirm `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, and `provider` appear in the resolution output.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: missing `await` on `Firebase.initializeApp()`, missing `async` on `main()`, unused imports.

3. **Verify `firebase_options.dart`**
   ```
   cat lib/firebase_options.dart
   ```
   Confirm it contains `class DefaultFirebaseOptions` and is not the placeholder. Confirm it was not modified by the agent.

4. **Verify `pubspec.yaml` dependencies**
   ```
   cat pubspec.yaml
   ```
   Confirm all five packages appear under `dependencies:` with their exact version constraints.

5. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app launches without crashing.
   - The app bar displays "CraftBridge" in white on warm brown.
   - The body shows "CraftBridge", the tagline, and "Firebase connected ✓" in green.
   - No `FirebaseException` errors in the debug console.
   - No `MissingPluginException` errors in the debug console.
   Press `q` to quit.

6. **Verify no unintended files were modified by the agent**
   ```
   git diff --name-only
   ```
   Expected changed files: `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `lib/firebase_options.dart` (modified by CLI in Part 1), and platform-specific files modified by FlutterFire CLI (`android/app/build.gradle`, `android/build.gradle`, `ios/Runner.xcodeproj`, `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`). No other Dart files should be modified by the agent.

7. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 04
  Failed Check: [exact check that failed]
  Error Output: [exact error message or description]
  Root Cause: [agent's diagnosis]
  Suggested Fix: [exact steps the developer should take to resolve it]
  ```

**If all checks pass:**

Output:
```
VERIFICATION PASSED
All Section 9 acceptance criteria confirmed.
Proceeding to commit and push.
```

Then run:
```
git add .
git commit -m "PR04: Firebase Introduction — Project Setup + Configuration"
git push origin pr04-firebase-setup
```

---

## Section 9 – Acceptance Criteria

- [ ] `lib/firebase_options.dart` contains a generated `DefaultFirebaseOptions` class and is not the PR01 placeholder comment.
- [ ] `pubspec.yaml` includes `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, and `provider` with correct caret version constraints.
- [ ] `flutter pub get` resolves all packages with no errors.
- [ ] `lib/main.dart` has an `async main()` with `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- [ ] The app launches on the emulator without any `FirebaseException` or `MissingPluginException` in the debug console.
- [ ] The emulator body displays "Firebase connected ✓" in green alongside the app name and tagline.
- [ ] `android/app/google-services.json` exists and is not empty.
- [ ] Firebase Authentication with Email/Password is enabled in the Firebase Console.
- [ ] Cloud Firestore database has been created in test mode.
- [ ] Firebase Storage bucket has been created.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR04 for CraftBridge. I connected the Flutter project to Firebase by creating the Firebase project in the console, enabling Auth, Firestore, and Storage, running the FlutterFire CLI to generate `firebase_options.dart`, and updating `main.dart` to initialize Firebase before the app starts."

2. **Firebase project creation:** "I created the Firebase project at console.firebase.google.com with the name CraftBridge. I disabled Google Analytics — it's not needed for this build. The project now has three services active: Authentication with Email/Password, Cloud Firestore in test mode, and a Storage bucket. All three are in the `asia-south1` region for low latency."

3. **FlutterFire CLI:** "The FlutterFire CLI is the modern, recommended way to connect a Flutter project to Firebase. Running `flutterfire configure` read my Firebase project, generated `lib/firebase_options.dart` with platform-specific API keys and project IDs, placed `google-services.json` into `android/app/`, placed `GoogleService-Info.plist` into `ios/Runner/`, and updated the Gradle and Xcode build files. I didn't touch any of those platform files manually."

4. **`firebase_options.dart`:** "The generated `firebase_options.dart` contains a `DefaultFirebaseOptions` class with a `currentPlatform` getter. At runtime, `currentPlatform` detects whether the app is running on Android or iOS and returns the correct `FirebaseOptions` for that platform. This is why `Firebase.initializeApp()` only needs one call — it handles platform detection automatically."

5. **`pubspec.yaml` dependencies:** "I added five packages: `firebase_core` which is the foundation for all Firebase SDKs, `firebase_auth` for email and password sign-in, `cloud_firestore` for our four-collection database, `firebase_storage` for product images, and `provider` for state management. All use caret constraints — `^3.6.0` means any compatible version from 3.6.0 up to but not including 4.0.0."

6. **`async main()` pattern:** "The `main()` function is now `async`. The first call is `WidgetsFlutterBinding.ensureInitialized()` — this is required whenever you need to call platform channels before `runApp()`. The second call is `await Firebase.initializeApp()` — this blocks until Firebase is ready. Only then does `runApp()` execute. If you skip `ensureInitialized()` and call `initializeApp()` before `runApp()`, Flutter throws a binding error."

7. **Test mode Firestore:** "The Firestore database is created in test mode, which allows all reads and writes for 30 days without authentication. This is intentional — we need to test Firebase interactions without auth rules blocking us during development. PR39 will deploy production-ready security rules that lock down access by role."

8. **'Firebase connected ✓' confirmation:** "The green 'Firebase connected ✓' text in the body is a static string — it is not a live Firebase call. It's a visual confirmation that `main.dart` compiled and ran with Firebase initialized. If `initializeApp()` had thrown an exception, the app would have crashed before rendering this text. It will be removed in PR08."

9. **Emulator demonstration:** "On the emulator the app shows the warm brown app bar, the app name and tagline, and the green 'Firebase connected ✓' text. No errors in the debug console. This confirms that `firebase_options.dart` is valid, the dependencies resolved correctly, and the async initialization pattern works."

10. **What's Next:** "PR05 will produce the Design Thinking document — user personas, user journeys, wireframe descriptions, and a finalized color palette — and update `app_theme.dart` with the final color scheme that will be used for the rest of the project."