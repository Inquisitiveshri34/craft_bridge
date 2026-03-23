# PR46 – Dark Mode — Dynamic Theming

**Project:** CraftBridge
**PR Number:** 46 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Add `darkTheme` to `AppTheme`, create `ThemeProvider` with persistence via `shared_preferences`, and wire dynamic theme switching into `main.dart` with a toggle accessible from all home screens.

---

## Section 2 – Assignments Covered

- Assignment 3.46 — Dark Mode — Dynamic Theming

---

## Section 3 – Objective

This PR adds full dark mode support to CraftBridge — implementing `AppTheme.darkTheme` using Material 3's `ColorScheme.fromSeed` with `brightness: Brightness.dark`, creating `ThemeProvider` as a `ChangeNotifier` that stores and persists the user's theme preference via `shared_preferences`, updating `main.dart` to consume `ThemeProvider` for both `theme` and `darkTheme`, and adding a dark mode toggle accessible from `ArtisanHomeScreen`, `AdminHomeScreen`, and `BuyerHomeScreen`. After this PR, the app responds to system theme changes and also supports manual override via the toggle.

---

## Section 4 – Architecture Context

```
pubspec.yaml:
  shared_preferences: ^2.3.2   ← added this PR

AppTheme (updated this PR):
  lightTheme   ← unchanged from PR05/PR19
  darkTheme    ← new static getter

ThemeProvider (ChangeNotifier — this PR):
  ├── _isDarkMode: bool
  ├── isDarkMode getter
  ├── toggleTheme()
  └── _loadThemePreference() / _saveThemePreference()
        └── SharedPreferences key: 'isDarkMode'

main.dart (updated this PR):
  MultiProvider:
    ├── ... existing providers ...
    └── ChangeNotifierProvider(create: (_) => ThemeProvider())
  MaterialApp:
    ├── theme: AppTheme.lightTheme
    ├── darkTheme: AppTheme.darkTheme
    └── themeMode: themeProvider.themeMode
          (ThemeMode.light / ThemeMode.dark / ThemeMode.system)

Theme toggle location:
  ArtisanHomeScreen AppBar action  ← brightness icon
  AdminHomeScreen AppBar action    ← brightness icon
  BuyerHomeScreen AppBar action    ← brightness icon (Home tab only)
```

This PR sits after the buyer nav shell (PR45) and before error handling (PR47). `ThemeProvider` is a new `ChangeNotifier` registered in `MultiProvider` — `main.dart` must be updated.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `pubspec.yaml` — add `shared_preferences`
- `lib/core/theme/app_theme.dart` — add `darkTheme`
- `lib/main.dart` — add `ThemeProvider` to `MultiProvider`, wire `themeMode`
- `lib/screens/artisan/artisan_home_screen.dart` — add theme toggle
- `lib/screens/admin/admin_home_screen.dart` — add theme toggle
- `lib/screens/buyer/buyer_home_screen.dart` — add theme toggle

**Critical note on `ThemeProvider`:** The locked folder structure does not include a standalone `theme_provider.dart` file. `ThemeProvider` is implemented directly inside `app_theme.dart` as an additional class in the same file — keeping it co-located with the theme data it controls.

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_constants.dart`.
- Do NOT modify any other provider files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml` beyond adding `shared_preferences`.

---

## Section 6 – Technical Requirements

---

### `pubspec.yaml`

Add `shared_preferences: ^2.3.2` under the `dependencies:` section, after `firebase_messaging: ^15.1.3`.

---

### `lib/core/theme/app_theme.dart`

Two additions to the existing PR19 implementation:

---

**Addition 1 — `ThemeProvider` class appended to the file:**

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Add these imports to the existing import block.

Then append `ThemeProvider` at the bottom of the file, after the `AppTheme` class:

```dart
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  Future<void> _saveThemePreference() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}
```

**Implementation notes:**

- `ThemeProvider` is co-located with `AppTheme` in `app_theme.dart` — no new file is created.
- `_loadThemePreference()` is called in the constructor — it loads the persisted preference asynchronously. On the first build, `_isDarkMode` is `false` (the default); after the async load completes, `notifyListeners()` triggers a rebuild with the correct persisted value.
- `toggleTheme()` is `async` — it calls `_saveThemePreference()` after flipping the flag and notifying listeners.
- `themeMode` returns `ThemeMode.light` or `ThemeMode.dark` — not `ThemeMode.system`. Manual toggle always overrides the system setting.
- `try-catch` around `SharedPreferences` calls — preference read/write failures must not crash the app.

---

**Addition 2 — `darkTheme` static getter on `AppTheme`:**

Add to the `AppTheme` class after `lightTheme`:

