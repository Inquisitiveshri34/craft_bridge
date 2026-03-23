# PR19 – Themes + Styles — AppTheme Globally Applied

**Project:** CraftBridge
**PR Number:** 19 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Complete `AppTheme.lightTheme` with full typography scale, `TextTheme` overrides, and `SnackBarTheme`, and wire `AppTheme.lightTheme` explicitly into `main.dart`.

---

## Section 2 – Assignments Covered

- Assignment 3.19 — Themes + Styles — AppTheme Globally Applied

---

## Section 3 – Objective

This PR completes the global theme layer for CraftBridge by adding the full `TextTheme` override to `AppTheme.lightTheme` — establishing consistent typography across all screens — and adding `SnackBarTheme` and `BottomNavigationBarTheme` sub-themes so that the snackbars introduced in PR18 and the bottom navigation bar in PR17 inherit brand-consistent styling without per-widget overrides. `main.dart` is updated to confirm `theme: AppTheme.lightTheme` is explicitly set (it was already set in PR08, but this PR verifies and documents the wiring). After this PR, the theme is complete and no screen in PRs 20–51 needs to hardcode any colour, font size, or spacing value that belongs in the theme.

---

## Section 4 – Architecture Context

```
lib/
  core/
    theme/
      app_theme.dart          ← updated this PR (TextTheme + new sub-themes)
  main.dart                   ← verified this PR (theme wiring confirmed)

Theme sub-themes after this PR:
  ✓ colorScheme (PR05)
  ✓ appBarTheme (PR05)
  ✓ elevatedButtonTheme (PR05)
  ✓ outlinedButtonTheme (PR05)
  ✓ inputDecorationTheme (PR05)
  ✓ cardTheme (PR05)
  ✓ floatingActionButtonTheme (PR05)
  ✓ chipTheme (PR05)
  ✓ dividerTheme (PR05)
  ★ textTheme (this PR — NEW)
  ★ snackBarTheme (this PR — NEW)
  ★ bottomNavigationBarTheme (this PR — NEW)

All screens from PR20 onward use:
  Theme.of(context).textTheme.headlineMedium
  Theme.of(context).colorScheme.primary
  (never hardcoded values)
```

This PR sits between `ManageProductsScreen` (PR18) and `AddEditProductScreen` (PR20). The typography scale added here is immediately consumed by PR20's form screen. The `SnackBarTheme` retroactively improves the snackbar shown in PR18's delete confirmation.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/core/theme/app_theme.dart`
- `lib/main.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_constants.dart`.
- Do NOT modify any screen files.
- Do NOT modify any widget files.
- Do NOT modify any provider files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/core/theme/app_theme.dart`

Add three new sub-themes to the existing `lightTheme` getter. All existing sub-themes from PR05 are preserved unchanged. The three additions are appended to the `ThemeData` constructor call.

---

**Addition 1 — `textTheme`:**

```dart
textTheme: const TextTheme(
  displayLarge: TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  ),
  displayMedium: TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  ),
  displaySmall: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  ),
  headlineLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  ),
  titleLarge: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ),
),
```

**Note:** `TextTheme` is declared `const` — all `TextStyle` entries use only compile-time constant values. No `color` is specified in any `TextStyle` — colors are applied by Material 3's `ColorScheme` `onSurface` token automatically at the widget level. Specifying colors here would override the automatic dark/light mode adaptation added in PR46.

---

**Addition 2 — `snackBarTheme`:**

```dart
snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  backgroundColor: const Color(0xFF1C1B1F),
  contentTextStyle: const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ),
  actionTextColor: const Color(0xFFF0E6E0),
),
```

- `SnackBarBehavior.floating` makes the snackbar float above the bottom navigation bar rather than pushing it up.
- `backgroundColor` uses the near-black `#1C1B1F` (the `on-surface` colour from the design system) for maximum contrast.
- `actionTextColor` uses the chip background colour `#F0E6E0` — a warm off-white that reads well against the dark snackbar.

---

**Addition 3 — `bottomNavigationBarTheme`:**

```dart
bottomNavigationBarTheme: BottomNavigationBarThemeData(
  backgroundColor: Colors.white,
  selectedItemColor: const Color(0xFF5C4033),
  unselectedItemColor: const Color(0xFF9E9E9E),
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
```

- `type: BottomNavigationBarType.fixed` ensures all three labels are always visible (not shifting-style).
- `showUnselectedLabels: true` keeps all tab labels visible at all times.
- `elevation: 8` gives a subtle shadow above the bar.

---

### `lib/main.dart`

No structural changes. Verify the following is already present and correct — if not, add or correct it:

```dart
theme: AppTheme.lightTheme,
```

This line must be present as a named parameter of `MaterialApp` in `CraftBridgeApp.build()`. If it is already present from PR08, no change is needed to `main.dart`. The agent must read the file, confirm the line is present, and only modify `main.dart` if it is missing or incorrect.

