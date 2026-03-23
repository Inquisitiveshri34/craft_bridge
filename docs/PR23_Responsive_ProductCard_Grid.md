# PR23 – MediaQuery + LayoutBuilder — Responsive ProductCard Grid

**Project:** CraftBridge
**PR Number:** 23 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Replace `_PlaceholderProductCard` in `BuyerHomeScreen` with real `ProductCard` widgets, wire stub product data, and implement responsive grid and category filtering with `MediaQuery` and `LayoutBuilder`.

---

## Section 2 – Assignments Covered

- Assignment 3.23 — MediaQuery + LayoutBuilder — Responsive ProductCard Grid

---

## Section 3 – Objective

This PR upgrades `BuyerHomeScreen` from a skeleton placeholder grid to a functional product browsing experience — replacing the `_PlaceholderProductCard` stubs with real `ProductCard` widgets wired to a hardcoded stub product list. Category filter chips now actually filter the displayed products, and the search bar filters by title. The responsive grid established in PR17 is preserved and refined. Live Firestore data replaces the stub list in PR32 when `ProductProvider` is fully wired — this PR establishes the screen structure and filtering logic that PR32 will slot real data into.

---

## Section 4 – Architecture Context

```
BuyerHomeScreen (_BuyerHomeScreenState)
  │
  ├── _stubProducts: List<Map<String, dynamic>> (10 items — this PR)
  │     └── replaced by ProductProvider.products stream in PR32
  │
  ├── _filteredProducts (computed getter — this PR)
  │     └── filters _stubProducts by _selectedCategory and _searchController
  │
  ├── _buildSearchBar() — unchanged from PR17
  ├── _buildCategoryChips() — unchanged from PR17
  └── _buildProductGrid() — updated this PR
        └── GridView of ProductCard widgets
              └── each card onTap → ProductDetailScreen stub

Files modified this PR:
  lib/screens/buyer/buyer_home_screen.dart   ← full update
  lib/screens/buyer/product_detail_screen.dart ← minimal stub upgrade

ProductCard parameters this PR (from stub map):
  productId   → map['id']
  title       → map['title']
  price       → map['price']
  imageUrl    → '' (no real images yet — PR24/PR32)
  artisanName → map['artisanName']
  category    → map['category']
  isActive    → map['isActive']
  onTap       → Navigator.push → ProductDetailScreen stub
```

This PR sits after reusable widgets (PR22) and before Firebase Storage upload (PR24). It is the first PR where `ProductCard` is visible on screen. `ProductDetailScreen` receives a minimal stub upgrade to allow navigation.

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

Modify the PR17 implementation. The `StatefulWidget` structure, `_searchController`, `_selectedCategory`, `_currentNavIndex`, `dispose()`, `_buildSearchBar()`, `_buildCategoryChips()`, `AppBar`, and `BottomNavigationBar` are all unchanged. The following additions and replacements are made:

---

**New import to add:**
```dart
import 'package:craft_bridge/widgets/product_card.dart';
import 'package:craft_bridge/screens/buyer/product_detail_screen.dart';
```

---

**New field — `_stubProducts` list:**

Add to `_BuyerHomeScreenState` after `int _currentNavIndex = 0`:

```dart
final List<Map<String, dynamic>> _stubProducts = [
  {
    'id': '1',
    'title': 'Hand-painted Ceramic Vase',
    'price': 1200.0,
    'artisanName': 'Meera Devi',
    'category': 'Pottery',
    'isActive': true,
  },
  {
    'id': '2',
    'title': 'Block Print Cotton Scarf',
    'price': 650.0,
    'artisanName': 'Meera Devi',
    'category': 'Textiles',
    'isActive': true,
  },
  {
    'id': '3',
    'title': 'Silver Filigree Earrings',
    'price': 850.0,
    'artisanName': 'Ravi Kumar',
    'category': 'Jewellery',
    'isActive': true,
  },
  {
    'id': '4',
    'title': 'Teak Wood Serving Board',
    'price': 1800.0,
    'artisanName': 'Pradeep Nair',
    'category': 'Woodwork',
    'isActive': true,
  },
  {
    'id': '5',
    'title': 'Madhubani Wall Painting',
    'price': 3500.0,
    'artisanName': 'Sunita Sharma',
    'category': 'Paintings',
    'isActive': true,
  },
  {
    'id': '6',
    'title': 'Indigo Dyed Linen Cushion Cover',
    'price': 480.0,
    'artisanName': 'Meera Devi',
    'category': 'Textiles',
    'isActive': true,
  },
  {
    'id': '7',
    'title': 'Brass Temple Bell',
    'price': 750.0,
    'artisanName': 'Ravi Kumar',
    'category': 'Other',
    'isActive': true,
  },
  {
    'id': '8',
    'title': 'Handwoven Jute Basket',
    'price': 320.0,
    'artisanName': 'Sunita Sharma',
    'category': 'Other',
    'isActive': true,
  },
  {
    'id': '9',
    'title': 'Terracotta Planter Set',
    'price': 560.0,
    'artisanName': 'Pradeep Nair',
    'category': 'Pottery',
    'isActive': true,
  },
  {
    'id': '10',
    'title': 'Oxidised Silver Bangles',
    'price': 420.0,
    'artisanName': 'Ravi Kumar',
    'category': 'Jewellery',
    'isActive': true,
  },
];
```

