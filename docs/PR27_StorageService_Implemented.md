# PR27 – FlutterFire CLI + SDKs — StorageService Implemented

**Project:** CraftBridge
**PR Number:** 27 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Fully implement `StorageService` — add `updateProductImage()` and `deleteProductImage()` to complete the Firebase Storage lifecycle for product image management.

---

## Section 2 – Assignments Covered

- Assignment 3.27 — FlutterFire CLI + SDKs — StorageService Implemented

---

## Section 3 – Objective

This PR completes `StorageService` by implementing `updateProductImage()` and `deleteProductImage()` — the two methods that were stubbed in PR07 and left as `UnimplementedError` after PR24 implemented `uploadProductImage()`. After this PR, the full Firebase Storage lifecycle for product images is in place: upload a new image, replace an existing image (deleting the old file and uploading the new one), and delete an image entirely. These methods are consumed by `AddEditProductScreen` in PR36 when full product edit and delete flows are wired.

---

## Section 4 – Architecture Context

```
StorageService (complete after this PR)

  uploadProductImage(File, artisanId)       ← implemented PR24
    → 'products/{artisanId}/{timestamp}.jpg'
    → returns downloadUrl

  updateProductImage(File, artisanId, oldImageUrl)  ← implemented THIS PR
    → deleteProductImage(oldImageUrl)        (deletes old file)
    → uploadProductImage(newFile, artisanId) (uploads new file)
    → returns new downloadUrl

  deleteProductImage(String imageUrl)       ← implemented THIS PR
    → FirebaseStorage.refFromURL(imageUrl)
    → ref.delete()

Storage path structure:
  products/
    {artisanId}/
      {timestamp1}.jpg   ← original upload (PR24)
      {timestamp2}.jpg   ← after update (old file deleted, new file here)

FirestoreService UnimplementedError count:
  Unchanged at 12 (no firestore_service.dart changes this PR)

StorageService UnimplementedError count:
  Before: 2 (updateProductImage, deleteProductImage)
  After:  0 (all methods implemented)
```

This PR sits after `ProductProvider` (PR26) and before artisan registration flow (PR28). `StorageService` is now fully implemented. The `updateProductImage` and `deleteProductImage` methods are not yet called from any screen — their invocation points are wired in PR36.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/services/storage_service.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/storage_service.dart`

Replace the two remaining stub bodies. The class structure, the `_storage` field, the `dart:io` import, and the `firebase_storage` import are all preserved from PR24. The `uploadProductImage` implementation from PR24 is preserved unchanged.

---

**Implemented `deleteProductImage` method:**

```dart
Future<void> deleteProductImage(String imageUrl) async {
  if (imageUrl.isEmpty) return;
  try {
    final Reference ref = _storage.refFromURL(imageUrl);
    await ref.delete();
  } on FirebaseException catch (e) {
    if (e.code == 'object-not-found') {
      return;
    }
    rethrow;
  }
}
```

**Implementation notes:**

- `imageUrl.isEmpty` guard — if an empty string is passed (product with no image), return immediately without attempting a Firebase call.
- `_storage.refFromURL(imageUrl)` — converts a Firebase Storage download URL back to a `Reference`. This works for any `https://firebasestorage.googleapis.com/...` URL returned by `getDownloadURL()`.
- `object-not-found` catch — if the file has already been deleted (e.g. by a concurrent operation or a previous failed delete), swallow the error silently. Any other `FirebaseException` is re-thrown so the caller can handle it.
- `rethrow` — preserves the original stack trace rather than wrapping in a new exception.

---

**Implemented `updateProductImage` method:**

```dart
Future<String> updateProductImage(
  File newImageFile,
  String artisanId,
  String oldImageUrl,
) async {
  await deleteProductImage(oldImageUrl);
  final String newDownloadUrl =
      await uploadProductImage(newImageFile, artisanId);
  return newDownloadUrl;
}
```

**Implementation notes:**

- `updateProductImage` composes `deleteProductImage` and `uploadProductImage` — no new Firebase SDK calls are needed.
- `deleteProductImage(oldImageUrl)` is called first — if the old file cannot be deleted for any reason other than `object-not-found`, the error propagates and the upload is not attempted. This prevents orphaned files from accumulating.
- If `oldImageUrl` is empty (new product being edited that had no prior image), `deleteProductImage` returns immediately due to its empty-string guard, and the upload proceeds.
- `uploadProductImage` is called with the same `artisanId` — the new file goes into the same artisan-scoped folder.
- Returns `String` — the new download URL — so the caller can update the Firestore product document.

---

**Final `StorageService` structure after this PR:**

```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── implemented PR24 ──────────────────────────────────────
  Future<String> uploadProductImage(File imageFile, String artisanId) async {
    // timestamp filename, putFile, getDownloadURL
  }

  // ── implemented PR27 ──────────────────────────────────────
  Future<String> updateProductImage(
    File newImageFile,
    String artisanId,
    String oldImageUrl,
  ) async {
    // delete old, upload new, return new URL
  }

  Future<void> deleteProductImage(String imageUrl) async {
    // refFromURL, delete, object-not-found guard
  }
}
```

