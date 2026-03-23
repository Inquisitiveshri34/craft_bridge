# PR12 – Folder Structure Walkthrough — RoleRouterScreen

**Project:** CraftBridge
**PR Number:** 12 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `RoleRouterScreen` with full role-based and approval-status navigation logic routing every user to their correct home screen.

---

## Section 2 – Assignments Covered

- Assignment 3.12 — Folder Structure Walkthrough — RoleRouterScreen

---

## Section 3 – Objective

This PR implements `RoleRouterScreen` — the central navigation hub of CraftBridge that every app launch and every login event passes through. It reads `AuthProvider` and routes the user to the correct destination based on three factors: whether they are authenticated, what their role is, and whether they are approved (for artisans). After this PR, the full auth-to-home routing logic is in place and every subsequent screen PR simply needs to replace its stub — the routing already points to the correct file paths. Home screen stubs for `ArtisanHomeScreen` and `AdminHomeScreen` are also created in this PR to complete the navigation targets.

---

## Section 4 – Architecture Context

```
SplashScreen
    │
    └── Navigator.pushReplacement → RoleRouterScreen
                                          │
                          reads AuthProvider (context.watch)
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    │                     │                       │
             not initialized          no current user        current user
                    │                     │                       │
            loading spinner         LoginScreen          role switch:
                                                               │
                                              ┌────────────────┼────────────────┐
                                              │                │                │
                                           admin           artisan            buyer
                                              │                │                │
                                     AdminHomeScreen    isApproved?      BuyerHomeScreen
                                                        │       │
                                                       yes      no
                                                        │       │
                                               ArtisanHomeScreen  pending
                                                                   screen
```

This PR sits after `SplashScreen` (PR11) and before the auth screen shells (PR13). All navigation targets except `LoginScreen` are stubs at this point — `ArtisanHomeScreen` and `AdminHomeScreen` are upgraded to minimal stubs in this PR, `BuyerHomeScreen` is upgraded in PR17. `RoleRouterScreen` itself uses `pushReplacement` for all transitions so it never accumulates in the back stack.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/shared/role_router_screen.dart` — full implementation
- `lib/screens/artisan/artisan_home_screen.dart` — minimal stub upgrade
- `lib/screens/admin/admin_home_screen.dart` — minimal stub upgrade
- `lib/screens/auth/login_screen.dart` — minimal stub upgrade to allow navigation target

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify `splash_screen.dart`.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/shared/role_router_screen.dart`

**Widget type:** `StatelessWidget`

**Class name:** `RoleRouterScreen`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/screens/auth/login_screen.dart`
- `package:craft_bridge/screens/artisan/artisan_home_screen.dart`
- `package:craft_bridge/screens/buyer/buyer_home_screen.dart`
- `package:craft_bridge/screens/admin/admin_home_screen.dart`

**Constructor:** `const RoleRouterScreen({super.key})`

**`build` method logic:**

The `build` method uses `context.watch<AuthProvider>()` to observe the auth state. It must evaluate the following conditions in order and return a `Widget` for each case:

**Case 1 — Not yet initialized:**
```dart
if (!authProvider.isInitialized) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

**Case 2 — No authenticated user:**
```dart
if (authProvider.currentUser == null) {
  return const LoginScreen();
}
```

**Case 3 — Admin role:**
```dart
if (authProvider.currentUser!.role == AppConstants.roleAdmin) {
  return const AdminHomeScreen();
}
```

**Case 4 — Artisan role, approved:**
```dart
if (authProvider.currentUser!.role == AppConstants.roleArtisan &&
    authProvider.currentUser!.isApproved) {
  return const ArtisanHomeScreen();
}
```

**Case 5 — Artisan role, not approved:**
```dart
if (authProvider.currentUser!.role == AppConstants.roleArtisan &&
    !authProvider.currentUser!.isApproved) {
  return _PendingApprovalScreen();
}
```

**Case 6 — Buyer role (default):**
```dart
return const BuyerHomeScreen();
```

**Important architectural note:** `RoleRouterScreen` does NOT use `Navigator.push` or `Navigator.pushReplacement` inside `build`. It returns the destination widget directly. Because `RoleRouterScreen` is placed as the `home` of the app via `SplashScreen`'s `pushReplacement`, it sits at the base of the navigation stack. Returning the destination widget directly means the destination is rendered in place — the user sees the correct screen immediately and the back button exits the app, not navigates backwards within it.

This pattern also means that when `AuthProvider` changes (e.g. after sign-out), `context.watch` triggers a rebuild of `RoleRouterScreen`, which then returns `LoginScreen()` — the routing is fully reactive with no explicit navigation calls needed.

