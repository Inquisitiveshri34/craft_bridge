# PR31 – Firestore Schema — Full Product CRUD Implemented

**Project:** CraftBridge
**PR Number:** 31 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement all product write methods in `FirestoreService` and `ProductProvider`, wire `AddEditProductScreen` and `ManageProductsScreen` to live Firestore data, and replace stub product lists with real `ProductModel` streams.

---

## Section 2 – Assignments Covered

- Assignment 3.31 — Firestore Schema — Full Product CRUD Implemented

---

## Section 3 – Objective

This PR completes the full product CRUD lifecycle — implementing `FirestoreService.addProduct()`, `updateProduct()`, and `deleteProduct()`, adding corresponding write methods to `ProductProvider`, updating `AddEditProductScreen` to write real `ProductModel` documents to Firestore, and wiring `ManageProductsScreen` to display live products from `ProductProvider` instead of its `_stubProducts` list. After this PR, artisans can create, edit, and delete real products that persist in Firestore and are immediately visible to buyers through the live `BuyerHomeScreen` stream.

---

## Section 4 – Architecture Context

```
FirestoreService (Product Write Methods — filled this PR)
  addProduct(ProductModel)
    → _db.collection('products').doc(product.id).set(product.toMap())

  updateProduct(String productId, Map<String, dynamic> data)
    → _db.collection('products').doc(productId).update(data)

  deleteProduct(String productId)
    → _db.collection('products').doc(productId).delete()

ProductProvider (new write methods — this PR)
  addProduct(ProductModel)
  updateProduct(String productId, Map<String, dynamic> data)
  deleteProduct(String productId)

AddEditProductScreen — updated this PR:
  product parameter type: Map<String, dynamic>? → ProductModel?
  _handleSubmit() → ProductProvider.addProduct() or updateProduct()
  image URL from _uploadedImageUrl

ManageProductsScreen — updated this PR:
  _stubProducts list → removed
  listenToArtisanProducts(artisanId) called in initState
  Consumer<ProductProvider> replaces hardcoded grid

firestore_service.dart UnimplementedError count:
  Before: 11
  After:   8 (3 product write stubs filled)
```

This PR sits after `ArtisanOrdersScreen` (PR30) and before `BuyerHomeScreen` live data (PR32). It is the most impactful PR in the artisan flow — real product data enters Firestore for the first time.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/services/firestore_service.dart`
- `lib/providers/product_provider.dart`
- `lib/screens/artisan/add_edit_product_screen.dart`
- `lib/screens/artisan/manage_products_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`, `order_provider.dart`, or `cart_provider.dart`.
- Do NOT modify any other screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/firestore_service.dart`

Replace the three Product Write Method stub bodies. All other methods are unchanged.

---

**Implemented product write methods:**

```dart
// ── Product Write Methods ── implemented in PR31 ──────────────

Future<void> addProduct(ProductModel product) async {
  await _db
      .collection(AppConstants.productsCollection)
      .doc(product.id)
      .set(product.toMap());
}

Future<void> updateProduct(
    String productId, Map<String, dynamic> data) async {
  await _db
      .collection(AppConstants.productsCollection)
      .doc(productId)
      .update(data);
}

Future<void> deleteProduct(String productId) async {
  await _db
      .collection(AppConstants.productsCollection)
      .doc(productId)
      .delete();
}
```

**Implementation notes:**

- `addProduct` uses `.doc(product.id).set(...)` — the document ID is set by the caller (from `ProductProvider.addProduct()` which generates it via `_db.collection(...).doc().id`). Using a caller-specified ID rather than Firestore auto-ID allows the `ProductModel.id` field to match the Firestore document ID from the moment of creation.
- `updateProduct` uses `.update(data)` — partial update with only the changed fields. Callers never pass the full product map to `updateProduct`; they pass only the fields that changed.
- `deleteProduct` uses `.delete()` — hard delete. Soft delete (setting `isActive: false`) is a separate `updateProduct` call; `deleteProduct` permanently removes the document.

---

**`UnimplementedError` count after this PR:**

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `8`.

---

### `lib/providers/product_provider.dart`

Add three write methods to the existing PR26 implementation. The existing fields, getters, `listenToProducts()`, `listenToArtisanProducts()`, `getProductById()`, `clearError()`, and `dispose()` are all unchanged.

---