After this PR, `grep -c 'UnimplementedError' lib/services/storage_service.dart` must return `0`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/services/storage_service.dart` | `updateProductImage()` and `deleteProductImage()` fully implemented — `StorageService` complete with all three methods |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly one file.

---

**File: `lib/services/storage_service.dart`**

Make two targeted replacements to the existing PR24 implementation:

**Change 1 — Replace `updateProductImage` stub body:**

Find the `updateProductImage` method:
```dart
Future<String> updateProductImage(
  File newImageFile,
  String artisanId,
  String oldImageUrl,
) async {
  throw UnimplementedError('updateProductImage not yet implemented');
}
```

Replace the `throw UnimplementedError(...)` body with:
```dart
await deleteProductImage(oldImageUrl);
final String newDownloadUrl =
    await uploadProductImage(newImageFile, artisanId);
return newDownloadUrl;
```

**Change 2 — Replace `deleteProductImage` stub body:**

Find the `deleteProductImage` method:
```dart
Future<void> deleteProductImage(String imageUrl) async {
  throw UnimplementedError('deleteProductImage not yet implemented');
}
```

Replace the `throw UnimplementedError(...)` body with:
```dart
if (imageUrl.isEmpty) return;
try {
  final Reference ref = _storage.refFromURL(imageUrl);
  await ref.delete();
} on FirebaseException catch (e) {
  if (e.code == 'object-not-found') {
    return;
  }
  rethrow;
}
```

**Critical implementation rules:**
- `deleteProductImage` must be implemented BEFORE `updateProductImage` in the file — `updateProductImage` calls `deleteProductImage`, so the Dart compiler needs `deleteProductImage` to exist. In practice the order in the file does not matter for Dart (methods can call each other regardless of order), but the PR07 stub order was `updateProductImage` first, `deleteProductImage` second — preserve this order.
- `_storage.refFromURL(imageUrl)` — not `_storage.ref().child(...)`. `refFromURL` takes a full download URL and resolves it to a `Reference`. This is the correct method when you have a download URL and need a `Reference` for deletion.
- `rethrow` — not `throw e`. `rethrow` preserves the original exception and its stack trace.
- The `uploadProductImage` implementation from PR24 must NOT be modified. Only the two stub bodies are replaced.

After editing, verify:
```
grep -c 'UnimplementedError' lib/services/storage_service.dart
```
Must return `0`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `FirebaseException` — already imported via `firebase_storage`; `Reference` type — from `firebase_storage`; `rethrow` used outside a `catch` block (must be inside `on FirebaseException catch (e)`); `refFromURL` vs `ref()` — confirm correct method name.

2. **Verify `UnimplementedError` count is zero**
   ```
   grep -c 'UnimplementedError' lib/services/storage_service.dart
   ```
   Must return `0`.

3. **Verify `refFromURL` is used in `deleteProductImage`**
   ```
   grep 'refFromURL' lib/services/storage_service.dart
   ```
   Must return one line.

4. **Verify `object-not-found` guard**
   ```
   grep 'object-not-found' lib/services/storage_service.dart
   ```
   Must return one line — inside the `FirebaseException` catch.

5. **Verify `rethrow` is used**
   ```
   grep 'rethrow' lib/services/storage_service.dart
   ```
   Must return one line.

6. **Verify `imageUrl.isEmpty` guard**
   ```
   grep 'imageUrl.isEmpty' lib/services/storage_service.dart
   ```
   Must return one line — at the start of `deleteProductImage`.

7. **Verify `updateProductImage` calls both `deleteProductImage` and `uploadProductImage`**
   ```
   grep 'deleteProductImage\|uploadProductImage' lib/services/storage_service.dart
   ```
   Must return at least four lines — the two method definitions and the two calls inside `updateProductImage`.

8. **Verify `uploadProductImage` from PR24 is unchanged**
   ```
   grep 'millisecondsSinceEpoch' lib/services/storage_service.dart
   ```
   Must return one line — confirming the PR24 timestamp filename logic is still present.

9. **Hot reload on emulator — StorageService integration test**
   ```
   flutter run
   ```
   Log in as an approved artisan → "My Products" → FAB (+).

   **Test `uploadProductImage` still works (PR24 unchanged):**
   - Select an image, fill all fields, tap "Add Product".
   - Confirm success snackbar and navigation back.
   - Open Firebase Console → Storage → confirm new file present.

   **Test `deleteProductImage` via Firebase Console:**
   - Note the download URL of a previously uploaded image.
   - In Flutter DevTools or via a temporary test button, call `StorageService().deleteProductImage(url)` and verify the file disappears from Firebase Console.
   - Call `deleteProductImage('')` — confirm no error (empty string guard).
   - Call `deleteProductImage(url)` a second time — confirm no error (`object-not-found` guard).

   **Note:** `updateProductImage` is not yet called from any screen — full end-to-end testing of `updateProductImage` happens in PR36. The method composition is verified via the unit logic in Section 6.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/services/storage_service.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 27
  Failed Check: [exact check that failed]
  Error Output: [exact error message or error description]
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
git commit -m "PR27: FlutterFire CLI + SDKs — StorageService Implemented"
git push origin pr27-storage-service
```

