# PR09 – Responsive UI — CustomTextField + CustomButton

**Project:** CraftBridge
**PR Number:** 09 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `CustomTextField` and `CustomButton` — the two foundational reusable input widgets styled with `AppTheme` tokens.

---

## Section 2 – Assignments Covered

- Assignment 3.9 — Responsive UI — CustomTextField + CustomButton

---

## Section 3 – Objective

This PR implements the two reusable input widgets that every form in CraftBridge will use — `CustomTextField` for all text input fields and `CustomButton` for all primary and secondary action buttons. Both widgets are styled exclusively from `AppTheme` tokens established in PR05, ensuring visual consistency across all 14 screens without any per-widget hardcoded colors or dimensions. These widgets are the building blocks for `LoginScreen`, `RegistrationScreen`, `AddEditProductScreen`, and every other form screen implemented in PRs 13 through 44.

---

## Section 4 – Architecture Context

```
lib/
  widgets/
    custom_text_field.dart    ← fully implemented this PR
    custom_button.dart        ← fully implemented this PR

Consumed by (future PRs):
  screens/auth/
    login_screen.dart         ← PR13/PR14
    registration_screen.dart  ← PR13/PR14
  screens/artisan/
    add_edit_product_screen.dart ← PR20
  screens/buyer/
    cart_screen.dart          ← PR33
  screens/admin/
    manage_users_screen.dart  ← PR48

Widget dependency chain:
  AppTheme.lightTheme
    └── InputDecorationTheme  → consumed by CustomTextField
    └── ElevatedButtonTheme   → consumed by CustomButton (primary)
    └── OutlinedButtonTheme   → consumed by CustomButton (secondary)
```

This PR sits between `main.dart` wiring (PR08) and `AuthProvider` implementation (PR10). The widgets implemented here are passive — they have no Provider dependencies and no Firebase interactions. They are pure UI components that accept callbacks and display state passed in from their parent screens.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders from PR01.

**Allowed file modification:**
- `lib/widgets/custom_text_field.dart`
- `lib/widgets/custom_button.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any screen placeholder files.
- Do NOT modify any provider files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/widgets/custom_text_field.dart`

**Widget type:** `StatelessWidget`

**Class name:** `CustomTextField`

**Import:** `package:flutter/material.dart` only.

**Constructor parameters** (all named, with defaults where specified):

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `label` | `String` | Yes | — | The label text displayed above/inside the field |
| `hint` | `String` | No | `''` | Placeholder hint text |
| `controller` | `TextEditingController` | Yes | — | The text editing controller |
| `keyboardType` | `TextInputType` | No | `TextInputType.text` | Input keyboard type |
| `obscureText` | `bool` | No | `false` | Whether to obscure input (for passwords) |
| `suffixIcon` | `Widget?` | No | `null` | Optional widget shown at end of field |
| `validator` | `String? Function(String?)?` | No | `null` | Optional form validation function |
| `onChanged` | `void Function(String)?` | No | `null` | Callback on text change |
| `enabled` | `bool` | No | `true` | Whether the field is interactive |
| `maxLines` | `int` | No | `1` | Number of lines (use `null` for unlimited) — declare as `int?` with default `1` |
| `textCapitalization` | `TextCapitalization` | No | `TextCapitalization.none` | Text capitalisation behaviour |
| `prefixIcon` | `Widget?` | No | `null` | Optional widget shown at start of field |

**`build` method returns:** `TextFormField`

**`TextFormField` configuration:**
- `controller: controller`
- `keyboardType: keyboardType`
- `obscureText: obscureText`
- `enabled: enabled`
- `maxLines: obscureText ? 1 : maxLines`
- `textCapitalization: textCapitalization`
- `validator: validator`
- `onChanged: onChanged`
- `decoration`: `InputDecoration` with:
  - `labelText: label`
  - `hintText: hint.isEmpty ? null : hint`
  - `suffixIcon: suffixIcon`
  - `prefixIcon: prefixIcon`

**Do NOT override** `border`, `enabledBorder`, `focusedBorder`, `errorBorder`, `filled`, or `fillColor` inside the `InputDecoration` — these are already set globally by `AppTheme.lightTheme`'s `inputDecorationTheme`. Adding them here would override the theme and break the single-source-of-truth principle.

