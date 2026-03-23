# PR03 – Flutter & Dart Fundamentals — Folder Structure + Widget Demo

**Project:** CraftBridge
**PR Number:** 03 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `app_theme.dart` and `app_constants.dart`, and update `main.dart` to demonstrate Flutter widget tree fundamentals with AppTheme applied.

---

## Section 2 – Assignments Covered

- Assignment 3.3 — Flutter & Dart Fundamentals — Folder Structure + Widget Demo

---

## Section 3 – Objective

This PR implements the two core foundation files — `app_theme.dart` and `app_constants.dart` — and updates `main.dart` to consume them, demonstrating a clear understanding of Flutter's widget tree, `StatelessWidget` vs `StatefulWidget`, and Dart class structure. The theme and constants established here are provisional and will be refined in PR05 (design thinking) and PR19 (global theme application) — but they must be functional and analyzable from this PR forward. This PR also serves as the project's first demonstration of structured Dart code beyond a minimal scaffold.

---

## Section 4 – Architecture Context

```
lib/
  core/
    theme/
      app_theme.dart        ← created this PR (provisional theme)
    constants/
      app_constants.dart    ← created this PR (app-wide constants)
  main.dart                 ← modified this PR (consumes AppTheme)

Widget tree after this PR:
CraftBridgeApp (StatelessWidget)
  └── MaterialApp
        ├── title: 'CraftBridge'
        ├── theme: AppTheme.lightTheme
        └── home: CraftBridgeHome (StatefulWidget)
              └── Scaffold
                    ├── AppBar → Text('CraftBridge')
                    └── body → Center
                                └── Column
                                      ├── Text('Welcome to CraftBridge')
                                      └── Text('Digital storefront for local artisans')
```

This PR sits after the scaffold (PR01) and project plan (PR02) and before Firebase setup (PR04). It introduces the first real Dart class structures in the project. `app_theme.dart` will be extended in PR05 and PR19. `app_constants.dart` will be extended progressively as new constants are needed. `main.dart` in its current form is a demo — it will be fully replaced in PR08 with Firebase initialization and Provider setup.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders from PR01.

