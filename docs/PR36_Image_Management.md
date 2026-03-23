# PR36 – Firebase Storage — Product Image Management

**Project:** CraftBridge
**PR Number:** 36 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Wire `StorageService.updateProductImage()` and `deleteProductImage()` into `AddEditProductScreen` — enabling artisans to change or remove product images when editing existing listings.

---

## Section 2 – Assignments Covered

- Assignment 3.36 — Firebase Storage — Product Image Management

---

## Section 3 – Objective

This PR completes the product image lifecycle in `AddEditProductScreen` by wiring the two `StorageService` methods implemented in PR27 — `updateProductImage()` and `deleteProductImage()` — into the edit flow. When an artisan opens an existing product for editing, the current image is displayed as a preview. If they select a new image, `updateProductImage()` replaces the old Storage file and returns the new URL. If they tap "Remove", `deleteProductImage()` deletes the Storage file and clears the image URL. The Firestore product document is updated with the new or cleared image URL in the same `_handleSubmit()` call.

---

## Section 4 – Architecture Context

```
AddEditProductScreen (edit mode — _isEditMode == true)
  │
  ├── initState(): widget.product.imageUrl is non-empty
  │     → _uploadedImageUrl = widget.product.imageUrl
  │     → _buildImageSection() shows Image.network preview
  │
  ├── User taps "Change Image":
  │     → _pickImage() → _selectedImageFile = new File
  │     → _buildImageSection() shows Image.file preview
  │     → _handleSubmit():
  │           StorageService().updateProductImage(
  │             _selectedImageFile!, artisanId, _uploadedImageUrl!)
  │           → deleteProductImage(oldUrl) + uploadProductImage(newFile)
  │           → returns new downloadUrl
  │           → updateData['imageUrl'] = newDownloadUrl
  │
  ├── User taps "Remove":
  │     → _removeImage() → _selectedImageFile = null
  │                      → _imageRemoved = true  ← NEW FLAG this PR
  │     → _buildImageSection() shows placeholder
  │     → _handleSubmit():
  │           if _imageRemoved && _uploadedImageUrl != null:
  │             StorageService().deleteProductImage(_uploadedImageUrl!)
  │             → updateData['imageUrl'] = ''
  │
  └── User makes no image change:
        → _selectedImageFile == null && _imageRemoved == false
        → _handleSubmit() does not touch imageUrl in updateData

Files modified this PR:
  lib/screens/artisan/add_edit_product_screen.dart
```

This PR sits after product search (PR35) and before order status trigger (PR37). All `StorageService` methods have been implemented since PR27 — this PR wires them into the screen flow.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/artisan/add_edit_product_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any other screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

### `lib/screens/artisan/add_edit_product_screen.dart`

Four targeted changes to the PR31 implementation. The form structure, controllers, validators, `_buildCategoryDropdown()`, `_buildImageSection()` visual layout, `PopScope`, and `_addDirtyListeners()` are all preserved.

---

**Change 1 — Add `_imageRemoved` field:**

Add to `_AddEditProductScreenState` field declarations, after `String? _uploadedImageUrl`:

```dart
bool _imageRemoved = false;
```

This flag distinguishes between two remove scenarios in edit mode:
- User selected a new image (replace): `_selectedImageFile != null`
- User removed the image with no replacement (delete): `_selectedImageFile == null && _imageRemoved == true`

---

**Change 2 — Update `initState()` to load existing image as network preview:**

The PR31 `initState()` already sets:
```dart
_uploadedImageUrl = widget.product!.imageUrl.isNotEmpty
    ? widget.product!.imageUrl
    : null;
```

No change is needed here — this is already in place from PR31. Confirm it is present. If missing, add it.

---

**Change 3 — Update `_removeImage()` to set `_imageRemoved = true`:**

Replace the PR21 `_removeImage()` method with:

```dart
void _removeImage() {
  setState(() {
    _selectedImageFile = null;
    _imageRemoved = true;
    _isDirty = true;
  });
}
```

The addition of `_imageRemoved = true` is the only change from the PR21 version.

---

**Change 4 — Update `_buildImageSection()` to show network preview for existing images:**

The existing `_buildImageSection()` shows `Image.file` when `_selectedImageFile != null` and a placeholder tap target when `_selectedImageFile == null`. Add a third branch: when `_selectedImageFile == null` AND `_uploadedImageUrl != null` AND `_imageRemoved == false`, show `Image.network` preview of the existing image.

