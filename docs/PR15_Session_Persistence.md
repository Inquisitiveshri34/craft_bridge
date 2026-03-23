# PR15 – Hot Reload + DevTools — Session Persistence Verified

**Project:** CraftBridge
**PR Number:** 15 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Verify and harden session persistence in `AuthProvider` — full `authStateChanges` listener, `isInitialized` getter, and `isAdmin` getter — with no new screens.

---

## Section 2 – Assignments Covered

- Assignment 3.15 — Hot Reload + DevTools — Session Persistence Verified

---

## Section 3 – Objective

This PR hardens the session persistence layer in `AuthProvider` — ensuring the `authStateChanges()` listener correctly restores user sessions across app restarts, that `isInitialized` is set reliably in all auth state branches, and that the `isAdmin` computed getter is explicitly verified. A `docs/PR15_Session_Persistence.md` document is produced describing the session persistence architecture, the DevTools verification methodology, and the hot reload vs hot restart distinction. No new screens are created. `AuthProvider` receives one targeted hardening change — a stream subscription cancellation in a `dispose`-equivalent pattern — and `firestore_service.dart` is not touched.

---

## Section 4 – Architecture Context

```
App restart sequence (session persistence):
  main.dart → Firebase.initializeApp()
      │
      ▼
  AuthProvider() constructor → _init()
      │
      └── _auth.authStateChanges().listen(...)
                │
                ├── Firebase SDK reads persisted auth token from local storage
                │
                ├── token valid → emits User (non-null)
                │       └── FirestoreService.getUser(uid)
                │               └── sets _currentUser = UserModel
                │               └── _isInitialized = true
                │               └── notifyListeners()
                │
                └── token absent/expired → emits null
                        └── _currentUser = null
                        └── _isInitialized = true
                        └── notifyListeners()

SplashScreen watches isInitialized:
  false → spinner visible
  true  → Navigator.pushReplacement(RoleRouterScreen)

RoleRouterScreen watches currentUser + role:
  null         → LoginScreen
  admin        → AdminHomeScreen
  artisan+approved → ArtisanHomeScreen
  artisan+pending  → _PendingApprovalScreen
  buyer        → BuyerHomeScreen

Hot reload vs hot restart:
  Hot reload   → preserves Dart VM state, Provider state survives
  Hot restart  → reinitialises Dart VM, AuthProvider constructor re-runs,
                 _init() re-subscribes, Firebase token re-read from disk
```

This PR sits after full auth screen wiring (PR14) and before navigation routes (PR16). The session persistence mechanism was already built in PR10 — this PR verifies it rigorously, documents it, and adds the stream subscription cancellation hardening that makes `AuthProvider` production-safe.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/auth_provider.dart` — stream subscription field + `dispose` pattern added
- `docs/PR15_Session_Persistence.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any screen files.
- Do NOT modify any other provider files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/providers/auth_provider.dart`

Two targeted changes only. The full class structure from PR10 is preserved.

---

**Change 1 — Add stream subscription field:**

Add the following private field to the field declarations block, after `String? _errorMessage`:

```dart
StreamSubscription<User?>? _authSubscription;
```

This requires adding `dart:async` to the imports:

```dart
import 'dart:async';
```

---

**Change 2 — Update `_init()` to store the subscription:**

Replace the `_init()` method body to store the stream subscription in `_authSubscription`:

```dart
void _init() {
  _authSubscription = _auth.authStateChanges().listen((User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isInitialized = true;
      notifyListeners();
    } else {
      try {
        _currentUser = await _firestoreService.getUser(firebaseUser.uid);
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    }
  });
}
```

The only structural change from PR10 is the assignment `_authSubscription =` at the start of `_init()`. The listener body is identical to PR10.

---

**Change 3 — Add `dispose()` method:**

Add the following `dispose()` override to `AuthProvider`, after the `_setError` method:

```dart
@override
void dispose() {
  _authSubscription?.cancel();
  super.dispose();
}
```

`ChangeNotifier` has a `dispose()` method that is called when the provider is removed from the widget tree. Cancelling `_authSubscription` here prevents the stream listener from firing after the provider is disposed — a defensive measure that prevents memory leaks and post-dispose state mutations in long-running test or hot-restart scenarios.

---

**No other changes to `auth_provider.dart`.** All methods, getters, fields, and error mapping from PR10 are unchanged.

---

### `docs/PR15_Session_Persistence.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph explaining: Firebase Auth SDK persists the authenticated user's token to the device's local storage automatically. On every app start, `Firebase.initializeApp()` reads this token. When `AuthProvider._init()` subscribes to `authStateChanges()`, Firebase immediately emits the persisted user (or null if no session exists) without a network round-trip. This is what makes session persistence work — the first emission of `authStateChanges()` reflects the on-device auth state.

