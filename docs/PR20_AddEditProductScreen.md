# PR20 – Forms — AddEditProductScreen

**Project:** CraftBridge
**PR Number:** 20 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `AddEditProductScreen` with a complete add/edit mode form covering all product fields, category dropdown, and form submission scaffold.

---

## Section 2 – Assignments Covered

- Assignment 3.20 — Forms — AddEditProductScreen

---

## Section 3 – Objective

This PR implements `AddEditProductScreen` — the form screen used by artisans to create new products and edit existing ones. The screen operates in two modes: add mode (no product passed in) and edit mode (existing product data pre-populated). All product fields from the locked `ProductModel` schema are present — title, description, price, category, stock, and image placeholder. The form uses `CustomTextField` and validates all required fields. Image picking is scaffolded as a placeholder tap target in this PR and fully wired to `StorageService` in PR24. Form submission in this PR calls `_handleSubmit()` which shows a stub snackbar — live Firestore writes are wired in PR31 when `ProductProvider` is fully implemented.

---

## Section 4 – Architecture Context

```
ManageProductsScreen
    └── FAB (+) → AddEditProductScreen (add mode)
    └── (future PR31) product card tap → AddEditProductScreen (edit mode)

AddEditProductScreen modes:
  Add mode:  widget.product == null
             AppBar title: 'Add Product'
             all fields empty
             submit: _handleSubmit() → stub snackbar (PR31: creates product)

  Edit mode: widget.product != null
             AppBar title: 'Edit Product'
             all fields pre-populated from widget.product
             submit: _handleSubmit() → stub snackbar (PR31: updates product)

Form fields (matching ProductModel locked schema):
  title        → CustomTextField (required)
  description  → CustomTextField (required, multiline)
  price        → CustomTextField (required, numeric keyboard)
  category     → DropdownButtonFormField (AppConstants.productCategories)
  stock        → CustomTextField (required, numeric keyboard)
  image        → tappable placeholder (wired to image picker in PR21)

Files modified this PR:
  lib/screens/artisan/add_edit_product_screen.dart ← full implementation
```

This PR sits after `AppTheme` completion (PR19) and before local image picker state (PR21). The form structure established here is the scaffold that PR21 adds image picker state to, without restructuring the widget tree.

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

---

### `lib/screens/artisan/add_edit_product_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `AddEditProductScreen` and `_AddEditProductScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/widgets/custom_text_field.dart`
- `package:craft_bridge/widgets/custom_button.dart`

---

**`AddEditProductScreen` class:**

```dart
class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}
```

The `product` parameter is `Map<String, dynamic>?` in this PR because `ProductModel` is not yet consumed by this screen (no Provider wiring until PR31). In PR31 this parameter type will be updated to `ProductModel?`. Using a map now allows the screen to be tested with the stub data from `ManageProductsScreen` without requiring Provider.

---

**`_AddEditProductScreenState` fields:**

```dart
final _formKey = GlobalKey<FormState>();
final _titleController = TextEditingController();
final _descriptionController = TextEditingController();
final _priceController = TextEditingController();
final _stockController = TextEditingController();
String? _selectedCategory;
bool _isLoading = false;
bool get _isEditMode => widget.product != null;
```

---

**`initState()` method:**

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
    _stockController.text =
        widget.product!['stock'].toString();
    _selectedCategory = widget.product!['category'] as String?;
  }
}
```

---

**`dispose()` method:**

```dart
@override
void dispose() {
  _titleController.dispose();
  _descriptionController.dispose();
  _priceController.dispose();
  _stockController.dispose();
  super.dispose();
}
```

---

**`_handleSubmit()` method:**

```dart
Future<void> _handleSubmit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  await Future.delayed(const Duration(milliseconds: 500));
  setState(() => _isLoading = false);
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

The `Future.delayed` simulates async work. In PR31 this method will be replaced with a real `ProductProvider.addProduct()` or `ProductProvider.updateProduct()` call.

---

**`_buildImagePlaceholder()` method:**

```dart
Widget _buildImagePlaceholder() {
  return GestureDetector(
    onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker — implemented in PR21'),
        ),
      );
    },
    child: Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
          const SizedBox(height: 4),
          Text(
            '(Image picker wired in PR21)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.35),
                ),
          ),
        ],
      ),
    ),
  );
}
```

---

**`_buildCategoryDropdown()` method:**

