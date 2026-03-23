# PR21 – Local State — Product Form State + Image Picker State

**Project:** CraftBridge
**PR Number:** 21 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Add `image_picker` integration to `AddEditProductScreen` — local image file state, image preview, upload progress placeholder, and form dirty tracking.

---

## Section 2 – Assignments Covered

- Assignment 3.21 — Local State — Product Form State + Image Picker State

---

## Section 3 – Objective

This PR wires the `image_picker` package into `AddEditProductScreen`, replacing the tap-hint placeholder from PR20 with a real image selection flow. When an artisan taps the image area, the device gallery opens and the selected image is shown as a preview inside the container. Local state tracks the selected `File`, whether an upload is in progress, and whether the form has unsaved changes (dirty tracking). The actual Firebase Storage upload is wired in PR24 — in this PR, the selected file is stored in state and a progress placeholder is shown. An `_isDirty` flag gates a back-navigation confirmation dialog, preventing accidental data loss when the artisan has started filling in the form.

---

## Section 4 – Architecture Context

```
AddEditProductScreen (_AddEditProductScreenState)
  │
  ├── New state fields (this PR):
  │     ├── File? _selectedImageFile      ← picked from gallery
  │     ├── bool _isUploadingImage        ← upload in progress (stub)
  │     └── bool _isDirty                 ← form has unsaved changes
  │
  ├── _buildImageSection() (replaces _buildImagePlaceholder)
  │     ├── _selectedImageFile == null → placeholder tap target
  │     └── _selectedImageFile != null → Image.file preview + change/remove buttons
  │
  ├── _pickImage()
  │     └── ImagePicker().pickImage(source: ImageSource.gallery)
  │     └── sets _selectedImageFile via setState
  │
  ├── _onFieldChanged() → sets _isDirty = true via setState
  │
  └── WillPopScope (wrap Scaffold)
        └── if _isDirty → showDialog confirmation
        └── if !_isDirty → allow pop

pubspec.yaml:
  image_picker: ^1.1.2   ← added this PR

Packages used:
  dart:io                ← File type
  image_picker           ← ImagePicker, XFile, ImageSource
```

This PR sits after `AddEditProductScreen` form structure (PR20) and before reusable widgets (PR22). The `_selectedImageFile` field added here is consumed by `StorageService.uploadProductImage()` in PR24 — the file reference is already in the right place, only the upload call is missing.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/artisan/add_edit_product_screen.dart`
- `pubspec.yaml` — add `image_picker` dependency

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

---

## Section 6 – Technical Requirements

---

### `pubspec.yaml`

Add `image_picker: ^1.1.2` under the `dependencies:` section, after `provider: ^6.1.2`.

After editing, the agent must run:
```
flutter pub get
```

---

### `lib/screens/artisan/add_edit_product_screen.dart`

Modify the PR20 implementation with targeted additions. The form structure from PR20 is preserved — only the image section, new state fields, new methods, and back navigation guard are added or modified.

---

**New imports to add:**

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
```

---

**New state fields to add to `_AddEditProductScreenState`** (after `bool _isLoading`):

```dart
File? _selectedImageFile;
bool _isUploadingImage = false;
bool _isDirty = false;
```

---

**`initState()` update:**

Add `_addDirtyListeners()` call at the end of `initState()`:

```dart
@override
void initState() {
  super.initState();
  if (_isEditMode) {
    _titleController.text = widget.product!['title'] as String;
    _descriptionController.text =
        widget.product!['description'] as String? ?? '';
    _priceController.text =
        (widget.product!['price'] as double).toStringAsFixed(0);
    _stockController.text = widget.product!['stock'].toString();
    _selectedCategory = widget.product!['category'] as String?;
  }
  _addDirtyListeners();
}
```

---

**`_addDirtyListeners()` method:**

```dart
void _addDirtyListeners() {
  _titleController.addListener(_markDirty);
  _descriptionController.addListener(_markDirty);
  _priceController.addListener(_markDirty);
  _stockController.addListener(_markDirty);
}
```

---

**`_markDirty()` method:**

```dart
void _markDirty() {
  if (!_isDirty) {
    setState(() => _isDirty = true);
  }
}
```

---

**`dispose()` update:**

Remove listeners before disposing controllers:

```dart
@override
void dispose() {
  _titleController.removeListener(_markDirty);
  _descriptionController.removeListener(_markDirty);
  _priceController.removeListener(_markDirty);
  _stockController.removeListener(_markDirty);
  _titleController.dispose();
  _descriptionController.dispose();
  _priceController.dispose();
  _stockController.dispose();
  super.dispose();
}
```

---

**`_pickImage()` method:**