---

**New computed getter — `_filteredProducts`:**

Add after the `_stubProducts` field:

```dart
List<Map<String, dynamic>> get _filteredProducts {
  final String query = _searchController.text.trim().toLowerCase();
  return _stubProducts.where((product) {
    final bool categoryMatch = _selectedCategory == 'All' ||
        product['category'] == _selectedCategory;
    final bool searchMatch = query.isEmpty ||
        (product['title'] as String).toLowerCase().contains(query);
    return categoryMatch && searchMatch;
  }).toList();
}
```

---

**Replace `_buildProductGrid()` method:**

Replace the PR17 `_buildProductGrid()` with:

```dart
Widget _buildProductGrid() {
  final List<Map<String, dynamic>> products = _filteredProducts;
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
      final Map<String, dynamic> product = products[index];
      return ProductCard(
        productId: product['id'] as String,
        title: product['title'] as String,
        price: product['price'] as double,
        imageUrl: '',
        artisanName: product['artisanName'] as String,
        category: product['category'] as String,
        isActive: product['isActive'] as bool,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: product['id'] as String,
              title: product['title'] as String,
              price: product['price'] as double,
              artisanName: product['artisanName'] as String,
            ),
          ),
        ),
      );
    },
  );
}
```

---

**Add `_buildEmptyState()` method:**

Add after `_buildProductGrid()`:

```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 72,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No products found',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try a different search or category.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.45),
              ),
        ),
      ],
    ),
  );
}
```

---

**Remove `_PlaceholderProductCard` private class:**

The `_PlaceholderProductCard` class from PR17 must be deleted entirely from the file — it is fully replaced by the real `ProductCard` widget.

---

### `lib/screens/buyer/product_detail_screen.dart`

Upgrade from PR01 placeholder to a minimal stub that accepts navigation parameters:

```dart
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  final String title;
  final double price;
  final String artisanName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    required this.artisanName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'By $artisanName',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'ProductDetailScreen — fully implemented in PR32/PR40/PR41/PR44',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

This stub accepts the four parameters needed by `BuyerHomeScreen`'s navigation call and displays basic product info. It is fully replaced across PRs 32, 40, 41, and 44.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_home_screen.dart` | Updated with 10-item stub product list, `_filteredProducts` computed getter, real `ProductCard` grid, empty state, `_PlaceholderProductCard` removed |
| 2 | `lib/screens/buyer/product_detail_screen.dart` | Minimal stub with 4 named parameters displaying basic product info |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify two files.

---

**File 1: `lib/screens/buyer/buyer_home_screen.dart`**

Make the following targeted changes to the PR17 implementation:

**Change 1 — Add imports:**
Add `import 'package:craft_bridge/widgets/product_card.dart';` and `import 'package:craft_bridge/screens/buyer/product_detail_screen.dart';` to the import block.

**Change 2 — Add `_stubProducts` field:**
Add the 10-item `_stubProducts` list to `_BuyerHomeScreenState` after `int _currentNavIndex = 0`, exactly as specified in Section 6.

**Change 3 — Add `_filteredProducts` getter:**
Add the computed getter after the `_stubProducts` field, exactly as specified in Section 6.

**Change 4 — Replace `_buildProductGrid()`:**
Replace the entire PR17 `_buildProductGrid()` method with the new version that uses `_filteredProducts`, real `ProductCard` widgets, and `Navigator.push` to `ProductDetailScreen`.