Replace the `_buildImageSection()` method with:

```dart
Widget _buildImageSection() {
  // Branch 1: New image selected — show local file preview
  if (_selectedImageFile != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Image.file(
            _selectedImageFile!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _pickImage,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Change Image'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _removeImage,
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isUploadingImage) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Text(
            'Uploading image...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Branch 2: Existing network image — show network preview
  if (_uploadedImageUrl != null && !_imageRemoved) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Image.network(
            _uploadedImageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.08),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Change Image'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _removeImage,
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Branch 3: No image — show placeholder tap target
  return GestureDetector(
    onTap: _pickImage,
    child: Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add product image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5),
                ),
          ),
        ],
      ),
    ),
  );
}
```

---

**Change 5 — Update `_handleSubmit()` to handle image update and delete:**

Replace the `_handleSubmit()` image handling section with the full edit-mode-aware version:

```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    String? imageUrl = _uploadedImageUrl;
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

    // Handle image changes
    if (_selectedImageFile != null) {
      // New image selected — upload (replace old if editing)
      setState(() => _isUploadingImage = true);
      if (_isEditMode && _uploadedImageUrl != null) {
        // Replace existing Storage file
        imageUrl = await StorageService().updateProductImage(
          _selectedImageFile!,
          artisanId,
          _uploadedImageUrl!,
        );
      } else {
        // Fresh upload (add mode or edit with no prior image)
        imageUrl = await StorageService().uploadProductImage(
          _selectedImageFile!,
          artisanId,
        );
      }
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
    } else if (_imageRemoved &&
        _isEditMode &&
        _uploadedImageUrl != null) {
      // Image explicitly removed — delete from Storage
      await StorageService().deleteProductImage(_uploadedImageUrl!);
      imageUrl = '';
    }

    if (!mounted) return;
    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isEditMode) {
      final Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory!,
        'stock': int.parse(_stockController.text.trim()),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
      success = await productProvider.updateProduct(
          widget.product!.id, updateData);
    } else {
      success = await productProvider.addProduct(
        artisanId: artisanId,
        artisanName: authProvider.currentUser!.displayName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: imageUrl ?? '',
        category: _selectedCategory!,
        stock: int.parse(_stockController.text.trim()),
      );
    }

    setState(() {
      _isLoading = false;
      _isDirty = false;
    });
    if (!mounted) return;
    if (success) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productProvider.errorMessage ??
                'Failed to save product.',
          ),
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _isUploadingImage = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

**Key changes from PR31 `_handleSubmit()`:**

1. `artisanId` is read before the image handling block — required for both `updateProductImage` and `deleteProductImage`.
2. Image handling is now three-branch:
   - `_selectedImageFile != null && _isEditMode && _uploadedImageUrl != null` → `updateProductImage` (replace old with new)
   - `_selectedImageFile != null` (else) → `uploadProductImage` (fresh upload, add mode or no prior image)
   - `_imageRemoved && _isEditMode && _uploadedImageUrl != null` → `deleteProductImage` then `imageUrl = ''`
3. When `imageUrl == ''` (image removed), `'imageUrl': imageUrl` is included in `updateData` — the conditional `if (imageUrl != null)` allows an empty string through, clearing the Firestore field.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/add_edit_product_screen.dart` | `_imageRemoved` flag, `_buildImageSection()` with three branches (new file, existing network, placeholder), `_handleSubmit()` with update/delete/upload routing |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly one file.

---

**File: `lib/screens/artisan/add_edit_product_screen.dart`**

Make the following five targeted changes to the PR31 implementation:

**Change 1:** Add `bool _imageRemoved = false` field after `String? _uploadedImageUrl`.

**Change 2:** Confirm `_uploadedImageUrl = widget.product!.imageUrl.isNotEmpty ? widget.product!.imageUrl : null` is present in `initState()`. If missing, add it.

**Change 3:** Replace `_removeImage()` body — add `_imageRemoved = true` to the `setState` call.

**Change 4:** Replace `_buildImageSection()` with the three-branch version specified in Section 6. The three branches are:
- `_selectedImageFile != null` → `Image.file` preview with Change/Remove buttons and upload progress indicator (identical to PR21 branch).
- `_uploadedImageUrl != null && !_imageRemoved` → `Image.network` preview with Change/Remove buttons.
- Neither condition → placeholder tap target (identical to PR21 placeholder).

**Change 5:** Replace `_handleSubmit()` with the full image-management-aware version specified in Section 6.