---

## Section 9 – Acceptance Criteria

- [ ] `StorageService.deleteProductImage()` is fully implemented — empty string guard, `refFromURL`, `ref.delete()`, `object-not-found` catch with silent return, `rethrow` for all other `FirebaseException` errors.
- [ ] `StorageService.updateProductImage()` is fully implemented — calls `deleteProductImage(oldImageUrl)` then `uploadProductImage(newImageFile, artisanId)`, returns new download URL.
- [ ] `grep -c 'UnimplementedError' lib/services/storage_service.dart` returns `0`.
- [ ] `StorageService.uploadProductImage()` from PR24 is unchanged.
- [ ] `deleteProductImage('')` returns immediately without a Firebase call.
- [ ] `deleteProductImage(url)` called twice on the same URL does not throw — the `object-not-found` error is swallowed.
- [ ] `updateProductImage` composes `deleteProductImage` and `uploadProductImage` with no new Firebase SDK calls.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR27 for CraftBridge. I completed `StorageService` by implementing `updateProductImage()` and `deleteProductImage()` — finishing the Firebase Storage lifecycle for product images. After this PR, `StorageService` has zero `UnimplementedError` stubs."

2. **`refFromURL` vs `ref().child()`:** "`deleteProductImage` receives a full Firebase Storage download URL — a string like `https://firebasestorage.googleapis.com/v0/b/project.appspot.com/o/products%2F...`. `_storage.refFromURL(url)` converts this URL back to a `Reference` object. `_storage.ref().child(path)` constructs a reference from a path — it requires knowing the path, not the URL. Since we stored the URL in Firestore (not the path), `refFromURL` is the correct method."

3. **`object-not-found` silent catch:** "When a delete fails with `object-not-found`, it means the file is already gone — either it was never uploaded, or it was deleted by a previous operation. In this case, silently returning is the correct behaviour — the desired end state (file does not exist) is already achieved. Any other `FirebaseException` — permission denied, quota exceeded, network error — is re-thrown so the caller can handle it. This distinction between 'already done' errors and 'real' errors is important for idempotent operations."

4. **`rethrow` preserves stack trace:** "`rethrow` re-throws the caught exception with its original stack trace intact. Writing `throw e` instead would reset the stack trace to the `throw` statement, losing the original context. When a `FirebaseException` is eventually caught by `AddEditProductScreen`'s try-catch in PR36, the original Firestore stack trace will be visible in the debug console, making diagnosis easier."

5. **`updateProductImage` as composition:** "`updateProductImage` calls `deleteProductImage` then `uploadProductImage` — it adds no new Firebase SDK logic. This is the composition principle: complex operations are built from simpler ones. The `deleteProductImage` call uses the `object-not-found` guard — so if the old URL is empty or the old file is already gone, the delete is a no-op and the upload proceeds. The `uploadProductImage` call reuses the PR24 timestamp filename logic."

6. **Delete-before-upload ordering:** "The delete happens before the upload. The alternative — upload first, then delete — would leave orphaned files if the upload fails: the old file would still exist but the new URL would be stored in Firestore, pointing to the new file, while the old file accumulates in Storage. Delete-first means if the upload fails, the product temporarily has no image but no orphaned files exist. The artisan can retry."

7. **Empty string guard in `deleteProductImage`:** "When an artisan creates a new product without selecting an image, `_uploadedImageUrl` in `AddEditProductScreen` is null. In PR36, when editing begins, `oldImageUrl` will be passed as an empty string if no previous image exists. The `if (imageUrl.isEmpty) return` guard prevents a `refFromURL('')` call — which would throw a malformed URL exception — turning a potential crash into a silent no-op."

8. **Why `updateProductImage` is not yet called from any screen:** "`updateProductImage` is wired in PR36 when the full product edit flow is implemented. At this point, `AddEditProductScreen` can load an existing product's data including its `imageUrl`, and when the artisan selects a new image and taps 'Update Product', `updateProductImage` is called with the new file, artisan ID, and the old URL. PR27 puts the implementation in place; PR36 calls it."

9. **`StorageService` zero `UnimplementedError` milestone:** "After PR27, `grep -c 'UnimplementedError' lib/services/storage_service.dart` returns 0. This is a meaningful milestone — `StorageService` is the first service file in the project to be fully implemented. `FirestoreService` still has 12 stubs to fill across PRs 31, 33, 34, 44, and 48."

10. **What's Next:** "PR28 will implement the artisan registration flow — updating `AuthProvider`, `RegistrationScreen`, and `RoleRouterScreen` to properly handle the artisan role with `isApproved: false` on signup, and the pending approval screen transition."