```dart
static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5C4033),
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1812),
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF2C1F1A),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B6355),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8B6355),
          side: const BorderSide(color: Color(0xFF8B6355), width: 1.5),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5C4A43)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF8B6355), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCF6679)),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        filled: true,
        fillColor: const Color(0xFF2C1F1A),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF2C1F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8B6355),
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3D2B22),
        selectedColor: const Color(0xFF8B6355),
        labelStyle: const TextStyle(fontSize: 13),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D2B22),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: const Color(0xFF3D2B22),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        actionTextColor: const Color(0xFFF0E6E0),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF2C1F1A),
        selectedItemColor: const Color(0xFF8B6355),
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
    );
```

**Dark theme colour decisions:**
- `seedColor` is the same `#5C4033` as light mode — the Material 3 seed generates a harmonious dark palette automatically.
- `surface: Color(0xFF1C1812)` — deep warm near-black (not pure black) maintains the earthy brand identity.
- App bar background `#2C1F1A` — dark warm brown, not generic dark grey.
- Button and FAB background `#8B6355` — lighter warm brown for visibility on dark backgrounds.
- Card background `#2C1F1A` — matches app bar for surface consistency.
- No `color` in any `TextStyle` in `textTheme` — same as light theme, letting Material 3 set text colours from `ColorScheme`.

---

### `lib/main.dart`

Three targeted changes.

---

**Change 1 — Add `ThemeProvider` import:**

```dart
import 'package:craft_bridge/core/theme/app_theme.dart';
```

Already present — `ThemeProvider` is in `app_theme.dart` so no new import is needed.

---

**Change 2 — Add `ThemeProvider` to `MultiProvider`:**

Add as the first provider in the `providers` list:

```dart
ChangeNotifierProvider(create: (_) => ThemeProvider()),
```

Order in `providers` list after this PR:
1. `ChangeNotifierProvider(create: (_) => ThemeProvider())`
2. `ChangeNotifierProvider(create: (_) => AuthProvider())`
3. `ChangeNotifierProvider(create: (_) => ProductProvider())`
4. `ChangeNotifierProvider(create: (_) => OrderProvider())`
5. `ChangeNotifierProvider(create: (_) => CartProvider())`

---

**Change 3 — Wire `ThemeProvider` to `MaterialApp`:**

Replace the `CraftBridgeApp.build()` to consume `ThemeProvider`:

```dart
@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    ),
  );
}
```

The `Consumer<ThemeProvider>` wraps `MaterialApp` — when `ThemeProvider.toggleTheme()` is called, `MaterialApp` rebuilds with the new `themeMode`.

---

### Theme toggle in home screens

Add a brightness toggle `IconButton` to the `AppBar.actions` of all three home screens.

**`ArtisanHomeScreen` AppBar actions update:**

```dart
actions: [
  Consumer<ThemeProvider>(
    builder: (_, themeProvider, __) => IconButton(
      icon: Icon(
        themeProvider.isDarkMode
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      tooltip: themeProvider.isDarkMode
          ? 'Switch to light mode'
          : 'Switch to dark mode',
      onPressed: () =>
          context.read<ThemeProvider>().toggleTheme(),
    ),
  ),
  IconButton(
    icon: const Icon(Icons.logout),
    tooltip: 'Sign Out',
    onPressed: () => context.read<AuthProvider>().signOut(),
  ),
],
```

Apply the same `Consumer<ThemeProvider>` `IconButton` addition to `AdminHomeScreen` and `BuyerHomeScreen` (Home tab only — already conditional on `_currentNavIndex == 0`).

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `pubspec.yaml` | `shared_preferences: ^2.3.2` added |
| 2 | `lib/core/theme/app_theme.dart` | `darkTheme` static getter added to `AppTheme`, `ThemeProvider` class appended |
| 3 | `lib/main.dart` | `ThemeProvider` added to `MultiProvider`, `Consumer<ThemeProvider>` wraps `MaterialApp`, `darkTheme` and `themeMode` wired |
| 4 | `lib/screens/artisan/artisan_home_screen.dart` | Brightness toggle `IconButton` added to `AppBar` actions |
| 5 | `lib/screens/admin/admin_home_screen.dart` | Brightness toggle `IconButton` added to `AppBar` actions |
| 6 | `lib/screens/buyer/buyer_home_screen.dart` | Brightness toggle `IconButton` added to Home tab `AppBar` actions |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must update `pubspec.yaml` and modify five Dart files.

---

**Step 1: Update `pubspec.yaml`**

Add `shared_preferences: ^2.3.2` after `firebase_messaging: ^15.1.3`. Run `flutter pub get`.

---

**File 1: `lib/core/theme/app_theme.dart`**

