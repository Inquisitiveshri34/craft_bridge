# PR38 – Push Notifications — FCM Setup Documented

**Project:** CraftBridge
**PR Number:** 38 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Add `firebase_messaging` package, implement FCM token registration and notification permission request in `AuthProvider`, and produce the FCM setup documentation.

---

## Section 2 – Assignments Covered

- Assignment 3.38 — Push Notifications — FCM Setup Documented

---

## Section 3 – Objective

This PR sets up the Firebase Cloud Messaging infrastructure for CraftBridge — adding the `firebase_messaging` package, requesting notification permissions from the user on sign-in, retrieving the device FCM token, storing it in the user's Firestore document, and producing `docs/PR38_FCM_Setup.md` documenting the full notification architecture. Full push notification delivery — triggered by order status changes — is out of scope for the MVP and documented as a post-MVP Cloud Function enhancement. After this PR, the FCM infrastructure is in place and ready for a Cloud Function to deliver notifications when implemented.

---

## Section 4 – Architecture Context

```
pubspec.yaml
  firebase_messaging: ^15.1.3   ← added this PR

AuthProvider (updated this PR)
  │
  ├── signIn() → _registerFcmToken()
  ├── signUp() → _registerFcmToken()
  │
  └── _registerFcmToken()
        │
        ├── FirebaseMessaging.instance.requestPermission()
        │     → NotificationSettings (granted / denied / provisional)
        │
        ├── if granted or provisional:
        │     FirebaseMessaging.instance.getToken()
        │       → String? fcmToken
        │
        └── if fcmToken != null:
              FirestoreService.updateUser(uid, {'fcmToken': fcmToken})
                → users/{uid}.update({'fcmToken': fcmToken})

Firestore users/{uid} document after this PR:
  ... existing fields ...
  fcmToken: String   ← new field (not in locked UserModel — stored directly)

Post-MVP Cloud Function (not implemented):
  orders/{orderId} onWrite
    → read order.buyerId / order.artisanId
    → read users/{buyerId or artisanId}.fcmToken
    → FCM.send(token, title, body)

docs/PR38_FCM_Setup.md ← produced this PR
```

This PR sits after order status trigger (PR37) and before Firestore security rules (PR39). The `fcmToken` field is stored directly in Firestore without updating the locked `UserModel` — the model is locked after PR07 and does not include `fcmToken`.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `pubspec.yaml` — add `firebase_messaging` dependency
- `lib/providers/auth_provider.dart`
- `docs/PR38_FCM_Setup.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files (including `user_model.dart` — `fcmToken` is NOT added to the model).
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any screen files.
- Do NOT modify any widget files.
- Do NOT modify any provider files other than `auth_provider.dart`.

---

## Section 6 – Technical Requirements

---

### `pubspec.yaml`

Add `firebase_messaging: ^15.1.3` under the `dependencies:` section, after `provider: ^6.1.2`.

After editing, run:
```
flutter pub get
```

---

### `lib/providers/auth_provider.dart`

Three targeted changes to the existing PR15/PR29 implementation. All existing fields, getters, methods, and the `StreamSubscription` from PR15 are preserved.

---

**Change 1 — Add import:**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
```

---

**Change 2 — Add `_registerFcmToken()` private method:**

Add after the `_init()` method:

```dart
Future<void> _registerFcmToken() async {
  try {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      final String? token = await messaging.getToken();
      if (token != null && _currentUser != null) {
        await _firestoreService.updateUser(
          _currentUser!.uid,
          {'fcmToken': token},
        );
      }
    }
  } catch (e) {
    debugPrint('FCM token registration failed: $e');
  }
}
```

**Implementation notes:**

- `requestPermission()` on Android always returns `authorized` — the permission system for Android 13+ is handled by the `firebase_messaging` package automatically. On iOS, a system dialog is shown.
- `getToken()` returns `null` if the device has no network or if the app is not properly configured with Firebase — the null check prevents a crash.
- `_currentUser != null` guard — ensures the token is only stored if a user is authenticated.
- The entire method is wrapped in `try-catch` — FCM failures must never crash the auth flow. The error is logged with `debugPrint` (visible in debug console, not shown to user).
- `FirestoreService.updateUser(uid, {'fcmToken': token})` stores the token using the existing `updateUser` method from PR10 — no new Firestore method needed.
- `fcmToken` is NOT added to `UserModel` — the model is locked. It is stored directly in the Firestore document as a raw map update.

