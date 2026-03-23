# PR08 – Flutter & Dart Deep Dive — main.dart + MaterialApp

**Project:** CraftBridge
**PR Number:** 08 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Update `main.dart` with async Firebase initialization, `MultiProvider` registration of all four providers, and `home` pointing to `SplashScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.8 — Flutter & Dart Deep Dive — main.dart + MaterialApp

---

## Section 3 – Objective

This PR replaces the temporary PR04 demo `main.dart` with the production-ready application entry point. It wires `MultiProvider` with all four `ChangeNotifier` providers — `AuthProvider`, `ProductProvider`, `OrderProvider`, and `CartProvider` — registers them at the top of the widget tree, and sets `home` to `SplashScreen`. After this PR, the app has a complete, correctly structured entry point that every subsequent screen PR builds on. The `CraftBridgeHome` demo widget and the `'Firebase connected ✓'` text are removed entirely. This is the final version of `main.dart` — no PR after PR08 modifies this file except PR19 (theme wiring) and PR46 (dark mode).

---

## Section 4 – Architecture Context

```
main.dart (after this PR)

void main() async
  └── WidgetsFlutterBinding.ensureInitialized()
  └── Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  └── runApp(const CraftBridgeApp())

CraftBridgeApp (StatelessWidget)
  └── MultiProvider
        ├── ChangeNotifierProvider → AuthProvider
        ├── ChangeNotifierProvider → ProductProvider
        ├── ChangeNotifierProvider → OrderProvider
        └── ChangeNotifierProvider → CartProvider
              └── MaterialApp
                    ├── title: AppConstants.appName
                    ├── debugShowCheckedModeBanner: false
                    ├── theme: AppTheme.lightTheme
                    └── home: SplashScreen()

Provider tree visible to ALL widgets below MaterialApp:
  AuthProvider   → manages auth state + user role
  ProductProvider → manages product list state
  OrderProvider  → manages order state
  CartProvider   → manages local cart state
```

This PR sits after the LLD (PR07) and before the `CustomTextField`/`CustomButton` widgets (PR09). The four providers are registered here as stubs — they contain only placeholder comments from PR01. That is intentional: the widget tree registration is correct even before the providers are implemented, because Flutter's Provider package resolves provider instances lazily. `SplashScreen` is also a placeholder at this point — it is implemented in PR11.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/main.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify any screen, widget, or provider placeholder files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

### `lib/main.dart`

Replace the entire PR04 content. This is the final production entry point for CraftBridge.

**Imports** (in this order):
- `package:flutter/material.dart`
- `package:firebase_core/firebase_core.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/firebase_options.dart`
- `package:craft_bridge/core/theme/app_theme.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/providers/product_provider.dart`
- `package:craft_bridge/providers/order_provider.dart`
- `package:craft_bridge/providers/cart_provider.dart`
- `package:craft_bridge/screens/shared/splash_screen.dart`

**`main()` function:**
- Declared `async`
- First line: `WidgetsFlutterBinding.ensureInitialized()`
- Second line: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- Third line: `runApp(const CraftBridgeApp())`

**`class CraftBridgeApp extends StatelessWidget`:**
- `const` constructor: `const CraftBridgeApp({super.key})`
- `build` method returns `MultiProvider` as the root widget
- `MultiProvider` has:
  - `providers` list containing four `ChangeNotifierProvider` entries in this exact order:
    1. `ChangeNotifierProvider(create: (_) => AuthProvider())`
    2. `ChangeNotifierProvider(create: (_) => ProductProvider())`
    3. `ChangeNotifierProvider(create: (_) => OrderProvider())`
    4. `ChangeNotifierProvider(create: (_) => CartProvider())`
  - `child`: `MaterialApp` configured as follows:
    - `title: AppConstants.appName`
    - `debugShowCheckedModeBanner: false`
    - `theme: AppTheme.lightTheme`
    - `home: const SplashScreen()`

**No other classes or widgets in this file.** The `CraftBridgeHome` `StatefulWidget` demo from PR03/PR04 is removed entirely. No `CraftBridgeHomeState`. No demo `Scaffold`. The file contains exactly two things: the `main()` function and the `CraftBridgeApp` class.

**`const` constructor requirement:** `CraftBridgeApp` must use `const CraftBridgeApp({super.key})`. The `build` method cannot be `const` because `MultiProvider` is not a const widget, but `CraftBridgeApp` itself must be constructable as `const`.

**Provider registration order rationale:** `AuthProvider` is first because it is the dependency that all other screens resolve first. `CartProvider` is last because it is the only local-state provider with no Firebase dependency.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/main.dart` | Production entry point with async Firebase init, `MultiProvider` with all four `ChangeNotifierProvider` registrations, `MaterialApp` with `AppTheme` and `SplashScreen` as home |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR07 is merged to main**

