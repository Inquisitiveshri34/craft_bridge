# PR10 – Firebase Auth + Firestore — AuthProvider Fully Wired

**Project:** CraftBridge
**PR Number:** 10 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `AuthProvider` with `signIn`, `signUp`, `signOut`, and `_init`, and implement all user methods in `FirestoreService`.

---

## Section 2 – Assignments Covered

- Assignment 3.10 — Firebase Auth + Firestore — AuthProvider Fully Wired

---

## Section 3 – Objective

This PR implements the authentication and user persistence layer for CraftBridge — the `AuthProvider` that wraps Firebase Auth's `authStateChanges()` stream and exposes the current user, role, loading state, and error messages to the widget tree, and all five user-related methods in `FirestoreService`. After this PR, the app can register new users with role assignment, sign existing users in, sign out, and persist session state across app restarts. Every role-gated screen from PR11 onward depends on the state exposed by `AuthProvider`.

---

## Section 4 – Architecture Context

```
Firebase Auth
    │
    └── authStateChanges() stream
              │
              ▼
        AuthProvider (ChangeNotifier)
              │
              ├── currentUser: UserModel?
              ├── isInitialized: bool
              ├── isLoading: bool
              ├── errorMessage: String?
              ├── isAdmin: bool (getter)
              ├── isApprovedArtisan: bool (getter)
              │
              ├── signIn(email, password)
              │         └── FirebaseAuth.signInWithEmailAndPassword()
              │         └── FirestoreService.getUser(uid)
              │         └── sets currentUser
              │
              ├── signUp(email, password, displayName, role, bio)
              │         └── FirebaseAuth.createUserWithEmailAndPassword()
              │         └── FirestoreService.createUser(UserModel)
              │         └── sets currentUser
              │
              ├── signOut()
              │         └── FirebaseAuth.signOut()
              │         └── clears currentUser
              │
              └── _init()
                        └── listens to authStateChanges()
                        └── on user → FirestoreService.getUser(uid)
                        └── sets isInitialized = true

FirestoreService (filled in this PR):
  createUser(UserModel)         → users/{uid}.set(user.toMap())
  getUser(String uid)           → users/{uid}.get() → UserModel?
  updateUser(uid, data)         → users/{uid}.update(data)
  getAllUsers()                  → users.get() → List<UserModel>
  updateUserApproval(uid, bool) → users/{uid}.update({'isApproved': bool})
```

This PR sits after the reusable widgets (PR09) and before `SplashScreen` (PR11). The `AuthProvider` implemented here is the provider that `SplashScreen` and `RoleRouterScreen` read to determine app routing. `FirestoreService` user methods filled in here are also used by the admin screen in PR48.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/auth_provider.dart`
- `lib/services/firestore_service.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any screen or widget files.
- Do NOT modify `product_provider.dart`, `order_provider.dart`, or `cart_provider.dart`.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/providers/auth_provider.dart`

**Imports:**
- `package:flutter/foundation.dart`
- `package:firebase_auth/firebase_auth.dart`
- `package:craft_bridge/models/user_model.dart`
- `package:craft_bridge/services/firestore_service.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:cloud_firestore/cloud_firestore.dart`

**Class:** `AuthProvider extends ChangeNotifier`

---

**Private fields:**
```dart
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirestoreService _firestoreService = FirestoreService();
UserModel? _currentUser;
bool _isInitialized = false;
bool _isLoading = false;
String? _errorMessage;
```

---

**Public getters:**
```dart
UserModel? get currentUser => _currentUser;
bool get isInitialized => _isInitialized;
bool get isLoading => _isLoading;
String? get errorMessage => _errorMessage;
bool get isAdmin => _currentUser?.role == AppConstants.roleAdmin;
bool get isApprovedArtisan =>
    _currentUser?.role == AppConstants.roleArtisan &&
    (_currentUser?.isApproved ?? false);
