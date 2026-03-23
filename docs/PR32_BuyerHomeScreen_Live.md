# PR32 – Reading Firestore — BuyerHomeScreen Live Product List

**Project:** CraftBridge
**PR Number:** 32 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Wire `BuyerHomeScreen` to `ProductProvider` live stream, replace stub product list with real Firestore data, and fully implement `ProductDetailScreen` with product image, artisan info, and add-to-cart scaffold.

---

## Section 2 – Assignments Covered

- Assignment 3.32 — Reading Firestore — BuyerHomeScreen Live Product List

---

## Section 3 – Objective

This PR completes the buyer product browsing experience by replacing `BuyerHomeScreen`'s hardcoded stub list with a live `ProductProvider` stream and implementing the full `ProductDetailScreen` with a Hero-connected image, artisan information, product description, price, and a stub "Add to Cart" button. After this PR, buyers see real products listed by approved artisans in real time, and tapping any product card shows a fully rendered detail screen. Cart functionality is wired in PR42.

---

## Section 4 – Architecture Context

```
BuyerHomeScreen (updated this PR)
  │
  ├── initState() → ProductProvider.listenToProducts()
  │
  └── Consumer<ProductProvider>
        ├── isLoading → CircularProgressIndicator
        ├── errorMessage → error widget with retry
        ├── products.isEmpty → empty state
        └── products → _filteredProducts getter
                          └── GridView of ProductCard

ProductDetailScreen (fully implemented this PR)
  │
  ├── parameters: ProductModel product
  │
  ├── Hero(tag: 'product-${product.id}') ← matches ProductCard tag
  │
  ├── Layout:
  │     Hero image (280px) → product title → artisan name
  │     → price → description → stock info
  │     → "Add to Cart" CustomButton (stub → PR42)
  │
  └── CartProvider.addItem() stub → PR42

BuyerHomeScreen data flow:
  Before PR32: _stubProducts (hardcoded List<Map>)
  After PR32:  ProductProvider.products (Stream<List<ProductModel>>)

Files modified this PR:
  lib/screens/buyer/buyer_home_screen.dart      ← live data wiring
  lib/screens/buyer/product_detail_screen.dart  ← full implementation
```

This PR sits after full product CRUD (PR31) and before order placement (PR33). After this PR, the complete buyer-facing product discovery flow — search, filter, browse, detail — is live with real Firestore data.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/buyer/buyer_home_screen.dart`
- `lib/screens/buyer/product_detail_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/buyer/buyer_home_screen.dart`

Modify the PR23/PR25 implementation. The `StatefulWidget` structure, `_searchController`, `_selectedCategory`, `_currentNavIndex`, `_contentOpacity`, `dispose()`, `_buildSearchBar()`, `_buildCategoryChips()`, `_buildEmptyState()`, `AppBar`, `BottomNavigationBar`, and `AnimatedOpacity` wrapper are all preserved. The following targeted changes are made:

---

**Change 1 — Add imports:**

```dart
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/models/product_model.dart';
```

Remove the stub-specific imports that are no longer needed — `product_detail_screen.dart` import is already present from PR23.

---

**Change 2 — Remove `_stubProducts` field:**

Delete the entire `_stubProducts` list declaration and its 10-item content.

---

**Change 3 — Update `initState()`:**

Add `ProductProvider.listenToProducts()` call to the existing `initState()`:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ProductProvider>().listenToProducts();
  });
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      setState(() => _contentOpacity = 1.0);
    }
  });
}
```

**Note:** `listenToProducts()` is called inside `addPostFrameCallback` — the Provider call must happen after the first frame. The `Future.delayed` for opacity can stay at the top level of `initState()` as it was in PR25.

---

**Change 4 — Update `_filteredProducts` getter:**

Replace the PR23 getter that filtered `_stubProducts` with one that filters `ProductProvider.products`:

```dart
List<ProductModel> get _filteredProducts {
  final List<ProductModel> allProducts =
      context.read<ProductProvider>().products;
  final String query = _searchController.text.trim().toLowerCase();
  return allProducts.where((product) {
    final bool categoryMatch = _selectedCategory == 'All' ||
        product.category == _selectedCategory;
    final bool searchMatch = query.isEmpty ||
        product.title.toLowerCase().contains(query);
    return categoryMatch && searchMatch;
  }).toList();
}
```

**Note on `context.read` in a getter:** `_filteredProducts` is called from within `build()` (via `Consumer`) — `context` is available. `context.read` is used rather than `context.watch` because the `Consumer<ProductProvider>` in the body already rebuilds when `ProductProvider` notifies — calling `context.watch` in the getter would add a redundant listener.

---

**Change 5 — Replace `_buildProductGrid()` with `Consumer`-based version:**

Replace the PR23/PR25 `_buildProductGrid()` method with:

```dart
Widget _buildProductGrid() {
  return Consumer<ProductProvider>(
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
              Text(
                productProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  productProvider.clearError();
                  productProvider.listenToProducts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      final List<ProductModel> products = _filteredProducts;
      if (products.isEmpty) {
        return _buildEmptyState();
      }
      final double screenWidth = MediaQuery.of(context).size.width;
      final int crossAxisCount = screenWidth < 600 ? 2 : 3;
      return GridView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final ProductModel product = products[index];
          return ProductCard(
            productId: product.id,
            title: product.title,
            price: product.price,
            imageUrl: product.imageUrl,
            artisanName: product.artisanName,
            category: product.category,
            isActive: product.isActive,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(product: product),
              ),
            ),
          );
        },
      );
    },
  );
}
```

---

### `lib/screens/buyer/product_detail_screen.dart`

Full replacement of the PR25 stub. Complete implementation of the product detail screen.

---

**Widget type:** `StatefulWidget`

**Class names:** `ProductDetailScreen` and `_ProductDetailScreenState`

