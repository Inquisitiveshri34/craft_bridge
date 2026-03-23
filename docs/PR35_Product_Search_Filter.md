# PR35 – Firestore Queries — Product Search + Category Filter

**Project:** CraftBridge
**PR Number:** 35 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement server-side product search and category filtering in `FirestoreService` and `ProductProvider`, and wire advanced filter state into `BuyerHomeScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.35 — Firestore Queries — Product Search + Category Filter

---

## Section 3 – Objective

This PR upgrades the product query layer from client-side filtering to a hybrid approach: category filtering is pushed to Firestore as a server-side `where` clause, and text search remains client-side (Firestore does not natively support full-text search). `ProductProvider` gains a `filterCategory` field and a `setFilter()` method that re-subscribes to the appropriate Firestore stream when the filter changes. `BuyerHomeScreen` is updated to drive its category chips through `ProductProvider.setFilter()` rather than local `setState`. After this PR, category-filtered product queries only fetch documents matching the selected category from Firestore, reducing bandwidth and improving performance for buyers browsing large catalogs.

---

## Section 4 – Architecture Context

```
Before PR35 (client-side filtering):
  FirestoreService.getProducts()
    → ALL active products fetched
    → BuyerHomeScreen._filteredProducts getter
        → client-side category + search filter applied

After PR35 (hybrid filtering):
  ProductProvider.setFilter(category: String, query: String)
    │
    ├── category == 'All' → FirestoreService.getProducts()
    │                          → all active products
    │
    └── category != 'All' → FirestoreService.getProductsByCategory(category)
                               → active products WHERE category == X

  BuyerHomeScreen:
    _selectedCategory → drives ProductProvider.setFilter()
    _searchController → client-side text filter on ProductProvider.products
    Consumer<ProductProvider> → shows filtered + searched results

New FirestoreService method this PR:
  getProductsByCategory(String category)
    → _db.collection('products')
         .where('isActive', isEqualTo: true)
         .where('category', isEqualTo: category)
         .snapshots()
         → Stream<List<ProductModel>>