```

---

**Constructor:**
```dart
AuthProvider() {
  _init();
}
```

---

**`_init()` method:**

```dart
void _init() {
  _auth.authStateChanges().listen((User? firebaseUser) async {
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

- Subscribes to `FirebaseAuth.instance.authStateChanges()`.
- When a user is present, fetches the `UserModel` from Firestore using `FirestoreService.getUser()`.
- Sets `_isInitialized = true` in both the null and non-null branches — this is the signal to `SplashScreen` that auth state is resolved and navigation can proceed.
- Calls `notifyListeners()` after every state change.
- Errors during Firestore fetch are caught silently — `_currentUser` is set to null and the app proceeds to the logged-out state.

---

**`signIn()` method:**

```dart
Future<bool> signIn(String email, String password) async {
  _setLoading(true);
  _clearError();
  try {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _currentUser = await _firestoreService.getUser(credential.user!.uid);
    _setLoading(false);
    return true;
  } on FirebaseAuthException catch (e) {
    _setError(_mapAuthError(e.code));
    _setLoading(false);
    return false;
  } catch (e) {
    _setError('An unexpected error occurred. Please try again.');
    _setLoading(false);
    return false;
  }
}
```

---

**`signUp()` method:**

```dart
Future<bool> signUp({
  required String email,
  required String password,
  required String displayName,
  required String role,
  String bio = '',
}) async {
  _setLoading(true);
  _clearError();
  try {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final UserModel newUser = UserModel(
      uid: credential.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      role: role,
      photoUrl: '',
      bio: bio.trim(),
      isApproved: role == AppConstants.roleBuyer,
      createdAt: Timestamp.now(),
    );
    await _firestoreService.createUser(newUser);
    _currentUser = newUser;
    _setLoading(false);
    return true;
  } on FirebaseAuthException catch (e) {
    _setError(_mapAuthError(e.code));
    _setLoading(false);
    return false;
  } catch (e) {
    _setError('An unexpected error occurred. Please try again.');
    _setLoading(false);
    return false;
  }
}
```

- `isApproved` is set to `true` only for buyers. Artisans get `isApproved: false` and must wait for admin approval.
- `bio` defaults to empty string — only artisans pass a non-empty bio.

---

**`signOut()` method:**

```dart
Future<void> signOut() async {
  await _auth.signOut();
  _currentUser = null;
  notifyListeners();
}
```

---

**`clearError()` public method:**

```dart
void clearError() {
  _errorMessage = null;
  notifyListeners();
}
```

---

**Private helper methods:**

```dart
void _setLoading(bool value) {
  _isLoading = value;
  notifyListeners();
}

void _clearError() {
  _errorMessage = null;
}

String _mapAuthError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No account found with this email address.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled.';
    case 'invalid-credential':
      return 'Invalid email or password. Please try again.';
    default:
      return 'Authentication failed. Please try again.';
  }
}

void _setError(String message) {
  _errorMessage = message;
  notifyListeners();
}
```

- `_mapAuthError` maps Firebase error codes to user-friendly messages.
- `_clearError` is private — it does not call `notifyListeners()` because it is always followed immediately by another state change that will notify.
- `clearError` (public, no underscore) is for screens to call when dismissing an error — it calls `notifyListeners()`.

---

### `lib/services/firestore_service.dart`

Replace only the User Methods group stub bodies. All other method stubs remain as `throw UnimplementedError(...)`. The class structure, the `_db` field, the import block, and all other method groups are not changed.

**User Methods — replace stub bodies with implementations:**

```dart
// ── User Methods ── implemented in PR10 ──────────────────────

Future<void> createUser(UserModel user) async {
  await _db
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .set(user.toMap());
}

Future<UserModel?> getUser(String uid) async {
  final DocumentSnapshot doc = await _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .get();
  if (!doc.exists) return null;
  return UserModel.fromMap(doc.data() as Map<String, dynamic>);
}

Future<void> updateUser(String uid, Map<String, dynamic> data) async {
  await _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update(data);
}

Future<List<UserModel>> getAllUsers() async {
  final QuerySnapshot snapshot =
      await _db.collection(AppConstants.usersCollection).get();
  return snapshot.docs
      .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
      .toList();
}

Future<void> updateUserApproval(String uid, bool isApproved) async {
  await _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'isApproved': isApproved});
}
```

**Additional import required in `firestore_service.dart`:**

Add `package:craft_bridge/core/constants/app_constants.dart` to the import block if not already present. All Firestore collection names must use `AppConstants.usersCollection`, never the hardcoded string `'users'`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/auth_provider.dart` | Full `AuthProvider` implementation with `_init`, `signIn`, `signUp`, `signOut`, computed getters, error mapping, and loading state management |
| 2 | `lib/services/firestore_service.dart` | User Methods group filled in — `createUser`, `getUser`, `updateUser`, `getAllUsers`, `updateUserApproval` — all other stubs unchanged |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR09 is merged to main**

Open your GitHub repository and confirm the `pr09-custom-widgets` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR10 branch**
```
git checkout -b pr10-auth-provider
```

**Step 4 — Confirm `auth_provider.dart` is the PR08 minimal stub**
```
cat lib/providers/auth_provider.dart
```
Must show the minimal `ChangeNotifier` stub from PR08:
```dart
import 'package:flutter/foundation.dart';
class AuthProvider extends ChangeNotifier {}
```
If it shows the PR01 placeholder comment or a full implementation, do not proceed.

**Step 5 — Confirm `firestore_service.dart` has all stubs throwing `UnimplementedError`**
```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `20`. If it returns fewer, the PR07 implementation is incomplete.

---

Manual setup for this PR is now complete.
Open `docs/PR10_AuthProvider.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files: `lib/providers/auth_provider.dart` and `lib/services/firestore_service.dart`.

---

**File 1: `lib/providers/auth_provider.dart`**

Replace the entire PR08 minimal stub with the full implementation specified in Section 6. Write the complete file in this order:

1. All import statements as specified.
2. `class AuthProvider extends ChangeNotifier` opening.
3. All private fields in the order specified.
4. All public getters in the order specified.
5. Constructor `AuthProvider()` calling `_init()`.
6. `_init()` method exactly as specified — subscribes to `authStateChanges()`, fetches `UserModel` on non-null user, sets `_isInitialized = true` in both branches.
7. `signIn()` method exactly as specified — `email.trim()`, `FirebaseAuthException` catch with `_mapAuthError`, generic catch, returns `bool`.
8. `signUp()` method exactly as specified — named parameters, constructs `UserModel` with `isApproved: role == AppConstants.roleBuyer`, calls `createUser`, returns `bool`.
9. `signOut()` method — calls `_auth.signOut()`, clears `_currentUser`, notifies.
10. `clearError()` public method — sets `_errorMessage = null`, notifies.
11. `_setLoading()` private helper.
12. `_clearError()` private helper — does NOT call `notifyListeners()`.
13. `_mapAuthError()` private helper — all 9 error code cases plus default.
14. `_setError()` private helper — sets `_errorMessage` and notifies.

**Critical implementation rules:**
- `_init()` must be called from the constructor, not from `main.dart` or any external caller.
- `signIn()` and `signUp()` must both call `_setLoading(true)` at the start and `_setLoading(false)` before every return path.
- `signUp()` sets `isApproved: role == AppConstants.roleBuyer` — this is a boolean expression that evaluates to `true` for buyers and `false` for artisans.
- `_clearError()` (private) does NOT notify — it is always called before a `_setLoading(true)` call that will notify.
- `clearError()` (public) DOES notify — it is called from UI to dismiss an error.

---

**File 2: `lib/services/firestore_service.dart`**

Do NOT rewrite the file. Open the existing file and replace only the five method bodies in the User Methods group. Replace each `throw UnimplementedError('...')` body with the implementation specified in Section 6.

Additionally, add `package:craft_bridge/core/constants/app_constants.dart` to the import block at the top of the file if it is not already present.

The agent must verify after editing that:
- All 15 remaining stubs (non-user-method stubs) still contain `throw UnimplementedError(...)`.
- The 5 user methods are now implemented with actual Firestore logic.
- No other method group has been touched.

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `15` after this PR (was 20 before, 5 user method stubs replaced).

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: missing `async` on `_init`'s listener callback, `FirebaseAuthException` not imported, `Timestamp` not imported from `cloud_firestore`, missing `AppConstants` import in `firestore_service.dart`.

2. **Verify `UnimplementedError` count in `firestore_service.dart`**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return exactly `15`. If it returns `20`, the user methods were not implemented. If it returns fewer than `15`, other method stubs were accidentally modified.

3. **Verify `AuthProvider` getters exist**
   ```
   grep -n 'get currentUser\|get isInitialized\|get isLoading\|get errorMessage\|get isAdmin\|get isApprovedArtisan' lib/providers/auth_provider.dart
   ```
   Must return 6 lines — one for each getter.

4. **Verify `_mapAuthError` handles `invalid-credential` case**
   ```
   grep 'invalid-credential' lib/providers/auth_provider.dart
   ```
   Must return one line. This error code is returned by Firebase for both wrong email and wrong password in newer SDK versions.

5. **Verify `isApproved` logic in `signUp`**
   ```
   grep 'isApproved:' lib/providers/auth_provider.dart
   ```
   Must return a line containing `role == AppConstants.roleBuyer`. This confirms artisans get `false` and buyers get `true` automatically.

6. **Verify `_init` sets `_isInitialized = true` in both branches**
   ```
   grep -c '_isInitialized = true' lib/providers/auth_provider.dart
   ```
   Must return `2` — one in the null branch and one in the non-null branch (inside try or catch). If it returns `1`, the initialization signal may not fire for logged-out users, causing `SplashScreen` to hang.

7. **Verify collection constants are used in `firestore_service.dart`**
   ```
   grep -n "'users'" lib/services/firestore_service.dart
   ```
   Must return no output. All collection references must use `AppConstants.usersCollection`.

8. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app launches and shows the `SplashScreen` stub `CircularProgressIndicator`.
   - After a brief moment (auth state resolves), the spinner continues — `SplashScreen` is still a stub and does not yet navigate. This is expected behaviour.
   - No `UnimplementedError` crash in the debug console (which would happen if `_init()` triggered a stub method).
   - No `FirebaseException` in the debug console.
   Press `q` to quit.

9. **Verify only the correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/providers/auth_provider.dart` and `lib/services/firestore_service.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 10
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
git commit -m "PR10: Firebase Auth + Firestore — AuthProvider Fully Wired"
git push origin pr10-auth-provider
```

---

## Section 9 – Acceptance Criteria

- [ ] `AuthProvider` extends `ChangeNotifier` and exposes `currentUser`, `isInitialized`, `isLoading`, `errorMessage`, `isAdmin`, and `isApprovedArtisan` getters.
- [ ] `AuthProvider` constructor calls `_init()` which subscribes to `authStateChanges()` and sets `_isInitialized = true` in both the null and non-null branches.
- [ ] `signIn()` calls `FirebaseAuth.signInWithEmailAndPassword()`, fetches `UserModel` from Firestore, handles `FirebaseAuthException` with `_mapAuthError`, and returns `bool`.
- [ ] `signUp()` calls `FirebaseAuth.createUserWithEmailAndPassword()`, constructs a `UserModel` with `isApproved: role == AppConstants.roleBuyer`, calls `FirestoreService.createUser()`, and returns `bool`.
- [ ] `signOut()` calls `FirebaseAuth.signOut()` and clears `_currentUser`.
- [ ] `_mapAuthError()` handles at minimum: `user-not-found`, `wrong-password`, `email-already-in-use`, `weak-password`, `invalid-email`, `invalid-credential`, and a default case.
- [ ] `firestore_service.dart` User Methods group is fully implemented: `createUser`, `getUser`, `updateUser`, `getAllUsers`, `updateUserApproval`.
- [ ] All collection references in `firestore_service.dart` use `AppConstants.usersCollection`, not hardcoded strings.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` returns exactly `15`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR10 for CraftBridge. I implemented `AuthProvider` — the most critical provider in the project — with full sign-in, sign-up, sign-out, and session persistence via Firebase Auth's `authStateChanges()` stream, and filled in all five user methods in `FirestoreService`."

2. **`authStateChanges()` stream and `_init()`:** "`_init()` is called from the `AuthProvider` constructor. It subscribes to Firebase Auth's `authStateChanges()` stream, which fires every time the auth state changes — on app start, on sign-in, on sign-out, and on token refresh. When a user is present, it fetches the full `UserModel` from Firestore using their `uid`. Setting `_isInitialized = true` in both the null and non-null branches is critical — it tells `SplashScreen` that auth state is resolved and navigation can proceed regardless of whether the user is logged in or out."

3. **Why `_isInitialized` must be set in both branches:** "If `_isInitialized` were only set in the non-null branch, a user who opens the app while logged out would see the splash spinner forever — `authStateChanges()` fires with `null` immediately for logged-out users, and `_isInitialized` would never become `true`. Setting it in both branches means the app always navigates away from the splash screen within milliseconds of the first auth state emission."

4. **`signIn()` and `signUp()` loading state pattern:** "Both methods call `_setLoading(true)` at the start and `_setLoading(false)` before every return path — both the success return and every error catch. This pattern ensures the UI loading spinner is never stuck in an active state after an operation completes or fails. `_clearError()` is called at the start without notifying — the subsequent `_setLoading(true)` call will notify with the cleared error in the same build cycle."

5. **`signUp()` `isApproved` logic:** "`isApproved: role == AppConstants.roleBuyer` is a boolean expression. When role is `'buyer'`, it evaluates to `true`. When role is `'artisan'`, it evaluates to `false`. This single line encodes the entire artisan approval gate — artisans are created with `isApproved: false` and cannot sell until an admin calls `updateUserApproval(uid, true)`."

6. **`_mapAuthError()` error code mapping:** "Firebase Auth throws `FirebaseAuthException` with a `code` property — strings like `'wrong-password'` and `'email-already-in-use'`. Raw Firebase codes are never shown to users. `_mapAuthError()` maps each code to a friendly sentence. Importantly, `'invalid-credential'` is included — newer versions of the Firebase Auth SDK return this code for both wrong email and wrong password to prevent user enumeration attacks."

7. **`FirestoreService` user methods:** "The five user methods use `AppConstants.usersCollection` for the collection name — never the hardcoded string `'users'`. `getUser` returns `UserModel?` — it returns null if the document doesn't exist, which can happen if a Firebase Auth user was created but the Firestore write failed. `updateUserApproval` is a targeted update of a single field rather than a full document write — this is the correct Firestore pattern for partial updates."

8. **`isAdmin` and `isApprovedArtisan` getters:** "These computed getters are consumed by `RoleRouterScreen` in PR12. `isAdmin` checks role against `AppConstants.roleAdmin`. `isApprovedArtisan` checks both role and `isApproved` — an artisan who is not yet approved should not reach `ArtisanHomeScreen`. The null-safe `?? false` on `isApproved` ensures the getter returns `false` safely if `_currentUser` is null."

9. **`UnimplementedError` count drops from 20 to 15:** "After this PR, `grep -c 'UnimplementedError' firestore_service.dart` returns 15. This is the verification signal that exactly five user method stubs were replaced with implementations and no other stubs were accidentally modified. The progressive fill-in schedule — PR10, PR26, PR31, PR33, PR34, PR44, PR48 — means this count will decrease predictably through the project."

10. **What's Next:** "PR11 will implement `SplashScreen` — replacing the stub `CircularProgressIndicator` with a real splash that waits for `AuthProvider.isInitialized` and then navigates to `RoleRouterScreen`."