**Imports:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/custom_button.dart';
```

---

**`ProductDetailScreen` class:**

```dart
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}
```

**Note:** The parameter changes from four individual named params (PR25 stub) to a single `ProductModel product`. `BuyerHomeScreen` is updated to pass `product: product` accordingly.

---

**`_ProductDetailScreenState`:**

**Fields:**

```dart
int _quantity = 1;
bool _isAddingToCart = false;
```

---

**`_buildImageSection()` method:**

```dart
Widget _buildImageSection() {
  return Hero(
    tag: 'product-${widget.product.id}',
    child: widget.product.imageUrl.isNotEmpty
        ? Image.network(
            widget.product.imageUrl,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: 280,
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
            errorBuilder: (_, __, ___) => _buildImageFallback(),
          )
        : _buildImageFallback(),
  );
}
```

---

**`_buildImageFallback()` method:**

```dart
Widget _buildImageFallback() {
  return Container(
    height: 280,
    width: double.infinity,
    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 72,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    ),
  );
}
```

---

**`_buildQuantitySelector()` method:**

```dart
Widget _buildQuantitySelector() {
  return Row(
    children: [
      Text(
        'Quantity',
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      const Spacer(),
      Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(7)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: _quantity > 1
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  '$_quantity',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            InkWell(
              onTap: _quantity < widget.product.stock
                  ? () => setState(() => _quantity++)
                  : null,
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(7)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: _quantity < widget.product.stock
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
```

---

**`_handleAddToCart()` method:**

```dart
Future<void> _handleAddToCart() async {
  setState(() => _isAddingToCart = true);
  await Future.delayed(const Duration(milliseconds: 300));
  setState(() => _isAddingToCart = false);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
          '${widget.product.title} added to cart — wired in PR42.'),
    ),
  );
}
```

---

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with:
  - `title: Text(widget.product.title, overflow: TextOverflow.ellipsis)`
  - `backgroundColor: Colors.transparent`
  - `elevation: 0`
  - `foregroundColor: Theme.of(context).colorScheme.onSurface`
- `body`: `SingleChildScrollView` with `column: Column` children:
  1. `_buildImageSection()`
  2. `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` and `child: Column` with `crossAxisAlignment: CrossAxisAlignment.start` and children:
     1. `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and children: `[Expanded(child: Text(widget.product.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))), const SizedBox(width: 16), Text('₹${widget.product.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))]`
     2. `const SizedBox(height: 8)`
     3. `Row` with `children`: `[Icon(Icons.store_outlined, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 4), Text(widget.product.artisanName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500))]`
     4. `const SizedBox(height: 4)`
     5. `Container` with `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, `decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12))`, `child: Text(widget.product.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary))`
     6. `const Divider(height: 32)`
     7. `Text('About this product', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`
     8. `const SizedBox(height: 8)`
     9. `Text(widget.product.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)), height: 1.5)`
     10. `const SizedBox(height: 16)`
     11. `Row` with `children`: `[Icon(Icons.inventory_2_outlined, size: 16, color: widget.product.stock > 0 ? Colors.green.shade700 : Theme.of(context).colorScheme.error), const SizedBox(width: 4), Text(widget.product.stock > 0 ? '${widget.product.stock} in stock' : 'Out of stock', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: widget.product.stock > 0 ? Colors.green.shade700 : Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500))]`
     12. `const Divider(height: 32)`
     13. `_buildQuantitySelector()`
     14. `const SizedBox(height: 16)`
     15. `CustomButton(label: 'Add to Cart', onPressed: widget.product.stock > 0 && !_isAddingToCart ? _handleAddToCart : null, isLoading: _isAddingToCart)`
     16. `const SizedBox(height: 32)`

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_home_screen.dart` | `_stubProducts` removed, `initState` wires `listenToProducts()`, `_filteredProducts` reads from `ProductProvider`, `_buildProductGrid` uses `Consumer<ProductProvider>` |
| 2 | `lib/screens/buyer/product_detail_screen.dart` | Full implementation — `ProductModel` parameter, Hero image, title/artisan/price/description/stock layout, quantity selector, stub add-to-cart button |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/screens/buyer/buyer_home_screen.dart`**

Make the five targeted changes specified in Section 6:

1. Add `ProductProvider` and `ProductModel` imports.
2. Remove `_stubProducts` field entirely.
3. Update `initState()` — add `addPostFrameCallback` with `listenToProducts()` call alongside existing opacity animation.
4. Update `_filteredProducts` getter to read from `context.read<ProductProvider>().products`.
5. Replace `_buildProductGrid()` with `Consumer<ProductProvider>` version.

**Critical rules:**
- The `AnimatedOpacity` wrapper, `_buildSearchBar()`, `_buildCategoryChips()`, `_buildEmptyState()`, `AppBar`, `BottomNavigationBar`, `dispose()`, and `_contentOpacity` logic from PR25 are ALL preserved unchanged.
- `_filteredProducts` now returns `List<ProductModel>` — update return type annotation if needed.
- `Navigator.push` to `ProductDetailScreen` now passes `product: product` (a `ProductModel`) instead of the four individual named parameters from PR23.
- `ProductCard.imageUrl` now passes `product.imageUrl` — real URLs for products with images, empty string for those without.

---

**File 2: `lib/screens/buyer/product_detail_screen.dart`**

Replace the entire PR25 stub with the full implementation specified in Section 6. Write the complete file:

1. All five import statements.
2. `ProductDetailScreen extends StatefulWidget` with `required ProductModel product` parameter.
3. `_ProductDetailScreenState` with `_quantity` and `_isAddingToCart` fields.
4. `_buildImageSection()` — `Hero`-wrapped `Image.network` or fallback, height 280.
5. `_buildImageFallback()` — 280px container with image icon.
6. `_buildQuantitySelector()` — `Row` with quantity display and `InkWell` increment/decrement. Decrement disabled at 1, increment disabled at `product.stock`.
7. `_handleAddToCart()` — stub with `Future.delayed` and stub snackbar referencing PR42.
8. `build()` — transparent `AppBar`, `SingleChildScrollView` > `Column` with image section + padded info column with all 16 children in the exact order specified.

**Critical rules:**
- `Hero` tag must be exactly `'product-${widget.product.id}'` — matching `ProductCard`.
- `Image.network` must include `loadingBuilder` with progress-aware indicator and `errorBuilder` falling back to `_buildImageFallback()`.
- Quantity increment is disabled when `_quantity >= widget.product.stock` — prevents ordering more than available stock.
- "Add to Cart" `CustomButton` is disabled when `widget.product.stock == 0` — out-of-stock products cannot be added.
- `_handleAddToCart` is a stub in this PR — real `CartProvider.addItem()` call is wired in PR42.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `context.read` used in a getter — valid when called from within a `Consumer` builder or `build()` method; `ProductModel` import missing; `ProductDetailScreen` constructor parameter change from four params to one — verify all call sites in `buyer_home_screen.dart` are updated.

2. **Verify `_stubProducts` is removed**
   ```
   grep '_stubProducts' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return no output.