```dart
Widget _buildCategoryDropdown() {
  return DropdownButtonFormField<String>(
    value: _selectedCategory,
    decoration: const InputDecoration(
      labelText: 'Category',
      hintText: 'Select a category',
    ),
    items: AppConstants.productCategories
        .map(
          (category) => DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          ),
        )
        .toList(),
    onChanged: (value) => setState(() => _selectedCategory = value),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please select a category.';
      }
      return null;
    },
  );
}
```

`DropdownButtonFormField` participates in the `Form` validation — its `validator` is called by `_formKey.currentState!.validate()` alongside all `CustomTextField` validators. The `InputDecoration` applied here uses `const` because only `labelText` and `hintText` are set — the border, fill, and padding come from `AppTheme.inputDecorationTheme`.

---

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with `title: Text(_isEditMode ? 'Edit Product' : 'Add Product')`
- `body`: `SafeArea` wrapping `SingleChildScrollView` wrapping `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` wrapping a `Form` with `key: _formKey` wrapping a `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch` and `children`:

  1. `Text('Product Image', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`
  2. `const SizedBox(height: 8)`
  3. `_buildImagePlaceholder()`
  4. `const SizedBox(height: 24)`
  5. `Text('Product Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`
  6. `const SizedBox(height: 12)`
  7. `CustomTextField(label: 'Title', hint: 'e.g. Hand-painted Ceramic Vase', controller: _titleController, textCapitalization: TextCapitalization.sentences, validator: (value) { if (value == null || value.trim().isEmpty) return 'Title is required.'; if (value.trim().length < 3) return 'Title must be at least 3 characters.'; return null; })`
  8. `const SizedBox(height: 16)`
  9. `CustomTextField(label: 'Description', hint: 'Describe your product — materials, dimensions, story', controller: _descriptionController, maxLines: 4, textCapitalization: TextCapitalization.sentences, validator: (value) { if (value == null || value.trim().isEmpty) return 'Description is required.'; if (value.trim().length < 10) return 'Description must be at least 10 characters.'; return null; })`
  10. `const SizedBox(height: 16)`
  11. `Row` with `children`:
      - `Expanded` child: `CustomTextField(label: 'Price (₹)', hint: '0', controller: _priceController, keyboardType: TextInputType.number, validator: (value) { if (value == null || value.trim().isEmpty) return 'Price is required.'; final price = double.tryParse(value.trim()); if (price == null) return 'Enter a valid number.'; if (price <= 0) return 'Price must be greater than 0.'; return null; })`
      - `const SizedBox(width: 12)`
      - `Expanded` child: `CustomTextField(label: 'Stock', hint: '0', controller: _stockController, keyboardType: TextInputType.number, validator: (value) { if (value == null || value.trim().isEmpty) return 'Stock is required.'; final stock = int.tryParse(value.trim()); if (stock == null) return 'Enter a whole number.'; if (stock < 0) return 'Stock cannot be negative.'; return null; })`
  12. `const SizedBox(height: 16)`
  13. `_buildCategoryDropdown()`
  14. `const SizedBox(height: 32)`
  15. `CustomButton(label: _isEditMode ? 'Update Product' : 'Add Product', onPressed: _isLoading ? null : _handleSubmit, isLoading: _isLoading)`
  16. `const SizedBox(height: 24)`

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/add_edit_product_screen.dart` | Full `AddEditProductScreen` with add/edit mode, all five product field groups, category dropdown with validation, image placeholder, and `_handleSubmit` stub |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must replace the PR18 minimal stub in `lib/screens/artisan/add_edit_product_screen.dart` with the full implementation specified in Section 6.

---

**File: `lib/screens/artisan/add_edit_product_screen.dart`**

Replace the PR18 stub entirely. Write the complete file in this order:

1. All import statements as specified.
2. `AddEditProductScreen extends StatefulWidget` with optional `product` parameter (`Map<String, dynamic>? product`) and `const` constructor.
3. `_AddEditProductScreenState` containing in order:
   - All fields: `_formKey`, four `TextEditingController` instances, `_selectedCategory`, `_isLoading`, `_isEditMode` getter.
   - `initState()` — pre-populates controllers when `_isEditMode` is true.
   - `dispose()` — disposes all four controllers.
   - `_handleSubmit()` — validates form, sets loading, simulates async delay, shows success snackbar, pops navigation.
   - `_buildImagePlaceholder()` — `GestureDetector` wrapping a 180px tall `Container` with photo icon and tap hint.
   - `_buildCategoryDropdown()` — `DropdownButtonFormField<String>` with all `AppConstants.productCategories` as items and required validator.
   - `build()` — `Scaffold` with dynamic `AppBar` title, `SingleChildScrollView` > `Padding` > `Form` > `Column` with all 16 children in the exact order specified.

**Critical implementation rules:**

- `_isEditMode` is a computed getter `bool get _isEditMode => widget.product != null` — not a stored field. It recomputes every time it is accessed, ensuring it reflects the current `widget.product` value.
- `initState()` pre-populates only when `_isEditMode` is true. For price, use `(widget.product!['price'] as double).toStringAsFixed(0)` — displays `1200.0` as `1200`, not `1200.0`.
- The price and stock fields are placed side by side in a `Row` with two `Expanded` children and a 12dp `SizedBox` between them.
- `DropdownButtonFormField` uses `const InputDecoration(labelText: 'Category', hintText: 'Select a category')` — only these two properties, relying on `AppTheme.inputDecorationTheme` for the rest.
- `_handleSubmit()` uses `Future.delayed(const Duration(milliseconds: 500))` as a stub for async work — this simulates the latency of a real Firestore write so the loading state is visually testable.
- The `CustomButton` at the bottom is NOT wrapped in a `Consumer<AuthProvider>` — loading state is managed by local `_isLoading`, not a Provider, in this PR.
- `mounted` check after `await Future.delayed` is required — if the user navigates away during the simulated delay, the `setState` and `ScaffoldMessenger` calls must be skipped.
- Section label `Text` widgets ('Product Image', 'Product Details') use `titleMedium` with `fontWeight: FontWeight.bold` — they are section dividers, not form field labels.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `DropdownButtonFormField<String>` type parameter must be explicit; `double.tryParse` returns `double?` — null check required before comparison; `int.tryParse` same pattern; `const InputDecoration(...)` — only valid when all properties are const-compatible.

2. **Verify `_isEditMode` getter**
   ```
   grep 'get _isEditMode' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line with the getter declaration.