---

#### 2. `authStateChanges()` Emission Sequence

An ASCII diagram showing the two startup paths:

```
App Start
    │
    ▼
Firebase.initializeApp()
    │
    ▼
AuthProvider._init() subscribes to authStateChanges()
    │
    ├── PATH A: Persisted session found (user was logged in)
    │       │
    │       ▼
    │   Stream emits User (non-null) immediately
    │       │
    │       ▼
    │   FirestoreService.getUser(uid) → UserModel
    │       │
    │       ▼
    │   _currentUser = UserModel
    │   _isInitialized = true
    │   notifyListeners()
    │       │
    │       ▼
    │   SplashScreen navigates → RoleRouterScreen
    │       │
    │       ▼
    │   RoleRouterScreen returns correct home screen
    │
    └── PATH B: No persisted session (user was logged out / first launch)
            │
            ▼
        Stream emits null immediately
            │
            ▼
        _currentUser = null
        _isInitialized = true
        notifyListeners()
            │
            ▼
        SplashScreen navigates → RoleRouterScreen
            │
            ▼
        RoleRouterScreen returns LoginScreen
```

Followed by 2–3 sentences explaining that both paths complete within milliseconds because neither requires a network call — the Firebase SDK reads the persisted token from disk. The Firestore `getUser` call in Path A does require a network round-trip, but it happens after `_isInitialized` is set, so the splash-to-role-router navigation is not blocked.

---

#### 3. `isInitialized` Timing

A prose section covering:

- `isInitialized` is `false` from `AuthProvider` construction until the first `authStateChanges()` emission is fully processed.
- `SplashScreen` adds a listener and waits for `isInitialized == true` before navigating. This means the splash is shown for however long it takes the first emission to resolve.
- In Path A, the Firestore `getUser` call happens inside the listener — `_isInitialized` is set to `true` after `getUser` completes (or fails). This means the user's full `UserModel` including `role` and `isApproved` is available by the time `RoleRouterScreen` first renders.
- In Path B, `_isInitialized` is set to `true` immediately when `null` is received. No Firestore call is needed.
- The critical correctness requirement: `_isInitialized = true` must be set in BOTH the null branch AND the non-null branch (including the catch block). If it were missing from the null branch, logged-out users would see the splash spinner forever.

---

#### 4. Hot Reload vs Hot Restart vs Full Restart

A table with columns: **Action**, **Dart VM State**, **AuthProvider State**, **Firebase Token**, **Observable Behaviour**.

| Action | Dart VM State | AuthProvider State | Firebase Token | Observable Behaviour |
|--------|--------------|-------------------|----------------|----------------------|
| Hot Reload (`r` in terminal) | Preserved | Preserved — `_currentUser` unchanged | Unchanged | UI updates immediately, no re-authentication, user stays logged in |
| Hot Restart (`R` in terminal) | Reinitialised | AuthProvider reconstructed, `_init()` re-runs | Read from disk | Splash screen shown briefly, session restored from persisted token |
| Full App Restart (kill + reopen) | Reinitialised | AuthProvider reconstructed, `_init()` re-runs | Read from disk | Same as hot restart — session restored automatically |
| Sign Out then Restart | Reinitialised | `_currentUser = null` on first emission | Token cleared by `signOut()` | Splash → LoginScreen |

Followed by one paragraph noting: hot reload is the fastest development cycle for UI changes because Provider state is preserved — the user stays on the correct screen without re-authenticating. Hot restart is used to verify session persistence specifically — it simulates the full app lifecycle while keeping the emulator running.

---

#### 5. Stream Subscription Lifecycle

A prose section covering:

- `_authSubscription` is the `StreamSubscription<User?>` returned by `authStateChanges().listen()`.
- Storing it in a field allows `dispose()` to cancel the subscription when the `AuthProvider` is removed from the widget tree.
- In production, `MultiProvider` at the top of the widget tree means `AuthProvider` lives for the entire app session and `dispose()` is only called on app shutdown — so `_authSubscription?.cancel()` rarely fires in practice.
- The cancel is a defensive measure for testing environments and hot restart scenarios where the provider tree may be reconstructed. Without it, the old subscription could fire on a disposed provider.
- `_authSubscription?.cancel()` uses the null-safe call operator `?.` — if `_init()` was never called or the subscription was never assigned (edge case in tests), the cancel is a no-op.

---

#### 6. `isAdmin` and `isApprovedArtisan` Getter Verification

A prose section covering:

- `isAdmin` returns `true` only when `_currentUser?.role == AppConstants.roleAdmin`.
- The admin user document must have `role: 'admin'` in Firestore — this is set manually in the Firebase Console for the initial admin account (there is no admin self-registration flow in the MVP).
- `isApprovedArtisan` returns `true` only when role is `'artisan'` AND `isApproved` is `true`.
- Both getters return `false` if `_currentUser` is null — the null-safe operator `?.` ensures no null dereference.
- Verification steps for admin account setup: open Firebase Console → Firestore → `users` collection → find the uid of the intended admin → set `role` field to `'admin'` manually.

---

#### 7. DevTools Verification Methodology

A prose section covering:

- Open Flutter DevTools by running `flutter run` then pressing `v` or opening the DevTools URL printed in the terminal.
- In the Provider tab (if using provider_devtools_extension) or Widget Inspector, observe `AuthProvider` state.
- Timeline verification: in the Performance tab, observe that the first frame after app launch does not block on auth state — `SplashScreen` renders immediately (showing the spinner) and auth resolution happens asynchronously.
- Widget rebuild tracking: in the Widget Inspector, confirm that only `SplashScreen` and `RoleRouterScreen` rebuild when `AuthProvider.notifyListeners()` fires on init — not the entire widget tree.
- Hot restart test procedure: with the app running and a user logged in, press `R` in the terminal to hot restart. Observe the splash spinner for ~500ms, then the app navigates directly to the user's home screen — not to `LoginScreen`. This confirms session persistence is working.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/auth_provider.dart` | Stream subscription field added, `_init()` updated to store subscription, `dispose()` added to cancel subscription |
| 2 | `docs/PR15_Session_Persistence.md` | Complete session persistence document with all 7 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR14 is merged to main**

Open your GitHub repository and confirm the `pr14-auth-validation` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR15 branch**
```
git checkout -b pr15-session-persistence
```

**Step 4 — Confirm `auth_provider.dart` is the PR10 implementation**
```
grep -c 'authStateChanges' lib/providers/auth_provider.dart
```
Must return at least `1`. If it returns `0`, the PR10 implementation is missing.

**Step 5 — Confirm `_authSubscription` field is NOT already present**
```
grep '_authSubscription' lib/providers/auth_provider.dart
```
Must return no output. If the field already exists, PR15 has been partially applied — do not proceed without diagnosis.

**Step 6 — Verify session persistence manually before agent work**

With the app currently working from PR14:
```
flutter run
```
- Register or log in with a test account.
- Confirm the app navigates to the correct home stub.
- Press `R` (capital R) in the terminal to hot restart.
- Confirm the app shows the splash screen briefly and then navigates to the correct home stub again — NOT to `LoginScreen`.
- This confirms the PR10 session persistence is working before PR15 hardens it.
- Press `q` to quit.

---

