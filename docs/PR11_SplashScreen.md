# PR11 – SDK Setup + Emulator — SplashScreen

**Project:** CraftBridge
**PR Number:** 11 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `SplashScreen` — displays the app logo and name while waiting for `AuthProvider.isInitialized`, then navigates to `RoleRouterScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.11 — SDK Setup + Emulator — SplashScreen

---

## Section 3 – Objective

This PR implements the real `SplashScreen`, replacing the PR08 stub `CircularProgressIndicator` with a polished branded screen that displays the app logo, name, and tagline while `AuthProvider` resolves the Firebase Auth state. Once `isInitialized` is `true`, `SplashScreen` navigates to `RoleRouterScreen` using `pushReplacement` so the splash never appears in the back stack. This is the first screen the user sees on every app launch — it must never hang, never crash, and always resolve to a navigation target within seconds of the auth state being known.

---

## Section 4 – Architecture Context

```
App launch
    │
    ▼
main.dart → MaterialApp → home: SplashScreen()
    │
    ▼
SplashScreen (StatefulWidget)
    │
    ├── initState()
    │     └── listens to AuthProvider via addPostFrameCallback
    │
    ├── build()
    │     └── Scaffold (no AppBar)
    │           └── Center
    │                 └── Column
    │                       ├── app logo (Icon — shopping bag)
    │                       ├── SizedBox(height: 16)
    │                       ├── Text(AppConstants.appName)  ← headlineMedium
    │                       ├── SizedBox(height: 8)
    │                       ├── Text(AppConstants.appTagline) ← bodyLarge
    │                       ├── SizedBox(height: 48)
    │                       └── CircularProgressIndicator()
    │
    └── _navigate()
          └── when AuthProvider.isInitialized == true
                └── Navigator.pushReplacement → RoleRouterScreen (stub)

AuthProvider.isInitialized
    └── set to true in _init() once authStateChanges() fires
          └── triggers SplashScreen to call _navigate()
```

This PR sits after `AuthProvider` (PR10) and before `RoleRouterScreen` (PR12). `RoleRouterScreen` is still a placeholder at this point — `SplashScreen` navigates to it, but it will only render a blank screen until PR12. That is expected and correct.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/shared/splash_screen.dart`
- `lib/screens/shared/role_router_screen.dart` — minimal stub upgrade only, to allow `SplashScreen` to navigate without analyzer errors

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify any widget files.
- Do NOT modify any provider files other than reading their public interface.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/shared/splash_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `SplashScreen` and `_SplashScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/screens/shared/role_router_screen.dart`

---

**`SplashScreen` class:**
```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
```

---

**`_SplashScreenState` class:**

**Fields:**
```dart
bool _hasNavigated = false;
```