Open your GitHub repository and confirm the `pr07-lld-models` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR08 branch**
```
git checkout -b pr08-main-dart
```

**Step 4 — Confirm the current state of `main.dart`**
```
cat lib/main.dart
```
Confirm it shows the PR04 version — `async main()` with `Firebase.initializeApp()`, the `CraftBridgeHome` demo widget, and the `'Firebase connected ✓'` text. If it shows PR01 placeholder or PR03 content, diagnose before continuing.

**Step 5 — Confirm provider placeholder files exist**
```
cat lib/providers/auth_provider.dart
cat lib/providers/product_provider.dart
cat lib/providers/order_provider.dart
cat lib/providers/cart_provider.dart
```
All four must show their single-comment placeholder lines from PR01. If any show a full implementation, do not proceed — the providers must be stubs at this point.

**Step 6 — Confirm `splash_screen.dart` placeholder exists**
```
cat lib/screens/shared/splash_screen.dart
```
Must show: `// SplashScreen — implemented in PR11`

---

Manual setup for this PR is now complete.
Open `docs/PR08_MainDart_MaterialApp.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must perform exactly one task: replace the entire content of `lib/main.dart`.

---

**Task — Rewrite `lib/main.dart`**

Replace all existing content with the production entry point as specified in Section 6. The implementation must satisfy every requirement below:

**Imports:** Write all 11 import statements in the order specified in Section 6. Every import must be present. No import may be omitted — even though the provider files currently contain only placeholder comments, they must be imported here because the `ChangeNotifierProvider` instantiations reference their classes. The Dart analyzer will report errors if these imports point to files that do not export the expected classes — however, because the provider files are single-comment stubs, the analyzer will report that `AuthProvider`, `ProductProvider`, `OrderProvider`, and `CartProvider` are undefined. This is expected and must be resolved as follows:

The agent must add minimal stub class definitions to the four provider placeholder files to satisfy the analyzer. Each provider file must be updated to contain exactly:

For `lib/providers/auth_provider.dart`:
```dart
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {}
```

For `lib/providers/product_provider.dart`:
```dart
import 'package:flutter/foundation.dart';

class ProductProvider extends ChangeNotifier {}
```

For `lib/providers/order_provider.dart`:
```dart
import 'package:flutter/foundation.dart';

class OrderProvider extends ChangeNotifier {}
```

For `lib/providers/cart_provider.dart`:
```dart
import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {}
```

These are minimal stubs — no methods, no fields, no logic. They exist solely so that `main.dart` can import and instantiate them without analyzer errors. They will be fully replaced in PRs 10, 26, 30, and 42 respectively.

Similarly, `lib/screens/shared/splash_screen.dart` must be updated to contain a minimal stub so that `main.dart`'s `home: const SplashScreen()` does not produce analyzer errors:

For `lib/screens/shared/splash_screen.dart`:
```dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

This stub renders a centered `CircularProgressIndicator` — a visually appropriate placeholder for a splash screen that will be fully implemented in PR11.

