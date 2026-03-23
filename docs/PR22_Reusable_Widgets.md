# PR22 – Reusable Widgets — ProductCard + OrderCard + CartItemTile

**Project:** CraftBridge
**PR Number:** 22 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `ProductCard`, `OrderCard`, and `CartItemTile` — the three reusable display widgets consumed across buyer, artisan, and cart screens.

---

## Section 2 – Assignments Covered

- Assignment 3.22 — Reusable Widgets — ProductCard + OrderCard + CartItemTile

---

## Section 3 – Objective

This PR implements the three reusable display widgets that form the visual backbone of CraftBridge's buyer and artisan flows. `ProductCard` is the product grid tile used in `BuyerHomeScreen` and `ManageProductsScreen`. `OrderCard` is the order list item used in `ArtisanOrdersScreen` and `BuyerOrdersScreen`. `CartItemTile` is the cart line item used in `CartScreen`. All three widgets accept data through typed parameters derived from the locked model signatures, are styled exclusively from `AppTheme` tokens, and are designed to be dropped into their respective screens in PRs 23, 30, 32, 33, 42, and 43 without modification.

---

## Section 4 – Architecture Context

```
lib/widgets/
  product_card.dart    ← implemented this PR
  order_card.dart      ← implemented this PR
  cart_item_tile.dart  ← implemented this PR

Consumed by:
  ProductCard    → BuyerHomeScreen (PR23/PR32)
                 → ManageProductsScreen (PR31, replaces _StubProductCard)
  OrderCard      → ArtisanOrdersScreen (PR30)
                 → BuyerOrdersScreen (PR43)
                 → ManageAllOrdersScreen (PR48)
  CartItemTile   → CartScreen (PR33/PR42)

Data contracts (from locked model signatures):
  ProductCard    ← ProductModel fields: id, title, price, imageUrl,
                   artisanName, category, isActive
  OrderCard      ← OrderModel fields: id, productTitle, productImageUrl,
                   buyerName, artisanName, quantity, totalPrice,
                   status, createdAt
  CartItemTile   ← CartItemModel fields: productId, title, imageUrl,
                   price, quantity, artisanName
                   + callbacks: onIncrement, onDecrement, onRemove
```

This PR sits after `AppTheme` completion (PR19) and before responsive buyer home screen (PR23). The widgets implemented here are passive — they accept data and callbacks but own no state and make no Firebase calls.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders from PR01.

**Allowed file modification:**
- `lib/widgets/product_card.dart`
- `lib/widgets/order_card.dart`
- `lib/widgets/cart_item_tile.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any screen files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/widgets/product_card.dart`

**Widget type:** `StatelessWidget`

**Class name:** `ProductCard`

**Imports:**
- `package:flutter/material.dart`
- `package:craft_bridge/core/constants/app_constants.dart`

**Constructor parameters** (all named):

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `productId` | `String` | Yes | Unique product identifier — used as Hero tag |
| `title` | `String` | Yes | Product title |
| `price` | `double` | Yes | Product price in rupees |
| `imageUrl` | `String` | Yes | Product image URL — empty string if no image |
| `artisanName` | `String` | Yes | Artisan display name shown on card |
| `category` | `String` | Yes | Product category |
| `isActive` | `bool` | Yes | Whether the product listing is active |
| `onTap` | `VoidCallback?` | No | Optional tap callback |

**Constructor:** `const ProductCard({super.key, required this.productId, required this.title, required this.price, required this.imageUrl, required this.artisanName, required this.category, required this.isActive, this.onTap})`

---

**`build` method returns:** `GestureDetector` with `onTap: onTap` wrapping a `Card` with `child: Column` with `children`:

**Child 1 — Image section:**
`Expanded` child: `Stack` with `children`:
- `Hero` with `tag: 'product-$productId'` wrapping `ClipRRect` with `borderRadius: const BorderRadius.vertical(top: Radius.circular(12))` wrapping:
  - If `imageUrl.isNotEmpty`: `Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)); }, errorBuilder: (context, error, stackTrace) => _buildImageFallback(context))`
  - If `imageUrl.isEmpty`: `_buildImageFallback(context)`
- `if (!isActive)` → `Positioned.fill` child: `Container` with `color: Colors.black.withOpacity(0.45)` and `child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Text('Inactive', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))))`

