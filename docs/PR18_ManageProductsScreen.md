# PR18 – ListView + GridView — ManageProductsScreen

**Project:** CraftBridge
**PR Number:** 18 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `ManageProductsScreen` with a responsive `GridView` of `ProductCard` placeholders, FAB navigation to `AddEditProductScreen`, swipe-to-delete scaffold, and empty state.

---

## Section 2 – Assignments Covered

- Assignment 3.18 — ListView + GridView — ManageProductsScreen

---

## Section 3 – Objective

This PR implements `ManageProductsScreen` — the screen where artisans view and manage their product listings. It renders a two-column responsive `GridView` of product cards, a floating action button that navigates to `AddEditProductScreen`, a swipe-to-delete `Dismissible` wrapper on each card, and a branded empty state when no products exist. At this stage the product list is a hardcoded stub list — live Firestore data is wired in PR31 when `ProductProvider` and `FirestoreService` product methods are fully implemented. This PR establishes the complete screen structure and interaction patterns that PR31 fills with real data.

---

## Section 4 – Architecture Context

```
ArtisanHomeScreen
    └── "My Products" card → ManageProductsScreen (this PR)
                                    │
                          ┌─────────┴──────────┐
                          │                    │
                    products exist        no products
                          │                    │
                   GridView (2 cols)     EmptyState widget
                   ProductCard stubs     "No products yet"
                   Dismissible wrap      FAB still visible
                          │
                          └── FAB (+) → AddEditProductScreen stub

Data source this PR:    hardcoded List<Map> stub (5 items)
Data source from PR31:  ProductProvider → FirestoreService.getProductsByArtisan()

Files modified this PR:
  lib/screens/artisan/manage_products_screen.dart  ← full implementation
  lib/screens/artisan/add_edit_product_screen.dart ← minimal stub upgrade
```

This PR sits at the start of Member 2's block (PRs 18–34). It depends on `AppTheme`, `AppConstants`, and the locked folder structure from PRs 01–17. It does not yet depend on any Provider or Firebase method.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/artisan/manage_products_screen.dart`
- `lib/screens/artisan/add_edit_product_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart` or any other provider files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/artisan/manage_products_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `ManageProductsScreen` and `_ManageProductsScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/screens/artisan/add_edit_product_screen.dart`

---

**`ManageProductsScreen` class:**
```dart
class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}
```

---

**`_ManageProductsScreenState` fields:**

```dart
final List<Map<String, dynamic>> _stubProducts = [
  {
    'id': '1',
    'title': 'Hand-painted Ceramic Vase',
    'price': 1200.0,
    'category': 'Pottery',
    'stock': 5,
    'isActive': true,
  },
  {
    'id': '2',
    'title': 'Block Print Cotton Scarf',
    'price': 650.0,
    'category': 'Textiles',
    'stock': 12,
    'isActive': true,
  },
  {
    'id': '3',
    'title': 'Silver Filigree Earrings',
    'price': 850.0,
    'category': 'Jewellery',
    'stock': 8,
    'isActive': false,
  },
  {
    'id': '4',
    'title': 'Teak Wood Serving Board',
    'price': 1800.0,
    'category': 'Woodwork',
    'stock': 3,
    'isActive': true,
  },
  {
    'id': '5',
    'title': 'Madhubani Wall Painting',
    'price': 3500.0,
    'category': 'Paintings',
    'stock': 1,
    'isActive': true,
  },
];
```

---

**`_handleDelete(String productId)` method:**

```dart
void _handleDelete(String productId) {
  setState(() {
    _stubProducts.removeWhere((p) => p['id'] == productId);
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Product removed.'),
      duration: Duration(seconds: 2),
    ),
  );
}
```

---

**`_buildEmptyState()` method:**

```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No products yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the + button to add your first product.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

---

**`_buildProductGrid()` method:**

```dart
Widget _buildProductGrid() {
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
    itemCount: _stubProducts.length,
    itemBuilder: (context, index) {
      final product = _stubProducts[index];
      return Dismissible(
        key: Key(product['id'] as String),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius:
                BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Product'),
              content: Text(
                'Are you sure you want to delete "${product['title']}"?',
              ),
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
        onDismissed: (_) => _handleDelete(product['id'] as String),
        child: _StubProductCard(product: product),
      );
    },
  );
}
```

---

**`build()` method:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: const Text('My Products'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Text(
              '${_stubProducts.length} items',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    ),
    body: _stubProducts.isEmpty ? _buildEmptyState() : _buildProductGrid(),
    floatingActionButton: FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddEditProductScreen(),
        ),
      ),
      tooltip: 'Add Product',
      child: const Icon(Icons.add),
    ),
  );
}
```

---

### `_StubProductCard` private widget

Defined in the same file below `_ManageProductsScreenState`.

**Widget type:** `StatelessWidget`

**Class name:** `_StubProductCard`

**Constructor parameter:** `required final Map<String, dynamic> product`

**`build` method returns:** `Card` with `child: Column` with `children`:

1. `Expanded` child: `Stack` with `children`:
   - `Container` filling full space: `decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))` and `child: Center(child: Icon(Icons.image_outlined, size: 40, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)))`
   - `Positioned(top: 8, right: 8)` child: `Container` with `padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)`, `decoration: BoxDecoration(color: product['isActive'] == true ? Colors.green.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(4))`, `child: Text(product['isActive'] == true ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: product['isActive'] == true ? Colors.green.shade800 : Colors.grey.shade600))`

2. `Padding` with `padding: const EdgeInsets.all(8)` and `child: Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:
   - `Text(product['title'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)`
   - `const SizedBox(height: 4)`
   - `Text('₹${(product['price'] as double).toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))`
   - `const SizedBox(height: 2)`
   - `Text('Stock: ${product['stock']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))`

---

### `lib/screens/artisan/add_edit_product_screen.dart`

Upgrade from PR01 placeholder to minimal stub:

```dart
import 'package:flutter/material.dart';

class AddEditProductScreen extends StatelessWidget {
  const AddEditProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: const Center(
        child: Text('AddEditProductScreen — implemented in PR20'),
      ),
    );
  }
}
```

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/manage_products_screen.dart` | Full `ManageProductsScreen` with responsive `GridView`, `Dismissible` swipe-to-delete with confirmation dialog, empty state, item count in app bar, FAB navigation |
| 2 | `lib/screens/artisan/add_edit_product_screen.dart` | Minimal stub with `AppBar` titled "Add Product" |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/screens/artisan/manage_products_screen.dart`**

Replace the PR16 minimal stub entirely. Write the complete file as specified in Section 6:

1. All import statements — `material.dart`, `app_constants.dart`, `add_edit_product_screen.dart`.
2. `ManageProductsScreen extends StatefulWidget` with `const` constructor.
3. `_ManageProductsScreenState` containing:
   - `_stubProducts` list with all 5 hardcoded map entries exactly as specified.
   - `_handleDelete(String productId)` — removes from `_stubProducts` via `setState`, shows `SnackBar`.
   - `_buildEmptyState()` — centered `Column` with inventory icon, "No products yet" heading, subtitle.
   - `_buildProductGrid()` — `MediaQuery` crossAxisCount, `GridView.builder` with `Dismissible` wrapper on each item, `confirmDismiss` shows `AlertDialog`, `onDismissed` calls `_handleDelete`.
   - `build()` — `Scaffold` with app bar (item count action), body switches between `_buildEmptyState()` and `_buildProductGrid()`, FAB navigates to `AddEditProductScreen`.
4. `_StubProductCard extends StatelessWidget` — `Card` > `Column` with `Stack` image area (active/inactive badge in top-right) and info section below with title (2-line max), price in primary colour, stock count.

**Critical implementation rules:**
- `Dismissible` must have `direction: DismissDirection.endToStart` — swipe left to reveal delete.
- `confirmDismiss` must show an `AlertDialog` with Cancel and Delete actions. Delete action text must be `colorScheme.error`.
- The `AlertDialog` uses a local `ctx` context to avoid using the outer context after potential async gaps.
- `Key(product['id'] as String)` is the `Dismissible` key — must be unique per product.
- `childAspectRatio: 0.72` is slightly taller than `BuyerHomeScreen`'s 0.75 to accommodate the stock count line.
- The active/inactive badge uses `Colors.green.shade100` / `Colors.grey.shade200` background — these are Material colour swatches, not theme colours, intentionally used for semantic status indication.
- FAB uses `FloatingActionButton` (not extended) — icon only, no label.

---

**File 2: `lib/screens/artisan/add_edit_product_screen.dart`**

Replace the PR01 placeholder comment with the minimal stub specified in Section 6.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `showDialog` returns `bool?` — `confirmDismiss` expects `Future<bool?>` which is compatible; `Dismissible` `key` must be a `Key` type, not a `String`; `withOpacity` deprecation.

2. **Verify stub product count**
   ```
   grep -c "'id'" lib/screens/artisan/manage_products_screen.dart
   ```
   Must return `5` — one `'id'` key per stub product.

3. **Verify `Dismissible` is present**
   ```
   grep 'Dismissible' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least two lines — the widget instantiation and the `key:` or `direction:` parameter.

4. **Verify `confirmDismiss` shows `AlertDialog`**
   ```
   grep 'AlertDialog' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least one line.

5. **Verify `_buildEmptyState` is present**
   ```
   grep '_buildEmptyState' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least two lines — the method definition and the call in `build`.

6. **Verify FAB navigates to `AddEditProductScreen`**
   ```
   grep 'AddEditProductScreen' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least one line.

7. **Verify item count in app bar**
   ```
   grep '_stubProducts.length' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least one line — confirming the count text is bound to the list length.

8. **Hot reload on emulator**
   ```
   flutter run
   ```
   Log in as an approved artisan and navigate to `ManageProductsScreen` via "My Products" card.
   Confirm:
   - App bar shows "My Products" and "5 items" count.
   - Grid renders 5 product cards in 2 columns with image placeholder, title, price (₹), stock count, and Active/Inactive badge.
   - Swiping a card left reveals a red delete background with trash icon.
   - Completing the swipe shows the `AlertDialog` with "Delete Product" title and product name.
   - Tapping Cancel dismisses the dialog and restores the card.
   - Tapping Delete removes the card, updates the item count, and shows "Product removed." snackbar.
   - After deleting all 5 products, the empty state renders with the inventory icon and "No products yet" text.
   - FAB (+) is visible throughout. Tapping it navigates to `AddEditProductScreen` stub.
   - Back button returns to `ArtisanHomeScreen`.
   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/artisan/manage_products_screen.dart` and `lib/screens/artisan/add_edit_product_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 18
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
git commit -m "PR18: ListView + GridView — ManageProductsScreen"
git push origin pr18-manage-products
```

---

## Section 9 – Acceptance Criteria

- [ ] `ManageProductsScreen` is a `StatefulWidget` with `_stubProducts` list of 5 hardcoded product maps.
- [ ] `build()` renders `_buildEmptyState()` when `_stubProducts` is empty and `_buildProductGrid()` when non-empty.
- [ ] `_buildProductGrid()` uses `MediaQuery` to set `crossAxisCount` (2 below 600dp, 3 at or above) and renders each product in a `Dismissible` wrapper.
- [ ] Each `Dismissible` has `direction: DismissDirection.endToStart`, a red delete background, `confirmDismiss` showing an `AlertDialog`, and `onDismissed` calling `_handleDelete`.
- [ ] `_handleDelete` removes the product from `_stubProducts` via `setState` and shows a `SnackBar`.
- [ ] App bar shows the product count as `'${_stubProducts.length} items'` which updates after deletion.
- [ ] `_buildEmptyState()` renders centered inventory icon, "No products yet" heading, and subtitle text.
- [ ] `_StubProductCard` renders image placeholder, active/inactive badge, product title (2-line max), price with ₹ prefix, and stock count.
- [ ] FAB navigates to `AddEditProductScreen` stub via `Navigator.push`.
- [ ] `AddEditProductScreen` minimal stub exists with `AppBar` titled "Add Product".
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR18 for CraftBridge. I implemented `ManageProductsScreen` — the artisan's product management hub — with a responsive two-column `GridView`, swipe-to-delete with confirmation dialog, an empty state, and FAB navigation to the add product screen."

2. **`StatefulWidget` justification:** "`ManageProductsScreen` is `StatefulWidget` because it owns `_stubProducts` — the local product list that changes when items are deleted. In PR31 this local list will be replaced by a `ProductProvider` stream, but the screen's `StatefulWidget` nature will be revisited at that point — for now local state is the right tool."

3. **`GridView.builder` vs `GridView.count`:** "`GridView.builder` is used rather than `GridView.count` because it builds items lazily — only the cards visible on screen are constructed. For a product grid that could eventually have dozens of items, lazy construction is important for performance. `GridView.count` constructs all items upfront regardless of scroll position."

4. **`Dismissible` swipe-to-delete pattern:** "Each card is wrapped in a `Dismissible` with `direction: DismissDirection.endToStart` — swipe from right to left. The background is a red container with a trash icon, revealed as the card slides. `confirmDismiss` intercepts the gesture before the card is removed, showing an `AlertDialog` to prevent accidental deletes. Only when the user confirms does `onDismissed` fire and `_handleDelete` execute."

5. **`AlertDialog` context safety:** "The `AlertDialog` uses a local `ctx` context parameter from the `builder` callback rather than the outer `context`. This is important because `showDialog` is async — by the time the user taps a button, the outer widget's `context` may have been invalidated. Using `ctx` from `builder` is always safe."

6. **`_StubProductCard` active/inactive badge:** "The card's image area uses a `Stack` with the badge `Positioned` at top-right. The badge uses `Colors.green.shade100` for active and `Colors.grey.shade200` for inactive — Material colour swatches chosen for semantic clarity. These are intentionally not theme colours because status colours (green = active, grey = inactive) are semantic constants, not design tokens."

7. **Item count in app bar:** "The app bar action shows `'${_stubProducts.length} items'`. This count rebuilds via `setState` every time a product is deleted, so the count always reflects the current list state. This gives the artisan immediate feedback that the deletion worked."

8. **Empty state design:** "When `_stubProducts` is empty, the screen renders the empty state rather than an empty grid. The empty state has a large faded inventory icon, a bold 'No products yet' heading, and a subtitle pointing to the FAB. The FAB remains visible over the empty state — the artisan always has a clear path to add their first product."

9. **Stub data as a PR pattern:** "The 5 hardcoded products are deliberately realistic — real Indian artisan product names, prices in rupees, varied categories, one inactive item. This makes the emulator demo feel authentic and also validates that the UI handles all the edge cases — long titles (truncated at 2 lines), inactive status, varying stock counts."

10. **What's Next:** "PR19 will apply the complete `AppTheme` globally — updating `app_theme.dart` with a full light theme and wiring it to `main.dart` — ensuring every screen built from PR19 onward inherits consistent typography, spacing, and colour tokens."