firestore_service.dart: no UnimplementedError stubs touched (new method added)
UnimplementedError count: unchanged at 4
```

This PR sits at the start of Member 3's block (PRs 35–51). It depends on `ProductProvider` (PR26), `BuyerHomeScreen` live data (PR32), and `AppConstants.productCategories` (PR03).

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/services/firestore_service.dart`
- `lib/providers/product_provider.dart`
- `lib/screens/buyer/buyer_home_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`, `order_provider.dart`, or `cart_provider.dart`.
- Do NOT modify any screen files other than `buyer_home_screen.dart`.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/firestore_service.dart`

Add one new method to the Product Read Methods group. No existing methods are modified. No stubs are replaced.

---

**New method — `getProductsByCategory`:**

```dart
Stream<List<ProductModel>> getProductsByCategory(String category) {
  return _db
      .collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .where('category', isEqualTo: category)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList());
}
```

**Implementation notes:**

- Two `where` clauses: `isActive == true` AND `category == category`. This is a Firestore composite query requiring a composite index on `isActive` + `category`.
- The method is NOT declared `async` — it returns a `Stream` synchronously.
- Uses `AppConstants.productsCollection` — not the hardcoded string `'products'`.
- The composite index for `isActive` + `category` must be created in the Firebase Console on first run — the debug console will print a direct URL.

---

**`UnimplementedError` count after this PR:**

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must still return `4` — no stubs were replaced in this PR.

---

### `lib/providers/product_provider.dart`

Add filter state management. All existing fields, getters, and methods from PRs 26 and 31 are preserved.

---

**New import:**

```dart
import 'package:craft_bridge/core/constants/app_constants.dart';
```

(If already present from PR31, do not duplicate.)

---

**New private fields** (add after `_artisanSubscription`):

```dart
String _filterCategory = 'All';
String _searchQuery = '';
```

---

**New public getters:**

```dart
String get filterCategory => _filterCategory;
String get searchQuery => _searchQuery;
```

---

**New `filteredProducts` computed getter:**

```dart
List<ProductModel> get filteredProducts {
  if (_searchQuery.isEmpty) {
    return List.unmodifiable(_products);
  }
  final String query = _searchQuery.toLowerCase();
  return _products
      .where((p) => p.title.toLowerCase().contains(query))
      .toList();
}
```

**Note:** Category filtering is handled server-side by `getProductsByCategory`. The `filteredProducts` getter only applies the text search on top of whatever `_products` currently contains (which is already category-filtered by the active stream).

---

**New `setFilter()` method:**

```dart
void setFilter({String? category, String? query}) {
  bool streamNeedsRestart = false;
  if (category != null && category != _filterCategory) {
    _filterCategory = category;
    streamNeedsRestart = true;
  }
  if (query != null) {
    _searchQuery = query;
  }
  if (streamNeedsRestart) {
    _restartProductStream();
  } else {
    notifyListeners();
  }
}
```

---

**New `_restartProductStream()` private method:**

```dart
void _restartProductStream() {
  _productsSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  final Stream<List<ProductModel>> stream =
      _filterCategory == 'All'
          ? _firestoreService.getProducts()
          : _firestoreService.getProductsByCategory(_filterCategory);
  _productsSubscription = stream.listen(
    (productList) {
      _products = productList;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (Object error) {
      _errorMessage = 'Failed to load products: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}
```

---

**Update `listenToProducts()` to use `_restartProductStream()`:**

Replace the existing `listenToProducts()` implementation with:

```dart
void listenToProducts() {
  _filterCategory = 'All';
  _searchQuery = '';
  _restartProductStream();
}
```

This ensures that calling `listenToProducts()` from `BuyerHomeScreen.initState()` always resets the filter state and starts with the `'All'` stream.

---

### `lib/screens/buyer/buyer_home_screen.dart`

Three targeted changes. The `StatefulWidget` structure, `_searchController`, `_currentNavIndex`, `_contentOpacity`, `dispose()`, `_buildEmptyState()`, `AppBar`, `BottomNavigationBar`, and `AnimatedOpacity` wrapper are all preserved.

---

**Change 1 — Remove `_selectedCategory` field:**

Delete `String _selectedCategory = 'All';` from `_BuyerHomeScreenState`.

`_selectedCategory` is now owned by `ProductProvider._filterCategory` — the screen no longer needs to store it locally.

---

**Change 2 — Update `_buildCategoryChips()` to read from `ProductProvider`:**

Replace the PR32 `_buildCategoryChips()` method with:

```dart
Widget _buildCategoryChips() {
  final List<String> categories = [
    'All',
    ...AppConstants.productCategories,
  ];
  return Consumer<ProductProvider>(
    builder: (context, productProvider, _) {
      final String selected = productProvider.filterCategory;
      return SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final String category = categories[index];
            final bool isSelected = selected == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                context
                    .read<ProductProvider>()
                    .setFilter(category: category);
              },
              selectedColor:
                  Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            );
          },
        ),
      );
    },
  );
}
```

---

**Change 3 — Update `_buildSearchBar()` to call `ProductProvider.setFilter()`:**

In `_buildSearchBar()`, update the `onChanged` callback from:
```dart
onChanged: (_) => setState(() {}),
```
to:
```dart
onChanged: (value) {
  context.read<ProductProvider>().setFilter(query: value);
  setState(() {});
},
```

The `setState(() {})` is retained to update the clear button visibility (which depends on `_searchController.text.isNotEmpty`).

---

**Change 4 — Update `_filteredProducts` getter:**

Replace with:

```dart
List<ProductModel> get _filteredProducts {
  return context.read<ProductProvider>().filteredProducts;
}
```

This delegates filtering entirely to `ProductProvider.filteredProducts` — the provider already applies the text search filter on top of the server-side category stream.

---

**Change 5 — Update `_buildProductGrid()` to use `filteredProducts`:**

In `_buildProductGrid()`, the `Consumer<ProductProvider>` body already reads `_filteredProducts` via `final List<ProductModel> products = _filteredProducts`. No structural change needed — the getter update in Change 4 is sufficient.

However, verify the `Consumer<ProductProvider>` in `_buildProductGrid()` is present — it was added in PR32. If it is present, no further change is needed.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/services/firestore_service.dart` | `getProductsByCategory()` added — server-side category filter stream |
| 2 | `lib/providers/product_provider.dart` | `_filterCategory`, `_searchQuery` fields, `setFilter()`, `_restartProductStream()`, `filteredProducts` getter, `listenToProducts()` updated |
| 3 | `lib/screens/buyer/buyer_home_screen.dart` | `_selectedCategory` removed, chips drive `ProductProvider.setFilter()`, search bar calls `setFilter(query:)`, `_filteredProducts` delegates to Provider |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly three files.

---

**File 1: `lib/services/firestore_service.dart`**

Add `getProductsByCategory(String category)` as a new method in the Product Read Methods group, after `getProductById`. The method is NOT a stub replacement — it is a new addition. Confirm `UnimplementedError` count remains at `4` after editing.

---

**File 2: `lib/providers/product_provider.dart`**

Make the following targeted additions and modifications:

**Addition 1:** Add `package:craft_bridge/core/constants/app_constants.dart` import if not already present.

**Addition 2:** Add `String _filterCategory = 'All'` and `String _searchQuery = ''` private fields after `_artisanSubscription`.