**Allowed file modification:**
- `lib/core/theme/app_theme.dart`
- `lib/core/constants/app_constants.dart`
- `lib/main.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.
- Do NOT modify any screen or widget placeholder files.
- Do NOT modify `pubspec.yaml`.
- Do NOT add any dependencies.

---

## Section 6 – Technical Requirements

### `lib/core/theme/app_theme.dart`

- A plain Dart file — no widgets, no `StatelessWidget`.
- Declares a `class AppTheme` with only `static` members — it is never instantiated.
- Contains one static getter: `static ThemeData get lightTheme`.
- `lightTheme` returns a `ThemeData` configured as follows:
  - `useMaterial3: true`
  - `colorScheme`: built using `ColorScheme.fromSeed` with `seedColor: const Color(0xFF6B4226)` (warm brown — provisional, will be finalized in PR05)
  - `fontFamily: 'Roboto'`
  - `appBarTheme`: `AppBarTheme` with:
    - `centerTitle: true`
    - `elevation: 0`
    - `backgroundColor: const Color(0xFF6B4226)`
    - `foregroundColor: Colors.white`
  - `elevatedButtonTheme`: `ElevatedButtonThemeData` with `style` set to `ElevatedButton.styleFrom` with:
    - `backgroundColor: const Color(0xFF6B4226)`
    - `foregroundColor: Colors.white`
    - `minimumSize: const Size(double.infinity, 48)`
    - `shape`: `RoundedRectangleBorder` with `borderRadius: BorderRadius.circular(8)`
  - `inputDecorationTheme`: `InputDecorationTheme` with:
    - `border`: `OutlineInputBorder` with `borderRadius: BorderRadius.circular(8)`
    - `contentPadding`: `const EdgeInsets.symmetric(horizontal: 16, vertical: 12)`
  - `cardTheme`: `CardTheme` with:
    - `elevation: 2`
    - `shape`: `RoundedRectangleBorder` with `borderRadius: BorderRadius.circular(12)`
- Imports required: `package:flutter/material.dart` only.
- The class must be named exactly `AppTheme`.
- No `darkTheme` in this PR — dark mode is added in PR46.

---

### `lib/core/constants/app_constants.dart`

- A plain Dart file — no widgets, no imports required beyond none (pure Dart).
- Declares a `class AppConstants` with only `static const` members — it is never instantiated.
- Contains the following constants:

  **App identity:**
  - `static const String appName = 'CraftBridge'`
  - `static const String appTagline = 'Digital storefront for local artisans'`

  **User roles:**
  - `static const String roleAdmin = 'admin'`
  - `static const String roleArtisan = 'artisan'`
  - `static const String roleBuyer = 'buyer'`

  **Order statuses:**
  - `static const String statusPending = 'pending'`
  - `static const String statusConfirmed = 'confirmed'`
  - `static const String statusShipped = 'shipped'`
  - `static const String statusDelivered = 'delivered'`
  - `static const String statusCancelled = 'cancelled'`

  **Product categories:**
  - `static const List<String> productCategories = ['Pottery', 'Textiles', 'Jewellery', 'Woodwork', 'Paintings', 'Leather', 'Other']`

  **Firestore collection names:**
  - `static const String usersCollection = 'users'`
  - `static const String productsCollection = 'products'`
  - `static const String ordersCollection = 'orders'`
  - `static const String reviewsCollection = 'reviews'`

  **UI constants:**
  - `static const double defaultPadding = 16.0`
  - `static const double cardBorderRadius = 12.0`
  - `static const double buttonBorderRadius = 8.0`
  - `static const double inputBorderRadius = 8.0`

- No imports needed. Pure Dart constants only.
- The class must be named exactly `AppConstants`.

---

### `lib/main.dart`

- Replace the PR01 content entirely.
- Imports:
  - `package:flutter/material.dart`
  - `package:craft_bridge/core/theme/app_theme.dart`
  - `package:craft_bridge/core/constants/app_constants.dart`
- `void main()` calls `runApp(const CraftBridgeApp())`.
- `class CraftBridgeApp extends StatelessWidget` with a `const` constructor.
  - `build` returns `MaterialApp` with:
    - `title: AppConstants.appName`
    - `debugShowCheckedModeBanner: false`
    - `theme: AppTheme.lightTheme`
    - `home: const CraftBridgeHome()`
- `class CraftBridgeHome extends StatefulWidget` with a `const` constructor.
  - Overrides `createState()` → returns `_CraftBridgeHomeState()`.
- `class _CraftBridgeHomeState extends State<CraftBridgeHome>`:
  - `build` returns a `Scaffold` with:
    - `appBar`: `AppBar` with `title: const Text(AppConstants.appName)`
    - `body`: `Center` containing a `Column` with `mainAxisAlignment: MainAxisAlignment.center` and two children:
      1. `Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium)`
      2. `const SizedBox(height: 8)`
      3. `Text(AppConstants.appTagline, style: Theme.of(context).textTheme.bodyLarge)`

- This `CraftBridgeHome` widget is a deliberate demo of `StatefulWidget` structure for Assignment 3.3. It contains no actual state — the `StatefulWidget` is used here to demonstrate the pattern, not because state is needed. It will be removed entirely in PR08 when `main.dart` is replaced with the full Provider + Firebase setup.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/core/theme/app_theme.dart` | `AppTheme` class with `lightTheme` static getter — provisional color scheme, appBar, button, input, and card themes |
| 2 | `lib/core/constants/app_constants.dart` | `AppConstants` class with all static const values for roles, statuses, categories, collections, and UI dimensions |
| 3 | `lib/main.dart` | Updated to consume `AppTheme` and `AppConstants`, demonstrate `StatelessWidget` + `StatefulWidget` widget tree |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR02 is merged to main**

Open your GitHub repository and confirm the `pr02-plan` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR03 branch**
```
git checkout -b pr03-fundamentals
```

**Step 4 — Confirm the placeholder files exist**
```
cat lib/core/theme/app_theme.dart
cat lib/core/constants/app_constants.dart
```
Both should show their single-comment placeholder lines from PR01. If either is missing, do not proceed — diagnose the PR01 scaffold before continuing.

---