3. **Verify `listenToProducts` is called in `initState`**
   ```
   grep 'listenToProducts' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

4. **Verify `Consumer<ProductProvider>` in `_buildProductGrid`**
   ```
   grep 'Consumer<ProductProvider>' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

5. **Verify `ProductDetailScreen` has `ProductModel` parameter**
   ```
   grep 'final ProductModel product' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line.

6. **Verify `Hero` tag in `ProductDetailScreen`**
   ```
   grep "product-\${widget.product.id}" lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line.

7. **Verify quantity stepper max bound**
   ```
   grep 'product.stock' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — decrement/increment bound checks and stock display.

8. **Verify `_buildImageSection` uses `Image.network`**
   ```
   grep 'Image.network' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least one line.

9. **Hot reload on emulator — buyer flow test**
   ```
   flutter run
   ```
   Log in as a buyer.

   Confirm:
   - `BuyerHomeScreen` loads with `CircularProgressIndicator` briefly.
   - Real products from Firestore appear in the grid — products created by artisans in PR31 testing.
   - Category chip filtering works on real data — tapping "Pottery" shows only pottery products.
   - Search bar filters real product titles in real time.
   - Empty state shows when filter/search produces no results.

   Tap any product card:
   - `ProductDetailScreen` opens with Hero animation.
   - Product image loads (or fallback shows for products without images).
   - Title, artisan name, price, category chip, description, stock count all render correctly.
   - Quantity stepper defaults to 1, increments up to `stock`, decrement disabled at 1.
   - "Add to Cart" button disabled for out-of-stock products.
   - Tapping "Add to Cart" shows stub snackbar "...added to cart — wired in PR42."
   - Back button returns to `BuyerHomeScreen` with Hero animation back to card.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/buyer/buyer_home_screen.dart` and `lib/screens/buyer/product_detail_screen.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 32
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
git commit -m "PR32: Reading Firestore — BuyerHomeScreen Live Product List"
git push origin pr32-buyer-home-live
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerHomeScreen._stubProducts` is removed — `grep '_stubProducts' buyer_home_screen.dart` returns no output.
- [ ] `BuyerHomeScreen.initState()` calls `ProductProvider.listenToProducts()` via `addPostFrameCallback`.
- [ ] `_filteredProducts` getter reads from `context.read<ProductProvider>().products` and returns `List<ProductModel>`.
- [ ] `_buildProductGrid()` uses `Consumer<ProductProvider>` with loading, error, empty, and list states.
- [ ] `ProductCard` in the grid passes `product.imageUrl` (real URL, not empty string).
- [ ] `Navigator.push` to `ProductDetailScreen` passes a `ProductModel` via `product:` parameter.
- [ ] `ProductDetailScreen` accepts `required ProductModel product` as its single constructor parameter.
- [ ] `ProductDetailScreen` wraps its image in `Hero(tag: 'product-${widget.product.id}')`.
- [ ] `ProductDetailScreen` renders title, artisan name, price, category chip, description, stock count, quantity selector, and "Add to Cart" button.
- [ ] Quantity stepper increments up to `widget.product.stock` and decrements down to 1 only.
- [ ] "Add to Cart" button is disabled when `widget.product.stock == 0`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR32 for CraftBridge. I wired `BuyerHomeScreen` to live Firestore data via `ProductProvider`, replaced the stub product list with a real stream, and fully implemented `ProductDetailScreen` — completing the buyer product discovery flow end-to-end."

2. **`initState` with `addPostFrameCallback`:** "`BuyerHomeScreen.initState()` now calls `ProductProvider.listenToProducts()` inside `addPostFrameCallback`. This starts the Firestore stream as soon as the buyer's home screen mounts. `listenToProducts()` only shows `isActive: true` products from approved artisans — the filter in `FirestoreService.getProducts()` from PR26 means buyers never see inactive or unapproved-artisan products."

3. **`_filteredProducts` reading from Provider:** "The `_filteredProducts` getter now reads `context.read<ProductProvider>().products` instead of the stub list. The `Consumer<ProductProvider>` in `_buildProductGrid()` triggers a rebuild when the provider notifies — at which point `_filteredProducts` recomputes with the latest product list and current filter state. `context.read` is used (not `watch`) because the `Consumer` already handles reactivity."

4. **`Consumer<ProductProvider>` four states:** "`_buildProductGrid()` wraps its content in `Consumer<ProductProvider>` which handles four states: loading spinner while Firestore first responds, error widget with retry if the stream fails, empty state if no products match the current filter, and the grid of `ProductCard` widgets for normal operation. Every async data screen in CraftBridge follows this four-state pattern."

5. **`ProductModel` parameter replacing four individual params:** "The PR25 `ProductDetailScreen` stub accepted four individual params — `productId`, `title`, `price`, `artisanName`. The full implementation accepts a single `ProductModel product`. This gives the detail screen access to every field — `description`, `imageUrl`, `category`, `stock`, `isActive` — without any additional navigation parameters. The `Hero` tag uses `widget.product.id` which matches `ProductCard`'s `'product-${product.id}'`."

6. **Quantity stepper stock bound:** "The quantity stepper's increment `onTap` is `null` when `_quantity >= widget.product.stock`. This prevents a buyer from adding more to cart than the artisan has in stock — a critical UX boundary. The out-of-stock case (`stock == 0`) disables the entire 'Add to Cart' button and shows the stock count in error red."

7. **Transparent `AppBar` design:** "The detail screen uses `backgroundColor: Colors.transparent` and `elevation: 0` on the `AppBar`. This lets the Hero image fill the full screen top including behind the system status bar, with the back arrow floating over it. `foregroundColor: colorScheme.onSurface` ensures the back arrow is visible against the image background."

8. **Category chip on detail screen:** "A small category chip appears below the artisan name — a `Container` with primary-colour background at 8% opacity and rounded corners. This gives buyers context about the product type at a glance. The same category value that drives `BuyerHomeScreen` filtering is displayed here — clicking back and selecting the same category would show related products."

9. **`_handleAddToCart` stub with PR42 reference:** "`_handleAddToCart` uses `Future.delayed(300ms)` to simulate cart operation latency. It shows a snackbar with the product title and 'wired in PR42'. In PR42, this method will call `context.read<CartProvider>().addItem(CartItemModel(...))` — no Firebase call needed as `CartProvider` is local state. The `_isAddingToCart` loading state is already in place for the real implementation."

10. **What's Next:** "PR33 will implement the order placement flow — `FirestoreService.createOrder()`, `OrderProvider.createOrder()`, `CartScreen`, and wiring the 'Place Order' button to write real `OrderModel` documents to Firestore."