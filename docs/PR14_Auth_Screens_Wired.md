# PR14 – Stateless vs Stateful Widgets — Auth Screens Fully Wired + Form Validation

**Project:** CraftBridge
**PR Number:** 14 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Add full form validation, `_formKey.currentState!.validate()` gating, and field-level error display to `LoginScreen` and `RegistrationScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.14 — Stateless vs Stateful Widgets — Auth Screens Fully Wired + Form Validation

---

## Section 3 – Objective

This PR completes the authentication screens by adding validators to every `CustomTextField`, gating the sign-in and sign-up button handlers behind `_formKey.currentState!.validate()`, and ensuring that field-level error messages render inline below each field. The widget tree structure established in PR13 is not changed — only `validator` callbacks are added to each `CustomTextField`, and the `_handleSignIn` and `_handleSignUp` methods are updated to validate before calling `AuthProvider`. After this PR, the full authentication flow — registration, login, session persistence, and role-based routing — is complete and testable end-to-end on the emulator.

---

## Section 4 – Architecture Context

```
LoginScreen (_LoginScreenState)
  Form (key: _formKey)
    └── CustomTextField(email)     ← validator added this PR
    └── CustomTextField(password)  ← validator added this PR
    └── CustomButton("Log In")
          └── _handleSignIn()
                └── PR13: authProvider.signIn(...)
                └── PR14: _formKey.currentState!.validate() guard added

RegistrationScreen (_RegistrationScreenState)
  Form (key: _formKey)
    └── CustomTextField(displayName)        ← validator added this PR
    └── CustomTextField(email)              ← validator added this PR
    └── CustomTextField(password)           ← validator added this PR
    └── CustomTextField(confirmPassword)    ← validator added this PR
    └── CustomTextField(bio, conditional)   ← validator added this PR
    └── CustomButton("Create Account")
          └── _handleSignUp()
                └── PR13: authProvider.signUp(...)
                └── PR14: _formKey.currentState!.validate() guard added

Validator execution order (Flutter Form behaviour):
  1. User taps button
  2. _formKey.currentState!.validate() called
  3. Flutter calls validator on every TextFormField in the Form
  4. Any non-null return value is shown as error text below the field
  5. validate() returns false if any validator returned non-null
  6. If false → do not call AuthProvider method
  7. If true  → call AuthProvider method
```

This PR sits after the auth screen shells (PR13) and before session persistence (PR15). No new files are created. No widget tree restructuring — only `validator` parameters are added to existing `CustomTextField` calls and the two handler methods are updated.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None.

**Allowed file modification:**
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/registration_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify any widget files.
- Do NOT modify any other screen files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/auth/login_screen.dart`

Modify the existing PR13 implementation. The widget tree structure does not change. The following targeted changes are made:

---

**Change 1 — Update `_handleSignIn()`:**

Replace the PR13 `_handleSignIn` body with:

```dart
Future<void> _handleSignIn() async {
  context.read<AuthProvider>().clearError();
  if (!_formKey.currentState!.validate()) return;
  await context.read<AuthProvider>().signIn(
    _emailController.text,
    _passwordController.text,
  );
}
```

The `clearError()` call before `validate()` ensures any previous `AuthProvider` error is dismissed before a new submission attempt. The `validate()` guard returns early if any field is invalid — `AuthProvider.signIn()` is only called when all fields pass.

---

**Change 2 — Add `validator` to email `CustomTextField`:**

Add the `validator` parameter to the email `CustomTextField`:

```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required.';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address.';
  }
  return null;
},
```

---

**Change 3 — Add `validator` to password `CustomTextField`:**

Add the `validator` parameter to the password `CustomTextField`:

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
},
```

---

### `lib/screens/auth/registration_screen.dart`

Modify the existing PR13 implementation. The widget tree structure does not change. The following targeted changes are made:

---

**Change 1 — Update `_handleSignUp()`:**

Replace the PR13 `_handleSignUp` body with:

```dart
Future<void> _handleSignUp() async {
  context.read<AuthProvider>().clearError();
  if (!_formKey.currentState!.validate()) return;
  await context.read<AuthProvider>().signUp(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    role: _selectedRole,
    bio: _bioController.text,
  );
}
```

---

**Change 2 — Add `validator` to display name `CustomTextField`:**

```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Display name is required.';
  }
  if (value.trim().length < 2) {
    return 'Name must be at least 2 characters.';
  }
  return null;
},
```

---

**Change 3 — Add `validator` to email `CustomTextField`:**

```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required.';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Please enter a valid email address.';
  }
  return null;
},
```

---

**Change 4 — Add `validator` to password `CustomTextField`:**

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
},
```