If `main.dart` requires no change, the agent must NOT include it in the git diff. Only `app_theme.dart` should appear in the diff if `main.dart` is already correct.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/core/theme/app_theme.dart` | Full `TextTheme` with all 13 text styles, `SnackBarTheme` (floating, dark background), `BottomNavigationBarTheme` (fixed type, brand colours) added to `lightTheme` |
| 2 | `lib/main.dart` | Verified — `theme: AppTheme.lightTheme` confirmed present; modified only if missing |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must make targeted additions to `lib/core/theme/app_theme.dart` and verify `lib/main.dart`.

---

**File 1: `lib/core/theme/app_theme.dart`**

Open the existing file. Locate the `ThemeData(` constructor call inside `static ThemeData get lightTheme`. Add the three new sub-theme entries — `textTheme`, `snackBarTheme`, and `bottomNavigationBarTheme` — as additional named parameters to the existing `ThemeData` constructor.

Do NOT remove or modify any of the nine existing sub-themes from PR05:
- `useMaterial3`
- `colorScheme`
- `fontFamily`
- `appBarTheme`
- `elevatedButtonTheme`
- `outlinedButtonTheme`
- `inputDecorationTheme`
- `cardTheme`
- `floatingActionButtonTheme`
- `chipTheme`
- `dividerTheme`

Add the three new sub-themes exactly as specified in Section 6, in this order after the existing sub-themes:
1. `textTheme` — the full 13-entry `const TextTheme(...)` block.
2. `snackBarTheme` — `SnackBarThemeData` with floating behaviour, dark background.
3. `bottomNavigationBarTheme` — `BottomNavigationBarThemeData` with brand colours and fixed type.

**Critical rules:**
- `textTheme` must be declared `const` — all `TextStyle` entries are compile-time constants.
- No `color` property in any `TextStyle` inside `textTheme` — colors come from `ColorScheme` automatically.
- `SnackBarThemeData` and `BottomNavigationBarThemeData` are NOT const (they contain `Color` values that are const, but the theme data objects themselves may not be) — do not add `const` to these.
- The file must have no unused imports after the change.

---

**File 2: `lib/main.dart`**

Read the file. Check whether `theme: AppTheme.lightTheme` is present as a parameter of `MaterialApp`.

- If present and correct: make no changes. Do not include in the commit.
- If absent or incorrect: add `theme: AppTheme.lightTheme,` as a named parameter to `MaterialApp` in `CraftBridgeApp.build()`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `const TextTheme(...)` — all entries must be `const TextStyle` instances with only compile-time constant values; `SnackBarThemeData` shape `BorderRadius.circular(8)` is not const (use `const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))` if const is needed, but `SnackBarThemeData` itself does not need to be const); `BottomNavigationBarThemeData` — verify correct parameter names (`selectedItemColor` not `activeColor`).

2. **Verify `textTheme` entry count**
   ```
   grep -c 'TextStyle(' lib/core/theme/app_theme.dart
   ```
   Must return at least `13` — one for each text style in the `TextTheme`. (Additional `TextStyle` instances may exist in other sub-themes — the count must be at minimum 13.)

3. **Verify no color in `textTheme` entries**
   ```
   grep -A5 'textTheme:' lib/core/theme/app_theme.dart | grep 'color:'
   ```
   Must return no output within the `textTheme` block. No `color:` property should appear in any `TextStyle` inside `textTheme`.

4. **Verify `snackBarTheme` is present**
   ```
   grep 'snackBarTheme' lib/core/theme/app_theme.dart
   ```
   Must return one line — the `snackBarTheme:` parameter.

5. **Verify `SnackBarBehavior.floating`**
   ```
   grep 'SnackBarBehavior.floating' lib/core/theme/app_theme.dart
   ```
   Must return one line.

6. **Verify `bottomNavigationBarTheme` is present**
   ```
   grep 'bottomNavigationBarTheme' lib/core/theme/app_theme.dart
   ```
   Must return one line.

7. **Verify `BottomNavigationBarType.fixed`**
   ```
   grep 'BottomNavigationBarType.fixed' lib/core/theme/app_theme.dart
   ```
   Must return one line.

8. **Verify existing PR05 sub-themes are preserved**
   ```
   grep -c 'appBarTheme\|elevatedButtonTheme\|outlinedButtonTheme\|inputDecorationTheme\|cardTheme\|floatingActionButtonTheme\|chipTheme\|dividerTheme' lib/core/theme/app_theme.dart
   ```
   Must return `8` — all eight PR05 sub-themes still present.

9. **Verify `main.dart` has `theme: AppTheme.lightTheme`**
   ```
   grep 'theme: AppTheme.lightTheme' lib/main.dart
   ```
   Must return one line.

10. **Hot reload on emulator**
    ```
    flutter run
    ```
    Confirm:
    - App launches and displays the splash screen correctly.
    - Navigate to `LoginScreen` — typography uses the new `TextTheme` values: "Welcome back" in `bodyLarge` (16sp, 400 weight), "CraftBridge" heading in `headlineMedium` (28sp, 600 weight).
    - Navigate to `ManageProductsScreen` (log in as artisan) — delete a product and confirm the snackbar floats above the screen bottom (not pinned) with dark background.
    - On `BuyerHomeScreen`, confirm the `BottomNavigationBar` shows all three labels (Home, Cart, Orders) with primary brown for the selected tab.
    - No visual regressions on any previously implemented screen.
    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Must show `lib/core/theme/app_theme.dart`. `lib/main.dart` appears only if it required a correction.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 19
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
git commit -m "PR19: Themes + Styles — AppTheme Globally Applied"
git push origin pr19-app-theme
```

