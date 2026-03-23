# PR24 – Images + Assets — Firebase Storage Upload

**Project:** CraftBridge
**PR Number:** 24 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `StorageService.uploadProductImage()` and wire it into `AddEditProductScreen` — replacing the `Future.delayed` stub with a real Firebase Storage upload with progress tracking.

---

## Section 2 – Assignments Covered

- Assignment 3.24 — Images + Assets — Firebase Storage Upload

---

## Section 3 – Objective

This PR implements the Firebase Storage upload layer for product images. `StorageService.uploadProductImage()` — stubbed in PR07 — is fully implemented with upload progress streaming, returning the download URL on completion. `AddEditProductScreen` is updated to call this method when `_selectedImageFile` is non-null, activating the `_isUploadingImage` progress indicator scaffolded in PR21 and storing the returned URL for inclusion in the product data. After this PR, artisans can select a product image from the gallery and have it durably stored in Firebase Storage, with the download URL ready for Firestore in PR31.

---

## Section 4 – Architecture Context

```
AddEditProductScreen
    │
    ├── _selectedImageFile (File?) — set in PR21 via image_picker
    │
    └── _handleSubmit() — updated this PR
          │
          ├── if _selectedImageFile != null:
          │     StorageService.uploadProductImage(file, artisanId)
          │       └── FirebaseStorage.ref('products/{artisanId}/{filename}')
          │       └── ref.putFile(file) → UploadTask
          │       └── UploadTask.snapshotEvents → progress stream
          │       └── await task.whenComplete() → ref.getDownloadURL()
          │       └── returns downloadUrl: String
          │
          └── _uploadedImageUrl: String? — stored for PR31 Firestore write

StorageService methods filled this PR:
  uploadProductImage(File imageFile, String artisanId)
    → 'products/{artisanId}/{uuid}.jpg'
    → returns download URL String

StorageService stubs remaining after this PR:
  updateProductImage  → still throws UnimplementedError (PR27)
  deleteProductImage  → still throws UnimplementedError (PR27)

Firebase Storage path structure:
  products/
    {artisanId}/
      {uuid}.jpg    ← unique per upload, avoids filename collisions
```