**`main.dart` structure:** After the provider and splash stubs are in place, write `main.dart` exactly as specified in Section 6:
- `async main()` with `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp()`
- `CraftBridgeApp` as a `StatelessWidget` with `const` constructor
- `build` returns `MultiProvider` with four `ChangeNotifierProvider` entries in the specified order
- `child` of `MultiProvider` is `MaterialApp` with `title`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `home: const SplashScreen()`
- No `CraftBridgeHome` class. No demo scaffold. No `'Firebase connected ✓'` text.

**File modification summary for this PR:**
- `lib/main.dart` — full replacement
- `lib/providers/auth_provider.dart` — minimal stub class
- `lib/providers/product_provider.dart` — minimal stub class
- `lib/providers/order_provider.dart` — minimal stub class
- `lib/providers/cart_provider.dart` — minimal stub class
- `lib/screens/shared/splash_screen.dart` — minimal stub widget

These additional file modifications are necessary consequences of making `main.dart` analyzable. They are within the spirit of this PR's goal.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. The most likely failure points are: `AuthProvider` class not found (fix: ensure provider stubs are written), `SplashScreen` not found (fix: ensure splash stub is written), `MultiProvider` not imported (fix: ensure `package:provider/provider.dart` is imported).

2. **Verify `main.dart` structure**
   ```
   cat lib/main.dart
   ```
   Confirm: `async main()` present, `MultiProvider` present, all four `ChangeNotifierProvider` entries present, `MaterialApp` with `theme: AppTheme.lightTheme` and `home: const SplashScreen()` present. Confirm `CraftBridgeHome` is absent. Confirm `'Firebase connected ✓'` is absent.

3. **Verify provider stubs**
   ```
   grep -l 'ChangeNotifier' lib/providers/*.dart
   ```
   Must return all four provider files. Each must extend `ChangeNotifier`.

4. **Verify `SplashScreen` stub**
   ```
   cat lib/screens/shared/splash_screen.dart
   ```
   Confirm it contains a `StatelessWidget` returning a `Scaffold` with a `CircularProgressIndicator`.

5. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app launches without crashing.
   - A centered `CircularProgressIndicator` is visible on screen (the `SplashScreen` stub).
   - No `ProviderNotFoundException` in the debug console.
   - No `FirebaseException` in the debug console.
   - No `MissingPluginException` in the debug console.
   Press `q` to quit.

6. **Verify `MultiProvider` provider count**
   ```
   grep -c 'ChangeNotifierProvider' lib/main.dart
   ```
   Must return `4`.

7. **Verify no demo code remains**
   ```
   grep -n 'CraftBridgeHome\|Firebase connected' lib/main.dart
   ```
   Must return no output. If either string is found, the demo code was not removed.

8. **Verify modified files**
   ```
   git diff --name-only
   ```
   Expected: `lib/main.dart`, `lib/providers/auth_provider.dart`, `lib/providers/product_provider.dart`, `lib/providers/order_provider.dart`, `lib/providers/cart_provider.dart`, `lib/screens/shared/splash_screen.dart`. No other files should appear.

9. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 08
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
git commit -m "PR08: Flutter & Dart Deep Dive — main.dart + MaterialApp"
git push origin pr08-main-dart
```

---

## Section 9 – Acceptance Criteria

- [ ] `lib/main.dart` contains an `async main()` with `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- [ ] `lib/main.dart` contains `MultiProvider` with exactly four `ChangeNotifierProvider` entries — `AuthProvider`, `ProductProvider`, `OrderProvider`, `CartProvider` — in that order.
- [ ] `MaterialApp` in `main.dart` uses `theme: AppTheme.lightTheme`, `home: const SplashScreen()`, and `debugShowCheckedModeBanner: false`.
- [ ] `CraftBridgeHome` class and `'Firebase connected ✓'` text are completely absent from `main.dart`.
- [ ] All four provider files contain a minimal `ChangeNotifier` stub class that allows `main.dart` to compile.
- [ ] `lib/screens/shared/splash_screen.dart` contains a minimal `StatelessWidget` stub returning a `Scaffold` with a centered `CircularProgressIndicator`.
- [ ] The emulator displays a centered `CircularProgressIndicator` with no errors in the debug console.
- [ ] No `ProviderNotFoundException`, `FirebaseException`, or `MissingPluginException` appears in the debug console.
- [ ] `grep -c 'ChangeNotifierProvider' lib/main.dart` returns `4`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR08 for CraftBridge. I replaced the temporary PR04 demo `main.dart` with the production application entry point — wiring `MultiProvider` with all four `ChangeNotifier` providers and setting the home screen to `SplashScreen`."