**New import to add:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
```

Wait — `FirebaseFirestore` is not used directly in `ProductProvider`. Instead, use `_firestoreService` methods. The `cloud_firestore` import is needed only for `Timestamp.now()` in `addProduct`. Add:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
```

---

**`addProduct()` method:**

```dart
Future<bool> addProduct({
  required String artisanId,
  required String artisanName,
  required String title,
  required String description,
  required double price,
  required String imageUrl,
  required String category,
  required int stock,
}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    final String productId = FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .doc()
        .id;
    final ProductModel product = ProductModel(
      id: productId,
      artisanId: artisanId,
      artisanName: artisanName,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      stock: stock,
      isActive: true,
      createdAt: Timestamp.now(),
    );
    await _firestoreService.addProduct(product);
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = 'Failed to add product: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

---

**`updateProduct()` method:**

```dart
Future<bool> updateProduct(
    String productId, Map<String, dynamic> data) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    await _firestoreService.updateProduct(productId, data);
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = 'Failed to update product: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

---

**`deleteProduct()` method:**

```dart
Future<bool> deleteProduct(String productId) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    await _firestoreService.deleteProduct(productId);
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = 'Failed to delete product: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

---

### `lib/screens/artisan/add_edit_product_screen.dart`

Four targeted changes to the PR24 implementation.

---

**Change 1 — Update imports:**

Add:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/providers/product_provider.dart';
```

Remove (if present — no longer needed as direct import):
```dart
import 'package:craft_bridge/services/storage_service.dart';
```

Wait — `StorageService` is still used directly in `_handleSubmit`. Keep the `storage_service.dart` import. Add only the three new imports.

---

**Change 2 — Update `product` parameter type:**

Change the `AddEditProductScreen` class from:
```dart
final Map<String, dynamic>? product;
const AddEditProductScreen({super.key, this.product});
```

To:
```dart
final ProductModel? product;
const AddEditProductScreen({super.key, this.product});
```

---

**Change 3 — Update `initState()` pre-population:**

Replace the PR24 `initState()` body for edit mode with `ProductModel`-typed field access:

```dart
@override
void initState() {
  super.initState();
  if (_isEditMode) {
    _titleController.text = widget.product!.title;
    _descriptionController.text = widget.product!.description;
    _priceController.text =
        widget.product!.price.toStringAsFixed(0);
    _stockController.text = widget.product!.stock.toString();
    _selectedCategory = widget.product!.category;
    _uploadedImageUrl = widget.product!.imageUrl.isNotEmpty
        ? widget.product!.imageUrl
        : null;
  }
  _addDirtyListeners();
}
```

---

**Change 4 — Replace `_handleSubmit()` with full Firestore write:**

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
      imageUrl = await StorageService().uploadProductImage(
        _selectedImageFile!,
        artisanId,
      );
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
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
        artisanId: authProvider.currentUser!.uid,
        artisanName:
            authProvider.currentUser!.displayName,
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

---

### `lib/screens/artisan/manage_products_screen.dart`

Replace the stub data layer with live `ProductProvider` data. Four targeted changes.

---

**Change 1 — Add imports:**

```dart
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/widgets/product_card.dart';
```

---

**Change 2 — Remove `_stubProducts` and replace with `initState`:**

Remove the entire `_stubProducts` field declaration and its 5-item map list.

Add `initState()` to `_ManageProductsScreenState`:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final String? artisanId =
        context.read<AuthProvider>().currentUser?.uid;
    if (artisanId != null) {
      context
          .read<ProductProvider>()
          .listenToArtisanProducts(artisanId);
    }
  });
}
```

---

**Change 3 — Replace `_handleDelete` with `ProductProvider.deleteProduct`:**

```dart
Future<void> _handleDelete(String productId) async {
  final bool success =
      await context.read<ProductProvider>().deleteProduct(productId);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Product deleted.' : 'Failed to delete product.',
      ),
    ),
  );
}
```

---

**Change 4 — Replace `build()` body with `Consumer<ProductProvider>`:**

Replace the `build()` method with:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: const Text('My Products'),
      actions: [
        Consumer<ProductProvider>(
          builder: (_, productProvider, __) {
            final int count =
                productProvider.artisanProducts.length;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '$count item${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          },
        ),
      ],
    ),
    body: Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (productProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(productProvider.errorMessage!,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    productProvider.clearError();
                    final String? artisanId = context
                        .read<AuthProvider>()
                        .currentUser
                        ?.uid;
                    if (artisanId != null) {
                      productProvider
                          .listenToArtisanProducts(artisanId);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final List<ProductModel> products =
            productProvider.artisanProducts;
        if (products.isEmpty) {
          return _buildEmptyState();
        }
        return _buildProductGrid(products);
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        _slideUpRoute(const AddEditProductScreen()),
      ),
      tooltip: 'Add Product',
      child: const Icon(Icons.add),
    ),
  );
}
```