---

**Change 5 — Add `validator` to confirm password `CustomTextField`:**

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password.';
  }
  if (value != _passwordController.text) {
    return 'Passwords do not match.';
  }
  return null;
},
```

---

**Change 6 — Add `validator` to bio `CustomTextField`:**

The bio field is only validated when the artisan role is selected. The validator must check `_selectedRole`:

```dart
validator: (value) {
  if (_selectedRole == AppConstants.roleArtisan) {
    if (value == null || value.trim().isEmpty) {
      return 'Please tell buyers about yourself and your craft.';
    }
    if (value.trim().length < 10) {
      return 'Bio must be at least 10 characters.';
    }
  }
  return null;
},
```

---

**Validator behaviour summary:**

| Screen | Field | Empty check | Format/length check | Cross-field check |
|--------|-------|-------------|--------------------|--------------------|
| Login | Email | Required | Valid email regex | — |
| Login | Password | Required | Min 6 chars | — |
| Register | Display Name | Required | Min 2 chars | — |
| Register | Email | Required | Valid email regex | — |
| Register | Password | Required | Min 6 chars | — |
| Register | Confirm Password | Required | — | Matches password field |
| Register | Bio | Required if artisan | Min 10 chars if artisan | Conditional on role |

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/auth/login_screen.dart` | Updated `_handleSignIn` with `validate()` guard, validators added to email and password fields |
| 2 | `lib/screens/auth/registration_screen.dart` | Updated `_handleSignUp` with `validate()` guard, validators added to all five fields including conditional bio validator |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR13 is merged to main**

Open your GitHub repository and confirm the `pr13-auth-shells` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR14 branch**
```
git checkout -b pr14-auth-validation
```

**Step 4 — Confirm both screens are the PR13 shell implementations**
```
grep '_handleSignIn\|_handleSignUp' lib/screens/auth/login_screen.dart lib/screens/auth/registration_screen.dart
```
Both methods must be present. Confirm neither contains `_formKey.currentState!.validate()` — if `validate()` is already present, the PR13 implementation was accidentally completed early and this PR has nothing to add.

**Step 5 — Confirm `Form` and `GlobalKey<FormState>` are present in both files**
```
grep 'GlobalKey<FormState>' lib/screens/auth/login_screen.dart
grep 'GlobalKey<FormState>' lib/screens/auth/registration_screen.dart
```
Both must return one line. If either is missing, the PR13 widget tree is incomplete — do not proceed.

---