**Change 5 — Add `_buildEmptyState()`:**
Add the `_buildEmptyState()` method after `_buildProductGrid()`.

**Change 6 — Remove `_PlaceholderProductCard`:**
Delete the `_PlaceholderProductCard` class entirely.

**Change 7 — Update `build()` body column:**
In `build()`, the `Expanded` child of the body `Column` must call `_buildProductGrid()` — this was already the case in PR17, so no change is needed here unless the PR17 implementation called `_buildProductGrid()` differently.

**Critical implementation rules:**
- `_filteredProducts` is a computed getter — NOT a stored field. It recomputes on every `build()` call, ensuring the filtered list always reflects the current `_searchController.text` and `_selectedCategory` values.
- `ProductCard.imageUrl` is passed as `''` (empty string) for all stub products — `ProductCard._buildImageFallback` handles the empty URL case.
- `Navigator.push` to `ProductDetailScreen` must pass `productId`, `title`, `price`, and `artisanName` as named parameters matching the stub's constructor.
- The `_buildSearchBar` `onChanged` already calls `setState(() {})` from PR17 — this is what triggers `_filteredProducts` to recompute on search input.
- The `_buildCategoryChips` `onSelected` already calls `setState(() => _selectedCategory = category)` from PR17 — this triggers `_filteredProducts` to recompute on category tap.
- Do NOT change `_buildSearchBar()`, `_buildCategoryChips()`, `AppBar`, `BottomNavigationBar`, `dispose()`, or the three state field declarations.

---

**File 2: `lib/screens/buyer/product_detail_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6. The stub must:
- Declare four named constructor parameters: `productId`, `title`, `price`, `artisanName`.
- Render a `Scaffold` with `AppBar(title: Text(title))` and a `Padding` > `Column` body displaying the title, artisan name, and price.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `_PlaceholderProductCard` still referenced somewhere after deletion — search all usages; `ProductDetailScreen` constructor parameter type mismatch — verify `price` is `double` not `String`; `_filteredProducts` getter references `_searchController` and `_selectedCategory` — both must be in scope.

2. **Verify `_PlaceholderProductCard` is fully removed**
   ```
   grep '_PlaceholderProductCard' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return no output.

3. **Verify `_stubProducts` has 10 items**
   ```
   grep -c "'id'" lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return `10`.

4. **Verify `_filteredProducts` getter is present**
   ```
   grep 'get _filteredProducts' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line.

5. **Verify `ProductCard` is used in the grid**
   ```
   grep 'ProductCard(' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

6. **Verify `_buildEmptyState` is present**
   ```
   grep '_buildEmptyState' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines — definition and call.

7. **Verify `ProductDetailScreen` stub parameters**
   ```
   grep 'final.*productId\|final.*title\|final.*price\|final.*artisanName' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return 4 lines.

8. **Hot reload on emulator — product grid test**
   ```
   flutter run
   ```
   Log in as a buyer.
   Confirm:
   - `BuyerHomeScreen` renders 10 `ProductCard` widgets in a 2-column grid (phone width).
   - Each card shows: grey image placeholder, product title, artisan name, price with ₹ prefix.
   - All 10 products are all-active (no inactive overlay).
   - Tapping the "Pottery" category chip filters to 2 pottery items (Ceramic Vase, Terracotta Planter Set).
   - Tapping "All" shows all 10 again.
   - Typing "scarf" in the search bar filters to 1 item (Block Print Cotton Scarf).
   - Clearing the search shows all 10 again (or current category filter).
   - Typing a search term with no matches shows the empty state with magnifying glass icon and "No products found".
   - Tapping any product card navigates to `ProductDetailScreen` stub showing the product title in the app bar and basic info.
   - Back button returns to `BuyerHomeScreen` with filter state preserved.
   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/buyer/buyer_home_screen.dart` and `lib/screens/buyer/product_detail_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 23
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
git commit -m "PR23: MediaQuery + LayoutBuilder — Responsive ProductCard Grid"
git push origin pr23-product-grid
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerHomeScreen` `_stubProducts` contains exactly 10 product maps with `id`, `title`, `price`, `artisanName`, `category`, and `isActive` keys.
- [ ] `_filteredProducts` is a computed getter that applies both `_selectedCategory` and `_searchController.text` filters simultaneously.
- [ ] `_buildProductGrid()` renders real `ProductCard` widgets using `_filteredProducts`, with `imageUrl: ''` for all stub products.
- [ ] Tapping a `ProductCard` navigates to `ProductDetailScreen` with `productId`, `title`, `price`, and `artisanName` passed as named parameters.
- [ ] `_buildEmptyState()` renders when `_filteredProducts` is empty — search icon, "No products found" heading, subtitle.
- [ ] Category chip filtering works — selecting "Pottery" shows only pottery products, "All" shows all.
- [ ] Search bar filtering works — typing a title substring filters the grid in real time.
- [ ] `_PlaceholderProductCard` class is completely removed from `buyer_home_screen.dart`.
- [ ] `ProductDetailScreen` is a `StatelessWidget` stub with four named constructor parameters and renders title, artisan name, and price.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR23 for CraftBridge. I upgraded `BuyerHomeScreen` from a skeleton placeholder grid to a functional product browsing experience — replacing the `_PlaceholderProductCard` stubs with real `ProductCard` widgets, wiring category filter chips and search bar to actually filter the displayed products, and adding a proper empty state."