Manual setup for this PR is now complete.
Open `docs/PR15_Session_Persistence.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify one Dart file and write one Markdown document.

---

**File 1: `lib/providers/auth_provider.dart`**

Make three targeted changes to the existing PR10 implementation:

**Change 1 — Add `dart:async` import:**

Add `import 'dart:async';` to the import block at the top of the file. Place it as the first import (Dart core imports before package imports is the conventional order).

**Change 2 — Add `_authSubscription` field:**

In the private fields block, after `String? _errorMessage`, add:
```dart
StreamSubscription<User?>? _authSubscription;
```

**Change 3 — Update `_init()` and add `dispose()`:**

Replace the `_init()` method with the version that assigns to `_authSubscription`:
```dart
void _init() {
  _authSubscription = _auth.authStateChanges().listen((User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _isInitialized = true;
      notifyListeners();
    } else {
      try {
        _currentUser = await _firestoreService.getUser(firebaseUser.uid);
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    }
  });
}
```

After the `_setError` method, add the `dispose()` override:
```dart
@override
void dispose() {
  _authSubscription?.cancel();
  super.dispose();
}
```

The agent must not change any other part of `auth_provider.dart`. All methods, getters, error mapping, `signIn`, `signUp`, `signOut`, `clearError`, and helper methods from PR10 are unchanged.

---

**File 2: `docs/PR15_Session_Persistence.md`**

Write a complete Markdown document containing all 7 sections specified in Section 6 of this PR document, in order. The agent must write each section as follows:

- **Section 1 — Overview:** 3–4 sentences covering the four points specified.
- **Section 2 — `authStateChanges()` Emission Sequence:** Reproduce the ASCII two-path diagram exactly as specified, followed by 2–3 sentences of explanation.
- **Section 3 — `isInitialized` Timing:** Full prose covering all five points specified, with emphasis on the requirement that `_isInitialized = true` must be set in both branches.
- **Section 4 — Hot Reload vs Hot Restart vs Full Restart:** The complete four-row table exactly as specified, followed by the explanatory paragraph.
- **Section 5 — Stream Subscription Lifecycle:** Full prose covering all five points specified including the null-safe `?.` operator explanation.
- **Section 6 — `isAdmin` and `isApprovedArtisan` Getter Verification:** Full prose covering all five points specified including the admin account setup steps.
- **Section 7 — DevTools Verification Methodology:** Full prose covering all four DevTools verification points specified.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `StreamSubscription` type requires `dart:async` import, `dispose()` override must call `super.dispose()`, `_authSubscription?.cancel()` must use null-safe call.

2. **Verify `_authSubscription` field is present**
   ```
   grep '_authSubscription' lib/providers/auth_provider.dart
   ```
   Must return at least three lines — the field declaration, the assignment in `_init()`, and the cancel in `dispose()`.

3. **Verify `dispose()` is present and calls `super.dispose()`**
   ```
   grep -A3 'void dispose()' lib/providers/auth_provider.dart
   ```
   Must show `_authSubscription?.cancel()` and `super.dispose()`.

4. **Verify `dart:async` import is present**
   ```
   grep 'dart:async' lib/providers/auth_provider.dart
   ```
   Must return one line.

5. **Verify `_isInitialized = true` still appears in both branches**
   ```
   grep -c '_isInitialized = true' lib/providers/auth_provider.dart
   ```
   Must return `2` — unchanged from PR10. If it returns `1`, the `_init()` update accidentally broke one branch.

6. **Verify PR10 methods are all still present**
   ```
   grep -c 'Future<bool> signIn\|Future<bool> signUp\|Future<void> signOut\|void clearError\|String _mapAuthError' lib/providers/auth_provider.dart
   ```
   Must return `5`. If any are missing, the agent incorrectly modified the PR10 implementation.

7. **Verify document exists and has all 7 sections**
   ```
   cat docs/PR15_Session_Persistence.md
   ```
   Confirm all 7 sections are present in order. Confirm Section 2 contains the ASCII diagram. Confirm Section 4 contains the four-row table.

8. **Hot restart session persistence test**
   ```
   flutter run
   ```
   - Log in with a valid test account (registered in PR14 testing).
   - Confirm the app navigates to the home stub.
   - Press `R` (hot restart) in the terminal.
   - Confirm splash appears briefly then app navigates directly to the home stub — not `LoginScreen`.
   - Press `q` to quit.

9. **Sign-out session clearing test**
   - If a way to trigger `signOut()` is accessible (e.g. `_PendingApprovalScreen` sign-out button, or direct Firestore manipulation), sign out.
   - Hot restart.
   - Confirm app navigates to `LoginScreen` — not the home stub.
   - This confirms `signOut()` correctly clears the Firebase token.

10. **Verify only the correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/providers/auth_provider.dart` and `docs/PR15_Session_Persistence.md` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 15
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
git commit -m "PR15: Hot Reload + DevTools — Session Persistence Verified"
git push origin pr15-session-persistence
```

---

## Section 9 – Acceptance Criteria

- [ ] `auth_provider.dart` imports `dart:async`.
- [ ] `AuthProvider` declares `StreamSubscription<User?>? _authSubscription` as a private field.
- [ ] `_init()` assigns the result of `_auth.authStateChanges().listen(...)` to `_authSubscription`.
- [ ] `AuthProvider.dispose()` calls `_authSubscription?.cancel()` followed by `super.dispose()`.
- [ ] `_isInitialized = true` is still set in both the null and non-null (including catch) branches of `_init()` — `grep -c '_isInitialized = true'` returns `2`.
- [ ] All PR10 methods (`signIn`, `signUp`, `signOut`, `clearError`, `_mapAuthError`) are unchanged and present.
- [ ] `docs/PR15_Session_Persistence.md` exists and contains all 7 sections in order.
- [ ] Section 4 of the document contains the four-row hot reload vs hot restart table.
- [ ] Hot restart with a logged-in user restores the session and navigates to the home stub — not `LoginScreen`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR15 for CraftBridge. I hardened the session persistence layer in `AuthProvider` by adding stream subscription lifecycle management, and produced the Session Persistence document explaining exactly how Firebase Auth's `authStateChanges()` enables automatic session restoration across app restarts."

2. **Why session persistence is automatic in Firebase Auth:** "Firebase Auth SDK persists the authenticated user's credential token to the device's local storage — on Android, this is `SharedPreferences`; on iOS, it's the Keychain. When the app restarts and `authStateChanges()` is subscribed to, Firebase immediately emits the stored user without a network call. The app restores the session entirely from disk — no login required."

3. **`_authSubscription` and `dispose()`:** "The PR10 `_init()` called `authStateChanges().listen(...)` but discarded the returned `StreamSubscription`. This means the subscription could not be cancelled — a potential memory leak and a post-dispose fire risk. PR15 stores the subscription in `_authSubscription` and cancels it in `dispose()`. In production, `AuthProvider` lives for the full app session so `dispose()` rarely fires — but the pattern is correct and production-safe."

4. **`StreamSubscription?.cancel()` null safety:** "The cancel call uses `_authSubscription?.cancel()` — the null-safe call operator. `_authSubscription` is nullable because `_init()` might not have been called in edge cases, such as a mock provider in tests. The `?.` means if `_authSubscription` is null, the cancel is a no-op — no null pointer exception."

5. **`_isInitialized` in both branches — the critical correctness requirement:** "One of the most common bugs in splash screen implementations is setting `_isInitialized = true` only in the signed-in branch. A logged-out user opens the app, `authStateChanges()` emits null, the null branch runs — but if `_isInitialized` is never set to true there, `SplashScreen` waits forever. This PR verifies and documents that both branches, including the catch block, set `_isInitialized = true`."

6. **Hot reload vs hot restart distinction:** "Hot reload (`r`) preserves the Dart VM state — `AuthProvider` keeps its `_currentUser` value, the user stays on whatever screen they were on. Hot restart (`R`) reinitialises the Dart VM — `AuthProvider` is reconstructed, `_init()` re-subscribes, Firebase reads the persisted token from disk. Hot restart is the correct tool for verifying session persistence because it simulates a full app lifecycle while keeping the emulator running and the debug connection alive."

7. **Path A vs Path B startup:** "The document's Section 2 diagrams two startup paths. Path A — persisted session found — fires the non-null branch, calls Firestore to get the full `UserModel`, sets `_isInitialized = true`, and the app routes to the user's home screen. Path B — no session — fires the null branch, sets `_isInitialized = true` immediately, and the app routes to `LoginScreen`. Both paths complete within milliseconds for the `_isInitialized` trigger — Path A's Firestore call is a side effect, not a blocker."

8. **DevTools verification methodology:** "The DevTools Performance timeline shows that `SplashScreen` renders its first frame — the spinner — before the auth state is resolved. Auth resolution happens on a background stream callback. This is the correct pattern: the UI thread is never blocked. The Widget Inspector confirms that only `SplashScreen` and `RoleRouterScreen` rebuild when `notifyListeners()` fires — not the entire `MaterialApp` tree."

9. **Admin account setup note:** "The `isAdmin` getter in `AuthProvider` checks `_currentUser?.role == AppConstants.roleAdmin`. There is no admin self-registration flow in the MVP. To create the admin account, a developer registers normally via the app, then manually opens the Firebase Console, finds the user's document in the `users` collection, and sets `role` to `'admin'`. This is documented in Section 6 of the PR15 document."

10. **What's Next:** "PR16 will wire the full navigation routes — implementing `RoleRouterScreen` modifications and creating the `ArtisanHomeScreen` and `AdminHomeScreen` shells with their navigation structure."