---

**Change 5 — Update `_buildProductGrid` to accept `List<ProductModel>` and use `ProductCard`:**

Replace the PR18 `_buildProductGrid()` with:

```dart
Widget _buildProductGrid(List<ProductModel> products) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final int crossAxisCount = screenWidth < 600 ? 2 : 3;
  return GridView.builder(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.72,
    ),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final ProductModel product = products[index];
      return Dismissible(
        key: Key(product.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius:
                BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child:
              const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Product'),
              content: Text(
                  'Delete "${product.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => _handleDelete(product.id),
        child: ProductCard(
          productId: product.id,
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrl,
          artisanName: product.artisanName,
          category: product.category,
          isActive: product.isActive,
          onTap: () => Navigator.push(
            context,
            _slideUpRoute(
              AddEditProductScreen(product: product),
            ),
          ),
        ),
      );
    },
  );
}
```

---

**Remove `_StubProductCard`:**

The `_StubProductCard` private class from PR18 must be deleted entirely — it is replaced by `ProductCard`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/services/firestore_service.dart` | `addProduct`, `updateProduct`, `deleteProduct` implemented — `UnimplementedError` count drops to 8 |
| 2 | `lib/providers/product_provider.dart` | `addProduct`, `updateProduct`, `deleteProduct` methods added |
| 3 | `lib/screens/artisan/add_edit_product_screen.dart` | `product` parameter type changed to `ProductModel?`, `initState` updated, `_handleSubmit` writes real Firestore data |
| 4 | `lib/screens/artisan/manage_products_screen.dart` | Stub data replaced with live `ProductProvider` stream, `ProductCard` replaces `_StubProductCard`, delete wired to `ProductProvider.deleteProduct` |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly four files.

---

**File 1: `lib/services/firestore_service.dart`**

Replace the three Product Write Method stub bodies with the implementations specified in Section 6. Verify `UnimplementedError` count is 8 after editing.

---

**File 2: `lib/providers/product_provider.dart`**

Add `cloud_firestore` and `app_constants` imports. Add three new methods — `addProduct`, `updateProduct`, `deleteProduct` — after `getProductById()`. All existing methods from PR26 are unchanged.

**Critical rules:**
- `addProduct` generates the Firestore document ID using `FirebaseFirestore.instance.collection(AppConstants.productsCollection).doc().id` — this produces a new unique Firestore ID without writing any data.
- All three methods set `_isLoading = true` at the start and `false` in both success and error paths.
- All three methods return `bool` — `true` on success, `false` on error.

---

**File 3: `lib/screens/artisan/add_edit_product_screen.dart`**

Make the four targeted changes specified in Section 6:
- Add three new imports.
- Change `product` parameter type from `Map<String, dynamic>?` to `ProductModel?`.
- Update `initState()` to use `ProductModel` typed field access.
- Replace `_handleSubmit()` with the full Firestore-writing version.

**Critical rules:**
- `_isEditMode` getter (`widget.product != null`) does not change — still correct for `ProductModel?`.
- `StorageService` import is retained — still used in `_handleSubmit`.
- The update data map uses `if (imageUrl != null) 'imageUrl': imageUrl` — only includes `imageUrl` in the update if a new image was uploaded. If no new image, the existing `imageUrl` in Firestore is preserved.
- `double.parse` and `int.parse` are used in `_handleSubmit` — the form validators ensure valid parseable input before `_handleSubmit` executes.

---

**File 4: `lib/screens/artisan/manage_products_screen.dart`**

Make the five targeted changes specified in Section 6:
- Add five new imports.
- Remove `_stubProducts` field.
- Add `initState()` with `addPostFrameCallback`.
- Replace `_handleDelete` with async version using `ProductProvider.deleteProduct`.
- Replace `build()` with `Consumer<ProductProvider>` version.
- Replace `_buildProductGrid()` to accept `List<ProductModel>` and use `ProductCard`.
- Remove `_StubProductCard` class.

**Critical rules:**
- `_handleDelete` is now `async` — `onDismissed` in `Dismissible` accepts `Future<void> Function(DismissDirection)`, so the async signature is compatible.
- `_buildEmptyState()` from PR18 is unchanged.
- `_slideUpRoute()` from PR25 is unchanged.
- `ProductCard.onTap` navigates to `AddEditProductScreen(product: product)` — passing the `ProductModel` to enable edit mode.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `ProductModel` not imported in `add_edit_product_screen.dart`; `FirebaseFirestore.instance` requires `cloud_firestore` import in `product_provider.dart`; `Dismissible.onDismissed` with async `_handleDelete` — `DismissDirection` parameter must still be accepted; `double.parse` vs `double.tryParse` — validators ensure non-null parseable input so `parse` is safe here.

2. **Verify `UnimplementedError` count**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return `8`.

3. **Verify `_StubProductCard` is removed**
   ```
   grep '_StubProductCard' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return no output.