---

**Change 3 — Call `_registerFcmToken()` from `signIn()` and `signUp()`:**

In `signIn()`, add after `_currentUser = await _firestoreService.getUser(credential.user!.uid)` and before `_setLoading(false)`:

```dart
await _registerFcmToken();
```

In `signUp()`, add after `_currentUser = newUser` and before `_setLoading(false)`:

```dart
await _registerFcmToken();
```

**Placement precision:**

For `signIn()`, the full updated try block becomes:

```dart
try {
  final UserCredential credential = await _auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  _currentUser = await _firestoreService.getUser(credential.user!.uid);
  await _registerFcmToken();
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
```

For `signUp()`, the full updated try block becomes:

```dart
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
  await _registerFcmToken();
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
```

---

### `docs/PR38_FCM_Setup.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: Firebase Cloud Messaging (FCM) enables CraftBridge to deliver push notifications to buyers and artisans about order events. In the MVP, the FCM infrastructure — permission request, token retrieval, token storage — is implemented in `AuthProvider`. Full notification delivery requires a Cloud Function or server-side trigger (not implemented in MVP). This document describes the FCM setup, the token lifecycle, the Firestore storage pattern, and the post-MVP notification architecture.

---

#### 2. FCM Token Lifecycle

An ASCII diagram showing the token flow:

```
User signs in or registers
        │
        ▼
AuthProvider._registerFcmToken()
        │
        ├── FirebaseMessaging.requestPermission()
        │         │
        │         ├── iOS: system permission dialog shown
        │         └── Android 13+: permission auto-granted
        │
        ├── AuthorizationStatus.authorized OR .provisional
        │         │
        │         ▼
        │   FirebaseMessaging.getToken()
        │         │
        │         └── returns String? fcmToken
        │
        └── fcmToken != null && _currentUser != null
                  │
                  ▼
        FirestoreService.updateUser(uid, {'fcmToken': fcmToken})
                  │
                  ▼
        users/{uid}.fcmToken = "AAAAxyz..."

Token refresh (post-MVP):
  FirebaseMessaging.onTokenRefresh
    → listen stream → updateUser with new token
```

Followed by 2–3 sentences explaining: FCM tokens change when the app is reinstalled, the user clears app data, or Firebase rotates the token. In the MVP, the token is only registered at sign-in. A production implementation would also listen to `FirebaseMessaging.instance.onTokenRefresh` to keep the stored token current.

---

#### 3. `fcmToken` Firestore Storage Pattern

A prose section covering:

- The FCM token is stored as a raw field `fcmToken: String` in the `users/{uid}` document via `FirestoreService.updateUser(uid, {'fcmToken': token})`.
- `UserModel` is NOT updated to include `fcmToken` — the model is locked after PR07. The token is a platform-infrastructure field, not a user-data field — it should not be part of the app's data model.
- The `updateUser` method uses Firestore's `.update()` — it adds the `fcmToken` field to the document if it doesn't exist, or updates it if it does. Documents created before this PR was deployed will have the field added on next sign-in.
- Reading the token from Firestore (for a Cloud Function to use) does not require `UserModel` — a Cloud Function accesses the Firestore document directly via the Admin SDK, bypassing the Flutter model layer.

---

#### 4. Notification Permission Behaviour

A table with columns: **Platform**, **Behaviour**, **Result**, **User Action Required**.

| Platform | Behaviour | Result | User Action Required |
|----------|-----------|--------|---------------------|
| Android < 13 | Notifications granted by default | `AuthorizationStatus.authorized` | None |
| Android 13+ | `firebase_messaging` auto-requests permission | `AuthorizationStatus.authorized` or `denied` | Accept dialog |
| iOS | System permission dialog shown on first `requestPermission()` call | `authorized`, `provisional`, or `denied` | Accept or decline dialog |
| iOS (provisional) | No dialog — provisional authorization granted silently | `AuthorizationStatus.provisional` | None (quiet notifications delivered) |