```dart
Future<void> _pickImage() async {
  try {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile == null) return;
    setState(() {
      _selectedImageFile = File(pickedFile.path);
      _isDirty = true;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open image picker: $e')),
    );
  }
}
```

- `maxWidth: 1024`, `maxHeight: 1024`: constrains the picked image to 1024px on the longest side — reduces upload size in PR24.
- `imageQuality: 85`: JPEG compression quality — balances visual quality against file size.
- `XFile` is the `image_picker` cross-platform file abstraction — convert to `dart:io File` via `File(pickedFile.path)` for use with Firebase Storage in PR24.

---

**`_removeImage()` method:**

```dart
void _removeImage() {
  setState(() {
    _selectedImageFile = null;
    _isDirty = true;
  });
}
```

---

**`_buildImageSection()` method** (replaces `_buildImagePlaceholder()`):

```dart
Widget _buildImageSection() {
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
  return GestureDetector(
    onTap: _pickImage,
    child: Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
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
            color:
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
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

Key differences from PR20's `_buildImagePlaceholder()`:
- When `_selectedImageFile != null`: renders `Image.file` preview (200px tall, cover fit), "Change Image" and "Remove" `OutlinedButton.icon` row, and optional upload progress indicator.
- When `_selectedImageFile == null`: renders the tap-target container — identical visual to PR20 but `onTap` now calls `_pickImage()` instead of showing a stub snackbar. The PR21 explanation text is removed.
- Remove buttons are disabled when `_isUploadingImage` is true.

---

**`_handleSubmit()` update:**

Add a dirty flag reset at the end of the success path, before `Navigator.pop`:

```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  await Future.delayed(const Duration(milliseconds: 500));
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
}
```

Setting `_isDirty = false` before `Navigator.pop` prevents the `WillPopScope` confirmation dialog from firing when the pop is triggered programmatically by a successful submit.

---

**`build()` update — two changes:**

**Change 1:** Replace `_buildImagePlaceholder()` call with `_buildImageSection()` call (item 3 in the Column children).

**Change 2:** Wrap the `Scaffold` in a `PopScope` widget for back-navigation dirty guard:

```dart
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: !_isDirty,
    onPopInvoked: (didPop) async {
      if (didPop) return;
      final bool? shouldPop = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Product Image',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  Text(
                    'Product Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Title',
                    hint: 'e.g. Hand-painted Ceramic Vase',
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required.';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Description',
                    hint:
                        'Describe your product — materials, dimensions, story',
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required.';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Price (₹)',
                          hint: '0',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Price is required.';
                            }
                            final price =
                                double.tryParse(value.trim());
                            if (price == null) {
                              return 'Enter a valid number.';
                            }
                            if (price <= 0) {
                              return 'Price must be greater than 0.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Stock',
                          hint: '0',
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Stock is required.';
                            }
                            final stock =
                                int.tryParse(value.trim());
                            if (stock == null) {
                              return 'Enter a whole number.';
                            }
                            if (stock < 0) {
                              return 'Stock cannot be negative.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 32),
                  CustomButton(
                    label:
                        _isEditMode ? 'Update Product' : 'Add Product',
                    onPressed: _isLoading ? null : _handleSubmit,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

**Note on `PopScope`:** `PopScope` replaces the deprecated `WillPopScope` in Flutter 3.12+. `canPop: !_isDirty` prevents the default back navigation when the form is dirty. `onPopInvoked` is called with `didPop: false` when `canPop` is false and the user attempts to pop — this is where the confirmation dialog is shown. If the user confirms, `Navigator.pop(context)` is called manually.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/add_edit_product_screen.dart` | Updated with `image_picker` integration, image preview, change/remove buttons, upload progress placeholder, `_isDirty` tracking with `PopScope` back-navigation guard |
| 2 | `pubspec.yaml` | `image_picker: ^1.1.2` added under dependencies |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must make targeted modifications to `lib/screens/artisan/add_edit_product_screen.dart` and add one dependency to `pubspec.yaml`.

---

**Step 1: Update `pubspec.yaml`**

Add `image_picker: ^1.1.2` to the `dependencies:` section after `provider: ^6.1.2`. Then run:
```
flutter pub get
```
Confirm it resolves without errors.

---

**Step 2: Modify `lib/screens/artisan/add_edit_product_screen.dart`**

Make the following targeted changes to the PR20 implementation in order:

**Change 1 — Add imports:**
Add `import 'dart:io';` and `import 'package:image_picker/image_picker.dart';` to the import block.

**Change 2 — Add state fields:**
After `bool _isLoading = false;`, add three new fields:
```dart
File? _selectedImageFile;
bool _isUploadingImage = false;
bool _isDirty = false;
```

**Change 3 — Update `initState()`:**
Add `_addDirtyListeners();` as the last line of `initState()`.

**Change 4 — Add `_addDirtyListeners()` method:**
Add the method after `initState()`.

**Change 5 — Add `_markDirty()` method:**
Add the method after `_addDirtyListeners()`.

**Change 6 — Update `dispose()`:**
Replace the PR20 `dispose()` with the updated version that removes listeners before disposing controllers.

**Change 7 — Add `_pickImage()` method:**
Add the method after `dispose()`.

**Change 8 — Add `_removeImage()` method:**
Add the method after `_pickImage()`.

**Change 9 — Add `_buildImageSection()` method:**
Add the method after `_removeImage()`. Remove the PR20 `_buildImagePlaceholder()` method entirely — it is replaced by `_buildImageSection()`.

**Change 10 — Update `_handleSubmit()`:**
Add `_isDirty = false` to the `setState` call before `Navigator.pop`.

**Change 11 — Update `build()`:**
- Replace `_buildImagePlaceholder()` call with `_buildImageSection()`.
- Wrap the `Scaffold` in `PopScope` with `canPop: !_isDirty` and `onPopInvoked` as specified in Section 6.

**Critical implementation rules:**
- `PopScope` wraps the entire `Scaffold` — it is the outermost widget returned by `build()`.
- `canPop: !_isDirty` — when `_isDirty` is true, `canPop` is false, preventing automatic pops.
- `_markDirty()` uses `if (!_isDirty)` guard before calling `setState` — prevents unnecessary rebuilds when the form is already dirty.
- `_pickImage()` wraps `ImagePicker().pickImage()` in try-catch — the picker can throw platform exceptions on simulators.
- After a successful `_handleSubmit()`, `_isDirty` is set to `false` before `Navigator.pop(context)` to prevent the `PopScope` dialog from intercepting the programmatic pop.
- The `_buildImageSection()` placeholder path (when `_selectedImageFile == null`) must NOT show the PR20 stub snackbar message — it calls `_pickImage()` directly.
- `Image.file` in the preview branch uses `fit: BoxFit.cover` and `height: 200` — maintains aspect ratio with a fixed height.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Confirm `image_picker` resolves without errors.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `XFile` requires `image_picker` import; `File` requires `dart:io` import; `PopScope` requires Flutter 3.12+ (verify Flutter version); `onPopInvoked` parameter is `bool didPop` — must match the signature exactly.

3. **Verify `image_picker` in `pubspec.yaml`**
   ```
   grep 'image_picker' pubspec.yaml
   ```
   Must return one line with the version constraint.

4. **Verify new state fields**
   ```
   grep '_selectedImageFile\|_isUploadingImage\|_isDirty' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least 6 lines — declarations plus usages.

5. **Verify `PopScope` is present**
   ```
   grep 'PopScope' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least two lines — `PopScope(` and `canPop:`.

6. **Verify `_buildImagePlaceholder` is removed**
   ```
   grep '_buildImagePlaceholder' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return no output — the PR20 method must be fully replaced.

7. **Verify `_buildImageSection` is present**
   ```
   grep '_buildImageSection' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least two lines — definition and call in `build()`.

8. **Verify dirty listeners are added and removed**
   ```
   grep 'addListener\|removeListener' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least 8 lines — 4 `addListener` calls and 4 `removeListener` calls.

9. **Hot reload on emulator — image picker test**
   ```
   flutter run
   ```
   Log in as artisan → "My Products" → FAB (+).
   Confirm:
   - Image section shows the tap-target placeholder with camera icon and "Tap to add product image".
   - Tapping the placeholder opens the device gallery.
   - Selecting an image shows the 200px preview with "Change Image" and "Remove" buttons below.
   - Tapping "Change Image" re-opens the gallery.
   - Tapping "Remove" returns to the placeholder tap target.
   - After selecting an image, `_isDirty` is true — pressing the system back button shows the "Discard Changes?" dialog.
   - Tapping "Keep Editing" dismisses the dialog and stays on the screen.
   - Tapping "Discard" navigates back to `ManageProductsScreen`.
   - After typing in the title field, pressing back shows the same dialog.
   - Successfully submitting the form navigates back without showing the dialog.
   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/screens/artisan/add_edit_product_screen.dart`, `pubspec.yaml`, `pubspec.lock`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 21
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
git commit -m "PR21: Local State — Product Form State + Image Picker State"
git push origin pr21-image-picker
```

---

## Section 9 – Acceptance Criteria

- [ ] `pubspec.yaml` contains `image_picker: ^1.1.2` and `flutter pub get` resolves successfully.
- [ ] `_AddEditProductScreenState` declares `File? _selectedImageFile`, `bool _isUploadingImage`, and `bool _isDirty`.
- [ ] `_addDirtyListeners()` adds `_markDirty` as a listener to all four `TextEditingController` instances.
- [ ] `dispose()` calls `removeListener(_markDirty)` on all four controllers before disposing them.
- [ ] `_pickImage()` calls `ImagePicker().pickImage()` with `maxWidth: 1024`, `maxHeight: 1024`, `imageQuality: 85`, wraps in try-catch, and sets `_selectedImageFile` via `setState`.
- [ ] `_buildImageSection()` renders the image preview with "Change Image" and "Remove" buttons when `_selectedImageFile != null`, and the tap-target placeholder when null.
- [ ] The `LinearProgressIndicator` and "Uploading image..." text are shown when `_isUploadingImage` is true.
- [ ] `build()` wraps `Scaffold` in `PopScope` with `canPop: !_isDirty` and `onPopInvoked` showing a "Discard Changes?" `AlertDialog`.
- [ ] Successful form submission sets `_isDirty = false` before `Navigator.pop` — no discard dialog on submit.
- [ ] `_buildImagePlaceholder()` from PR20 is fully removed and replaced by `_buildImageSection()`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR21 for CraftBridge. I wired the `image_picker` package into `AddEditProductScreen` — replacing the static placeholder with a real image selection flow, adding a 200px preview with change and remove controls, implementing dirty state tracking across all form fields, and adding a `PopScope` back-navigation guard to prevent accidental data loss."

2. **`image_picker` package and `XFile` to `File` conversion:** "`image_picker` returns an `XFile` — a cross-platform file abstraction that works on both Android and iOS. Firebase Storage's `putFile()` method (used in PR24) expects a `dart:io File`. The conversion is a single line: `File(pickedFile.path)`. `maxWidth: 1024` and `imageQuality: 85` reduce the file size before it reaches the upload step — important for keeping Storage costs low on a platform where artisans are uploading product photos."

3. **`_buildImageSection()` dual-state design:** "The image section has two visual states: the placeholder tap target when no image is selected, and the preview with action buttons when an image is selected. Both are returned from a single `_buildImageSection()` method using an `if` branch. This keeps the `build()` method clean — it calls `_buildImageSection()` once and the method handles both states internally."

4. **`Image.file` preview:** "`Image.file(_selectedImageFile!)` renders a local file directly — no URL, no network call, no Firebase yet. `fit: BoxFit.cover` fills the 200px height container while maintaining aspect ratio. `ClipRRect` with the card border radius ensures the image corners match the container's rounded corners."

5. **Dirty state tracking with `addListener`:** "`TextEditingController` has an `addListener` API that fires on every text change. Rather than adding `onChanged` callbacks to every `CustomTextField` — which would require restructuring the widget tree — the dirty listeners are added in `initState()` and removed in `dispose()`. `_markDirty()` uses an `if (!_isDirty)` guard so it only calls `setState` once — the first time any field is changed — rather than on every keystroke."

6. **`PopScope` replaces `WillPopScope`:** "`WillPopScope` was deprecated in Flutter 3.12. `PopScope` is its replacement. `canPop: !_isDirty` prevents the framework from popping the route when the form is dirty — the user's back gesture is intercepted. `onPopInvoked` is called with `didPop: false` when the pop was blocked, which is where the confirmation dialog is shown. If the user confirms discard, `Navigator.pop(context)` is called manually."

7. **Why `_isDirty = false` before `Navigator.pop` in `_handleSubmit`:** "After a successful submit, `Navigator.pop(context)` is called to return to `ManageProductsScreen`. But if `_isDirty` is still true at that point, `canPop` is false — `PopScope` would intercept the programmatic pop and show the discard dialog, which is nonsensical after a successful save. Setting `_isDirty = false` in the `setState` call before `pop` ensures `canPop` becomes true and the pop proceeds unimpeded."

8. **`_isUploadingImage` progress indicator:** "`_isUploadingImage` is a stub in this PR — it defaults to false and is never set to true. Its purpose is to scaffold the UI that PR24 will activate. When PR24 wires the actual `StorageService.uploadProductImage()` call, it will set `_isUploadingImage = true` before the upload and `false` after. The `LinearProgressIndicator` and "Uploading image..." text are already in place — PR24 just needs to toggle the flag."

9. **Disable during upload:** "The 'Change Image' and 'Remove' buttons are disabled when `_isUploadingImage` is true — `onPressed: _isUploadingImage ? null : _pickImage`. This prevents the artisan from changing the image while an upload is in progress, which would leave the upload referencing a file that no longer matches the UI."

10. **What's Next:** "PR22 will implement the three reusable widgets — `ProductCard`, `OrderCard`, and `CartItemTile` — that are consumed by the buyer browsing, artisan order, and cart screens respectively."