4. **Verify `ProductModel?` parameter type in `AddEditProductScreen`**
   ```
   grep 'ProductModel? product' lib/screens/artisan/add_edit_product_screen.dart
   ```
   Must return one line.

5. **Verify `ProductProvider` write methods are present**
   ```
   grep 'Future<bool> addProduct\|Future<bool> updateProduct\|Future<bool> deleteProduct' lib/providers/product_provider.dart
   ```
   Must return `3` lines.

6. **Verify Firestore ID generation in `addProduct`**
   ```
   grep 'FirebaseFirestore.instance' lib/providers/product_provider.dart
   ```
   Must return at least one line — the ID generation call.

7. **Verify `Consumer<ProductProvider>` in `manage_products_screen.dart`**
   ```
   grep 'Consumer<ProductProvider>' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least two lines — one for the app bar count and one for the body.

8. **Verify `_stubProducts` is removed**
   ```
   grep '_stubProducts' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return no output.

9. **Hot reload on emulator — full product CRUD test**
   ```
   flutter run
   ```
   Log in as an approved artisan.

   **Add product test:**
   - Tap FAB (+) on `ManageProductsScreen`.
   - Fill all fields, select an image, tap "Add Product".
   - Confirm: upload progress shows briefly, success snackbar, navigation back.
   - `ManageProductsScreen` shows the new product in the grid via live stream.
   - Open Firebase Console → Firestore → `products` collection → confirm new document with all fields.

   **Edit product test:**
   - Tap a product card in `ManageProductsScreen`.
   - `AddEditProductScreen` opens in edit mode with all fields pre-populated.
   - Change the price, tap "Update Product".
   - Confirm: success snackbar, updated price shows immediately in the grid.

   **Delete product test:**
   - Swipe a product card left → confirm delete dialog → tap "Delete".
   - Confirm: card disappears from grid (live stream update), "Product deleted." snackbar.
   - Firebase Console → `products` → confirm document deleted.

   **BuyerHomeScreen cross-verification:**
   - Log in as a buyer.
   - Confirm the product added in the artisan test appears in `BuyerHomeScreen` grid.
   - Note: `BuyerHomeScreen` still uses stub data in this PR — this cross-verification applies after PR32 wires live data.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/services/firestore_service.dart`, `lib/providers/product_provider.dart`, `lib/screens/artisan/add_edit_product_screen.dart`, `lib/screens/artisan/manage_products_screen.dart`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 31
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
git commit -m "PR31: Firestore Schema — Full Product CRUD Implemented"
git push origin pr31-product-crud
```

---

## Section 9 – Acceptance Criteria