Two additions:
1. Add `flutter/foundation.dart` and `shared_preferences/shared_preferences.dart` imports to the import block.
2. Add `darkTheme` static getter to `AppTheme` class after `lightTheme`.
3. Append `ThemeProvider extends ChangeNotifier` class at the bottom of the file.

**Critical rules:**
- `darkTheme` `textTheme` must have no `color` properties — identical `TextStyle` entries as `lightTheme.textTheme`.
- `ThemeProvider` constructor calls `_loadThemePreference()` — async, but the constructor is not `async`.
- `toggleTheme()` notifies before saving — the UI updates immediately while the disk write happens in background.

---

**File 2: `lib/main.dart`**

Three changes:
1. Add `ThemeProvider` as the first `ChangeNotifierProvider` in `MultiProvider`.
2. Wrap `MaterialApp` in `Consumer<ThemeProvider>`.
3. Add `darkTheme: AppTheme.darkTheme` and `themeMode: themeProvider.themeMode` to `MaterialApp`.

---

**Files 3–5: `artisan_home_screen.dart`, `admin_home_screen.dart`, `buyer_home_screen.dart`**

Add `Consumer<ThemeProvider>` brightness toggle `IconButton` to `AppBar.actions` in each screen. For `buyer_home_screen.dart`, the toggle is inside the `if (_currentNavIndex == 0)` block already governing the sign-out button actions.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Confirm `shared_preferences` resolves.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `ThemeMode` — from `material.dart`; `SharedPreferences` — requires `shared_preferences` import; `ThemeProvider` in same file as `AppTheme` — both must be exported from `app_theme.dart`; `Consumer<ThemeProvider>` in `main.dart` requires `app_theme.dart` import (already present).

3. **Verify `ThemeProvider` class in `app_theme.dart`**
   ```
   grep 'class ThemeProvider' lib/core/theme/app_theme.dart
   ```
   Must return one line.

4. **Verify `darkTheme` getter exists**
   ```
   grep 'static ThemeData get darkTheme' lib/core/theme/app_theme.dart
   ```
   Must return one line.

5. **Verify `ThemeProvider` in `MultiProvider`**
   ```
   grep 'ThemeProvider' lib/main.dart
   ```
   Must return at least two lines — the `ChangeNotifierProvider` and the `Consumer`.

6. **Verify `themeMode` wired to `MaterialApp`**
   ```
   grep 'themeMode' lib/main.dart
   ```
   Must return one line.

7. **Verify `darkTheme` wired to `MaterialApp`**
   ```
   grep 'darkTheme:' lib/main.dart
   ```
   Must return one line.

8. **Verify toggle in all three home screens**
   ```
   grep 'toggleTheme' lib/screens/artisan/artisan_home_screen.dart
   grep 'toggleTheme' lib/screens/admin/admin_home_screen.dart
   grep 'toggleTheme' lib/screens/buyer/buyer_home_screen.dart
   ```
   Each must return at least one line.