Followed by one paragraph: if the user denies notification permissions, `_registerFcmToken()` returns without error — the try-catch swallows any permission-related errors, and `getToken()` returns null when permissions are denied. The app continues to function normally without notifications.

---

#### 5. Post-MVP Notification Architecture

A prose section covering the full post-MVP Cloud Function design:

- **Trigger:** A Cloud Function listens on `orders/{orderId}` `onWrite` events. When the `status` field changes, the function fires.
- **Token retrieval:** The function reads `users/{buyerId}.fcmToken` (for buyer notifications on status change) or `users/{artisanId}.fcmToken` (for artisan notifications on new order).
- **Notification delivery:** The function calls `admin.messaging().send({token, notification: {title, body}})`.
- **Notification content examples:**
  - New order (to artisan): "New order received! [buyerName] ordered [productTitle]."
  - Status update (to buyer): "Your order for [productTitle] is now [status]."
- **Client-side handling:** `FirebaseMessaging.onMessage` (foreground) and `FirebaseMessaging.onMessageOpenedApp` (background tap) listeners would be added to `main.dart` to handle incoming notifications in the Flutter app.
- **Why this is post-MVP:** Cloud Functions require a Blaze (pay-as-you-go) Firebase plan. The Spark (free) plan does not support Cloud Functions. For a student project on the Spark plan, the notification trigger is documented but not implemented.

---

#### 6. MVP Limitations and Known Issues

A prose section covering:

- **Token not refreshed:** The FCM token is only registered at sign-in. If the token changes (app reinstall, data clear), the stored token becomes stale and notifications would fail. Mitigation: listen to `FirebaseMessaging.instance.onTokenRefresh` in `AuthProvider._init()`.
- **No foreground notification handling:** `FirebaseMessaging.onMessage` is not subscribed to in this PR. Foreground notifications would be silently received without any in-app display. Mitigation: add a `FlutterLocalNotificationsPlugin` integration or a custom in-app banner.
- **`fcmToken` not in `UserModel`:** Reading the FCM token from a `UserModel` instance is not possible. Any screen that needs the current device's FCM token must call `FirebaseMessaging.instance.getToken()` directly. This is acceptable since screens do not currently need the token.
- **Error swallowing:** FCM registration errors are logged with `debugPrint` but not surfaced to the user. If FCM fails due to a misconfigured Firebase project, the app continues without notifications with no visible indication.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `pubspec.yaml` | `firebase_messaging: ^15.1.3` added |
| 2 | `lib/providers/auth_provider.dart` | `_registerFcmToken()` implemented, called from `signIn()` and `signUp()` |
| 3 | `docs/PR38_FCM_Setup.md` | Complete FCM documentation with all 6 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must update `pubspec.yaml`, modify `auth_provider.dart`, and write `docs/PR38_FCM_Setup.md`.

---

**Step 1: Update `pubspec.yaml`**

Add `firebase_messaging: ^15.1.3` to the `dependencies:` section after `provider: ^6.1.2`. Run:
```
flutter pub get
```

---

**File 1: `lib/providers/auth_provider.dart`**

Make three targeted changes:

**Change 1:** Add `import 'package:firebase_messaging/firebase_messaging.dart'` to the import block.

**Change 2:** Add `_registerFcmToken()` private method after `_init()`, exactly as specified in Section 6.

**Change 3:** Add `await _registerFcmToken()` to both `signIn()` and `signUp()` try blocks, exactly as specified in Section 6 — after `_currentUser` is set in both methods, before `_setLoading(false)`.