---

### `_PendingApprovalScreen` widget

A private widget defined in the same file as `RoleRouterScreen`, below it.

**Widget type:** `StatelessWidget`

**Class name:** `_PendingApprovalScreen` (private — underscore prefix)

**No constructor parameters** beyond `super.key`.

**`build` method returns:** `Scaffold` with:
- `appBar`: `AppBar` with `title: const Text('Pending Approval')`
- `body`: `SafeArea` wrapping a `Padding` with `padding: const EdgeInsets.all(24)` wrapping a `Center` wrapping a `Column` with `mainAxisAlignment: MainAxisAlignment.center` and these children:
  1. `Icon(Icons.hourglass_empty_rounded, size: 72, color: Theme.of(context).colorScheme.primary)`
  2. `const SizedBox(height: 24)`
  3. `Text('Account Pending Approval', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))`
  4. `const SizedBox(height: 12)`
  5. `Text('Your artisan account is under review. You will be able to access your shop once an admin approves your registration.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), textAlign: TextAlign.center)`
  6. `const SizedBox(height: 32)`
  7. `ElevatedButton.icon(onPressed: () => context.read<AuthProvider>().signOut(), icon: const Icon(Icons.logout), label: const Text('Sign Out'))`

---

### `lib/screens/auth/login_screen.dart`

Upgrade the PR01 placeholder to a minimal stub:

```dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('LoginScreen — implemented in PR13'),
      ),
    );
  }
}
```

---

### `lib/screens/artisan/artisan_home_screen.dart`

Upgrade the PR01 placeholder to a minimal stub:

```dart
import 'package:flutter/material.dart';

class ArtisanHomeScreen extends StatelessWidget {
  const ArtisanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ArtisanHomeScreen — implemented in PR16'),
      ),
    );
  }
}
```

---

### `lib/screens/admin/admin_home_screen.dart`

Upgrade the PR01 placeholder to a minimal stub:

```dart
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('AdminHomeScreen — implemented in PR48'),
      ),
    );
  }
}
```

---

### `lib/screens/buyer/buyer_home_screen.dart`

The `BuyerHomeScreen` placeholder is NOT upgraded in this PR — it is upgraded in PR17. However, `RoleRouterScreen` imports it and returns `const BuyerHomeScreen()`. To satisfy the analyzer without modifying `buyer_home_screen.dart` beyond its current PR01 placeholder, the agent must upgrade it to a minimal stub identical in structure to the others:

```dart
import 'package:flutter/material.dart';

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('BuyerHomeScreen — implemented in PR17'),
      ),
    );
  }
}
```

This is noted as a necessary analyzer stub and will be fully replaced in PR17.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/shared/role_router_screen.dart` | Full `RoleRouterScreen` implementation with 6-case routing logic and embedded `_PendingApprovalScreen` |
| 2 | `lib/screens/auth/login_screen.dart` | Minimal stub `StatelessWidget` |
| 3 | `lib/screens/artisan/artisan_home_screen.dart` | Minimal stub `StatelessWidget` |
| 4 | `lib/screens/admin/admin_home_screen.dart` | Minimal stub `StatelessWidget` |
| 5 | `lib/screens/buyer/buyer_home_screen.dart` | Minimal stub `StatelessWidget` (analyzer bridge — fully replaced in PR17) |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR11 is merged to main**

Open your GitHub repository and confirm the `pr11-splash-screen` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR12 branch**
```
git checkout -b pr12-role-router
```

**Step 4 — Confirm `role_router_screen.dart` is the PR11 minimal stub**
```
cat lib/screens/shared/role_router_screen.dart
```
Must show the PR11 stub — `StatelessWidget` returning `Text('RoleRouterScreen — implemented in PR12')`.

**Step 5 — Confirm target screen files are PR01 placeholders**
```
cat lib/screens/auth/login_screen.dart
cat lib/screens/artisan/artisan_home_screen.dart
cat lib/screens/admin/admin_home_screen.dart
cat lib/screens/buyer/buyer_home_screen.dart
```
All four must show their single-comment placeholder lines from PR01. If any show a full implementation, note it but do not treat it as a blocker — the agent will upgrade them to stubs regardless.

---

Manual setup for this PR is now complete.
Open `docs/PR12_RoleRouterScreen.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify five files. All implementations must match Section 6 exactly.

---

**File 1: `lib/screens/shared/role_router_screen.dart`**

Replace the PR11 stub entirely. Write the complete file:

1. All import statements as specified — including all four screen imports.
2. `class RoleRouterScreen extends StatelessWidget` with `const` constructor.
3. `build` method using `context.watch<AuthProvider>()` and returning widgets directly (not pushing routes) for all six cases in the exact order specified in Section 6.
4. `class _PendingApprovalScreen extends StatelessWidget` defined below `RoleRouterScreen` in the same file, with the full layout specified in Section 6 including the sign-out `ElevatedButton.icon`.

**Critical implementation rules:**
- Use `context.watch<AuthProvider>()` — NOT `context.read`. `watch` is required so the `build` method re-evaluates when auth state changes.
- Return widget instances directly — do NOT use `Navigator.push`, `Navigator.pushReplacement`, or `WidgetsBinding.addPostFrameCallback` inside `build`.
- Evaluate the six cases in the exact order specified. Case order matters — `isInitialized` check must be first, null user check must be second.
- Use `AppConstants.roleAdmin`, `AppConstants.roleArtisan` for role comparisons — never hardcoded strings.
- `_PendingApprovalScreen` sign-out button must use `context.read<AuthProvider>().signOut()` — not `context.watch`.
- `_PendingApprovalScreen` is private (underscore prefix) and must not be exported or used outside this file.

---

**File 2: `lib/screens/auth/login_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6.

---

**File 3: `lib/screens/artisan/artisan_home_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6.

---

**File 4: `lib/screens/admin/admin_home_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6.

---

**File 5: `lib/screens/buyer/buyer_home_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: `context.watch` used in a method that isn't `build` (only `build` may use `watch`), `BuyerHomeScreen` import missing, `AppConstants` import missing, `_PendingApprovalScreen` accidentally made public.

2. **Verify six routing cases are present**
   ```
   grep -c 'return const\|return _Pending\|return const BuyerHomeScreen' lib/screens/shared/role_router_screen.dart
   ```
   Must return at least `5` — covering the loading scaffold, `LoginScreen`, `AdminHomeScreen`, `ArtisanHomeScreen`, and `BuyerHomeScreen` return statements. The `_PendingApprovalScreen` return is non-const so adjust count accordingly.

3. **Verify `context.watch` is used in `build`**
   ```
   grep 'context.watch<AuthProvider>' lib/screens/shared/role_router_screen.dart
   ```
   Must return one line inside the `build` method.

4. **Verify `AppConstants` role constants are used**
   ```
   grep 'AppConstants.role' lib/screens/shared/role_router_screen.dart
   ```
   Must return at least two lines — one for `roleAdmin` and one for `roleArtisan`. No hardcoded role strings permitted.

5. **Verify `_PendingApprovalScreen` is private**
   ```
   grep 'class _PendingApprovalScreen' lib/screens/shared/role_router_screen.dart
   ```
   Must return one line with the underscore prefix confirming it is private.

6. **Verify no `Navigator.push` calls in `RoleRouterScreen.build`**
   ```
   grep 'Navigator' lib/screens/shared/role_router_screen.dart
   ```
   Must return no output from the `RoleRouterScreen` class itself. `Navigator` may appear in `_PendingApprovalScreen` only if needed — but in the specified implementation it does not appear there either.

7. **Hot reload on emulator — logged-out state**
   ```
   flutter run
   ```
   Confirm the following sequence:
   - Splash screen appears briefly.
   - App navigates to `RoleRouterScreen`.
   - Since no user is logged in, `RoleRouterScreen` returns `LoginScreen()` stub.
   - Screen shows "LoginScreen — implemented in PR13".
   - No errors in debug console.
   Press `q` to quit.

8. **Verify all five stub files are correct**
   ```
   grep 'class.*Screen' lib/screens/auth/login_screen.dart
   grep 'class.*Screen' lib/screens/artisan/artisan_home_screen.dart
   grep 'class.*Screen' lib/screens/admin/admin_home_screen.dart
   grep 'class.*Screen' lib/screens/buyer/buyer_home_screen.dart
   ```
   Each must return a class declaration line confirming the stubs were written.

