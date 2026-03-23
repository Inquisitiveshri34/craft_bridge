# PR29 – Auth Flows — Full signIn/signUp/signOut Flows Tested

**Project:** CraftBridge
**PR Number:** 29 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Complete `FirebaseAuthException` error handling, add password visibility toggle polish, and verify all sign-in, sign-up, and sign-out flows end-to-end with user-friendly error messages.

---

## Section 2 – Assignments Covered

- Assignment 3.29 — Auth Flows — Full signIn/signUp/signOut Flows Tested

---

## Section 3 – Objective

This PR completes the authentication error handling layer — adding missing `FirebaseAuthException` error codes to `AuthProvider._mapAuthError()`, improving the password visibility toggle accessibility on both auth screens, and producing `docs/PR29_Auth_Flows.md` which documents every sign-in, sign-up, and sign-out flow with expected outcomes and edge cases. No new screens are created. The changes are surgical additions that make the auth experience production-quality without restructuring any widget tree.

---

## Section 4 – Architecture Context

```
AuthProvider._mapAuthError() — extended this PR:
  Current codes handled (PR10):
    user-not-found, wrong-password, email-already-in-use,
    weak-password, invalid-email, user-disabled,
    too-many-requests, operation-not-allowed, invalid-credential

  New codes added this PR:
    network-request-failed  → 'No internet connection. Please try again.'
    requires-recent-login   → 'Please sign out and sign in again to continue.'
    account-exists-with-different-credential
                            → 'An account already exists with a different sign-in method.'
    credential-already-in-use
                            → 'This credential is already associated with another account.'

LoginScreen — password toggle improvements:
  Before: suffixIcon uses raw IconButton
  After:  suffixIcon uses Semantics wrapper with label for accessibility

RegistrationScreen — same improvement applied to both password fields

docs/PR29_Auth_Flows.md ← produced this PR
```

This PR sits after artisan registration (PR28) and before `ArtisanOrdersScreen` (PR30). It closes the error handling gap in `AuthProvider` and documents the complete auth surface for the team.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/auth_provider.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/registration_screen.dart`
- `docs/PR29_Auth_Flows.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any other provider files.
- Do NOT modify `role_router_screen.dart`, `splash_screen.dart`, or `registration_screen.dart` beyond the password toggle semantic improvement.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/providers/auth_provider.dart`

One targeted change only — extend `_mapAuthError()` with four additional error code cases. All other methods, fields, and getters from PR10/PR15 are preserved unchanged.

---

**Updated `_mapAuthError()` method:**

Add the following four cases to the existing `switch` statement inside `_mapAuthError()`, before the `default` case:

```dart
case 'network-request-failed':
  return 'No internet connection. Please try again.';
case 'requires-recent-login':
  return 'Please sign out and sign in again to continue.';
case 'account-exists-with-different-credential':
  return 'An account already exists with a different sign-in method.';
case 'credential-already-in-use':
  return 'This credential is already associated with another account.';
```

The `default` case remains the last case:
```dart
default:
  return 'Authentication failed. Please try again.';
```

**Total error code cases after this PR:** 13 (9 from PR10 + 4 new).

---

### `lib/screens/auth/login_screen.dart`

One targeted change — wrap the password visibility `suffixIcon` `IconButton` in a `Semantics` widget to improve accessibility.

**Change:** Find the password `CustomTextField`'s `suffixIcon` parameter. Replace the raw `IconButton` with a `Semantics`-wrapped version:

```dart
suffixIcon: Semantics(
  label: _obscurePassword
      ? 'Show password'
      : 'Hide password',
  child: IconButton(
    icon: Icon(
      _obscurePassword
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
    ),
    onPressed: () =>
        setState(() => _obscurePassword = !_obscurePassword),
  ),
),
```

**Icon update:** Change from `Icons.visibility_off` / `Icons.visibility` (filled) to `Icons.visibility_off_outlined` / `Icons.visibility_outlined` (outlined) — outlined icons are visually lighter and more consistent with the `outlined` icon style used throughout the app (e.g. `Icons.shopping_bag_outlined`).

No other changes to `login_screen.dart`.

---

### `lib/screens/auth/registration_screen.dart`

Two targeted changes — apply the same `Semantics`-wrapped `IconButton` and outlined icon update to both password fields.

**Change 1 — Password field suffixIcon:**

```dart
suffixIcon: Semantics(
  label: _obscurePassword
      ? 'Show password'
      : 'Hide password',
  child: IconButton(
    icon: Icon(
      _obscurePassword
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
    ),
    onPressed: () =>
        setState(() => _obscurePassword = !_obscurePassword),
  ),
),
```

**Change 2 — Confirm password field suffixIcon:**

```dart
suffixIcon: Semantics(
  label: _obscureConfirmPassword
      ? 'Show confirm password'
      : 'Hide confirm password',
  child: IconButton(
    icon: Icon(
      _obscureConfirmPassword
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
    ),
    onPressed: () => setState(
        () => _obscureConfirmPassword = !_obscureConfirmPassword),
  ),
),
```

No other changes to `registration_screen.dart`.

---

### `docs/PR29_Auth_Flows.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: the auth layer in CraftBridge uses Firebase Auth for credential management and Firestore for user profile persistence. Every auth operation — sign-in, sign-up, sign-out — goes through `AuthProvider` which maps Firebase error codes to user-friendly messages. This document covers every flow, expected outcome, error state, and edge case in the auth surface as it exists after PR29.