**Critical rules:**
- `_registerFcmToken()` is declared `async` — it awaits `requestPermission()` and `getToken()`.
- The entire body is wrapped in `try-catch` — FCM failures must not propagate to the caller.
- `debugPrint` (not `print`) is used for error logging.
- `_currentUser != null` is checked before calling `updateUser` — `_registerFcmToken()` could theoretically be called before `_currentUser` is set in edge cases.
- Do NOT modify `UserModel` — `fcmToken` is stored via raw Firestore update only.
- All existing `signIn()` and `signUp()` logic is preserved — only `await _registerFcmToken()` is added.

---

**File 2: `docs/PR38_FCM_Setup.md`**

Write the complete Markdown document with all 6 sections as specified in Section 6. The ASCII diagram in Section 2 must be reproduced. The permission behaviour table in Section 4 must have all 4 rows.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Confirm `firebase_messaging` resolves without errors.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `FirebaseMessaging` import missing; `NotificationSettings` type from `firebase_messaging`; `AuthorizationStatus` enum values — confirm correct casing (`authorized`, not `Authorized`); `debugPrint` vs `print` — use `debugPrint`.

3. **Verify `firebase_messaging` in `pubspec.yaml`**
   ```
   grep 'firebase_messaging' pubspec.yaml
   ```
   Must return one line.

4. **Verify `_registerFcmToken` method exists**
   ```
   grep '_registerFcmToken' lib/providers/auth_provider.dart
   ```
   Must return at least three lines — definition, call in `signIn`, call in `signUp`.

5. **Verify `try-catch` wraps `_registerFcmToken`**
   ```
   grep -A20 'Future<void> _registerFcmToken' lib/providers/auth_provider.dart | grep 'catch'
   ```
   Must return one line — confirming the method body is wrapped in try-catch.

6. **Verify `requestPermission` is called**
   ```
   grep 'requestPermission' lib/providers/auth_provider.dart
   ```
   Must return one line.

7. **Verify `fcmToken` is stored via `updateUser`**
   ```
   grep 'fcmToken' lib/providers/auth_provider.dart
   ```
   Must return at least one line — the `updateUser` call with the token.

8. **Verify `UserModel` is not modified**
   ```
   grep 'fcmToken' lib/models/user_model.dart
   ```
   Must return no output — confirming the locked model is unchanged.

9. **Verify `_registerFcmToken` is called after `_currentUser` is set**
   ```
   grep -n '_currentUser\|_registerFcmToken' lib/providers/auth_provider.dart
   ```
   Review line numbers — in both `signIn()` and `signUp()`, `_registerFcmToken()` call must appear after the line that sets `_currentUser`.