**Critical implementation rules:**
- `_imageRemoved` is only meaningful in edit mode — in add mode it defaults to `false` and is never set to `true` (there is no existing image to remove).
- `updateProductImage(newFile, artisanId, oldUrl)` is called when editing with a pre-existing image AND a new file is selected — it deletes the old Storage file and uploads the new one.
- `uploadProductImage(newFile, artisanId)` is called in add mode OR when editing a product that had no image.
- `deleteProductImage(oldUrl)` is called when the user explicitly removes the image in edit mode with a pre-existing image URL.
- When image is removed: `imageUrl = ''` is set and included in `updateData` so Firestore clears the field.
- The `if (imageUrl != null)` conditional in `updateData` still applies — when image is removed, `imageUrl = ''` (not null) so it IS included in the update.
- All `mounted` checks are preserved from PR31.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `_imageRemoved` referenced before assignment if not properly initialised to `false`; `Image.network` `loadingBuilder` `SizedBox` height must be a fixed value — not `Expanded`; `updateProductImage` parameter order — `(newFile, artisanId, oldUrl)` — confirm matches `StorageService` signature.

2. **Verify `_imageRemoved` field**
   ```
   grep '_imageRemoved' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least four lines — declaration, set in `_removeImage`, check in `_buildImageSection`, check in `_handleSubmit`.

3. **Verify three branches in `_buildImageSection`**
   ```
   grep -c 'if (_selectedImageFile\|if (_uploadedImageUrl\|return GestureDetector' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return `3` — confirming all three branches are present.

4. **Verify `updateProductImage` is called**
   ```
   grep 'updateProductImage' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least one line.

5. **Verify `deleteProductImage` is called**
   ```
   grep 'deleteProductImage' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least one line.

6. **Verify `imageUrl = ''` for removed image**
   ```
   grep "imageUrl = ''" lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least one line — the assignment after `deleteProductImage`.

7. **Verify `_imageRemoved` in `_removeImage`**
   ```
   grep -A5 'void _removeImage' lib/screens/artisan/add_edit_product_screen.dart | grep '_imageRemoved'
   ```
   Must return one line.

8. **Hot reload on emulator — full image management test**
   ```
   flutter run
   ```
   Log in as an approved artisan.

   **Change image test (edit mode):**
   - Open an existing product with an image (created in PR31 testing).
   - Confirm: the existing image shows as a network preview in the "Product Image" section.
   - Tap "Change Image" → gallery opens → select a new image.
   - Confirm: `Image.file` preview replaces the network preview.
   - Tap "Update Product".
   - Confirm: `_isUploadingImage` activates (progress bar visible), upload completes, success snackbar, navigation back.
   - Open Firebase Console → Storage → confirm old file is deleted, new file is present.
   - Open Firebase Console → Firestore → confirm `imageUrl` field updated to new URL.
   - Open `BuyerHomeScreen` — confirm product shows new image.

   **Remove image test (edit mode):**
   - Open an existing product with an image.
   - Tap "Remove" → confirm: network preview disappears, placeholder tap target appears.
   - Tap "Update Product".
   - Confirm: `deleteProductImage` called (no upload progress), success snackbar.
   - Firebase Console → Storage → confirm image file deleted.
   - Firebase Console → Firestore → confirm `imageUrl` field is `''`.
   - `BuyerHomeScreen` → confirm product shows image fallback.

   **Add product with image (regression test):**
   - Tap FAB (+) → add new product with image.
   - Confirm: `uploadProductImage` called (not `updateProductImage`), success.

   **Edit product without changing image (regression test):**
   - Open existing product → change title only → tap "Update Product".
   - Confirm: no Storage operations, only Firestore `title` field updated.

   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/artisan/add_edit_product_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 36
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
git commit -m "PR36: Firebase Storage — Product Image Management"
git push origin pr36-image-management
```

---

## Section 9 – Acceptance Criteria