2. **Why `main.dart` is the most important non-screen file:** "`main.dart` is the root of the entire widget tree. Everything registered in `MultiProvider` here is available to every widget in the app via `context.watch`, `context.read`, and `Consumer`. Getting this file right before any screen is implemented means no screen ever has to worry about whether its provider is accessible — it always is."

3. **`MultiProvider` registration order:** "The four providers are registered in dependency order. `AuthProvider` is first because `RoleRouterScreen` reads it immediately after splash. `ProductProvider` and `OrderProvider` are next because they're the core data providers for the artisan and buyer flows. `CartProvider` is last because it's local-only with no Firebase dependency. Order matters in `MultiProvider` only if one provider depends on another — in CraftBridge they're independent, but the ordering makes the dependency intent explicit."

4. **`ChangeNotifierProvider` with `create` callback:** "Each provider uses `ChangeNotifierProvider(create: (_) => ProviderClass())`. The `create` callback receives a `BuildContext` but we don't need it here since none of the providers depend on other providers at construction time. The `create` form is preferred over the `value` form in `MultiProvider` because it ties the provider lifecycle to the widget tree — Flutter disposes the provider when the widget is removed."

5. **Provider stubs as a necessary bridge:** "The four provider files were single-comment placeholders from PR01. `main.dart` can't import and instantiate a class that doesn't exist. Rather than implementing the full providers before `main.dart` — which would be out of sequence — the agent writes minimal `extends ChangeNotifier` stub classes. These stubs satisfy the analyzer, allow `main.dart` to compile, and will be fully replaced in PRs 10, 26, 30, and 42 without any change to `main.dart`."

6. **`SplashScreen` stub:** "The same bridge pattern applies to `SplashScreen`. The stub renders a `CircularProgressIndicator` — which is visually appropriate for a loading screen — so the emulator shows something meaningful while the real implementation waits for PR11. The stub is a `StatelessWidget` because the real `SplashScreen` will be `StatefulWidget`, but the stub doesn't need state."

7. **Removing the demo code:** "The `CraftBridgeHome` demo widget and `'Firebase connected ✓'` text from PR04 are completely removed. They served their purpose — demonstrating `StatefulWidget` in PR03 and confirming Firebase initialization in PR04. From PR08 onward, `main.dart` is clean and production-shaped."

8. **`const CraftBridgeApp({super.key})`:** "Using `super.key` in the constructor is the Dart 3 pattern — it passes the `key` parameter to the parent `StatelessWidget` constructor without a named intermediate variable. The `const` constructor means `runApp(const CraftBridgeApp())` in `main()` is a compile-time constant instantiation, which is a minor but correct Flutter best practice."

9. **Emulator demonstration:** "On the emulator you see a centered `CircularProgressIndicator` on a white background — the `SplashScreen` stub. No app bar, no text, just the spinner. This confirms `MultiProvider` initialized all four providers without error, Firebase initialized successfully, and the routing landed on `SplashScreen` as expected."

10. **What's Next:** "PR09 will implement `custom_text_field.dart` and `custom_button.dart` — the two reusable input widgets that every auth screen, product form, and cart screen will use, styled with `AppTheme` tokens."