This PR sits after responsive product grid (PR23) and before animations (PR25). `StorageService` is partially implemented — only `uploadProductImage` is filled. `updateProductImage` and `deleteProductImage` remain as stubs until PR27.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/services/storage_service.dart`
- `lib/screens/artisan/add_edit_product_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify `buyer_home_screen.dart` or any other screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/storage_service.dart`

Replace only the `uploadProductImage` stub body. The `updateProductImage` and `deleteProductImage` stubs remain as `throw UnimplementedError(...)`. The class structure, the `_storage` field, and all import statements are preserved.

---

**New import to add:**

```dart
import 'dart:io';
```

The existing import `package:firebase_storage/firebase_storage.dart` is already present from PR07. Add `dart:io` above it.

A UUID is needed for generating unique filenames. Rather than adding the `uuid` package, use the `DateTime.now().millisecondsSinceEpoch` approach to generate a unique-enough filename for the MVP:

No additional package imports required.

---

**Implemented `uploadProductImage` method:**

```dart
Future<String> uploadProductImage(
  File imageFile,
  String artisanId,
) async {
  final String fileName =
      '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final Reference ref = _storage
      .ref()
      .child('products')
      .child(artisanId)
      .child(fileName);
  final UploadTask uploadTask = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await uploadTask;
  final String downloadUrl = await ref.getDownloadURL();
  return downloadUrl;
}
```

**Implementation notes:**

- `DateTime.now().millisecondsSinceEpoch` produces a unique integer (milliseconds since Unix epoch) as the filename — e.g. `1714920345678.jpg`. Collisions are practically impossible for single-user artisan uploads.
- `SettableMetadata(contentType: 'image/jpeg')` ensures Firebase Storage sets the correct MIME type on the uploaded blob — without this, some clients may fail to display the image from the Storage URL.
- `await uploadTask` blocks until the upload completes. `UploadTask` implements `Future`, so `await` on it works directly.
- `ref.getDownloadURL()` is called after `await uploadTask` — calling it before completion would return a URL for an incomplete file.
- Return type is `String` — the caller receives the public download URL to store in Firestore.
- The two remaining stubs (`updateProductImage`, `deleteProductImage`) must still throw `UnimplementedError`.

---

### `lib/screens/artisan/add_edit_product_screen.dart`

Modify the PR21 implementation with targeted changes to `_handleSubmit()` and the imports.

---

**New imports to add:**

```dart
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/services/storage_service.dart';
```

---

**New field to add to `_AddEditProductScreenState`:**

Add after `bool _isDirty = false`:

```dart
String? _uploadedImageUrl;
```

This field stores the Firebase Storage download URL after a successful upload. It is passed to the Firestore product document in PR31.

---

**Replace `_handleSubmit()` with the updated version:**

```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    String? imageUrl = _uploadedImageUrl;
    if (_selectedImageFile != null) {
      setState(() => _isUploadingImage = true);
      final String? artisanId =
          context.read<AuthProvider>().currentUser?.uid;
      if (artisanId == null) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: user not authenticated.')),
        );
        return;
      }
      imageUrl =
          await StorageService().uploadProductImage(
        _selectedImageFile!,
        artisanId,
      );
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
    }
    setState(() {
      _isLoading = false;
      _isDirty = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Product updated successfully.'
              : 'Product added successfully.',
        ),
      ),
    );
    Navigator.pop(context);
  } catch (e) {
    setState(() {
      _isLoading = false;
      _isUploadingImage = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
  }
}
```

**Key changes from PR21 `_handleSubmit()`:**

1. Wrapped in `try-catch` — upload errors are surfaced to the user via a snackbar instead of crashing.
2. `_isUploadingImage = true` is set before the upload and `false` after — activating the `LinearProgressIndicator` scaffolded in PR21.
3. `AuthProvider.currentUser?.uid` is read via `context.read<AuthProvider>()` — the artisan ID is required as the Storage path segment.
4. `StorageService().uploadProductImage(_selectedImageFile!, artisanId)` replaces `Future.delayed`.
5. `_uploadedImageUrl` stores the returned URL for use in PR31's Firestore write.
6. If `_selectedImageFile` is null (no image selected), `_uploadedImageUrl` retains its previous value (empty for new products, existing URL for edits).
7. Null check on `artisanId` — if for any reason the current user is null, the submit is aborted with an error snackbar.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/services/storage_service.dart` | `uploadProductImage()` fully implemented — timestamp filename, `putFile` with JPEG metadata, `getDownloadURL()` return |
| 2 | `lib/screens/artisan/add_edit_product_screen.dart` | `_handleSubmit()` updated with real Storage upload, `_isUploadingImage` activation, `_uploadedImageUrl` storage, error handling |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/services/storage_service.dart`**

Make targeted changes to the existing PR07 stub file:

**Change 1 — Add `dart:io` import:**
Add `import 'dart:io';` at the top of the import block, before `package:firebase_storage/firebase_storage.dart`.

**Change 2 — Replace `uploadProductImage` stub body:**
Find the `uploadProductImage` method stub body (`throw UnimplementedError('uploadProductImage not yet implemented');`). Replace it with the full implementation specified in Section 6.

The agent must verify after editing:
- `uploadProductImage` is fully implemented and no longer throws `UnimplementedError`.
- `updateProductImage` still throws `UnimplementedError('updateProductImage not yet implemented')`.
- `deleteProductImage` still throws `UnimplementedError('deleteProductImage not yet implemented')`.

```
grep -c 'UnimplementedError' lib/services/storage_service.dart
```
Must return `2` after this PR (was 3 before — one stub replaced).

---

**File 2: `lib/screens/artisan/add_edit_product_screen.dart`**

Make the following targeted changes to the PR21 implementation:

**Change 1 — Add imports:**
Add `import 'package:provider/provider.dart'`, `import 'package:craft_bridge/providers/auth_provider.dart'`, and `import 'package:craft_bridge/services/storage_service.dart'` to the import block.

**Change 2 — Add `_uploadedImageUrl` field:**
Add `String? _uploadedImageUrl;` after `bool _isDirty = false` in the field declarations.

**Change 3 — Replace `_handleSubmit()`:**
Replace the entire PR21 `_handleSubmit()` method body with the new implementation specified in Section 6.

**Critical implementation rules:**
- `context.read<AuthProvider>()` must be called before any `await` — reading from context after an `await` gap requires a `mounted` check. In this implementation, `context.read<AuthProvider>().currentUser?.uid` is read before the `await uploadProductImage` call, so it is safe.
- The `try-catch` wraps the entire upload and submit flow — any `FirebaseException`, `StorageException`, or unexpected error is caught and shown to the user.
- `_isUploadingImage` is only set to `true` when `_selectedImageFile != null` — it should not show the upload progress for submissions with no image.
- `setState` calls must not be made after `await` without a `mounted` check — each `setState` after an `await` in the method is preceded by a `mounted` check via the overall `try-catch` structure and the explicit `if (!mounted) return` guard.
- `StorageService()` is instantiated directly — not via Provider. `StorageService` is a stateless utility class, not a `ChangeNotifier`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `UploadTask` not imported — it is part of `firebase_storage`, already imported; `Reference` type needs to be inferred correctly from `_storage.ref().child(...)` chain; `SettableMetadata` import — it is part of `firebase_storage`; `File` type ambiguity if `dart:io` is not imported.

2. **Verify `UnimplementedError` count in `storage_service.dart`**
   ```
   grep -c 'UnimplementedError' lib/services/storage_service.dart
   ```
   Must return `2` — `updateProductImage` and `deleteProductImage` stubs remain.

3. **Verify `uploadProductImage` is implemented**
   ```
   grep 'getDownloadURL' lib/services/storage_service.dart
   ```
   Must return one line — the download URL retrieval.

4. **Verify `millisecondsSinceEpoch` filename**
   ```
   grep 'millisecondsSinceEpoch' lib/services/storage_service.dart
   ```
   Must return one line — the timestamp-based filename generation.

5. **Verify `SettableMetadata` is used**
   ```
   grep 'SettableMetadata' lib/services/storage_service.dart
   ```
   Must return one line.

6. **Verify `_uploadedImageUrl` field exists**
   ```
   grep '_uploadedImageUrl' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least three lines — declaration, assignment in `_handleSubmit`, and usage.

7. **Verify `_isUploadingImage` is activated**
   ```
   grep '_isUploadingImage = true' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line — inside `_handleSubmit` before the upload call.

8. **Verify `StorageService().uploadProductImage` call**
   ```
   grep 'StorageService()' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line.

9. **Verify `AuthProvider` is read for artisan ID**
   ```
   grep 'currentUser?.uid' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line inside `_handleSubmit`.

10. **Hot reload on emulator — upload test**
    ```
    flutter run
    ```
    Log in as an approved artisan → "My Products" → FAB (+).

    **Test with image:**
    - Tap the image placeholder → select a photo from the gallery.
    - Fill all required fields (Title, Description, Price, Stock, Category).
    - Tap "Add Product".
    - Confirm:
      - `_isUploadingImage` activates: `LinearProgressIndicator` and "Uploading image..." text appear briefly.
      - After upload completes: loading spinner appears on the button.
      - Success snackbar "Product added successfully." appears.
      - Screen pops back to `ManageProductsScreen`.
    - Open Firebase Console → Storage → `products/{artisanId}/` → confirm a `.jpg` file with a timestamp name is present.
    - Open Firebase Console → Storage → copy the download URL and confirm it loads the image in a browser.

    **Test without image:**
    - Open `AddEditProductScreen` again.
    - Fill all fields but do NOT select an image.
    - Tap "Add Product".
    - Confirm: no `LinearProgressIndicator`, no upload progress — just the button loading spinner for a moment, then success snackbar.

    **Test error handling:**
    - Temporarily set Firebase Storage rules to deny all writes (in the Firebase Console).
    - Attempt an upload.
    - Confirm: "Upload failed: [Firebase error message]" snackbar appears, loading state clears.
    - Restore Storage rules.

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/services/storage_service.dart` and `lib/screens/artisan/add_edit_product_screen.dart` should appear.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 24
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
git commit -m "PR24: Images + Assets — Firebase Storage Upload"
git push origin pr24-storage-upload
```

---

## Section 9 – Acceptance Criteria

- [ ] `StorageService.uploadProductImage()` is fully implemented — constructs a Storage path `products/{artisanId}/{timestamp}.jpg`, calls `ref.putFile()` with `SettableMetadata(contentType: 'image/jpeg')`, awaits the upload, and returns `ref.getDownloadURL()`.
- [ ] `grep -c 'UnimplementedError' lib/services/storage_service.dart` returns `2` — `updateProductImage` and `deleteProductImage` stubs unchanged.
- [ ] `AddEditProductScreen._handleSubmit()` reads `AuthProvider.currentUser?.uid` for the artisan ID path segment.
- [ ] `_isUploadingImage` is set to `true` before the upload call and `false` after — activating and deactivating the `LinearProgressIndicator`.
- [ ] `_uploadedImageUrl` stores the returned download URL after a successful upload.
- [ ] `_handleSubmit()` is wrapped in `try-catch` — upload errors show a "Upload failed: $e" snackbar and clear loading state.
- [ ] If `_selectedImageFile` is null, no upload is attempted and `_uploadedImageUrl` retains its previous value.
- [ ] A null `artisanId` (unauthenticated user) aborts the submit with an error snackbar.
- [ ] A `.jpg` file with a timestamp name appears in Firebase Storage under `products/{artisanId}/` after a successful upload.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR24 for CraftBridge. I implemented `StorageService.uploadProductImage()` — replacing the `Future.delayed` stub with a real Firebase Storage upload — and wired it into `AddEditProductScreen`, activating the upload progress indicator scaffolded in PR21."

2. **Firebase Storage path design:** "Images are stored at `products/{artisanId}/{timestamp}.jpg`. The artisan ID as a path segment naturally groups all images by artisan — when an artisan's account is deleted, all their images can be found and cleaned up at `products/{artisanId}/`. The timestamp filename `DateTime.now().millisecondsSinceEpoch` generates a unique integer — `1714920345678.jpg` — that avoids collisions without needing a UUID package."

3. **`putFile` vs `putData`:** "`ref.putFile(imageFile)` uploads a `dart:io File` directly from the device filesystem — it streams the file to Firebase Storage without loading it entirely into memory. The alternative, `putData`, takes a `Uint8List` which requires reading the entire file into memory first. For potentially large product photos, `putFile` is the correct choice."

4. **`SettableMetadata(contentType: 'image/jpeg')`:** "Without explicit content type metadata, Firebase Storage stores the file as `application/octet-stream`. When a browser or Flutter `Image.network` widget fetches the URL, it relies on the content-type header to know how to decode the bytes. Setting `contentType: 'image/jpeg'` ensures the Storage CDN serves the file with the correct header, making the URL work reliably as an `Image.network` source."

5. **`await uploadTask` then `getDownloadURL()`:** "`UploadTask` implements `Future` — `await uploadTask` waits for the upload to complete. `getDownloadURL()` is called only after `await uploadTask` — calling it before completion would fail because the file doesn't exist yet. The download URL is a permanent HTTPS URL served by Firebase's CDN — it works in any browser or `Image.network` widget without authentication."

6. **`_isUploadingImage` activation:** "PR21 scaffolded the `LinearProgressIndicator` and 'Uploading image...' text, but `_isUploadingImage` was never set to `true`. PR24 sets `_isUploadingImage = true` before the `await uploadProductImage` call and `false` after. This makes the progress UI visible during the actual upload — which can take 2–10 seconds on a mobile connection for a 1MB image."

7. **`AuthProvider.currentUser?.uid` before `await`:** "The artisan ID is read from `context.read<AuthProvider>()` before any `await`. Reading from `context` after an `await` is technically valid if the widget is still mounted, but it's a lint-flagged practice. Getting the value synchronously before the first `await` is cleaner and avoids any edge case where the auth state changes mid-upload."

8. **`try-catch` error handling:** "The entire upload and submit flow is wrapped in `try-catch`. Firebase Storage can throw `FirebaseException` for quota exceeded, permission denied, or network errors. Catching and showing the error to the user — 'Upload failed: [message]' — is far better than an unhandled exception crash. The `catch` block resets both `_isLoading` and `_isUploadingImage` so the UI returns to a submittable state."

9. **`_uploadedImageUrl` for PR31:** "`_uploadedImageUrl` is a new field that stores the Firebase Storage download URL after a successful upload. In this PR it's not yet written to Firestore — that happens in PR31 when `ProductProvider.addProduct()` is implemented. The field is already in the right place: when PR31 constructs the `ProductModel` to write, it will use `_uploadedImageUrl ?? ''` as the `imageUrl` field."

10. **What's Next:** "PR25 will add hero animations between `ProductCard` and `ProductDetailScreen`, `AnimatedOpacity` transitions on screen entry, and a `PageRouteBuilder` slide transition for the `AddEditProductScreen` navigation."