**Addition 3:** Add `filterCategory` and `searchQuery` public getters after `errorMessage` getter.

**Addition 4:** Add `filteredProducts` computed getter after `searchQuery` getter.

**Addition 5:** Add `_restartProductStream()` private method after `listenToArtisanProducts()`.

**Addition 6:** Add `setFilter()` method after `_restartProductStream()`.

**Modification:** Replace `listenToProducts()` body with the simplified version that resets filter state and calls `_restartProductStream()`.

**Critical rules:**
- `_restartProductStream()` is private — underscore prefix.
- `setFilter()` only calls `_restartProductStream()` when `_filterCategory` actually changes — not on every `query` change, since text search is client-side.
- `filteredProducts` applies only text search — the category filter is already handled by whichever stream is active.
- `listenToProducts()` must reset `_filterCategory = 'All'` and `_searchQuery = ''` — this ensures calling it from `initState` always starts fresh.

---

**File 3: `lib/screens/buyer/buyer_home_screen.dart`**

Make the five targeted changes specified in Section 6:

1. Remove `String _selectedCategory = 'All'` field.
2. Replace `_buildCategoryChips()` with the `Consumer<ProductProvider>`-driven version.
3. Update `_buildSearchBar()` `onChanged` to call `setFilter(query: value)`.
4. Replace `_filteredProducts` getter to delegate to `ProductProvider.filteredProducts`.
5. Verify `_buildProductGrid()` still reads `_filteredProducts` — no structural change needed.

**Critical rules:**
- `_selectedCategory` field must be completely removed — no references to it remain.
- `_buildCategoryChips()` now wraps in `Consumer<ProductProvider>` to read `filterCategory`.
- `FilterChip.onSelected` calls `context.read<ProductProvider>().setFilter(category: category)` — not `setState`.
- `setState(() {})` is still called in `onChanged` for the search bar — but only to update the clear button visibility.
- The `_contentOpacity` field and `initState()` `Future.delayed` from PR25 must remain unchanged.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `_selectedCategory` still referenced somewhere after deletion — search for all uses; `filteredProducts` getter return type — `List<ProductModel>` not `List.unmodifiable`; `getProductsByCategory` must not be `async`.

2. **Verify `getProductsByCategory` is added**
   ```
   grep 'getProductsByCategory' lib/services/firestore_service.dart
   ```
   Must return at least two lines — the method signature and the `.where('category'...)` clause.

3. **Verify `UnimplementedError` count unchanged**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must still return `4`.

4. **Verify `_filterCategory` and `_searchQuery` fields**
   ```
   grep '_filterCategory\|_searchQuery' lib/providers/product_provider.dart
   ```
   Must return at least six lines — field declarations, getters, and usages in `setFilter` and `_restartProductStream`.

5. **Verify `_restartProductStream` is private**
   ```
   grep '_restartProductStream' lib/providers/product_provider.dart
   ```
   Must return at least two lines — definition and call in `setFilter` and `listenToProducts`.

6. **Verify `_selectedCategory` is removed from `buyer_home_screen.dart`**
   ```
   grep '_selectedCategory' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return no output.

7. **Verify `setFilter` is called from chips**
   ```
   grep 'setFilter' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines — one in `_buildCategoryChips` and one in `_buildSearchBar`.

8. **Verify `Consumer<ProductProvider>` in `_buildCategoryChips`**
   ```
   grep -A3 '_buildCategoryChips' lib/screens/buyer/buyer_home_screen.dart | grep 'Consumer'
   ```
   Must return one line — `Consumer<ProductProvider>` inside `_buildCategoryChips`.