- [ ] `_AddEditProductScreenState` declares `bool _imageRemoved = false`.
- [ ] `_removeImage()` sets `_imageRemoved = true` via `setState`.
- [ ] `_buildImageSection()` has three branches: `Image.file` preview when `_selectedImageFile != null`, `Image.network` preview when `_uploadedImageUrl != null && !_imageRemoved`, and placeholder when neither.
- [ ] `Image.network` branch in `_buildImageSection()` includes `loadingBuilder` with progress indicator and `errorBuilder` with broken image icon.
- [ ] `_handleSubmit()` calls `StorageService().updateProductImage()` when editing a product that has an existing image URL and a new file is selected.
- [ ] `_handleSubmit()` calls `StorageService().uploadProductImage()` when adding a product or editing one with no prior image URL.
- [ ] `_handleSubmit()` calls `StorageService().deleteProductImage()` when `_imageRemoved == true` in edit mode with a prior image URL, and sets `imageUrl = ''`.
- [ ] After removing an image and updating, Firebase Storage file is deleted and Firestore `imageUrl` field is `''`.
- [ ] Editing a product without changing the image does not trigger any Storage operations.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR36 for CraftBridge. I wired `StorageService.updateProductImage()` and `deleteProductImage()` into `AddEditProductScreen` — completing the full product image lifecycle for edit mode and giving artisans the ability to change or remove product images on existing listings."

2. **`_imageRemoved` flag design:** "PR21 added `_selectedImageFile` to track a newly picked file. PR36 adds `_imageRemoved` to track an explicit removal — these are two distinct user actions with different Storage outcomes. Without `_imageRemoved`, there's no way to distinguish 'user didn't change the image' (no Storage operation) from 'user removed the image' (delete Storage file and clear Firestore field). The boolean flag makes this distinction explicit."

3. **Three-branch `_buildImageSection()`:** "The image section now has three visual states corresponding to three data states. Branch 1: `_selectedImageFile != null` — user picked a new file, show `Image.file` preview. Branch 2: `_uploadedImageUrl != null && !_imageRemoved` — existing product image, show `Image.network` preview. Branch 3: neither — no image, show the placeholder tap target. The branches evaluate in order so the newest selection always takes priority."

4. **`Image.network` branch in edit mode:** "When an artisan opens a product for editing, `initState()` sets `_uploadedImageUrl` from `widget.product!.imageUrl`. The `_buildImageSection()` Branch 2 then shows the existing Firebase Storage URL as a network image preview. This gives the artisan visual confirmation of the current product image before they decide to change or remove it."

5. **`updateProductImage` vs `uploadProductImage` routing:** "In `_handleSubmit()`, the image upload routing is: if editing AND has existing URL AND has new file → `updateProductImage` (deletes old, uploads new). If not editing OR has no existing URL → `uploadProductImage` (fresh upload only). `updateProductImage` from PR27 is a composition of `deleteProductImage` + `uploadProductImage` — calling it correctly avoids orphaned Storage files."

6. **`deleteProductImage` and `imageUrl = ''`:** "When the artisan removes an image in edit mode, `_handleSubmit()` calls `deleteProductImage(_uploadedImageUrl!)` — the PR27 implementation handles the `object-not-found` case silently. After deletion, `imageUrl` is set to `''` — an empty string, not null. The update data map includes `'imageUrl': imageUrl` (which is `''`) so Firestore clears the field. `ProductCard` and `OrderCard` handle empty `imageUrl` with their `_buildImageFallback()` methods."

7. **No Storage operation when image unchanged:** "If `_selectedImageFile == null && _imageRemoved == false`, neither upload nor delete runs. The `updateData` map in edit mode uses `if (imageUrl != null) 'imageUrl': imageUrl`. Since `imageUrl` is still `_uploadedImageUrl` (the original URL), it IS included in the update but contains the unchanged value — a harmless no-op write. For maximum efficiency, we could also skip `imageUrl` entirely if it hasn't changed, but the simpler code is more readable."

8. **`mounted` checks in async flow:** "The `_handleSubmit()` method has multiple `await` calls — `updateProductImage`, `uploadProductImage`, `deleteProductImage`, and `productProvider.updateProduct`. Each `await` is a potential disposal point. The `if (!mounted) return` guards after the image block and before provider calls ensure `setState` and `ScaffoldMessenger` are never called on a disposed widget."

9. **Emulator demonstration of all three paths:** "On the emulator: editing a product with an existing image and selecting a new one triggers the upload progress bar, then updates the product card image across both `ManageProductsScreen` and `BuyerHomeScreen`. Removing an image shows the fallback icon on the card. Adding a product with an image calls `uploadProductImage` — same as before PR36. Editing without touching the image updates only the text fields with no Storage activity."

10. **What's Next:** "PR37 will wire the order status update flow — connecting the status bottom sheet in `ArtisanOrdersScreen` to `FirestoreService.updateOrderStatus()` via `OrderProvider`, replacing the stub snackbar with a real Firestore write."