---

#### 2. Sign-In Flow

A table with columns: **Step**, **Action**, **Expected Outcome**, **Error Scenario**.

| Step | Action | Expected Outcome | Error Scenario |
|------|--------|-----------------|----------------|
| 1 | User enters email + password and taps "Log In" | `_handleSignIn()` calls `clearError()` then `validate()` | Validation fails → field error text shown, `signIn()` not called |
| 2 | `_formKey.currentState!.validate()` passes | `AuthProvider.signIn()` called with trimmed email and password | — |
| 3 | `FirebaseAuth.signInWithEmailAndPassword()` succeeds | `FirestoreService.getUser(uid)` called to fetch `UserModel` | Firebase error → `_mapAuthError()` converts code → `errorMessage` set → error text shown below button |
| 4 | `FirestoreService.getUser(uid)` returns `UserModel` | `_currentUser` set, `notifyListeners()`, `RoleRouterScreen` rebuilds | Firestore error → `_currentUser = null`, `_isInitialized = true`, app routes to `LoginScreen` |
| 5 | `RoleRouterScreen` evaluates role | Routes to correct home screen | Unexpected role → defaults to `BuyerHomeScreen` |

Followed by a prose note: the `invalid-credential` error code is returned by Firebase Auth SDK v5+ for both wrong email and wrong password — it replaces the older `user-not-found` and `wrong-password` codes. Both codes are handled in `_mapAuthError()` for backward compatibility.

---

#### 3. Sign-Up Flow

A table with columns: **Step**, **Action**, **Expected Outcome**, **Error Scenario**.

| Step | Action | Expected Outcome | Error Scenario |
|------|--------|-----------------|----------------|
| 1 | User selects role, fills all fields, taps "Create Account" | `_handleSignUp()` calls `clearError()` then `validate()` | Validation fails → all invalid fields show errors simultaneously |
| 2 | Validation passes | `AuthProvider.signUp()` called | — |
| 3 | `FirebaseAuth.createUserWithEmailAndPassword()` succeeds | `UserModel` constructed with `isApproved: role == roleBuyer` | `email-already-in-use` → friendly message shown |
| 4 | `FirestoreService.createUser(userModel)` called | User document written to Firestore `users/{uid}` | Firestore write fails → Auth user created but no Firestore doc — orphaned Auth account |
| 5 | `signUp()` returns `true` | For artisan: approval dialog shown. For buyer: `RoleRouterScreen` routes to `BuyerHomeScreen` | `signUp()` returns `false` → error shown, no dialog |

Followed by a prose note on the orphaned account edge case: if `FirebaseAuth.createUserWithEmailAndPassword()` succeeds but `FirestoreService.createUser()` fails, a Firebase Auth account exists with no Firestore user document. On next sign-in, `getUser(uid)` returns null, `_currentUser` is null, and `RoleRouterScreen` shows `LoginScreen`. The user is effectively locked out. Mitigation: the `catch` block in `signUp()` catches this failure and returns `false`, but the orphaned Auth account remains. Post-MVP enhancement: delete the Auth account if Firestore write fails.

---

#### 4. Sign-Out Flow

A table with columns: **Trigger**, **Action**, **Expected Outcome**.

| Trigger | Action | Expected Outcome |
|---------|--------|-----------------|
| Artisan taps Sign Out in `ArtisanHomeScreen` AppBar | `context.read<AuthProvider>().signOut()` | `FirebaseAuth.signOut()`, `_currentUser = null`, `notifyListeners()`, `RoleRouterScreen` → `LoginScreen` |
| Admin taps Sign Out in `AdminHomeScreen` AppBar | Same | Same — `LoginScreen` shown |
| Buyer taps Sign Out in `BuyerHomeScreen` AppBar | Same | Same — `LoginScreen` shown |
| Pending artisan taps Sign Out on `_PendingApprovalScreen` | Same | Same — `LoginScreen` shown |
| App is force-killed and relaunched | `Firebase.initializeApp()`, `AuthProvider._init()`, `authStateChanges()` emits persisted user | Session restored — appropriate home screen shown |
| `FirebaseAuth.signOut()` throws | Exception propagates — `_currentUser` not cleared | Rare — network not required for sign-out; local token is cleared synchronously |