**`initState()`:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAuthAndNavigate();
  });
}
```

**`_checkAuthAndNavigate()`:**
```dart
void _checkAuthAndNavigate() {
  final authProvider = context.read<AuthProvider>();
  if (authProvider.isInitialized) {
    _navigate();
  } else {
    authProvider.addListener(_onAuthStateChanged);
  }
}
```

**`_onAuthStateChanged()`:**
```dart
void _onAuthStateChanged() {
  final authProvider = context.read<AuthProvider>();
  if (authProvider.isInitialized && !_hasNavigated) {
    authProvider.removeListener(_onAuthStateChanged);
    _navigate();
  }
}
```

**`_navigate()`:**
```dart
void _navigate() {
  if (!mounted || _hasNavigated) return;
  _hasNavigated = true;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const RoleRouterScreen()),
  );
}
```

**`dispose()`:**
```dart
@override
void dispose() {
  context.read<AuthProvider>().removeListener(_onAuthStateChanged);
  super.dispose();
}
```

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- No `AppBar`
- `body`: `SafeArea` wrapping a `Center` wrapping a `Column` with:
  - `mainAxisAlignment: MainAxisAlignment.center`
  - `children`:
    1. `Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).colorScheme.primary)`
    2. `const SizedBox(height: 16)`
    3. `Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))`
    4. `const SizedBox(height: 8)`
    5. `Text(AppConstants.appTagline, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
    6. `const SizedBox(height: 48)`
    7. `CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)`

---

**Navigation guard design:**

The `_hasNavigated` boolean prevents double-navigation. Both `_checkAuthAndNavigate` and `_onAuthStateChanged` check this flag before calling `_navigate()`. The `_navigate()` method also checks `mounted` — if the widget is disposed before navigation fires (unlikely but possible), the navigation call is safely skipped.

The `dispose()` method removes the `_onAuthStateChanged` listener. This prevents a `setState called after dispose` error in the edge case where `AuthProvider` notifies after `SplashScreen` is removed from the tree.

---

### `lib/screens/shared/role_router_screen.dart`

Upgrade the PR01 placeholder to a minimal stub that `SplashScreen` can navigate to without analyzer errors:

```dart
import 'package:flutter/material.dart';

class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('RoleRouterScreen — implemented in PR12'),
      ),
    );
  }
}
```

This stub is replaced entirely in PR12 with the full navigation logic.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/shared/splash_screen.dart` | Full `SplashScreen` implementation — branded display, auth state listener, safe navigation to `RoleRouterScreen` |
| 2 | `lib/screens/shared/role_router_screen.dart` | Minimal stub `StatelessWidget` allowing `SplashScreen` to navigate without errors |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR10 is merged to main**

Open your GitHub repository and confirm the `pr10-auth-provider` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR11 branch**
```
git checkout -b pr11-splash-screen
```

**Step 4 — Confirm `splash_screen.dart` is the PR08 minimal stub**
```
cat lib/screens/shared/splash_screen.dart
```
Must show the PR08 minimal stub — a `StatelessWidget` returning a `Scaffold` with a `CircularProgressIndicator`. If it shows the PR01 placeholder comment, do not proceed.

**Step 5 — Confirm `role_router_screen.dart` is the PR01 placeholder**
```
cat lib/screens/shared/role_router_screen.dart
```
Must show: `// RoleRouterScreen — implemented in PR12`

**Step 6 — Confirm `AuthProvider` is fully implemented**
```
grep -c 'isInitialized' lib/providers/auth_provider.dart
```
Must return at least `3` — the field declaration, the getter, and at least one setter. If it returns fewer, the PR10 implementation is incomplete.

---

Manual setup for this PR is now complete.
Open `docs/PR11_SplashScreen.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/screens/shared/splash_screen.dart`**

Replace the entire PR08 stub content with the full implementation specified in Section 6.

Write the complete file in this order:

1. All import statements as specified.
2. `class SplashScreen extends StatefulWidget` with `const` constructor and `createState()`.
3. `class _SplashScreenState extends State<SplashScreen>` containing:
   - `bool _hasNavigated = false` field.
   - `initState()` override calling `WidgetsBinding.instance.addPostFrameCallback((_) { _checkAuthAndNavigate(); })`.
   - `_checkAuthAndNavigate()` — reads `AuthProvider`, calls `_navigate()` if already initialized, otherwise adds listener.
   - `_onAuthStateChanged()` — checks `isInitialized && !_hasNavigated`, removes listener, calls `_navigate()`.
   - `_navigate()` — checks `mounted && !_hasNavigated`, sets `_hasNavigated = true`, calls `Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoleRouterScreen()))`.
   - `dispose()` — removes `_onAuthStateChanged` listener, calls `super.dispose()`.
   - `build()` — returns `Scaffold` with surface background color, no `AppBar`, `SafeArea` > `Center` > `Column` with all seven children as specified in Section 6.

**Critical implementation rules:**
- `addPostFrameCallback` is required in `initState()`. Do NOT call `_checkAuthAndNavigate()` directly in `initState()` — `context` is not available for Provider reads until after the first frame.
- `_hasNavigated` flag must be checked in both `_onAuthStateChanged()` and `_navigate()` to prevent double-navigation.
- `Navigator.pushReplacement` must be used — not `Navigator.push`. The splash screen must not be in the back stack.
- `dispose()` must remove the listener to prevent memory leaks and post-dispose errors.
- The `CircularProgressIndicator` in the build method is always visible — it is not conditional on `isInitialized`. The navigation happens via the listener pattern, not by conditionally rendering a different widget.

---

**File 2: `lib/screens/shared/role_router_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6. The stub must:
- Import `package:flutter/material.dart`.
- Declare `class RoleRouterScreen extends StatelessWidget` with `const` constructor.
- `build` returns `Scaffold` with `body: Center(child: Text('RoleRouterScreen — implemented in PR12'))`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: `context` used inside `initState()` directly without `addPostFrameCallback` (context is available but Provider reads in `initState` before first frame can fail), missing import for `role_router_screen.dart`, `Navigator` used after widget is disposed (caught by `mounted` check).

2. **Verify `_hasNavigated` guard is present**
   ```
   grep -c '_hasNavigated' lib/screens/shared/splash_screen.dart
   ```
   Must return at least `4` — field declaration, check in `_onAuthStateChanged`, check in `_navigate()`, and set in `_navigate()`.

3. **Verify `pushReplacement` is used, not `push`**
   ```
   grep 'pushReplacement' lib/screens/shared/splash_screen.dart
   ```
   Must return the navigation line. If `Navigator.push` is found instead, the splash screen will appear in the back stack.

4. **Verify listener is removed in `dispose`**
   ```
   grep 'removeListener' lib/screens/shared/splash_screen.dart
   ```
   Must return at least one line — confirming the listener cleanup is in place.

5. **Verify `addPostFrameCallback` is used in `initState`**
   ```
   grep 'addPostFrameCallback' lib/screens/shared/splash_screen.dart
   ```
   Must return one line.

6. **Verify `RoleRouterScreen` stub exists**
   ```
   cat lib/screens/shared/role_router_screen.dart
   ```
   Confirm it contains a `StatelessWidget` class and the text `'RoleRouterScreen — implemented in PR12'`.

7. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm the following sequence:
   - App launches showing the `SplashScreen` — the shopping bag icon, "CraftBridge" headline, tagline, and a `CircularProgressIndicator` all visible on the surface-colored background.
   - Within 1–2 seconds, the app navigates to the `RoleRouterScreen` stub showing "RoleRouterScreen — implemented in PR12".
   - No `UnimplementedError` crash.
   - No `setState called after dispose` error in the debug console.
   - No `ProviderNotFoundException` in the debug console.
   Press `q` to quit.

8. **Verify the navigation transition works for both logged-in and logged-out states**

   Since no user is currently logged in (no sign-in flow is wired yet), the `authStateChanges()` stream fires with `null`, `AuthProvider._isInitialized` becomes `true`, and `SplashScreen` navigates to `RoleRouterScreen` stub. Confirm this sequence completes without error.

9. **Verify only the correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/shared/splash_screen.dart` and `lib/screens/shared/role_router_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 11
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
git commit -m "PR11: SDK Setup + Emulator — SplashScreen"
git push origin pr11-splash-screen
```

---

## Section 9 – Acceptance Criteria

- [ ] `SplashScreen` is a `StatefulWidget` with `_SplashScreenState`.
- [ ] `initState()` uses `WidgetsBinding.instance.addPostFrameCallback` to defer the auth check to after the first frame.
- [ ] `_checkAuthAndNavigate()` reads `AuthProvider.isInitialized` — navigates immediately if `true`, adds a listener if `false`.
- [ ] `_onAuthStateChanged()` removes the listener before calling `_navigate()` and guards with `!_hasNavigated`.
- [ ] `_navigate()` uses `Navigator.of(context).pushReplacement` — not `Navigator.push` — and guards with `mounted && !_hasNavigated`.
- [ ] `dispose()` removes the `_onAuthStateChanged` listener.
- [ ] `build()` renders a `Scaffold` with no `AppBar`, a shopping bag icon, app name in `headlineMedium`, tagline in `bodyLarge`, and a `CircularProgressIndicator` — all styled from `Theme.of(context)`.
- [ ] `RoleRouterScreen` minimal stub exists as a `StatelessWidget` and can be navigated to without errors.
- [ ] On the emulator, the splash screen is visible briefly then transitions to the `RoleRouterScreen` stub text.
- [ ] No `setState called after dispose`, `ProviderNotFoundException`, or `UnimplementedError` appears in the debug console.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR11 for CraftBridge. I implemented the real `SplashScreen` — the branded launch screen that displays the app identity while Firebase Auth resolves the session state, then navigates to `RoleRouterScreen` using the listener pattern."

2. **Why `SplashScreen` is `StatefulWidget`:** "`SplashScreen` needs to manage two pieces of local state — `_hasNavigated` to prevent double-navigation, and the listener lifecycle for the auth provider. `StatelessWidget` cannot own a lifecycle — it has no `initState` or `dispose`. `StatefulWidget` gives us both."

3. **`addPostFrameCallback` in `initState`:** "The auth check can't happen directly in `initState` because `context.read<AuthProvider>()` requires the widget to be mounted in the tree, and Provider resolution happens on the first frame. `addPostFrameCallback` defers the call to after the first frame is rendered — this is the correct Flutter pattern for any Provider access that needs to happen immediately after a widget mounts."

4. **Listener pattern vs `StreamBuilder`:** "`SplashScreen` uses `addListener` rather than a `StreamBuilder` or `Consumer` because we only need to react to one specific state transition — `isInitialized` going from `false` to `true`. Using a `Consumer` or `context.watch` would rebuild the splash screen's widget tree on every `AuthProvider` notification, which is unnecessary overhead for a screen whose only job is to navigate away."

5. **`_hasNavigated` double-navigation guard:** "Without `_hasNavigated`, it's possible for `_navigate()` to be called twice — once from `_checkAuthAndNavigate()` if auth is already initialized on the first check, and once from `_onAuthStateChanged()` if a notification fires concurrently. `_hasNavigated` is a boolean flag that guarantees navigation happens exactly once. The check appears in both `_onAuthStateChanged()` and `_navigate()` for belt-and-suspenders safety."

6. **`pushReplacement` design decision:** "`Navigator.pushReplacement` removes `SplashScreen` from the navigation stack before pushing `RoleRouterScreen`. If we used `Navigator.push`, the user could press the Android back button from any screen and land back on the splash screen — which would then try to navigate forward again. `pushReplacement` makes the transition irreversible, which is the correct behaviour for a splash-to-app transition."

7. **`dispose()` listener cleanup:** "If `AuthProvider` fires a notification after `SplashScreen` has been removed from the tree — which can happen if the widget is disposed during navigation — the `_onAuthStateChanged` listener would call `context.read<AuthProvider>()` on a disposed widget and throw a `setState called after dispose` error. `dispose()` removes the listener to prevent this. The `mounted` check in `_navigate()` is the secondary defence."

8. **Visual design of the splash screen:** "The screen uses `Theme.of(context).colorScheme.surface` as the background — the warm off-white `#FFF8F5` from PR05. The shopping bag icon is 80dp in the primary brown. The app name is `headlineMedium` bold in the primary color. The tagline is `bodyLarge` at 60% opacity of the on-surface color. The `CircularProgressIndicator` is always visible — it reassures the user the app is working. All colors come from the theme, zero hardcoded values."

9. **Emulator demonstration:** "On the emulator you see the splash screen appear — brown icon, 'CraftBridge' headline, 'Digital storefront for local artisans' tagline, and a spinner. Within about one second, Firebase Auth fires its `authStateChanges` event with null (no user logged in), `AuthProvider` sets `isInitialized = true`, the listener fires, and `SplashScreen` navigates to the `RoleRouterScreen` stub showing its placeholder text."

10. **What's Next:** "PR12 will implement `RoleRouterScreen` — the navigation hub that reads `AuthProvider` and routes every user to the correct home screen based on their role and approval status."