9. **Hot reload on emulator — filter test**
   ```
   flutter run
   ```
   Log in as a buyer.
   Confirm:
   - `BuyerHomeScreen` loads with all active products.
   - Tapping "Pottery" chip → `ProductProvider.setFilter(category: 'Pottery')` → `_restartProductStream()` → Firestore stream switches to `getProductsByCategory('Pottery')` → only pottery products shown.
   - Tapping "All" → stream switches back to `getProducts()` → all products shown.
   - Typing in search bar → `setFilter(query: 'scarf')` → `filteredProducts` getter applies text filter on current stream data → matching products shown.
   - Simultaneous category + search filter works — e.g. "Textiles" + "indigo" shows only textile products with "indigo" in the title.
   - Category chip state is driven by `ProductProvider.filterCategory` — visually correct chip is highlighted after filter change.
   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/services/firestore_service.dart`, `lib/providers/product_provider.dart`, and `lib/screens/buyer/buyer_home_screen.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 35
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
git commit -m "PR35: Firestore Queries — Product Search + Category Filter"
git push origin pr35-product-search-filter
```

---

## Section 9 – Acceptance Criteria

- [ ] `FirestoreService.getProductsByCategory()` is a new method returning `Stream<List<ProductModel>>` with two `where` clauses: `isActive == true` and `category == category`, not declared `async`.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` still returns `4` — no stubs replaced.
- [ ] `ProductProvider` has `_filterCategory` and `_searchQuery` private fields with corresponding public getters.
- [ ] `ProductProvider.setFilter()` updates `_filterCategory` and/or `_searchQuery` and restarts the Firestore stream only when the category changes.
- [ ] `ProductProvider._restartProductStream()` subscribes to `getProducts()` when `_filterCategory == 'All'` and `getProductsByCategory(_filterCategory)` otherwise.
- [ ] `ProductProvider.filteredProducts` applies text search on `_products` — returns all products when `_searchQuery` is empty.
- [ ] `ProductProvider.listenToProducts()` resets `_filterCategory = 'All'` and `_searchQuery = ''` before calling `_restartProductStream()`.
- [ ] `BuyerHomeScreen._selectedCategory` field is completely removed.
- [ ] `BuyerHomeScreen._buildCategoryChips()` uses `Consumer<ProductProvider>` to read `filterCategory` and calls `setFilter(category:)` on chip tap.
- [ ] `BuyerHomeScreen._buildSearchBar()` calls `setFilter(query:)` on text change.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR35 for CraftBridge, and my first PR as Member 3. I upgraded the product query layer from full client-side filtering to a hybrid approach — pushing category filtering to Firestore as a server-side query and keeping text search client-side — improving performance for buyers browsing large product catalogs."

2. **Why hybrid filtering:** "Firestore doesn't natively support full-text search — you'd need Algolia or a Cloud Function for that. But category filtering maps perfectly to a Firestore `where` clause. By sending `where('category', isEqualTo: 'Pottery')` to Firestore, only pottery documents are transmitted over the network. For a category with 5 products out of 500 total, this is a 99% reduction in data transfer. Text search on the remaining small set is fast enough client-side."

3. **`getProductsByCategory` dual `where` clauses:** "`getProductsByCategory` has two `where` clauses — `isActive == true` and `category == X`. Both are required: without `isActive`, inactive products would appear in category results. With both, Firestore returns only active products in the selected category. This compound filter requires a composite index — when it first runs on a live project, the SDK prints a one-click index creation URL."

4. **`_restartProductStream()` pattern:** "`_restartProductStream()` is the single point of stream lifecycle management in `ProductProvider`. It cancels the existing subscription, sets loading, and starts a new stream based on `_filterCategory`. Whether called from `listenToProducts()` (initial load with 'All') or `setFilter()` (category change), the same logic runs. This avoids duplicating the subscription setup code."

5. **`setFilter()` conditional stream restart:** "`setFilter()` only restarts the stream when `_filterCategory` actually changes — not when the text query changes. Text search is client-side so it doesn't require a new Firestore query. If only `query` is updated, `notifyListeners()` is called to trigger `filteredProducts` to recompute — no stream restart needed. This prevents unnecessary Firestore reads on every keystroke."

6. **`filteredProducts` getter design:** "`filteredProducts` only applies text filtering on `_products` — the category filtering is already handled by whichever stream is active. When `_filterCategory` is 'Pottery', `_products` already contains only pottery items from Firestore. `filteredProducts` then narrows that set by title text. The two filters compose cleanly without interfering."

7. **`listenToProducts()` reset behaviour:** "`listenToProducts()` resets `_filterCategory = 'All'` and `_searchQuery = ''` before calling `_restartProductStream()`. This is important: if a buyer navigates away from `BuyerHomeScreen` with 'Pottery' selected and returns, `initState` calls `listenToProducts()` again, resetting to the 'All' state. This matches the expected UX — returning to the browse screen shows all products."

8. **Category chips state driven by Provider:** "The category chips in `_buildCategoryChips()` now wrap their content in `Consumer<ProductProvider>` and read `productProvider.filterCategory` to determine which chip is selected. Before this PR, the chip state was stored in `_selectedCategory` — a local field. Moving it to the Provider means the chip state and the data state are always in sync, even if the filter is changed programmatically."

9. **`setState(() {})` retained in search bar:** "The search bar's `onChanged` still calls `setState(() {})` alongside `setFilter(query: value)`. The `setState` is needed to update the clear button visibility — which depends on `_searchController.text.isNotEmpty`, a local field. The `setFilter` is needed to update the Provider. Both are necessary."

10. **What's Next:** "PR36 will implement full product image management — wiring `StorageService.updateProductImage()` and `deleteProductImage()` into `AddEditProductScreen` so artisans can change or remove product images when editing existing listings."