- [ ] `FirestoreService.addProduct()`, `updateProduct()`, and `deleteProduct()` are implemented using `AppConstants.productsCollection`.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` returns `8`.
- [ ] `ProductProvider` has `addProduct`, `updateProduct`, and `deleteProduct` methods — all returning `Future<bool>`.
- [ ] `ProductProvider.addProduct()` generates the Firestore document ID using `FirebaseFirestore.instance.collection(...).doc().id`.
- [ ] `AddEditProductScreen.product` parameter type is `ProductModel?` — not `Map<String, dynamic>?`.
- [ ] `AddEditProductScreen._handleSubmit()` calls `ProductProvider.addProduct()` in add mode and `ProductProvider.updateProduct()` in edit mode.
- [ ] `ManageProductsScreen` uses `Consumer<ProductProvider>` — the `_stubProducts` list is removed.
- [ ] `ManageProductsScreen._buildProductGrid()` accepts `List<ProductModel>` and renders `ProductCard` widgets.
- [ ] `_StubProductCard` is completely removed from `manage_products_screen.dart`.
- [ ] Tapping a `ProductCard` in `ManageProductsScreen` opens `AddEditProductScreen` in edit mode with a `ProductModel` parameter.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR31 for CraftBridge. I completed the full product CRUD cycle — implementing all three product write methods in `FirestoreService` and `ProductProvider`, upgrading `AddEditProductScreen` to write real `ProductModel` documents to Firestore, and replacing `ManageProductsScreen`'s hardcoded stub list with a live `ProductProvider` stream."

2. **Document ID generation pattern:** "`ProductProvider.addProduct()` generates the document ID before writing — `FirebaseFirestore.instance.collection('products').doc().id`. Calling `.doc()` with no arguments generates a new unique Firestore ID without creating any document. This ID is then embedded in the `ProductModel` as `product.id` and used as the document path in `FirestoreService.addProduct()`. This pattern ensures `product.id` and the Firestore document ID are always identical."

3. **`updateProduct` with partial data map:** "`FirestoreService.updateProduct()` takes a `Map<String, dynamic>` — only the fields that changed. In `AddEditProductScreen._handleSubmit()`, the update map includes title, description, price, category, stock, and conditionally `imageUrl` — only if a new image was uploaded. Fields not in the map (artisanId, artisanName, createdAt) are untouched in Firestore. `update()` is used instead of `set()` — `set()` would overwrite the entire document."

4. **`if (imageUrl != null) 'imageUrl': imageUrl` in update map:** "The conditional map entry `if (imageUrl != null) 'imageUrl': imageUrl` is Dart's collection `if` for map literals. If no new image was uploaded in edit mode, `imageUrl` is null and the `imageUrl` key is not added to the update map — preserving the existing image URL in Firestore. If a new image was uploaded, the new URL replaces the old one."

5. **`_StubProductCard` removal:** "`_StubProductCard` was the temporary card widget in PR18 that displayed hardcoded product map data. Now that `ManageProductsScreen` receives real `ProductModel` objects from `ProductProvider`, the real `ProductCard` widget from PR22 is used instead. `ProductCard` handles live image URLs, inactive overlays, and Hero tags — capabilities the stub never had."

6. **`Consumer<ProductProvider>` replacing stub state:** "`ManageProductsScreen` previously owned its data as `_stubProducts: List<Map>`. Now the screen is entirely data-driven via `Consumer<ProductProvider>` — it renders loading, error, empty, or list states based on `productProvider.artisanProducts`. When an artisan adds a product, `ProductProvider` notifies listeners, `Consumer` rebuilds, and the new card appears in the grid without any explicit refresh."

7. **Edit mode via `ProductCard.onTap`:** "Tapping a `ProductCard` in `ManageProductsScreen` now opens `AddEditProductScreen(product: product)` — passing the full `ProductModel`. `AddEditProductScreen._isEditMode` evaluates to `true`, `initState()` pre-populates all fields from the model's typed properties (`.title`, `.price`, `.category`), and the submit button says 'Update Product'. The move from `Map<String, dynamic>?` to `ProductModel?` gives type-safe field access."

8. **`_handleDelete` becomes async:** "`_handleDelete` in `ManageProductsScreen` is now `async` — it awaits `ProductProvider.deleteProduct()` and shows a success or failure snackbar based on the result. The `Dismissible.onDismissed` callback accepts `Future<void> Function(DismissDirection)`, so the async signature is compatible. The Firestore delete is real — the document is permanently removed."

9. **Live stream cross-verification with BuyerHomeScreen:** "After this PR, products added by artisans persist in Firestore. `BuyerHomeScreen` still uses stub data in this PR, but its `ProductProvider.listenToProducts()` query for `isActive == true` will return these real products when wired in PR32. The Firestore data is already correct — PR32 is simply the screen wiring step."

10. **What's Next:** "PR32 will wire `BuyerHomeScreen` to `ProductProvider.products` — replacing the stub product list with live Firestore data — and fully implement `ProductDetailScreen` with product images, artisan info, and the full detail layout."