---

## Section 9 – Acceptance Criteria

- [ ] `AppTheme.lightTheme` contains a `textTheme` with all 13 `TextStyle` entries as specified — `displayLarge` through `labelSmall`.
- [ ] No `TextStyle` inside `textTheme` specifies a `color` property.
- [ ] `textTheme` is declared `const`.
- [ ] `AppTheme.lightTheme` contains `snackBarTheme` with `SnackBarBehavior.floating`, dark `backgroundColor` (`#1C1B1F`), and `actionTextColor` (`#F0E6E0`).
- [ ] `AppTheme.lightTheme` contains `bottomNavigationBarTheme` with `selectedItemColor: Color(0xFF5C4033)`, `showUnselectedLabels: true`, and `type: BottomNavigationBarType.fixed`.
- [ ] All nine PR05 sub-themes (`appBarTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, `inputDecorationTheme`, `cardTheme`, `floatingActionButtonTheme`, `chipTheme`, `dividerTheme`, `colorScheme`) remain present and unchanged.
- [ ] `main.dart` has `theme: AppTheme.lightTheme` as a `MaterialApp` parameter.
- [ ] The floating snackbar from `ManageProductsScreen` (PR18) renders with the dark background and rounded corners from the new theme.
- [ ] `BuyerHomeScreen` `BottomNavigationBar` renders with primary brown selected colour and fixed-type labels.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR19 for CraftBridge. I completed the global theme by adding the full Material 3 `TextTheme` with all 13 type scale entries, a floating `SnackBarTheme`, and a `BottomNavigationBarTheme` — ensuring every screen from PR20 onward inherits consistent typography and component styling without any per-widget overrides."

2. **Why `TextTheme` colors are omitted:** "The `TextTheme` entries specify size, weight, and letter spacing — but no `color`. In Material 3, text colors are determined by the `ColorScheme` at the widget level — `onSurface` for body text, `onPrimary` for text on primary containers. If we specified colors here, they would override the automatic light/dark adaptation that PR46 adds. Omitting colors from `TextTheme` is the correct Material 3 pattern."

3. **`const TextTheme` significance:** "The entire `TextTheme` is declared `const` — every `TextStyle` uses only compile-time constant values (numbers and enum-like `FontWeight` constants). This means the `TextTheme` object is created once at compile time and reused, never re-allocated. For a theme object that is accessed on every widget rebuild, `const` is a meaningful micro-optimisation."

4. **Typography scale rationale:** "`headlineMedium` at 28sp/600 weight is used for screen titles and the app name on splash and login. `titleMedium` at 16sp/600 weight is used for product card titles and list item primary text. `bodyLarge` at 16sp/400 weight is used for descriptions and form labels. `bodySmall` at 12sp/400 weight is used for metadata like timestamps and stock counts. This scale matches the design spec from PR05 exactly — PR19 is the implementation of what PR05 described."

5. **`SnackBarBehavior.floating`:** "The default `SnackBarBehavior.fixed` pins the snackbar to the bottom of the screen and pushes the bottom navigation bar up — an awkward visual jump. `floating` makes the snackbar float above all other bottom UI. Combined with `borderRadius: BorderRadius.circular(8)`, the floating snackbar looks like a toast notification rather than a system bar."

6. **`SnackBarTheme` color choices:** "The snackbar background is `#1C1B1F` — the near-black from the design system — rather than `Colors.black`. This is warmer and more consistent with the brand. The action text color is `#F0E6E0` — the warm off-white chip background from PR05. Together they read: dark warm background, warm off-white action. No pure black or pure white in the brand."

7. **`BottomNavigationBarType.fixed`:** "There are two `BottomNavigationBar` types in Flutter: `fixed` shows all labels at all times, `shifting` hides unselected labels and animates the selected one. `fixed` is the correct choice for three tabs — it gives buyers immediate visibility of all navigation options without requiring a discovery interaction."

8. **Retroactive theme improvement for PR18:** "The `SnackBarTheme` added in this PR retroactively improves the snackbar in PR18's `_handleDelete` method — that snackbar was already floating (because `ManageProductsScreen` doesn't override snackbar behaviour), but without the theme it used Flutter's default dark background. Now it uses the brand near-black and the correct border radius."

9. **`main.dart` verification pattern:** "Rather than unconditionally rewriting `main.dart`, the agent reads the file and checks whether `theme: AppTheme.lightTheme` is already present. This is the correct agent behaviour for files that have been built up across multiple PRs — only modify what needs to change, never rewrite what is already correct. `main.dart` was correctly wired in PR08, so this PR should produce no diff on that file."

10. **What's Next:** "PR20 will implement `AddEditProductScreen` — the product creation and editing form with all product fields, a category dropdown, and the complete form submission flow wired to `AppConstants.productCategories`."