**Child 2 — Info section:**
`Padding` with `padding: const EdgeInsets.all(8)` and `child: Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:
1. `Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)`
2. `const SizedBox(height: 2)`
3. `Text(artisanName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)), maxLines: 1, overflow: TextOverflow.ellipsis)`
4. `const SizedBox(height: 4)`
5. `Text('₹${price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))`

---

**`_buildImageFallback` private method:**

```dart
Widget _buildImageFallback(BuildContext context) {
  return Container(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
    ),
  );
}
```

---

### `lib/widgets/order_card.dart`

**Widget type:** `StatelessWidget`

**Class name:** `OrderCard`

**Imports:**
- `package:flutter/material.dart`
- `package:cloud_firestore/cloud_firestore.dart`
- `package:craft_bridge/core/constants/app_constants.dart`

**Constructor parameters** (all named):

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `orderId` | `String` | Yes | Order ID — displayed truncated |
| `productTitle` | `String` | Yes | Title of the ordered product |
| `productImageUrl` | `String` | Yes | Product image URL — empty if none |
| `buyerName` | `String` | Yes | Name of the buyer |
| `artisanName` | `String` | Yes | Name of the artisan |
| `quantity` | `int` | Yes | Quantity ordered |
| `totalPrice` | `double` | Yes | Total order price |
| `status` | `String` | Yes | Order status string |
| `createdAt` | `Timestamp` | Yes | Firestore timestamp of order creation |
| `onTap` | `VoidCallback?` | No | Optional tap callback |
| `showBuyerName` | `bool` | No | If true, shows buyer name; if false, shows artisan name. Default: `true` |

**Constructor:** Non-const (contains `Timestamp`). `OrderCard({super.key, required ...all required params..., this.onTap, this.showBuyerName = true})`

---

**Status colour helper** — private static method:

```dart
static Color _statusColor(String status) {
  switch (status) {
    case AppConstants.statusPending:
      return Colors.orange.shade700;
    case AppConstants.statusConfirmed:
      return Colors.blue.shade700;
    case AppConstants.statusShipped:
      return Colors.purple.shade700;
    case AppConstants.statusDelivered:
      return Colors.green.shade700;
    case AppConstants.statusCancelled:
      return Colors.red.shade700;
    default:
      return Colors.grey.shade700;
  }
}
```

---

**`_buildStatusChip` private method:**

```dart
Widget _buildStatusChip(BuildContext context) {
  final Color color = _statusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      status[0].toUpperCase() + status.substring(1),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

---

**`_formatDate` private method:**

```dart
String _formatDate(Timestamp timestamp) {
  final DateTime dt = timestamp.toDate();
  final List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}
```

---

**`build` method returns:** `Card` with `child: InkWell` with `borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius)` and `onTap: onTap` and `child: Padding` with `padding: const EdgeInsets.all(12)` and `child: Row` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:

**Child 1 — Product image:**
`ClipRRect` with `borderRadius: BorderRadius.circular(8)` wrapping `SizedBox` with `width: 64, height: 64` wrapping:
- If `productImageUrl.isNotEmpty`: `Image.network(productImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageFallback(context))`
- If `productImageUrl.isEmpty`: `_buildImageFallback(context)`

Where `_buildImageFallback` for `OrderCard` is:
```dart
Widget _buildImageFallback(BuildContext context) {
  return Container(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    child: Icon(
      Icons.shopping_bag_outlined,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
    ),
  );
}
```

**Child 2 — Spacing:**
`const SizedBox(width: 12)`

**Child 3 — Order details:**
`Expanded` child: `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:
1. `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and `children`: `[Expanded(child: Text(productTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), _buildStatusChip(context)]`
2. `const SizedBox(height: 4)`
3. `Text(showBuyerName ? 'Buyer: $buyerName' : 'Artisan: $artisanName', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
4. `const SizedBox(height: 4)`
5. `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and `children`: `[Text('Qty: $quantity', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))), Text('₹${totalPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))]`
6. `const SizedBox(height: 4)`
7. `Text(_formatDate(createdAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)))`

---

### `lib/widgets/cart_item_tile.dart`

**Widget type:** `StatelessWidget`

**Class name:** `CartItemTile`

**Imports:**
- `package:flutter/material.dart`

**Constructor parameters** (all named):

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `productId` | `String` | Yes | Product ID |
| `title` | `String` | Yes | Product title |
| `imageUrl` | `String` | Yes | Product image URL |
| `price` | `double` | Yes | Unit price |
| `quantity` | `int` | Yes | Current quantity in cart |
| `artisanName` | `String` | Yes | Artisan name |
| `onIncrement` | `VoidCallback` | Yes | Callback to increase quantity by 1 |
| `onDecrement` | `VoidCallback` | Yes | Callback to decrease quantity by 1 |
| `onRemove` | `VoidCallback` | Yes | Callback to remove item from cart entirely |

**Constructor:** `const CartItemTile({super.key, required ...all params...})`

---

**`build` method returns:** `Card` with `child: Padding` with `padding: const EdgeInsets.all(12)` and `child: Row` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:

**Child 1 — Product image:**
`ClipRRect` with `borderRadius: BorderRadius.circular(8)` wrapping `SizedBox` with `width: 72, height: 72` wrapping:
- If `imageUrl.isNotEmpty`: `Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageFallback(context))`
- If `imageUrl.isEmpty`: `_buildImageFallback(context)`

Where `_buildImageFallback` for `CartItemTile` is:
```dart
Widget _buildImageFallback(BuildContext context) {
  return Container(
    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    child: Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
    ),
  );
}
```

**Child 2 — Spacing:**
`const SizedBox(width: 12)`

**Child 3 — Item details:**
`Expanded` child: `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:
1. `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and `children`: `[Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)), IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Remove item')]`
2. `const SizedBox(height: 2)`
3. `Text(artisanName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)))`
4. `const SizedBox(height: 8)`
5. `Row` with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and `children`:
   - `Text('₹${(price * quantity).toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))`
   - `_buildQuantityStepper(context)`

---

**`_buildQuantityStepper` private method:**

```dart
Widget _buildQuantityStepper(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: quantity > 1 ? onDecrement : null,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: quantity > 1
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.3),
            ),
          ),
        ),
        Container(
          width: 32,
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        InkWell(
          onTap: onIncrement,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(7),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
```

The decrement button `onTap` is `null` when `quantity <= 1` — this disables the button and removes the ripple effect, preventing quantity from going below 1.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/widgets/product_card.dart` | `ProductCard` with `Hero` tag, network image with loading/error states, inactive overlay, price/title/artisan info section |
| 2 | `lib/widgets/order_card.dart` | `OrderCard` with status chip colour-coding, date formatting, buyer/artisan name toggle via `showBuyerName` |
| 3 | `lib/widgets/cart_item_tile.dart` | `CartItemTile` with quantity stepper (disabled decrement at qty 1), item total, remove button |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must implement exactly three files. All are replacements of PR01 placeholder comments.

---

**File 1: `lib/widgets/product_card.dart`**

Replace the PR01 placeholder entirely. Write the complete file as specified in Section 6:

1. Imports: `material.dart` and `app_constants.dart`.
2. `class ProductCard extends StatelessWidget` with `const` constructor and all 8 named parameters.
3. `build()` returning `GestureDetector` > `Card` > `Column` with:
   - `Expanded` image section: `Stack` with `Hero`-wrapped `ClipRRect` containing network image (with `loadingBuilder` and `errorBuilder`) or fallback, plus inactive overlay `Positioned.fill` when `!isActive`.
   - Info section: `Padding` > `Column` with title (2-line max), artisan name (muted), price (primary colour bold).
4. `_buildImageFallback(BuildContext context)` private method.

**Critical rules:**
- `Hero` tag must be `'product-$productId'` — this exact string is required for hero animations in PR25.
- `Image.network` `loadingBuilder` must show a `CircularProgressIndicator` with `strokeWidth: 2` and a calculated `value` based on loading progress — not a static spinner.
- The inactive overlay uses `Positioned.fill` so it covers the entire image area without clipping.
- `const` constructor is valid because all parameters are `const`-compatible types.

---

**File 2: `lib/widgets/order_card.dart`**

Replace the PR01 placeholder entirely. Write the complete file as specified in Section 6:

1. Imports: `material.dart`, `cloud_firestore/cloud_firestore.dart`, `app_constants.dart`.
2. `class OrderCard extends StatelessWidget` with non-const constructor (due to `Timestamp`) and all 11 parameters.
3. `static Color _statusColor(String status)` — switch on `AppConstants` status constants.
4. `Widget _buildStatusChip(BuildContext context)` — `Container` with colour-coded border and background.
5. `String _formatDate(Timestamp timestamp)` — formats as `'DD Mon YYYY'`.
6. `build()` returning `Card` > `InkWell` > `Padding` > `Row` with image thumbnail, `SizedBox(width: 12)`, and `Expanded` details column.
7. `_buildImageFallback(BuildContext context)` private method (shopping bag icon).

**Critical rules:**
- `_statusColor` is `static` — it does not require `BuildContext` and can be called without an instance.
- `showBuyerName` parameter controls whether "Buyer: $buyerName" or "Artisan: $artisanName" is shown in the subtitle — this allows the same widget to be used in both artisan order lists and buyer order lists.
- `status` capitalisation in chip: `status[0].toUpperCase() + status.substring(1)` — converts `'pending'` to `'Pending'`.
- `_formatDate` must use a manual months list — do NOT import `intl` package for this formatting.

---

**File 3: `lib/widgets/cart_item_tile.dart`**

Replace the PR01 placeholder entirely. Write the complete file as specified in Section 6:

1. Import: `material.dart` only.
2. `class CartItemTile extends StatelessWidget` with `const` constructor and all 9 named parameters.
3. `build()` returning `Card` > `Padding` > `Row` with 72×72 image thumbnail, `SizedBox(width: 12)`, and `Expanded` details column.
4. `_buildQuantityStepper(BuildContext context)` private method — `Container` with border and `Row` of decrement `InkWell`, quantity count text (32px wide), increment `InkWell`.
5. `_buildImageFallback(BuildContext context)` private method (image icon).

**Critical rules:**
- Decrement `InkWell.onTap` must be `quantity > 1 ? onDecrement : null` — never allows quantity below 1.
- Item total shown as `₹${(price * quantity).toStringAsFixed(0)}` — the total for the line, not the unit price.
- `IconButton` for remove uses `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` — removes default 48dp touch target padding so the close icon sits flush in the row without excessive whitespace.
- `const` constructor is valid for `CartItemTile`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `Timestamp` requires `cloud_firestore` import in `order_card.dart`; `Hero` tag string interpolation `'product-$productId'`; `loadingBuilder` return type must be `Widget`; non-const constructor on `OrderCard` because `Timestamp` is not const.

2. **Verify `Hero` tag in `ProductCard`**
   ```
   grep 'product-\$productId' lib/widgets/product_card.dart
   ```
   Must return one line — the `Hero` tag string.

3. **Verify `_statusColor` is static**
   ```
   grep 'static Color _statusColor' lib/widgets/order_card.dart
   ```
   Must return one line.

4. **Verify all five status cases in `_statusColor`**
   ```
   grep -c 'AppConstants.status' lib/widgets/order_card.dart
   ```
   Must return `5` — one for each order status constant.

5. **Verify `showBuyerName` toggle**
   ```
   grep 'showBuyerName' lib/widgets/order_card.dart
   ```
   Must return at least three lines — field declaration, constructor default, and conditional usage.

6. **Verify decrement guard in `CartItemTile`**
   ```
   grep 'quantity > 1' lib/widgets/cart_item_tile.dart
   ```
   Must return at least two lines — the `onTap` condition and the icon colour condition.

7. **Verify `IconButton` zero padding in `CartItemTile`**
   ```
   grep 'EdgeInsets.zero' lib/widgets/cart_item_tile.dart
   ```
   Must return one line.

8. **Verify `_formatDate` uses manual month list**
   ```
   grep "'Jan'" lib/widgets/order_card.dart
   ```
   Must return one line confirming the manual months list is present.

9. **Hot reload on emulator — widget preview**
   ```
   flutter run
   ```
   These widgets are not yet wired to any screen that uses them with live data. Verify the app still launches and navigates correctly — no `UnimplementedError` or import errors introduced by these new files.
   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/widgets/product_card.dart`, `lib/widgets/order_card.dart`, and `lib/widgets/cart_item_tile.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 22
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
git commit -m "PR22: Reusable Widgets — ProductCard + OrderCard + CartItemTile"
git push origin pr22-reusable-widgets
```

---

## Section 9 – Acceptance Criteria

- [ ] `ProductCard` is a `StatelessWidget` with a `const` constructor and 8 named parameters matching the spec.
- [ ] `ProductCard` wraps its image in a `Hero` widget with tag `'product-$productId'`.
- [ ] `ProductCard` `Image.network` uses `loadingBuilder` with a progress-aware `CircularProgressIndicator` and `errorBuilder` falling back to `_buildImageFallback`.
- [ ] `ProductCard` renders an inactive overlay (`Positioned.fill` dark container with "Inactive" label) when `isActive` is false.
- [ ] `OrderCard` is a `StatelessWidget` with a non-const constructor and 11 named parameters including `showBuyerName` defaulting to `true`.
- [ ] `OrderCard._statusColor` is a `static` method returning colour-coded values for all five order status constants from `AppConstants`.
- [ ] `OrderCard._buildStatusChip` renders a colour-coded chip with capitalised status text.
- [ ] `OrderCard._formatDate` formats a `Timestamp` as `'DD Mon YYYY'` using a manual months list without the `intl` package.
- [ ] `CartItemTile` is a `StatelessWidget` with a `const` constructor and 9 named parameters including `onIncrement`, `onDecrement`, and `onRemove` callbacks.
- [ ] `CartItemTile._buildQuantityStepper` disables the decrement button when `quantity <= 1`.
- [ ] `CartItemTile` shows `₹${(price * quantity).toStringAsFixed(0)}` as the line total, not the unit price.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR22 for CraftBridge. I implemented the three reusable display widgets — `ProductCard`, `OrderCard`, and `CartItemTile` — that form the visual backbone of the buyer browsing, artisan order management, and cart flows. These widgets are used across six screens in PRs 23 through 48."

2. **`ProductCard` `Hero` animation tag:** "`ProductCard` wraps its image in a `Hero` widget with tag `'product-$productId'`. When a buyer taps a card to open `ProductDetailScreen` in PR32, and `ProductDetailScreen` also wraps its image in a `Hero` with the same tag, Flutter automatically animates the image from the grid position to the detail screen position. The exact tag format — `'product-'` prefix plus the product ID — is what PR25 and PR32 will reference."

3. **`Image.network` `loadingBuilder`:** "The `loadingBuilder` callback fires while the network image is loading. `loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!` gives a 0.0 to 1.0 progress value for the `CircularProgressIndicator`. When `expectedTotalBytes` is null — meaning the image server didn't report a content-length — the indicator is indeterminate. This is the correct pattern for network image loading."

4. **`ProductCard` inactive overlay:** "When `isActive` is false, a `Positioned.fill` dark overlay covers the image. `Positioned.fill` is equivalent to `Positioned(top: 0, bottom: 0, left: 0, right: 0)` — it stretches to fill the entire `Stack`. The overlay uses `Colors.black.withOpacity(0.45)` — semi-transparent black. The 'Inactive' label uses a `Colors.black54` pill for contrast. This gives artisans immediate visual feedback about which products are not visible to buyers."

5. **`OrderCard` `showBuyerName` toggle:** "`OrderCard` is used in two contexts: artisan order lists (where the artisan wants to know who the buyer is) and buyer order lists (where the buyer wants to know who the artisan is). The `showBuyerName` parameter — defaulting to `true` — controls which name is shown. When `ArtisanOrdersScreen` uses `OrderCard`, it passes `showBuyerName: true`. When `BuyerOrdersScreen` uses it, it passes `showBuyerName: false`. One widget, two contexts."

6. **`_statusColor` as a `static` method:** "`_statusColor` doesn't need `BuildContext` or any instance data — it's a pure function from status string to colour. Declaring it `static` means it can be called without constructing an `OrderCard` instance, which is useful if any other widget ever needs to map a status to a colour. It uses `AppConstants.statusPending` etc. rather than hardcoded strings."

7. **`_formatDate` without `intl`:** "The `intl` package would be the obvious choice for date formatting, but adding it for a single three-field date format is unnecessary overhead. A manual months list — `['Jan', 'Feb', ...]` — and string interpolation produces `'15 Mar 2025'` with zero dependencies. This is the pragmatic choice for a student project."

8. **`CartItemTile` quantity stepper:** "The stepper is a custom `Container` with a border and a `Row` of two `InkWell` buttons flanking a 32px-wide quantity text. `InkWell` is used instead of `IconButton` because `IconButton` has a 48dp minimum touch target that would make the stepper too wide. The decrement `onTap` is `null` when `quantity <= 1` — Flutter automatically removes the ripple effect when `onTap` is null, giving a natural disabled appearance."

9. **`CartItemTile` line total:** "The price shown in `CartItemTile` is `price * quantity` — the total for that line item, not the unit price. This is the standard e-commerce cart UX — users see what each line costs them in total, not the per-unit price they already saw on the product card. Unit price is available on the product detail screen."

10. **What's Next:** "PR23 will wire `ProductCard` into `BuyerHomeScreen` — replacing the `_PlaceholderProductCard` skeleton with real `ProductCard` widgets and adding responsive grid logic and category filtering with `MediaQuery` and `LayoutBuilder`."