3. **Verify four controllers are declared**
   ```
   grep -c 'TextEditingController()' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return `4` — title, description, price, stock.

4. **Verify `DropdownButtonFormField` is present**
   ```
   grep 'DropdownButtonFormField' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least two lines — declaration and usage.

5. **Verify `AppConstants.productCategories` is used in dropdown**
   ```
   grep 'AppConstants.productCategories' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line.

6. **Verify validator count**
   ```
   grep -c 'validator:' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return `5` — title, description, price, stock, and category.

7. **Verify `_handleSubmit` has `mounted` check**
   ```
   grep 'mounted' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return at least one line.

8. **Verify `Future.delayed` stub is present**
   ```
   grep 'Future.delayed' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line.

9. **Hot reload on emulator — add mode test**
   ```
   flutter run
   ```
   Log in as artisan → "My Products" → FAB (+).
   Confirm:
   - `AddEditProductScreen` opens with "Add Product" app bar title.
   - Image placeholder (180px tall) is visible with camera icon and tap hint.
   - Tapping the image placeholder shows "Image picker — implemented in PR21" snackbar.
   - "Product Image" and "Product Details" section labels visible.
   - Five form controls visible: Title, Description, Price + Stock (side by side), Category dropdown.
   - Category dropdown opens `AppConstants.productCategories` options: Pottery, Textiles, Jewellery, Woodwork, Paintings, Leather, Other.
   - "Add Product" button at bottom.
   - Tapping "Add Product" with empty fields shows validators on all five fields simultaneously.
   - Filling all fields and tapping "Add Product" shows loading state (spinner in button, button disabled) for ~500ms then snackbar "Product added successfully." then navigation back to `ManageProductsScreen`.

10. **Hot reload on emulator — edit mode test**

    From `ManageProductsScreen`, trigger edit mode by temporarily modifying the FAB to pass a stub product:
    ```dart
    MaterialPageRoute(builder: (_) => AddEditProductScreen(product: _stubProducts[0]))
    ```
    Confirm:
    - `AddEditProductScreen` opens with "Edit Product" app bar title.
    - All fields pre-populated with stub product data.
    - "Update Product" button label instead of "Add Product".
    - Submit shows "Product updated successfully." snackbar.

    Revert the temporary FAB modification after testing.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/artisan/add_edit_product_screen.dart` should appear.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 20
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
git commit -m "PR20: Forms — AddEditProductScreen"
git push origin pr20-add-edit-product
```

---

## Section 9 – Acceptance Criteria