Manual setup for this PR is now complete.
Open `docs/PR03_Flutter_Dart_Fundamentals.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must implement three files. No new files are created. No new folders are created. The agent replaces placeholder content in the three files listed below.

---

**File 1: `lib/core/theme/app_theme.dart`**

Replace the single-comment placeholder entirely. Write a complete Dart file with the following structure:

- Import `package:flutter/material.dart`.
- Declare `class AppTheme` — no constructor, no instance members.
- Implement `static ThemeData get lightTheme` returning a fully configured `ThemeData` as specified in Section 6. Every sub-theme (`appBarTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, `cardTheme`) must be present. Use `ColorScheme.fromSeed` with `seedColor: const Color(0xFF6B4226)`. Set `useMaterial3: true`. Set `fontFamily: 'Roboto'`.
- The file must have no unused imports and must be fully analyzable.

---

**File 2: `lib/core/constants/app_constants.dart`**

Replace the single-comment placeholder entirely. Write a complete Dart file with the following structure:

- No imports.
- Declare `class AppConstants` — no constructor, no instance members.
- Implement every constant listed in Section 6 exactly:
  - `appName`, `appTagline` (app identity)
  - `roleAdmin`, `roleArtisan`, `roleBuyer` (roles)
  - `statusPending`, `statusConfirmed`, `statusShipped`, `statusDelivered`, `statusCancelled` (order statuses)
  - `productCategories` as a `static const List<String>` with all 7 values
  - `usersCollection`, `productsCollection`, `ordersCollection`, `reviewsCollection` (Firestore collection names)
  - `defaultPadding`, `cardBorderRadius`, `buttonBorderRadius`, `inputBorderRadius` (UI constants)
- All values must match Section 6 exactly. No extra constants. No missing constants.

---

**File 3: `lib/main.dart`**

Replace the PR01 content entirely. Write a complete Dart file with the following structure:

- Import `package:flutter/material.dart`.
- Import `package:craft_bridge/core/theme/app_theme.dart`.
- Import `package:craft_bridge/core/constants/app_constants.dart`.
- Implement `void main()` calling `runApp(const CraftBridgeApp())`.
- Implement `class CraftBridgeApp extends StatelessWidget` — `build` returns `MaterialApp` with `title: AppConstants.appName`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `home: const CraftBridgeHome()`.
- Implement `class CraftBridgeHome extends StatefulWidget` — `createState()` returns `_CraftBridgeHomeState()`.
- Implement `class _CraftBridgeHomeState extends State<CraftBridgeHome>` — `build` returns `Scaffold` with `AppBar` titled `AppConstants.appName` and a centered `Column` body showing `AppConstants.appName` in `headlineMedium` style and `AppConstants.appTagline` in `bodyLarge` style, separated by an 8px `SizedBox`.
- All `const` constructors must be used wherever valid.
- No unused imports.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. If any issues are reported, fix them before continuing. Common issues to watch for: unused imports, missing `const` constructors, type mismatches in `ThemeData` configuration.

2. **Verify file contents**
   ```
   cat lib/core/theme/app_theme.dart
   cat lib/core/constants/app_constants.dart
   cat lib/main.dart
   ```
   Confirm each file no longer contains the placeholder comment and instead contains full Dart class implementations.

3. **Verify constant count in `app_constants.dart`**
   Confirm the following are all present by reading the file:
   - 2 app identity constants
   - 3 role constants
   - 5 order status constants
   - 1 product categories list with 7 items
   - 4 Firestore collection name constants
   - 4 UI dimension constants

4. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app bar displays "CraftBridge" in white text on a warm brown (`#6B4226`) background, centered.
   - The body shows "CraftBridge" in `headlineMedium` style and "Digital storefront for local artisans" in `bodyLarge` style, centered.
   - No overflow errors, no red error widgets, no debug banner.
   Press `q` to quit.

5. **Verify no unintended files were modified**
   ```
   git diff --name-only
   ```
   Only these three files should appear: `lib/core/theme/app_theme.dart`, `lib/core/constants/app_constants.dart`, `lib/main.dart`.

6. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 03
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
git commit -m "PR03: Flutter & Dart Fundamentals — Folder Structure + Widget Demo"
git push origin pr03-fundamentals
```

---

## Section 9 – Acceptance Criteria

- [ ] `lib/core/theme/app_theme.dart` is fully implemented with `AppTheme` class and `lightTheme` static getter.
- [ ] `lightTheme` includes `useMaterial3: true`, `ColorScheme.fromSeed` with seed `0xFF6B4226`, and all four sub-themes: `appBarTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, `cardTheme`.
- [ ] `lib/core/constants/app_constants.dart` is fully implemented with all 19 constants and the `productCategories` list containing exactly 7 items.
- [ ] `AppConstants.roleAdmin`, `AppConstants.roleArtisan`, and `AppConstants.roleBuyer` equal `'admin'`, `'artisan'`, and `'buyer'` respectively.
- [ ] All four Firestore collection name constants are present and correctly named.
- [ ] `lib/main.dart` imports and uses both `AppTheme.lightTheme` and `AppConstants.appName`.
- [ ] `main.dart` contains both a `StatelessWidget` (`CraftBridgeApp`) and a `StatefulWidget` (`CraftBridgeHome`) demonstrating the widget tree pattern.
- [ ] The emulator displays the app bar with "CraftBridge" in white on warm brown, and the body shows the app name and tagline centered.
- [ ] No new files were created and no files outside the three modified files were changed.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR03 for CraftBridge. I implemented `app_theme.dart` and `app_constants.dart` — the two core foundation files that every subsequent PR will reference — and updated `main.dart` to demonstrate the Flutter widget tree with a `StatelessWidget` and `StatefulWidget` working together."

2. **`AppTheme` design:** "`AppTheme` is a pure static class — never instantiated, never extended. It exposes a single `lightTheme` getter that returns a fully configured `ThemeData`. Using `ColorScheme.fromSeed` with Material 3 means Flutter generates a harmonious color palette from our seed color, the warm brown `#6B4226`. This color represents the artisan craft aesthetic and will be finalized in PR05."

3. **Sub-theme configuration:** "Inside `lightTheme` I configured four sub-themes — `appBarTheme` for consistent navigation styling, `elevatedButtonTheme` so every button in the app inherits full-width sizing and rounded corners without per-widget styling, `inputDecorationTheme` for consistent text field borders, and `cardTheme` for consistent product card elevation. Defining these once here means zero per-widget theme code in 34 subsequent screen files."

4. **`AppConstants` design:** "`AppConstants` is also a pure static class. It contains role strings — `'admin'`, `'artisan'`, `'buyer'` — order status strings, the product category list, Firestore collection names, and UI dimension values. Using constants instead of string literals throughout the codebase means a typo in a collection name gets caught by the Dart analyzer, not by a runtime Firestore error."

5. **Why collection name constants matter:** "When Member 2 queries `FirestoreService.getProducts()` in PR26, they will reference `AppConstants.productsCollection`. If that constant has a typo, `flutter analyze` flags it. If they hardcode the string `'products'` and misspell it, the app silently returns an empty list. Constants make the difference between a compile-time error and a runtime mystery."

6. **`StatelessWidget` vs `StatefulWidget` demo in `main.dart`:** "`CraftBridgeApp` is a `StatelessWidget` because the MaterialApp configuration never changes. `CraftBridgeHome` is a `StatefulWidget` — not because it has state right now, but to demonstrate the `createState()` pattern and show that I understand when and why to use each type. This demo widget is explicitly temporary and gets replaced in PR08."

7. **Widget tree walkthrough:** "The tree is: `CraftBridgeApp` → `MaterialApp` → `CraftBridgeHome` → `Scaffold` → `AppBar` + `Center` → `Column` → two `Text` widgets. The `Text` widgets use `Theme.of(context).textTheme` to pull styles from `AppTheme.lightTheme` — demonstrating that the theme is correctly wired into the widget tree via `BuildContext`."

8. **`flutter analyze` result:** "With Material 3 and `ColorScheme.fromSeed`, all color references are type-safe. All `const` constructors are in place. The analyzer returns zero issues — the same baseline established in PR01 is maintained."

9. **Emulator demonstration:** "On the emulator you can see the warm brown app bar with 'CraftBridge' centered in white, and the body shows the app name in headline style and the tagline below it. This is a real theme in action — not hardcoded colors, but `AppTheme.lightTheme` applied through `MaterialApp`."

10. **What's Next:** "PR04 will set up the Firebase project, enable Auth and Firestore, run the FlutterFire CLI to generate `firebase_options.dart`, and update `main.dart` and `pubspec.yaml` with all Firebase dependencies."