Manual setup for this PR is now complete.
Open `docs/PR14_Auth_Screens_Wired.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent makes targeted modifications to two existing files. The widget tree is not restructured. Only the `_handleSignIn`, `_handleSignUp` methods and `validator` parameters are changed.

---

**File 1: `lib/screens/auth/login_screen.dart`**

Make the following three targeted changes to the existing file:

**Change 1 — Replace `_handleSignIn` body:**

Find the existing `_handleSignIn` method. Replace its entire body with:
```dart
context.read<AuthProvider>().clearError();
if (!_formKey.currentState!.validate()) return;
await context.read<AuthProvider>().signIn(
  _emailController.text,
  _passwordController.text,
);
```

**Change 2 — Add `validator` to email `CustomTextField`:**

Find the email `CustomTextField` call. Add the `validator` parameter with the email validation logic specified in Section 6.

**Change 3 — Add `validator` to password `CustomTextField`:**

Find the password `CustomTextField` call. Add the `validator` parameter with the password validation logic specified in Section 6.

The agent must not change any other part of `login_screen.dart`. The widget tree, all other parameters, `dispose()`, imports, and class declarations are unchanged.

---

**File 2: `lib/screens/auth/registration_screen.dart`**

Make the following six targeted changes to the existing file:

**Change 1 — Replace `_handleSignUp` body:**

Find the existing `_handleSignUp` method. Replace its entire body with the validated version specified in Section 6.

**Change 2 through 6 — Add validators to all five `CustomTextField` calls:**

For each of the five `CustomTextField` widgets (display name, email, password, confirm password, bio), add the `validator` parameter with the exact validation logic specified in Section 6.

The bio validator must reference `_selectedRole` and `AppConstants.roleArtisan` — it must only apply validation when the artisan role is selected.

The agent must not change any other part of `registration_screen.dart`. All other parameters, the `_buildRoleCard` method, `dispose()`, imports, and class declarations are unchanged.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `RegExp` used without import (it is in `dart:core`, no import needed), `_passwordController` referenced inside the confirm password validator closure (valid — closures capture the enclosing scope), `_selectedRole` referenced inside the bio validator closure (valid for same reason).

2. **Verify `validate()` is present in both handler methods**
   ```
   grep '_formKey.currentState!.validate()' lib/screens/auth/login_screen.dart
   grep '_formKey.currentState!.validate()' lib/screens/auth/registration_screen.dart
   ```
   Each must return exactly one line.

3. **Verify `clearError()` is called in both handlers**
   ```
   grep 'clearError()' lib/screens/auth/login_screen.dart
   grep 'clearError()' lib/screens/auth/registration_screen.dart
   ```
   Each must return exactly one line in the respective handler method.

4. **Verify validator count in `login_screen.dart`**
   ```
   grep -c 'validator:' lib/screens/auth/login_screen.dart
   ```
   Must return `2` — one for email, one for password.

5. **Verify validator count in `registration_screen.dart`**
   ```
   grep -c 'validator:' lib/screens/auth/registration_screen.dart
   ```
   Must return `5` — one each for display name, email, password, confirm password, and bio.

6. **Verify confirm password cross-field check**
   ```
   grep '_passwordController.text' lib/screens/auth/registration_screen.dart
   ```
   Must return at least two lines — one for the `_handleSignUp` call and one inside the confirm password validator closure.

7. **Verify bio validator is conditional on role**
   ```
   grep 'roleArtisan' lib/screens/auth/registration_screen.dart
   ```
   Must return at least three lines — the `_buildRoleCard` call, the conditional children `if`, and the bio validator condition.

8. **Hot reload on emulator — full auth flow test**
   ```
   flutter run
   ```
   Perform the following manual verification steps:

   **Login validation test:**
   - Navigate to `LoginScreen`.
   - Tap "Log In" with empty fields → email and password error messages appear below each field.
   - Enter an invalid email format (e.g. `notanemail`) → email error shows "Please enter a valid email address."
   - Enter a 3-character password → password error shows "Password must be at least 6 characters."
   - Enter valid email and 6+ character password → no field errors → `AuthProvider.signIn()` is called.

   **Registration validation test:**
   - Navigate to `RegistrationScreen`.
   - Tap "Create Account" with empty fields → all field errors appear simultaneously.
   - Enter mismatched passwords → confirm password shows "Passwords do not match."
   - Select Artisan role, leave bio empty, tap "Create Account" → bio shows "Please tell buyers about yourself and your craft."
   - Select Buyer role → bio field disappears → "Create Account" succeeds validation (bio not required for buyers).
   - Fill all fields correctly as Buyer → no validation errors → `AuthProvider.signUp()` is called.

   Confirm no debug console errors during any of the above.
   Press `q` to quit.

9. **End-to-end registration and login test (if Firebase project is live)**

   If the Firebase project has a live Firestore database (set up in PR04):
   - Register a new buyer account with a valid email and password.
   - Confirm the app navigates to `BuyerHomeScreen` stub after registration.
   - Sign out is not yet wired on the stub screen — restart the app.
   - Log in with the same credentials.
   - Confirm the app navigates to `BuyerHomeScreen` stub again.

   This test confirms the full Auth + Firestore write + role routing chain works end-to-end.

10. **Verify only the correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/auth/login_screen.dart` and `lib/screens/auth/registration_screen.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 14
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
git commit -m "PR14: Stateless vs Stateful Widgets — Auth Screens Fully Wired + Form Validation"
git push origin pr14-auth-validation
```

---

## Section 9 – Acceptance Criteria