**`const` constructor:** `const CustomTextField({super.key, ...})` — however, note that `TextEditingController` is not a `const` type, so the constructor itself cannot be `const`. Use a non-const constructor: `CustomTextField({super.key, required this.label, ...})`.

---

### `lib/widgets/custom_button.dart`

**Widget type:** `StatelessWidget`

**Class name:** `CustomButton`

**Import:** `package:flutter/material.dart` only.

**Constructor parameters** (all named, with defaults where specified):

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `label` | `String` | Yes | — | The button label text |
| `onPressed` | `VoidCallback?` | Yes | — | Tap callback — pass `null` to disable the button |
| `isLoading` | `bool` | No | `false` | When `true`, replaces label with a `CircularProgressIndicator` |
| `variant` | `ButtonVariant` | No | `ButtonVariant.primary` | Controls whether to render `ElevatedButton` or `OutlinedButton` |
| `icon` | `IconData?` | No | `null` | Optional leading icon — renders `ElevatedButton.icon` / `OutlinedButton.icon` when provided |
| `width` | `double?` | No | `null` | Optional explicit width override — defaults to full width via theme `minimumSize` |

**Supporting enum** (defined in the same file, above the `CustomButton` class):

```dart
enum ButtonVariant { primary, secondary }
```

**`build` method logic:**

The method builds a `SizedBox` with `width: width ?? double.infinity` wrapping the button widget.

The button widget is determined by `variant`:

- If `variant == ButtonVariant.primary`:
  - If `icon != null` and `isLoading == false`: return `ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))`
  - Otherwise: return `ElevatedButton(onPressed: isLoading ? null : onPressed, child: _buildChild())`

- If `variant == ButtonVariant.secondary`:
  - If `icon != null` and `isLoading == false`: return `OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))`
  - Otherwise: return `OutlinedButton(onPressed: isLoading ? null : onPressed, child: _buildChild())`

**Private helper method `_buildChild()`:**

```dart
Widget _buildChild() {
  if (isLoading) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
  return Text(label);
}
```

**Do NOT override** `backgroundColor`, `foregroundColor`, `minimumSize`, or `shape` inside `ButtonStyle` — these are already set globally by `AppTheme.lightTheme`'s `elevatedButtonTheme` and `outlinedButtonTheme`. The button inherits all styling from the theme.

**`const` constructor:** `const CustomButton({super.key, required this.label, required this.onPressed, ...})`.

**Disabled state:** When `onPressed` is `null` OR when `isLoading` is `true`, the button's `onPressed` is passed as `null`. Flutter's Material button automatically renders in a disabled visual state when `onPressed` is `null` — no additional styling is required.

**Loading state behaviour:** When `isLoading` is `true`, the button shows a 20×20 `CircularProgressIndicator` with `strokeWidth: 2` in `Colors.white`, and `onPressed` is forced to `null` regardless of the passed value. This prevents double-submission during async operations.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/widgets/custom_text_field.dart` | `CustomTextField` `StatelessWidget` with 12 configurable parameters, renders `TextFormField` styled from `AppTheme` |
| 2 | `lib/widgets/custom_button.dart` | `CustomButton` `StatelessWidget` with `ButtonVariant` enum, loading state, icon support, and primary/secondary variants |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR08 is merged to main**

Open your GitHub repository and confirm the `pr08-main-dart` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR09 branch**
```
git checkout -b pr09-custom-widgets
```

**Step 4 — Confirm placeholder files exist**
```
cat lib/widgets/custom_text_field.dart
cat lib/widgets/custom_button.dart
```
Both must show their single-comment placeholder lines from PR01. If either shows a full implementation, do not proceed.

---

Manual setup for this PR is now complete.
Open `docs/PR09_CustomTextField_CustomButton.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must implement exactly two files. No new files are created. No new folders are created.

---

**File 1: `lib/widgets/custom_text_field.dart`**

Replace the single-comment placeholder entirely. Write a complete Dart file:

- Import `package:flutter/material.dart`.
- Declare `class CustomTextField extends StatelessWidget`.
- Declare all 12 constructor parameters exactly as specified in Section 6. Use `this.paramName` shorthand in the constructor parameter list. `maxLines` must be declared as `final int? maxLines` with a default of `1` in the constructor.
- Implement `build` returning a `TextFormField` configured exactly as specified in Section 6.
- `hintText` must be `hint.isEmpty ? null : hint` — an empty string hint should not render as an empty hint label in the field.
- Do NOT add any `InputDecoration` border or fill properties — these come from the theme.
- Do NOT add any `style` property to the `TextFormField` — font styling comes from the theme.
- Ensure the constructor is not declared `const` because `TextEditingController` is not a const-compatible type.

---

**File 2: `lib/widgets/custom_button.dart`**

Replace the single-comment placeholder entirely. Write a complete Dart file:

- Import `package:flutter/material.dart`.
- Declare `enum ButtonVariant { primary, secondary }` above the class definition.
- Declare `class CustomButton extends StatelessWidget`.
- Declare all 6 constructor parameters exactly as specified in Section 6.
- Declare `const CustomButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.variant = ButtonVariant.primary, this.icon, this.width})`.
- Implement `_buildChild()` as a private method exactly as specified in Section 6. The `CircularProgressIndicator` inside `_buildChild` must have `strokeWidth: 2` and `valueColor: AlwaysStoppedAnimation<Color>(Colors.white)`.
- Implement `build` returning a `SizedBox` with `width: width ?? double.infinity` wrapping the appropriate button variant.
- Button variant logic must handle all four cases: primary with icon, primary without icon, secondary with icon, secondary without icon.
- When `isLoading` is `true`, `onPressed` must be `null` on the button regardless of what was passed in.
- When `icon` is not null but `isLoading` is `true`, render the non-icon button form (i.e. `ElevatedButton` not `ElevatedButton.icon`) with the loading child — this prevents the icon from showing during loading.
- Do NOT add any `style` overrides to any button — all styling comes from the theme.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: `TextEditingController` parameter incorrectly marked `const`, missing `?` on nullable parameters, incorrect `AlwaysStoppedAnimation` type argument, `_buildChild` not returning `Widget` type explicitly.

2. **Verify `CustomTextField` parameter count**
   ```
   grep -c 'final ' lib/widgets/custom_text_field.dart
   ```
   Must return `12` — one for each declared field.

3. **Verify `ButtonVariant` enum exists**
   ```
   grep 'enum ButtonVariant' lib/widgets/custom_button.dart
   ```
   Must return the enum declaration line.

4. **Verify loading state disables button**
   ```
   grep 'isLoading ? null : onPressed' lib/widgets/custom_button.dart
   ```
   Must return at least one line — confirming the loading guard is present.

5. **Verify no theme overrides in `CustomTextField`**
   ```
   grep -n 'border:\|fillColor:\|filled:\|focusedBorder:\|enabledBorder:' lib/widgets/custom_text_field.dart
   ```
   Must return no output. Any match means the widget is overriding theme properties it should inherit.

6. **Verify no style overrides in `CustomButton`**
   ```
   grep -n 'style:.*Button\|backgroundColor:\|foregroundColor:\|minimumSize:' lib/widgets/custom_button.dart
   ```
   Must return no output. Any match means the widget is overriding theme properties it should inherit.

7. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app launches and shows the `SplashScreen` stub `CircularProgressIndicator`.
   - No errors in the debug console.
   - No widget rendering errors (the new widget files are not yet wired to any screen, so no visible change is expected).
   Press `q` to quit.

8. **Verify only the correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/widgets/custom_text_field.dart` and `lib/widgets/custom_button.dart` should appear. If any other files appear, diagnose before pushing.

9. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 09
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
git commit -m "PR09: Responsive UI — CustomTextField + CustomButton"
git push origin pr09-custom-widgets
```

---

## Section 9 – Acceptance Criteria