9. **Hot reload on emulator — dark mode test**
   ```
   flutter run
   ```
   Log in as a buyer.

   Confirm:
   - App launches in light mode (warm browns, off-white backgrounds).
   - `BuyerHomeScreen` Home tab shows moon/dark mode icon in app bar.
   - Tap the icon → entire app switches to dark mode instantly.
   - Dark mode: deep warm near-black backgrounds, lighter brown buttons, all text readable.
   - `BottomNavigationBar` dark background visible.
   - `ProductCard` dark card backgrounds.
   - `LoginScreen` dark input fields with warm borders.
   - Tap the icon again → switches back to light mode.
   - Kill and relaunch the app (dark mode was active) → app relaunches in dark mode (preference persisted).

   Log in as artisan → confirm toggle works in `ArtisanHomeScreen`.
   Log in as admin → confirm toggle works in `AdminHomeScreen`.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `pubspec.yaml`, `pubspec.lock`, `lib/core/theme/app_theme.dart`, `lib/main.dart`, `lib/screens/artisan/artisan_home_screen.dart`, `lib/screens/admin/admin_home_screen.dart`, `lib/screens/buyer/buyer_home_screen.dart`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 46
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
git commit -m "PR46: Dark Mode — Dynamic Theming"
git push origin pr46-dark-mode
```

---

## Section 9 – Acceptance Criteria

- [ ] `pubspec.yaml` contains `shared_preferences: ^2.3.2`.
- [ ] `AppTheme.darkTheme` is a static getter returning a full `ThemeData` with `ColorScheme.fromSeed(brightness: Brightness.dark)` and warm near-black surface colours.
- [ ] `darkTheme.textTheme` has no `color` properties in any `TextStyle`.
- [ ] `ThemeProvider` class is defined in `app_theme.dart` with `isDarkMode`, `themeMode`, `toggleTheme()`, `_loadThemePreference()`, and `_saveThemePreference()`.
- [ ] `ThemeProvider` persists the preference to `SharedPreferences` with key `'isDarkMode'`.
- [ ] `main.dart` `MultiProvider` includes `ChangeNotifierProvider(create: (_) => ThemeProvider())`.
- [ ] `MaterialApp` is wrapped in `Consumer<ThemeProvider>` and consumes `darkTheme: AppTheme.darkTheme` and `themeMode: themeProvider.themeMode`.
- [ ] Brightness toggle `IconButton` is present in `ArtisanHomeScreen`, `AdminHomeScreen`, and `BuyerHomeScreen` (Home tab only).
- [ ] Dark mode preference persists across app restarts.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR46 for CraftBridge. I added full dark mode support — implementing `AppTheme.darkTheme` with Material 3's dark colour scheme, creating `ThemeProvider` in `app_theme.dart` with `SharedPreferences` persistence, wiring both themes into `main.dart`, and adding a brightness toggle to all three home screens."

2. **`ThemeProvider` in `app_theme.dart`:** "`ThemeProvider` lives in `app_theme.dart` rather than a separate file — the locked folder structure has no `theme_provider.dart`. Co-locating it with `AppTheme` is logical: `ThemeProvider` is only meaningful in the context of `AppTheme.lightTheme` and `AppTheme.darkTheme`. It's the same separation-of-concerns argument as keeping constants in `app_constants.dart`."

3. **`ColorScheme.fromSeed` with `brightness: Brightness.dark`:** "The dark theme uses the same seed colour `#5C4033` as the light theme — but passes `brightness: Brightness.dark` to `ColorScheme.fromSeed`. Material 3 automatically generates a dark-mode-appropriate palette from the seed: darker surfaces, lighter on-surface colours, adjusted tonal values. The warm near-black `#1C1812` surface colour maintains the earthy brand identity rather than using generic `Colors.grey.shade900`."

4. **`toggleTheme()` notifies before saving:** "`toggleTheme()` calls `notifyListeners()` before `_saveThemePreference()`. This makes the UI switch instantly — the `Consumer<ThemeProvider>` rebuilds `MaterialApp` with the new `themeMode` immediately. The disk write happens in the background via `async`. If the write fails (rare), the in-memory state is still correct for the current session."

5. **`_loadThemePreference()` async constructor pattern:** "The `ThemeProvider` constructor calls `_loadThemePreference()` — an `async` method — without `await`. The constructor cannot be `async`. On construction, `_isDarkMode` defaults to `false`; the disk read completes asynchronously and `notifyListeners()` triggers a rebuild with the persisted value. There's a brief moment where the app renders in light mode before the dark preference is loaded — imperceptible in practice because `SharedPreferences` reads are sub-millisecond."

6. **`Consumer<ThemeProvider>` wrapping `MaterialApp`:** "The `Consumer` must wrap `MaterialApp`, not just the screens. When `ThemeProvider` notifies, the `MaterialApp` must rebuild to apply the new `themeMode`. If the `Consumer` only wrapped individual screens, the `MaterialApp`'s `themeMode` would be stale and the `Theme.of(context)` in those screens wouldn't update."

7. **`ThemeMode.light` vs `ThemeMode.system`:** "`ThemeProvider.themeMode` returns `ThemeMode.light` or `ThemeMode.dark` — never `ThemeMode.system`. The manual toggle always overrides the system preference. A more sophisticated implementation might have three states: light, dark, system. For the MVP, the binary toggle is simpler and more discoverable — the brightness icon is an obvious on/off switch."

8. **Dark theme colour rationale:** "The dark app bar uses `#2C1F1A` — a warm dark brown — rather than pure black. The card background is the same `#2C1F1A`. Buttons use `#8B6355` — a lighter warm brown that provides sufficient contrast on dark surfaces. This palette feels like the same brand in a dimmer light, not a completely different design."

9. **Toggle in all three home screens:** "Every role gets the dark mode toggle — artisan, admin, and buyer. The toggle is an `IconButton` in the `AppBar.actions` showing `Icons.dark_mode_outlined` or `Icons.light_mode_outlined` based on `themeProvider.isDarkMode`. The icon updates reactively via `Consumer<ThemeProvider>`. The tooltip text also updates — 'Switch to dark mode' vs 'Switch to light mode'."

10. **What's Next:** "PR47 will add comprehensive error handling across all async screens — implementing `LoadingWidget`, `EmptyStateWidget`, and `ErrorWidget` as reusable components, and applying them consistently across `ManageProductsScreen`, `ArtisanOrdersScreen`, `BuyerHomeScreen`, and `BuyerOrdersScreen`."