- [ ] `AddEditProductScreen` is a `StatefulWidget` with an optional `Map<String, dynamic>? product` parameter.
- [ ] `_isEditMode` is a computed getter (`bool get _isEditMode => widget.product != null`), not a stored field.
- [ ] `initState()` pre-populates all four controllers and `_selectedCategory` when `_isEditMode` is true.
- [ ] `dispose()` disposes all four `TextEditingController` instances.
- [ ] `build()` renders `AppBar` with title `'Edit Product'` when `_isEditMode` is true and `'Add Product'` otherwise.
- [ ] The form contains a 180px image placeholder, Title, Description, Price + Stock (side-by-side `Row`), and Category dropdown — in that order.
- [ ] All five fields have validators: Title (required, min 3), Description (required, min 10), Price (required, positive number), Stock (required, non-negative integer), Category (required selection).
- [ ] `_buildCategoryDropdown()` uses `AppConstants.productCategories` and has a `validator` that requires a selection.
- [ ] `_handleSubmit()` validates the form, shows a 500ms loading state, shows the correct mode-specific success snackbar, and pops navigation.
- [ ] The `CustomButton` label is `'Update Product'` in edit mode and `'Add Product'` in add mode.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR20 for CraftBridge. I implemented `AddEditProductScreen` — the dual-mode product form used by artisans to create new listings and edit existing ones — with all five product field groups, a category dropdown wired to `AppConstants`, full validators, and a loading-state submit flow."

2. **Dual-mode design via `_isEditMode` getter:** "The screen operates in two modes controlled by a single optional parameter — `product`. If `product` is null, the screen is in add mode; if it's non-null, it's in edit mode. `_isEditMode` is a computed getter rather than a stored boolean — `bool get _isEditMode => widget.product != null`. Computed getters are always in sync with the underlying data and cannot go stale the way a stored bool can."

3. **`initState()` pre-population:** "`initState()` is the right lifecycle method to pre-populate `TextEditingController` values. It runs once when the state object is created — before the first build. Pre-populating in `build()` would reset the fields on every rebuild, overwriting whatever the user has typed. Pre-populating in `initState()` sets initial values once and lets the user edit from there."

4. **Price as `toStringAsFixed(0)`:** "The price controller is pre-populated with `toStringAsFixed(0)` — this converts `1200.0` to `'1200'` rather than `'1200.0'`. Artisans don't think in floating-point notation. The validator parses it back with `double.tryParse` — `tryParse` is used instead of `parse` because `parse` throws on invalid input while `tryParse` returns null, which is safer to handle in a validator closure."

5. **Price and stock side by side:** "Price and stock are placed in a `Row` with two `Expanded` children and a 12dp gap. `Expanded` gives each field exactly half the available horizontal space. This is the right layout for two related numeric fields — it keeps them visually grouped and saves vertical space on a scrollable form."

6. **`DropdownButtonFormField` in a `Form`:** "`DropdownButtonFormField` is the correct widget for a validated dropdown — it participates in `Form` validation just like `TextFormField`. When `_formKey.currentState!.validate()` is called, the dropdown's `validator` fires along with all `CustomTextField` validators. The `InputDecoration` on the dropdown uses `const` with only `labelText` and `hintText` — all other decoration properties come from `AppTheme.inputDecorationTheme`."

7. **Image placeholder design:** "The image placeholder is a `GestureDetector` wrapping a styled `Container`. Its `onTap` shows a snackbar explaining the image picker is in PR21 — this is intentional developer communication baked into the UI. In PR21, the `GestureDetector.onTap` will call `image_picker` instead of showing the snackbar, and the container will display the selected image rather than the placeholder icon."

8. **`_handleSubmit()` stub pattern:** "The submit handler validates the form, sets `_isLoading = true`, waits 500ms (simulating Firestore latency), clears loading, checks `mounted`, shows a mode-specific snackbar, and pops. The `mounted` check is critical — if the user somehow navigates away during the 500ms delay, calling `setState` or `ScaffoldMessenger.of(context)` on a disposed widget throws an error."

9. **Local `_isLoading` vs Provider `isLoading`:** "This PR manages loading state with a local `_isLoading` bool rather than `ProductProvider.isLoading`. That's correct for now because `ProductProvider` isn't wired yet. In PR31, `_handleSubmit` will be updated to use `context.read<ProductProvider>()` — the loading state will move from local `setState` to Provider, and the `CustomButton`'s `isLoading` will read from the Provider instead."

10. **What's Next:** "PR21 will add image picker state to `AddEditProductScreen` — wiring the `image_picker` package to the placeholder tap target, showing a real image preview in the container, and managing the selected `File` in local state."