- [ ] `lib/widgets/custom_text_field.dart` implements `CustomTextField` as a `StatelessWidget` with exactly 12 named constructor parameters as specified.
- [ ] `CustomTextField.build` returns a `TextFormField` with `labelText`, `hintText`, `controller`, `keyboardType`, `obscureText`, `suffixIcon`, `prefixIcon`, `validator`, `onChanged`, `enabled`, `maxLines`, and `textCapitalization` all wired correctly.
- [ ] `CustomTextField` does not override any `InputDecoration` border, fill, or color properties — all are inherited from `AppTheme`.
- [ ] `lib/widgets/custom_button.dart` declares `enum ButtonVariant { primary, secondary }` in the same file above the class.
- [ ] `CustomButton` implements all four button cases: primary with icon, primary without icon, secondary with icon, secondary without icon.
- [ ] When `isLoading` is `true`, `CustomButton` renders a 20×20 `CircularProgressIndicator` with `strokeWidth: 2` and `valueColor: AlwaysStoppedAnimation<Color>(Colors.white)`, and `onPressed` is forced to `null`.
- [ ] `CustomButton` does not override any `ButtonStyle` properties — all button styling is inherited from `AppTheme`.
- [ ] `SizedBox` wrapping the button uses `width: width ?? double.infinity` to default to full width.
- [ ] No new files were created and no files outside the two widget files were modified.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR09 for CraftBridge. I implemented `CustomTextField` and `CustomButton` — the two foundational reusable input widgets that every form screen in the app will use, styled entirely from `AppTheme` tokens with no hardcoded colors or dimensions."

2. **Why reusable widgets matter in a 51-PR project:** "CraftBridge has at least six form screens — login, registration, add/edit product, cart checkout, review submission, and profile. Without `CustomTextField` and `CustomButton`, each screen would independently configure `TextFormField` and `ElevatedButton` with the same colors and dimensions. Any design change would require touching six files. With these widgets, a design change to the input field border radius touches exactly one file — `AppTheme`."

3. **`CustomTextField` parameter design:** "The widget has 12 parameters. The most important are `controller` and `label` — both required. The rest are optional with sensible defaults: `keyboardType` defaults to text, `obscureText` defaults to false, `maxLines` defaults to 1. The `suffixIcon` parameter is what enables the password visibility toggle in `LoginScreen` without `CustomTextField` needing to know anything about password state."

4. **Theme inheritance in `CustomTextField`:** "The `TextFormField` inside `CustomTextField` does not set `border`, `fillColor`, `filled`, or any border state. These come entirely from `AppTheme.lightTheme.inputDecorationTheme` — the three-state border spec (enabled, focused, error) that was configured in PR05. If I had added `border: OutlineInputBorder()` inside `InputDecoration` here, it would override the theme and every field in the app would lose the focused-state brown border."

5. **`ButtonVariant` enum:** "The enum has two values — `primary` and `secondary`. Primary renders an `ElevatedButton` with a filled brown background. Secondary renders an `OutlinedButton` with a brown border and transparent background. Both inherit their sizing from `AppTheme` — `minimumSize: Size(double.infinity, 48)` means every button is full-width and 48dp tall by default. The `width` parameter allows overriding this for inline buttons."

6. **Loading state implementation:** "When `isLoading` is `true`, two things happen: the label is replaced by a 20×20 `CircularProgressIndicator`, and `onPressed` is forced to `null`. Forcing `null` is critical — it prevents double-submission if a user taps a button while an async operation is in flight. The spinner is white because it sits on the filled primary button background."

7. **Icon button variants:** "The `icon` parameter enables `ElevatedButton.icon` and `OutlinedButton.icon` — Flutter's built-in icon+label button layout. When `isLoading` is `true`, even if `icon` is set, the icon-form button is not rendered — the non-icon form is used with the spinner child. This avoids an ugly state where the icon and spinner appear simultaneously."

8. **`SizedBox` width wrapper:** "The `SizedBox(width: width ?? double.infinity)` pattern is the standard Flutter way to make a button full-width. `ElevatedButton` itself respects the width constraint from its parent — wrapping it in an infinite-width `SizedBox` makes it stretch to fill the parent's horizontal space. Passing an explicit `width` overrides this for buttons that should not be full-width."

9. **`flutter analyze` on these widgets:** "Both widgets are pure `StatelessWidget` implementations with no async code, no state, and no Firebase dependencies. The only analyzer trap is `AlwaysStoppedAnimation<Color>` — it requires the explicit `<Color>` type argument or Dart infers `dynamic`. With the type argument, the analyzer is satisfied."

10. **What's Next:** "PR10 will implement `AuthProvider` — the most critical provider in the project — with `signIn`, `signUp`, `signOut`, and `_init`, and will fill in all user methods in `FirestoreService` that were stubbed in PR07."