---

#### 5. Error Code Reference

A table with columns: **Firebase Error Code**, **User-Facing Message**, **When Triggered**.

| Firebase Error Code | User-Facing Message | When Triggered |
|---------------------|--------------------|-|
| `user-not-found` | No account found with this email address. | Sign-in with unregistered email (older SDK) |
| `wrong-password` | Incorrect password. Please try again. | Sign-in with wrong password (older SDK) |
| `invalid-credential` | Invalid email or password. Please try again. | Sign-in failure in SDK v5+ (replaces user-not-found + wrong-password) |
| `email-already-in-use` | An account with this email already exists. | Sign-up with existing email |
| `weak-password` | Password must be at least 6 characters. | Sign-up with password < 6 chars |
| `invalid-email` | Please enter a valid email address. | Sign-in or sign-up with malformed email |
| `user-disabled` | This account has been disabled. | Sign-in to a disabled account |
| `too-many-requests` | Too many attempts. Please try again later. | Rate limiting by Firebase |
| `operation-not-allowed` | Email/password sign-in is not enabled. | Auth method disabled in Firebase Console |
| `requires-recent-login` | Please sign out and sign in again to continue. | Sensitive operation on stale session |
| `network-request-failed` | No internet connection. Please try again. | No network connectivity |
| `account-exists-with-different-credential` | An account already exists with a different sign-in method. | Linking conflict |
| `credential-already-in-use` | This credential is already associated with another account. | Credential linking conflict |
| `default` | Authentication failed. Please try again. | Any unmapped error code |

---

#### 6. Password Visibility Toggle Accessibility

A prose section covering:

- Both auth screens use a `Semantics` wrapper around the password visibility `IconButton` with a dynamic `label` — `'Show password'` when obscured, `'Hide password'` when visible.
- The `Semantics` label is read by screen readers (TalkBack on Android, VoiceOver on iOS) to announce the current state and available action.
- Icon style change: from filled `Icons.visibility` / `Icons.visibility_off` to outlined `Icons.visibility_outlined` / `Icons.visibility_off_outlined` — consistent with the outlined icon style used throughout the app.
- The `RegistrationScreen` has two password fields — both receive separate `Semantics` labels: `'Show/Hide password'` and `'Show/Hide confirm password'`.

---

#### 7. Auth Flow Edge Cases

A prose section covering:

- **Cold start with persisted session:** App opens, `AuthProvider._init()` fires, `authStateChanges()` immediately emits the cached user. `SplashScreen` shows for ~200ms, then `RoleRouterScreen` routes to the correct home screen. No login required.
- **Token expiry:** Firebase Auth tokens auto-refresh. In the rare case of a refresh failure, `authStateChanges()` emits null, `RoleRouterScreen` shows `LoginScreen`. The user must sign in again.
- **Concurrent sessions:** Firebase Auth supports multiple simultaneous sessions on different devices. Sign-out on one device does not affect other devices.
- **Email case sensitivity:** `email.trim()` is applied in both `signIn()` and `signUp()`. Firebase Auth normalises emails to lowercase internally — `User@Example.com` and `user@example.com` refer to the same account.
- **Password field auto-fill:** Both auth screens use `TextFormField` via `CustomTextField` — Android and iOS autofill services can suggest saved credentials. No explicit `autofillHints` are set in this PR — a post-MVP improvement.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/auth_provider.dart` | `_mapAuthError()` extended with 4 new error codes — total 13 cases |
| 2 | `lib/screens/auth/login_screen.dart` | Password visibility `suffixIcon` wrapped in `Semantics`, icons updated to outlined variants |
| 3 | `lib/screens/auth/registration_screen.dart` | Both password field `suffixIcon` widgets wrapped in `Semantics` with distinct labels, icons updated |
| 4 | `docs/PR29_Auth_Flows.md` | Complete auth flow documentation with all 7 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify three Dart files and write one Markdown document.

---

**File 1: `lib/providers/auth_provider.dart`**

Make one targeted change: add four new `case` entries to `_mapAuthError()`'s `switch` statement, before the `default` case. The exact strings and messages are specified in Section 6. No other changes to `auth_provider.dart`.

---

**File 2: `lib/screens/auth/login_screen.dart`**

Make one targeted change: locate the password `CustomTextField`'s `suffixIcon` parameter. Replace the existing `IconButton(...)` with the `Semantics`-wrapped version specified in Section 6, updating the icons from filled to outlined variants. No other changes to `login_screen.dart`.

---

**File 3: `lib/screens/auth/registration_screen.dart`**

Make two targeted changes: apply the `Semantics` wrapper and outlined icon update to both the password `CustomTextField` and the confirm password `CustomTextField` suffixIcon parameters, with distinct `Semantics` labels as specified in Section 6. No other changes to `registration_screen.dart`.

---

**File 4: `docs/PR29_Auth_Flows.md`**

Write the complete Markdown document with all 7 sections as specified in Section 6. Tables must be fully populated — no empty cells. Prose sections must cover all points specified.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `Semantics` widget — ensure `label` is a non-null `String`; `Icons.visibility_outlined` — available in Flutter 3.0+; switch `case` syntax — each new case must end with `return '...'` not fall through.

2. **Verify total error code count in `_mapAuthError`**
   ```
   grep -c "case '" lib/providers/auth_provider.dart
   ```
   Must return `13` — 9 from PR10 plus 4 new.

3. **Verify all four new error codes are present**
   ```
   grep 'network-request-failed\|requires-recent-login\|account-exists-with-different-credential\|credential-already-in-use' lib/providers/auth_provider.dart
   ```
   Must return `4` lines.

4. **Verify `Semantics` wrapper in `login_screen.dart`**
   ```
   grep 'Semantics' lib/screens/auth/login_screen.dart
   ```
   Must return at least two lines — the opening `Semantics(` and `label:` parameter.

5. **Verify `Semantics` wrappers in `registration_screen.dart`**
   ```
   grep -c 'Semantics' lib/screens/auth/registration_screen.dart
   ```
   Must return at least `4` — two `Semantics(` openings and two `label:` parameters for the two password fields.

6. **Verify outlined icons are used**
   ```
   grep 'visibility_outlined\|visibility_off_outlined' lib/screens/auth/login_screen.dart
   grep 'visibility_outlined\|visibility_off_outlined' lib/screens/auth/registration_screen.dart
   ```
   Each must return at least `2` lines — one for each state of the toggle.

7. **Verify no filled visibility icons remain**
   ```
   grep 'Icons.visibility,' lib/screens/auth/login_screen.dart
   grep 'Icons.visibility,' lib/screens/auth/registration_screen.dart
   ```
   Must return no output — confirming the old filled icons are replaced.
   Note: `grep 'Icons.visibility,'` with a trailing comma avoids matching `Icons.visibility_outlined`.

8. **Verify document has all 7 sections**
   ```
   cat docs/PR29_Auth_Flows.md
   ```
   Confirm all 7 sections are present. Confirm Section 5 table has 14 rows (13 error codes + header). Confirm Section 2 and Section 3 tables have 5 rows each (plus header).

9. **Hot reload on emulator — error handling test**
   ```
   flutter run
   ```

   **Sign-in error tests:**
   - Enter a non-existent email + any password → tap "Log In" → confirm "Invalid email or password. Please try again." or "No account found with this email address." appears below button.
   - Enter correct email + wrong password → confirm appropriate error message.
   - Disable WiFi/mobile data → tap "Log In" → confirm "No internet connection. Please try again." appears.
   - Re-enable network.

   **Sign-up error tests:**
   - Attempt to register with an already-used email → confirm "An account with this email already exists."
   - Attempt password < 6 chars → form validator catches it before Firebase (confirm validator fires, not `_mapAuthError`).

   **Password visibility toggle test:**
   - On `LoginScreen`: tap the eye icon → password becomes visible, icon changes to outlined eye, semantic label updates.
   - On `RegistrationScreen`: both password fields have independent toggles — toggling one does not affect the other.
   - Enable TalkBack (Android) / VoiceOver (iOS) and confirm "Show password" / "Hide password" is announced when the toggle is focused.

   **Sign-out test:**
   - Sign in as any role → tap Sign Out → confirm `LoginScreen` is shown.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/providers/auth_provider.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/auth/registration_screen.dart`, `docs/PR29_Auth_Flows.md`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 29
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
git commit -m "PR29: Auth Flows — Full signIn/signUp/signOut Flows Tested"
git push origin pr29-auth-flows
```

---

## Section 9 – Acceptance Criteria

- [ ] `AuthProvider._mapAuthError()` handles 13 error codes — including `network-request-failed`, `requires-recent-login`, `account-exists-with-different-credential`, and `credential-already-in-use`.
- [ ] `grep -c "case '" lib/providers/auth_provider.dart` returns `13`.
- [ ] `LoginScreen` password `suffixIcon` is wrapped in `Semantics` with `label` toggling between `'Show password'` and `'Hide password'`.
- [ ] `LoginScreen` uses `Icons.visibility_off_outlined` and `Icons.visibility_outlined` — no filled variants.
- [ ] `RegistrationScreen` password field and confirm password field `suffixIcon` are both wrapped in `Semantics` with distinct labels.
- [ ] `RegistrationScreen` uses outlined visibility icons for both password fields.
- [ ] `docs/PR29_Auth_Flows.md` exists with all 7 sections — sign-in table, sign-up table, sign-out table, 14-row error code reference, accessibility notes, edge cases.
- [ ] Network disconnection during sign-in shows "No internet connection. Please try again."
- [ ] All PR14 validators remain unchanged — `grep -c 'validator:' lib/screens/auth/registration_screen.dart` returns `5`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR29 for CraftBridge. I completed the authentication error handling layer — adding four new `FirebaseAuthException` error code mappings, improving password visibility toggle accessibility with `Semantics` wrappers, and producing the comprehensive auth flow documentation."

2. **Why add more error codes:** "PR10 handled 9 error codes — the most common ones. But Firebase Auth can return codes for network failures, stale sessions, and credential conflicts that a production app should handle gracefully. `network-request-failed` is particularly important — on a mobile app, network connectivity is unreliable, and showing 'Authentication failed' when the real issue is 'no WiFi' is confusing to users."

3. **`invalid-credential` backward compatibility:** "Firebase Auth SDK v5+ returns `invalid-credential` for both wrong email and wrong password — it replaced the older `user-not-found` and `wrong-password` codes to prevent user enumeration attacks. CraftBridge handles all three codes: `user-not-found` and `wrong-password` for older SDK behaviour, `invalid-credential` for SDK v5+. This ensures correct error messages regardless of which Firebase Auth SDK version is resolved."

4. **`requires-recent-login` use case:** "Firebase requires a recent login for sensitive operations like changing email or deleting an account. If an artisan's session is old and they attempt such an operation, `requires-recent-login` is returned. The message 'Please sign out and sign in again' is the correct user-facing instruction — it tells them exactly what to do."

5. **`Semantics` wrapper for accessibility:** "Flutter's `Semantics` widget adds semantic information that screen readers use to describe UI elements. Without a `Semantics` label on the eye icon button, TalkBack announces 'Button' — unhelpful. With `label: _obscurePassword ? 'Show password' : 'Hide password'`, TalkBack announces the current state and available action. The label toggles with the icon state — when the password is visible, it reads 'Hide password'."

6. **Outlined vs filled icon style:** "The visibility icons are updated from `Icons.visibility` (filled) to `Icons.visibility_outlined` (outlined). This matches the outlined icon style used throughout the app — `Icons.shopping_bag_outlined`, `Icons.inventory_2_outlined`, `Icons.receipt_long_outlined`. Visual consistency is a design quality signal — mixing filled and outlined icons in the same app looks unpolished."

7. **Distinct `Semantics` labels for two password fields:** "`RegistrationScreen` has two password fields. Both use eye icon toggles. If both had `label: 'Show password'`, a screen reader user would hear 'Show password' twice with no distinction. Separate labels — 'Show password' and 'Show confirm password' — give each field a unique, descriptive accessibility identity."

8. **Orphaned account edge case:** "Section 3 of the PR29 document covers a real edge case: if `FirebaseAuth.createUserWithEmailAndPassword()` succeeds but `FirestoreService.createUser()` fails — due to a network error or Firestore quota — a Firebase Auth account exists with no Firestore document. The user appears to be registered but cannot actually sign in meaningfully. This is documented as a known MVP limitation with a post-MVP mitigation — deleting the Auth account if the Firestore write fails."

9. **Sign-out table completeness:** "Section 4 covers every sign-out trigger in the app: artisan, admin, buyer, and pending artisan — all call the same `AuthProvider.signOut()` method. The table also covers force-kill and relaunch (session restoration) and the rare case of `FirebaseAuth.signOut()` throwing — which essentially never happens because sign-out is a local operation that clears the cached token without a network call."

10. **What's Next:** "PR30 will implement `ArtisanOrdersScreen` with a `StreamBuilder` showing live orders, and create the `OrderProvider` stub — bringing the artisan order tracking flow to life for the first time."