2. **`_filteredProducts` computed getter pattern:** "`_filteredProducts` is a computed getter, not a stored field. Every time `build()` runs — which happens when `_selectedCategory` or `_searchController.text` changes via `setState` — the getter recomputes the filtered list from scratch. This is simpler and more reliable than maintaining a separate `_filteredProducts` list that has to be kept in sync. The performance cost is negligible for lists of this size."

3. **Combined search and category filtering:** "The getter applies both filters simultaneously using a `where` with two conditions joined by `&&`. `categoryMatch` is true when the category is 'All' or matches `_selectedCategory`. `searchMatch` is true when the query is empty or the title contains the query string (case-insensitive). Both must be true for a product to appear. This means a user can filter by 'Pottery' AND search for 'Vase' at the same time."

4. **`imageUrl: ''` for stub products:** "`ProductCard` receives `imageUrl: ''` for all stub products because no real images exist yet — they are uploaded in PR24 and stored in Firebase Storage. The `ProductCard._buildImageFallback` method handles the empty URL case by showing the grey placeholder icon. When PR32 wires live Firestore data, the real `imageUrl` values will replace the empty strings automatically."

5. **`ProductCard` `Hero` animation readiness:** "Each `ProductCard` in the grid has a `Hero` with tag `'product-${product['id']}'`. The `ProductDetailScreen` stub does not yet have a `Hero` — that is added in PR32 when the full detail screen is implemented. The `Hero` on the card is harmless without a matching tag on the destination — Flutter simply doesn't animate if no match is found."

6. **Empty state design decision:** "The empty state uses `Icons.search_off_rounded` — a different icon from `ManageProductsScreen`'s `Icons.inventory_2_outlined`. The empty state context is different: in `ManageProductsScreen`, 'no products' means the artisan hasn't listed anything. In `BuyerHomeScreen`, 'no products found' means the search/filter returned nothing. Different icons communicate different reasons for emptiness."

7. **Preserving PR17 structure:** "The `_buildSearchBar()`, `_buildCategoryChips()`, `AppBar`, `BottomNavigationBar`, and the three state fields from PR17 are completely unchanged. The `build()` body column still calls `_buildSearchBar()`, `_buildCategoryChips()`, and `Expanded(_buildProductGrid())` in the same order. Only `_buildProductGrid()` is replaced and `_PlaceholderProductCard` is removed — surgical changes only."

8. **`ProductDetailScreen` stub parameters:** "The `ProductDetailScreen` stub accepts four parameters — `productId`, `title`, `price`, and `artisanName` — because `BuyerHomeScreen` passes these four from the stub product map. The full `ProductDetailScreen` in PR32 will accept these same parameters (plus a full `ProductModel`), so the navigation call in `BuyerHomeScreen` won't need to change when PR32 replaces the stub."

9. **Filter state preservation on back navigation:** "When the user taps a product card and then presses back, they return to `BuyerHomeScreen` with `_selectedCategory` and `_searchController.text` exactly as they left them. `Navigator.push` preserves the state of the source screen — the `_BuyerHomeScreenState` is not rebuilt on return, so the filter state is maintained."

10. **What's Next:** "PR24 will implement `StorageService.uploadProductImage()` and wire it into `AddEditProductScreen` — replacing the `Future.delayed` stub with a real Firebase Storage upload, making product images actually persist."