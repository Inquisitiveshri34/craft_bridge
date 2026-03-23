# PR28 – Firebase Auth — Artisan Registration with Role + isApproved

**Project:** CraftBridge
**PR Number:** 28 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Verify and harden the artisan registration flow — confirm `isApproved: false` on artisan signup, validate `RoleRouterScreen` pending artisan routing, and add artisan-specific post-registration UX.

---

## Section 2 – Assignments Covered

- Assignment 3.28 — Firebase Auth — Artisan Registration with Role + isApproved

---

## Section 3 – Objective

This PR audits and hardens the artisan registration and approval flow end-to-end. `AuthProvider.signUp()` already sets `isApproved: role == AppConstants.roleBuyer` (from PR10), meaning artisans are created with `isApproved: false`. `RoleRouterScreen` already routes pending artisans to `_PendingApprovalScreen` (from PR12). This PR verifies both are working correctly, adds a targeted improvement to `RegistrationScreen` so artisan registrants see a clear post-registration message about the approval process, and produces `docs/PR28_Artisan_Registration.md` documenting the full artisan onboarding flow for the team. The artisan-specific bio field and role selector are already functional from PR13/PR14.

---

## Section 4 – Architecture Context

```
Artisan Registration Flow (end-to-end):

RegistrationScreen
  └── selects "I am an Artisan"
  └── fills displayName, email, password, bio
  └── taps "Create Account"
  └── _handleSignUp() calls AuthProvider.signUp(role: 'artisan', bio: bio)
        │
        └── FirebaseAuth.createUserWithEmailAndPassword()
        └── UserModel(isApproved: false, role: 'artisan', bio: bio)
        └── FirestoreService.createUser(userModel)
        └── _currentUser = userModel
        └── notifyListeners()
              │
              ▼
        RoleRouterScreen (context.watch rebuilds)
              │
              └── role == 'artisan' && !isApproved
                      └── _PendingApprovalScreen
                              ├── hourglass icon
                              ├── "Account Pending Approval"
                              ├── explanation text
                              └── Sign Out button

Admin Approval Flow:
  Firebase Console → Firestore → users/{uid}
    → set isApproved: true manually (MVP)
    → PR48: ManageUsersScreen approve button

Post-approval:
  Next app launch or sign-in → AuthProvider._init()
    → FirestoreService.getUser(uid)
    → _currentUser.isApproved == true
    → RoleRouterScreen routes to ArtisanHomeScreen

Changes this PR:
  lib/screens/auth/registration_screen.dart  ← post-registration artisan message
  docs/PR28_Artisan_Registration.md          ← new documentation
```