9. **Verify modified files**
   ```
   git diff --name-only
   ```
   Expected: `lib/screens/shared/role_router_screen.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/artisan/artisan_home_screen.dart`, `lib/screens/admin/admin_home_screen.dart`, `lib/screens/buyer/buyer_home_screen.dart`.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 12
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
git commit -m "PR12: Folder Structure Walkthrough — RoleRouterScreen"
git push origin pr12-role-router
```

---

## Section 9 – Acceptance Criteria

- [ ] `RoleRouterScreen` is a `StatelessWidget` that uses `context.watch<AuthProvider>()` and returns destination widgets directly without using `Navigator`.
- [ ] All six routing cases are handled in the correct order: not initialized, no user, admin, approved artisan, pending artisan, buyer.
- [ ] Role comparisons use `AppConstants.roleAdmin` and `AppConstants.roleArtisan` — no hardcoded role strings.
- [ ] `_PendingApprovalScreen` is defined in the same file as a private class, renders the hourglass icon, approval message, and sign-out button.
- [ ] `_PendingApprovalScreen` sign-out button calls `context.read<AuthProvider>().signOut()`.
- [ ] `LoginScreen`, `ArtisanHomeScreen`, `AdminHomeScreen`, and `BuyerHomeScreen` are all minimal stub `StatelessWidget` classes.
- [ ] On the emulator, the app navigates from splash through `RoleRouterScreen` and lands on the `LoginScreen` stub text for a logged-out user.
- [ ] No `Navigator.push` or `Navigator.pushReplacement` calls exist inside `RoleRouterScreen.build`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR12 for CraftBridge. I implemented `RoleRouterScreen` — the central navigation hub that every app launch passes through — with full six-case routing logic that directs every user to their correct home screen based on authentication state, role, and approval status."

2. **Why `RoleRouterScreen` is `StatelessWidget` not `StatefulWidget`:** "`RoleRouterScreen` doesn't manage any state itself — it reads from `AuthProvider` using `context.watch` and returns a widget based on that state. The reactivity comes entirely from `AuthProvider`'s `ChangeNotifier`. When auth state changes — a sign-in, a sign-out, an approval status update — `AuthProvider` calls `notifyListeners()`, `context.watch` triggers a rebuild of `RoleRouterScreen`, and the correct screen is returned automatically."

3. **Returning widgets directly vs `Navigator.push`:** "The design decision to return destination widgets directly instead of calling `Navigator.push` is what makes this router reactive. If I used `Navigator.push` inside `build`, it would fire on every rebuild — causing infinite navigation pushes. By returning the destination widget as the `build` result, `RoleRouterScreen` acts as a switcher — the visible screen is always whatever the current auth state dictates, with no navigation history to manage."

4. **Six-case routing order:** "The order of the cases matters. `isInitialized` must be checked first — before any user access — because `currentUser` is null while auth is resolving, and we don't want to flash `LoginScreen` for a split second on every app launch for a logged-in user. The null check comes second. Then admin, then artisan with approval check, then artisan pending, then buyer as the default catch-all."

5. **`AppConstants` role constants:** "Role comparisons use `AppConstants.roleAdmin` and `AppConstants.roleArtisan` — the string constants `'admin'` and `'artisan'`. Hardcoding these strings in `RoleRouterScreen` would create a silent dependency on the exact Firestore field values. Using the constants means a future rename touches one file."

6. **`_PendingApprovalScreen` design:** "The pending approval screen is a private class defined in the same file as `RoleRouterScreen`. It's private because no other screen should ever navigate to it directly — it should only appear when `RoleRouterScreen` determines the artisan is unapproved. The sign-out button uses `context.read<AuthProvider>().signOut()` — `read` not `watch`, because this is a one-time action, not a state observation."

7. **What happens after `signOut()` from the pending screen:** "When the artisan taps 'Sign Out', `AuthProvider.signOut()` clears `_currentUser` and calls `notifyListeners()`. `RoleRouterScreen` rebuilds via `context.watch`, evaluates `currentUser == null`, and returns `LoginScreen()`. The transition is immediate and requires zero navigation code in the pending screen."

8. **Stub upgrades for navigation targets:** "Four screen files are upgraded from PR01 placeholders to minimal stubs — `LoginScreen`, `ArtisanHomeScreen`, `AdminHomeScreen`, and `BuyerHomeScreen`. Without these stubs, importing them in `RoleRouterScreen` would cause analyzer errors. Each stub renders a one-line text with its implementation PR number, making it immediately clear which PR completes each screen."

9. **Emulator demonstration:** "On the emulator, the splash screen appears for about one second, then the screen shows 'LoginScreen — implemented in PR13'. That transition — splash to role router to login stub — confirms the entire auth routing chain works: `AuthProvider._init()` fires, `_isInitialized` becomes `true`, `SplashScreen` navigates to `RoleRouterScreen`, `RoleRouterScreen` evaluates `currentUser == null` and returns `LoginScreen()`."

10. **What's Next:** "PR13 will implement the `LoginScreen` and `RegistrationScreen` shells — the widget tree, form structure, and `AuthProvider` wiring — without full validation, which comes in PR14."