10. **Hot reload on emulator — FCM registration test**
    ```
    flutter run
    ```
    Sign out (if signed in) and sign back in.
    Confirm:
    - On Android emulator: no visible permission dialog (Android <13 auto-grants).
    - Sign-in completes normally — no crash, no visible error.
    - Open Firebase Console → Firestore → `users` collection → find the signed-in user's document → confirm `fcmToken` field is present with a long token string.
    - Sign out → sign back in → confirm `fcmToken` field updates (may be same or different token depending on Firebase's rotation schedule).
    - Sign in as a different user → confirm that user's document also gets `fcmToken` field.

    **On physical Android 13+ device or iOS simulator (if available):**
    - Sign in → confirm notification permission dialog appears.
    - Accept → `fcmToken` stored in Firestore.
    - Sign in again → `requestPermission()` does not re-show dialog (permission already granted) → token refreshed.

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `pubspec.yaml`, `pubspec.lock`, `lib/providers/auth_provider.dart`, `docs/PR38_FCM_Setup.md`.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 38
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
git commit -m "PR38: Push Notifications — FCM Setup Documented"
git push origin pr38-fcm-setup
```

---

## Section 9 – Acceptance Criteria

- [ ] `pubspec.yaml` contains `firebase_messaging: ^15.1.3` and `flutter pub get` resolves successfully.
- [ ] `AuthProvider` imports `firebase_messaging`.
- [ ] `AuthProvider._registerFcmToken()` is implemented — calls `requestPermission()`, checks `authorizationStatus`, calls `getToken()`, stores token via `FirestoreService.updateUser()`.
- [ ] `_registerFcmToken()` entire body is wrapped in `try-catch` with `debugPrint` for error logging.
- [ ] `_registerFcmToken()` is called from `signIn()` after `_currentUser` is set and before `_setLoading(false)`.
- [ ] `_registerFcmToken()` is called from `signUp()` after `_currentUser` is set and before `_setLoading(false)`.
- [ ] `UserModel` (`lib/models/user_model.dart`) is NOT modified — `fcmToken` is not in the model.
- [ ] After sign-in on the emulator, the user's Firestore document has a `fcmToken` field.
- [ ] `docs/PR38_FCM_Setup.md` exists with all 6 sections including the ASCII token lifecycle diagram and the 4-row permission behaviour table.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR38 for CraftBridge. I set up the Firebase Cloud Messaging infrastructure — adding the `firebase_messaging` package, implementing notification permission request and FCM token registration in `AuthProvider`, and documenting the complete notification architecture including the post-MVP Cloud Function design."

2. **FCM token purpose:** "An FCM token is a unique identifier for a specific app installation on a specific device. When a Cloud Function wants to send a push notification to a buyer, it needs their FCM token to address the message. Storing the token in Firestore at sign-in time makes it available to any server-side function that needs to notify that user."

3. **`requestPermission()` platform differences:** "On Android below version 13, notifications are granted by default — `requestPermission()` returns `authorized` without showing any dialog. On Android 13+, the operating system requires explicit permission — `firebase_messaging` handles the system dialog. On iOS, a system dialog is always shown on the first call. The `_registerFcmToken()` implementation handles all three cases with a single check on `authorizationStatus`."

4. **`try-catch` around the entire method:** "FCM can fail for many reasons — network unavailability, Firebase project misconfiguration, Google Play Services issues on emulators. Wrapping the entire `_registerFcmToken()` body in `try-catch` ensures none of these failures propagate to `signIn()` or `signUp()`. The auth flow completes successfully even if FCM fails. The error is logged with `debugPrint` for debugging but never shown to the user."

5. **`fcmToken` not in `UserModel`:** "The `UserModel` is locked after PR07 — adding `fcmToken` to it would require modifying a locked file. But more importantly, `fcmToken` is a platform-infrastructure field, not a user-data field. It changes with device reinstalls, it's platform-specific, and it's only consumed by server-side functions. Storing it via a raw `updateUser` call keeps it out of the app's data model where it doesn't belong."

6. **`updateUser` reuse from PR10:** "`FirestoreService.updateUser(uid, {'fcmToken': token})` uses the existing partial-update method from PR10. No new Firestore method is needed. Firestore's `.update()` adds the `fcmToken` field to existing user documents that were created before this PR — they didn't have `fcmToken` before, but `.update()` creates the field if it doesn't exist."

7. **Post-MVP Cloud Function design:** "Section 5 of the documentation describes the full post-MVP notification architecture. A Cloud Function on `orders/{orderId}` `onWrite` reads the buyer or artisan FCM token from Firestore and calls `admin.messaging().send()`. This is why the token needs to be stored in Firestore — the Cloud Function runs on Google's servers, not on the device, so it can't call `getToken()` directly."

8. **Why Cloud Functions are post-MVP:** "Cloud Functions require Firebase's Blaze pay-as-you-go plan. The Spark free plan doesn't support them. For a student project, implementing the full notification trigger would require upgrading the Firebase plan and billing setup. The PR38 documentation explicitly notes this — the infrastructure is ready, the Cloud Function is a named post-MVP enhancement with a clear implementation path."

9. **Token refresh limitation:** "Section 6 documents the known limitation: FCM tokens are only registered at sign-in. If the token changes — which happens on app reinstall or when Firebase rotates tokens — the stored token becomes stale. A production implementation would subscribe to `FirebaseMessaging.instance.onTokenRefresh` in `AuthProvider._init()` and update the Firestore document on each refresh event."

10. **What's Next:** "PR39 will deploy production-ready Firestore security rules — replacing the test-mode rules from PR04 with role-based access control that restricts read and write operations based on the authenticated user's role and ownership of documents."