This PR sits after `StorageService` completion (PR27) and before auth flows testing (PR29). The core approval mechanics are already built — this PR adds clarity for the artisan user and documents the flow for the team.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/auth/registration_screen.dart`
- `docs/PR28_Artisan_Registration.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify `role_router_screen.dart`.
- Do NOT modify any widget files.
- Do NOT modify any provider files other than reading their interface.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/auth/registration_screen.dart`

One targeted addition only. The PR14 implementation is preserved in its entirety — no existing widget, validator, controller, or method is changed. The following is added:

---

**Add `_showArtisanApprovalDialog()` method to `_RegistrationScreenState`:**

```dart
Future<void> _showArtisanApprovalDialog() async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.hourglass_empty_rounded,
        size: 48,
        color: Colors.orange,
      ),
      title: const Text('Registration Submitted'),
      content: const Text(
        'Your artisan account has been created and is pending admin approval. '
        'You will be able to access your shop once an admin reviews and '
        'approves your registration.\n\n'
        'You can sign in at any time to check your approval status.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
```

---

**Update `_handleSignUp()` to show the dialog after successful artisan registration:**

Replace the PR14 `_handleSignUp()` body with:

```dart
Future<void> _handleSignUp() async {
  context.read<AuthProvider>().clearError();
  if (!_formKey.currentState!.validate()) return;
  final bool success = await context.read<AuthProvider>().signUp(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    role: _selectedRole,
    bio: _bioController.text,
  );
  if (success && _selectedRole == AppConstants.roleArtisan) {
    if (!mounted) return;
    await _showArtisanApprovalDialog();
  }
}
```

**Key changes from PR14:**

1. `AuthProvider.signUp()` returns `bool` — the PR14 version did not capture the return value. This PR captures it in `final bool success`.
2. After a successful artisan registration (`success == true && _selectedRole == AppConstants.roleArtisan`), the approval dialog is shown before `RoleRouterScreen` routes to `_PendingApprovalScreen`.
3. `mounted` check before showing the dialog — required after the `await signUp()` call.
4. Buyer registrations (`_selectedRole == AppConstants.roleBuyer`) proceed exactly as in PR14 — no dialog, `RoleRouterScreen` routes directly to `BuyerHomeScreen`.

**Why no `Navigator.pop` after registration:**
`RoleRouterScreen` is reactive — it rebuilds via `context.watch<AuthProvider>()` when `AuthProvider._currentUser` is set by `signUp()`. After `signUp()` completes, the route stack already routes to the correct destination. `Navigator.pop` is not needed and would cause issues.

---

### `docs/PR28_Artisan_Registration.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: the artisan onboarding flow in CraftBridge is a two-step process — self-registration and admin approval. Artisans create an account with the 'artisan' role via `RegistrationScreen`, which creates a Firestore user document with `isApproved: false`. They are then held at `_PendingApprovalScreen` until an admin manually sets `isApproved: true` in Firestore (MVP) or uses `ManageUsersScreen` (PR48). Only after approval does `RoleRouterScreen` route the artisan to `ArtisanHomeScreen`.

---

#### 2. Registration Data Written to Firestore

A table with columns: **Field**, **Value on Artisan Signup**, **Set By**.

| Field | Value on Artisan Signup | Set By |
|-------|------------------------|--------|
| `uid` | Firebase Auth UID | `FirebaseAuth.createUserWithEmailAndPassword()` |
| `email` | User-entered email | `RegistrationScreen` form |
| `displayName` | User-entered name | `RegistrationScreen` form |
| `role` | `'artisan'` | `RegistrationScreen._selectedRole` |
| `photoUrl` | `''` (empty) | `AuthProvider.signUp()` hardcodes empty string |
| `bio` | User-entered bio | `RegistrationScreen._bioController` |
| `isApproved` | `false` | `AuthProvider.signUp()` — `role == AppConstants.roleBuyer` evaluates to `false` |
| `createdAt` | Server timestamp | `Timestamp.now()` in `AuthProvider.signUp()` |

---

#### 3. `isApproved` Logic in `AuthProvider.signUp()`

A prose section covering:

- The expression `isApproved: role == AppConstants.roleBuyer` in `AuthProvider.signUp()` is a boolean expression that evaluates at runtime.
- When `role` is `'buyer'`, the expression evaluates to `true` — buyers are approved immediately.
- When `role` is `'artisan'`, the expression evaluates to `false` — artisans require admin approval.
- When `role` is `'admin'` (not reachable via the registration UI — admin accounts are created manually in Firestore), the expression also evaluates to `false`. Admins do not need `isApproved` — `RoleRouterScreen` routes on `role == 'admin'` directly without checking `isApproved`.
- The single expression handles all three roles correctly without a switch statement or multiple branches.

---

#### 4. `RoleRouterScreen` Routing Logic for Artisans

A prose section covering the four artisan-related routing cases in `RoleRouterScreen.build()`:

- **Not initialized:** `isInitialized == false` → loading spinner. Covers the brief moment between app launch and auth state resolution.
- **No user:** `currentUser == null` → `LoginScreen`. Covers logged-out artisans.
- **Artisan, approved:** `role == 'artisan' && isApproved == true` → `ArtisanHomeScreen`. Covers approved artisans.
- **Artisan, pending:** `role == 'artisan' && isApproved == false` → `_PendingApprovalScreen`. Covers newly registered and awaiting-approval artisans.

Note: `RoleRouterScreen` is reactive — it uses `context.watch<AuthProvider>()`. When an admin approves an artisan (setting `isApproved: true` in Firestore), `AuthProvider._init()` fires `notifyListeners()` via the `authStateChanges()` listener, `RoleRouterScreen` rebuilds, and the artisan is instantly routed to `ArtisanHomeScreen` without requiring a sign-out/sign-in cycle. Wait — this is partially correct: `authStateChanges()` only fires on auth token changes, not on Firestore document changes. Clarify: in the MVP, the artisan must sign out and sign back in after approval for `RoleRouterScreen` to pick up the updated `isApproved` value. Real-time approval notification requires a Firestore document listener on the user document — a post-MVP enhancement.

---

#### 5. `_PendingApprovalScreen` Specification

A prose section covering:

- `_PendingApprovalScreen` is defined as a private class in `role_router_screen.dart`.
- It renders a centered `Column` with: hourglass icon (72dp, primary color), "Account Pending Approval" in `headlineSmall` bold, an explanation paragraph, and a sign-out `ElevatedButton.icon`.
- The sign-out button calls `context.read<AuthProvider>().signOut()` — on sign-out, `AuthProvider._currentUser` is cleared, `RoleRouterScreen` rebuilds, and `LoginScreen` is shown.
- There is no "back" navigation from `_PendingApprovalScreen` — `RoleRouterScreen` returns it directly, not via `Navigator.push`, so the back button exits the app rather than navigating to another screen.

---

#### 6. MVP Admin Approval Process

A numbered list covering the manual admin approval steps for the MVP:

1. Open Firebase Console at console.firebase.google.com.
2. Navigate to Firestore Database → the `users` collection.
3. Find the artisan's document by their UID (visible in Authentication → Users).
4. Click the `isApproved` field — it will show `false`.
5. Edit the value to `true` and click Update.
6. The artisan must sign out and sign back in for the change to take effect (MVP limitation — real-time Firestore listener on user document is a post-MVP enhancement).
7. After sign-in, `AuthProvider._init()` fetches the updated `UserModel` with `isApproved: true`, `RoleRouterScreen` routes to `ArtisanHomeScreen`.

Note: PR48 implements `ManageUsersScreen` with an Approve button that calls `FirestoreService.updateUserApproval(uid, true)` — eliminating the manual Firebase Console step.

---

#### 7. Post-Registration Artisan UX

A prose section covering the dialog added in this PR:

- After a successful artisan registration, `_showArtisanApprovalDialog()` is called before `RoleRouterScreen` routes to `_PendingApprovalScreen`.
- The dialog shows an orange hourglass icon, "Registration Submitted" title, and an explanation that the account is pending admin approval.
- The dialog is `barrierDismissible: false` — the artisan must explicitly tap "Got it" to dismiss it. This prevents accidental dismissal before reading the message.
- After dismissal, `RoleRouterScreen` has already routed to `_PendingApprovalScreen` (because `signUp()` completed before the dialog was shown) — the artisan lands on the pending screen after tapping "Got it".
- Buyer registrations do not show this dialog — buyers go directly to `BuyerHomeScreen` after registration.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/auth/registration_screen.dart` | `_showArtisanApprovalDialog()` added, `_handleSignUp()` updated to capture return value and show dialog for artisan role |
| 2 | `docs/PR28_Artisan_Registration.md` | Complete artisan registration flow documentation with all 7 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify one Dart file and write one Markdown document.

---

**File 1: `lib/screens/auth/registration_screen.dart`**

Make two targeted changes to the existing PR14 implementation:

**Change 1 — Add `_showArtisanApprovalDialog()` method:**

Add the method to `_RegistrationScreenState` after `_handleSignUp()`:

```dart
Future<void> _showArtisanApprovalDialog() async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: const Icon(
        Icons.hourglass_empty_rounded,
        size: 48,
        color: Colors.orange,
      ),
      title: const Text('Registration Submitted'),
      content: const Text(
        'Your artisan account has been created and is pending admin approval. '
        'You will be able to access your shop once an admin reviews and '
        'approves your registration.\n\n'
        'You can sign in at any time to check your approval status.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
```

**Change 2 — Update `_handleSignUp()`:**

Replace the PR14 `_handleSignUp()` body with:

```dart
Future<void> _handleSignUp() async {
  context.read<AuthProvider>().clearError();
  if (!_formKey.currentState!.validate()) return;
  final bool success = await context.read<AuthProvider>().signUp(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    role: _selectedRole,
    bio: _bioController.text,
  );
  if (success && _selectedRole == AppConstants.roleArtisan) {
    if (!mounted) return;
    await _showArtisanApprovalDialog();
  }
}
```

**Critical implementation rules:**
- The `_showArtisanApprovalDialog` is shown only when `success == true && _selectedRole == AppConstants.roleArtisan`. If `signUp()` returns `false` (error), no dialog is shown — the error is displayed via the `Consumer<AuthProvider>` error text in the build method.
- `mounted` check is required before `await _showArtisanApprovalDialog()` because `signUp()` is `async` — the widget may have been disposed.
- All PR14 validators, controllers, role cards, `dispose()`, and `build()` are completely unchanged.
- No `Navigator.pop` or navigation calls are added — `RoleRouterScreen` handles routing reactively.

---

**File 2: `docs/PR28_Artisan_Registration.md`**

Write a complete Markdown document with all 7 sections specified in Section 6 of this PR document, in order. The agent must write each section as follows:

- **Section 1 — Overview:** 3–4 sentences as specified.
- **Section 2 — Registration Data Written to Firestore:** Complete 8-row table with all columns as specified.
- **Section 3 — `isApproved` Logic:** Full prose covering all five points — boolean expression evaluation for all three roles, no switch statement needed.
- **Section 4 — `RoleRouterScreen` Routing Logic:** Full prose covering all four artisan-related routing cases, including the clarification about sign-out/sign-in requirement for approval detection in the MVP.
- **Section 5 — `_PendingApprovalScreen` Specification:** Full prose covering all four points — class location, visual layout, sign-out behaviour, back navigation.
- **Section 6 — MVP Admin Approval Process:** Complete 7-step numbered list.
- **Section 7 — Post-Registration Artisan UX:** Full prose covering all five points — dialog trigger condition, visual content, `barrierDismissible: false`, post-dismissal destination, buyer exclusion.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `showDialog<void>` return type — `await showDialog` returns `T?`, using `void` as the type parameter means the return is `void?` which is fine; `AlertDialog.icon` parameter — available in Flutter 3.10+; `barrierDismissible: false` is a named parameter of `showDialog`, not `AlertDialog`.

2. **Verify `_showArtisanApprovalDialog` method exists**
   ```
   grep '_showArtisanApprovalDialog' lib/screens/auth/registration_screen.dart
   ```
   Must return at least two lines — the method definition and the call in `_handleSignUp`.

3. **Verify `success` return value is captured**
   ```
   grep 'final bool success' lib/screens/auth/registration_screen.dart
   ```
   Must return one line.

4. **Verify artisan role condition guards the dialog**
   ```
   grep 'roleArtisan' lib/screens/auth/registration_screen.dart
   ```
   Must return at least four lines — the `_buildRoleCard` call, the conditional bio `if`, the `_handleSignUp` role check, and the `AppConstants.roleArtisan` reference.

5. **Verify `barrierDismissible: false`**
   ```
   grep 'barrierDismissible' lib/screens/auth/registration_screen.dart
   ```
   Must return one line.

6. **Verify `mounted` check before dialog**
   ```
   grep 'mounted' lib/screens/auth/registration_screen.dart
   ```
   Must return at least one line — the `if (!mounted) return` before `_showArtisanApprovalDialog`.

7. **Verify PR14 validators are unchanged**
   ```
   grep -c 'validator:' lib/screens/auth/registration_screen.dart
   ```
   Must return `5` — same as PR14. No validators were added or removed.

8. **Verify document exists and has 7 sections**
   ```
   cat docs/PR28_Artisan_Registration.md
   ```
   Confirm all 7 sections are present. Confirm Section 2 has 8 rows. Confirm Section 6 has 7 steps.

9. **Hot reload on emulator — artisan registration flow test**
   ```
   flutter run
   ```

   **Artisan registration test:**
   - From `LoginScreen`, tap "Don't have an account? Register".
   - Select "I am an Artisan" role card.
   - Fill all fields including bio (min 10 chars).
   - Tap "Create Account".
   - Confirm:
     - Loading spinner appears on button.
     - After signup completes, the "Registration Submitted" `AlertDialog` appears with orange hourglass icon and explanation text.
     - `barrierDismissible: false` — tapping outside the dialog does nothing.
     - Tapping "Got it" dismisses the dialog.
     - App shows `_PendingApprovalScreen` with hourglass icon and "Account Pending Approval".
   - Open Firebase Console → Firestore → `users` collection → confirm new document with `role: 'artisan'` and `isApproved: false`.

   **Buyer registration test (regression):**
   - Register a new buyer account.
   - Confirm: no dialog appears, app navigates directly to `BuyerHomeScreen` stub.

   **Admin approval test:**
   - In Firebase Console, find the artisan's user document.
   - Set `isApproved: true`.
   - Sign out (use the "Sign Out" button on `_PendingApprovalScreen`).
   - Sign back in with the artisan's credentials.
   - Confirm: app navigates to `ArtisanHomeScreen` (no longer shows `_PendingApprovalScreen`).

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/auth/registration_screen.dart` and `docs/PR28_Artisan_Registration.md` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 28
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
git commit -m "PR28: Firebase Auth — Artisan Registration with Role + isApproved"
git push origin pr28-artisan-registration
```

---

## Section 9 – Acceptance Criteria

- [ ] `_RegistrationScreenState` has a `_showArtisanApprovalDialog()` method that shows a non-dismissible `AlertDialog` with orange hourglass icon, "Registration Submitted" title, and explanation text.
- [ ] `_handleSignUp()` captures `AuthProvider.signUp()` return value as `final bool success`.
- [ ] The artisan approval dialog is shown only when `success == true && _selectedRole == AppConstants.roleArtisan`.
- [ ] A `mounted` check precedes the `_showArtisanApprovalDialog()` call.
- [ ] Buyer registration does not show the dialog — buyer users proceed directly to `BuyerHomeScreen`.
- [ ] All PR14 validators, controllers, role cards, and `build()` structure are unchanged — `grep -c 'validator:'` returns `5`.
- [ ] `docs/PR28_Artisan_Registration.md` exists with all 7 sections including the 8-row registration data table and 7-step admin approval process.
- [ ] After artisan registration, Firebase Console shows the user document with `role: 'artisan'` and `isApproved: false`.
- [ ] After admin sets `isApproved: true` and artisan signs back in, app routes to `ArtisanHomeScreen`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR28 for CraftBridge. I hardened the artisan registration flow — capturing `AuthProvider.signUp()`'s return value to show a post-registration approval dialog for artisan users, and producing the artisan registration flow documentation for the team."

2. **Why capture `signUp()` return value:** "PR14's `_handleSignUp()` called `signUp()` but discarded the `bool` return value. That worked because `RoleRouterScreen` handles navigation reactively — but it meant there was no way to conditionally show the approval dialog only on success. Capturing `final bool success` allows the dialog to appear only when registration succeeds, not when it fails due to a validation or Firebase error."

3. **`barrierDismissible: false` design decision:** "Setting `barrierDismissible: false` means the artisan cannot accidentally dismiss the dialog by tapping outside it. This message is important — it explains why they'll be sent to a 'pending' screen rather than their artisan dashboard. Forcing an explicit 'Got it' tap ensures the message is read."

4. **Dialog timing relative to `RoleRouterScreen` routing:** "The dialog appears after `signUp()` completes — at which point `AuthProvider._currentUser` is already set with `isApproved: false`. `RoleRouterScreen` has already queued a rebuild to show `_PendingApprovalScreen`. The dialog appears on top of `RegistrationScreen` while `RoleRouterScreen` has already routed beneath. When the artisan dismisses the dialog, `Navigator.pop(ctx)` removes the dialog, and `_PendingApprovalScreen` is revealed."

5. **`mounted` check after async gap:** "The `mounted` check before `_showArtisanApprovalDialog()` is required because `signUp()` is `async` — the widget might theoretically be disposed during the Firebase Auth and Firestore operations. If the widget is disposed, calling `showDialog` on a disposed `BuildContext` throws. The `mounted` check prevents this."

6. **Buyer registration regression:** "The `if (success && _selectedRole == AppConstants.roleArtisan)` condition explicitly excludes buyers — they never see the approval dialog. A successful buyer registration allows `RoleRouterScreen` to route to `BuyerHomeScreen` with no interruption. The single condition handles both roles correctly."

7. **`isApproved` boolean expression review:** "The PR10 expression `isApproved: role == AppConstants.roleBuyer` evaluates to `true` for buyers and `false` for artisans. Section 3 of the PR28 document covers the edge case of admin accounts — admins also get `isApproved: false`, but `RoleRouterScreen` routes on `role == 'admin'` before checking `isApproved`, so the value is irrelevant for admins."

8. **Sign-out/sign-in requirement for approval detection:** "In the MVP, when an admin approves an artisan in Firestore, the artisan's device doesn't know immediately. `AuthProvider._init()` uses `authStateChanges()` — which only fires on auth token changes, not Firestore document changes. The artisan must sign out and sign back in for `AuthProvider` to re-fetch the `UserModel` with `isApproved: true`. PR48's `ManageUsersScreen` will handle the admin side; real-time approval detection is a post-MVP enhancement requiring a Firestore document listener on the user doc."

9. **PR48 `ManageUsersScreen` preview:** "Section 6 of the documentation describes the current manual Firebase Console approval process. When PR48 implements `ManageUsersScreen`, admins will see a list of pending artisan registrations and tap an 'Approve' button that calls `FirestoreService.updateUserApproval(uid, true)` — eliminating the manual Firebase Console workflow entirely."

10. **What's Next:** "PR29 will complete auth flow testing — adding comprehensive `FirebaseAuthException` error handling, password visibility toggle polish, and user-friendly error messages for all auth failure scenarios."