- [ ] `_handleSignIn()` calls `clearError()` then `_formKey.currentState!.validate()` before calling `AuthProvider.signIn()`.
- [ ] `_handleSignUp()` calls `clearError()` then `_formKey.currentState!.validate()` before calling `AuthProvider.signUp()`.
- [ ] Email validator in both screens checks for non-empty and matches `RegExp(r'^[^@]+@[^@]+\.[^@]+')`.
- [ ] Password validator in both screens checks for non-empty and minimum 6 characters.
- [ ] Display name validator checks for non-empty and minimum 2 characters.
- [ ] Confirm password validator checks for non-empty and matches `_passwordController.text`.
- [ ] Bio validator is conditional — only applies when `_selectedRole == AppConstants.roleArtisan` — and checks for non-empty and minimum 10 characters.
- [ ] Tapping "Log In" or "Create Account" with empty fields shows inline error text below each invalid field simultaneously.
- [ ] Mismatched passwords on `RegistrationScreen` show the "Passwords do not match." error on the confirm field.
- [ ] Bio validation is skipped when Buyer role is selected.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR14 for CraftBridge. I completed the auth screens by adding validators to all seven form fields across `LoginScreen` and `RegistrationScreen`, gating both handler methods behind `_formKey.currentState!.validate()`, and making the full end-to-end registration and login flow functional."

2. **How Flutter's `Form` validation works:** "Calling `_formKey.currentState!.validate()` triggers Flutter to call the `validator` function on every `TextFormField` inside the `Form` widget. If any validator returns a non-null string, that string is displayed as error text beneath the field, and `validate()` returns `false`. The button handler checks the return value — if `false`, it returns early without calling `AuthProvider`. All field errors appear simultaneously, not one at a time."

3. **`clearError()` before `validate()`:** "Both handlers call `context.read<AuthProvider>().clearError()` before `validate()`. This dismisses any previous `AuthProvider` error — for example, a 'wrong password' message from a previous attempt — before the new validation run. Without this call, the `AuthProvider` error from a previous attempt would remain visible even after the user corrects their input and taps the button again."

4. **Email regex design:** "The email validator uses `RegExp(r'^[^@]+@[^@]+\.[^@]+')` — a deliberately simple pattern that catches the obvious cases: missing `@`, missing domain, missing TLD. It does not try to be RFC 5321 compliant. Over-engineering email validation is a common mistake — the real authority on whether an email is valid is Firebase Auth, which will reject invalid formats with a clear error code that `_mapAuthError` handles."

5. **Confirm password cross-field validation:** "The confirm password validator references `_passwordController.text` inside its closure. This is a closure capturing the outer `_RegistrationScreenState` scope — valid Dart. `_passwordController.text` is read at the moment `validate()` is called, so it always reflects the current password field value. This is the standard Flutter pattern for cross-field validation."

6. **Conditional bio validator:** "The bio validator checks `_selectedRole` before applying any rules. When `_selectedRole` is `'buyer'`, the validator returns `null` immediately — no error, field not required. When `_selectedRole` is `'artisan'`, it enforces non-empty and 10-character minimum. This is important because the bio `CustomTextField` itself is only conditionally rendered — if the field is not in the tree when `validate()` runs, its validator is not called. The condition in the validator and the condition for rendering the field must stay in sync."

7. **PR13 structure preserved:** "The widget tree from PR13 is not touched. The only changes are `validator` parameters added to six `CustomTextField` calls and the two handler method bodies updated. The `Form`, `Column`, `Consumer`, and navigation structure are identical. This demonstrates the value of building the shells first — PR14's diff is minimal and surgical."

8. **Stateless vs Stateful in context of this PR:** "The assignment title references Stateless vs Stateful. `LoginScreen` and `RegistrationScreen` are `StatefulWidget` because they own local state — controllers, `_obscurePassword`, `_selectedRole`. The validators themselves are stateless closures — they take a value, check it, return a string or null. The `Form` widget manages which fields are in error state internally. This separation — stateful widget owns data, Form manages validation display — is the correct Flutter architecture."

9. **End-to-end flow demonstration:** "On the emulator: tapping 'Log In' with empty fields shows both error messages at once. Entering a bad email shows the regex error. Entering matching, valid credentials calls `AuthProvider.signIn()`, which calls Firebase Auth, fetches the `UserModel` from Firestore, `RoleRouterScreen` rebuilds via `context.watch`, and the app navigates to the correct home stub. The complete authentication pipeline — form validation, Firebase Auth, Firestore read, role routing — works end-to-end."

10. **What's Next:** "PR15 will verify session persistence — ensuring that `AuthProvider._init()` and `authStateChanges()` correctly restore the user session on app restart, and adding the `isAdmin` getter verification and `isInitialized` timing checks via the DevTools timeline."