# PR42 – CRUD Flow — CartProvider + CartScreen Fully Wired

**Project:** CraftBridge
**PR Number:** 42 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `CartProvider` with full local cart state management and wire `CartScreen` to it, replacing the single-item stub with a multi-item cart.

---

## Section 2 – Assignments Covered

- Assignment 3.42 — CRUD Flow — CartProvider + CartScreen Fully Wired

---

## Section 3 – Objective

This PR implements `CartProvider` — the local-only state management layer for the buyer's shopping cart — and wires `CartScreen` to it, replacing the single-item `ProductModel` stub from PR33 with a full multi-item cart. `ProductDetailScreen`'s "Add to Cart" button is updated to call `CartProvider.addItem()` instead of navigating directly to `CartScreen`. After this PR, buyers can add multiple products to their cart, adjust quantities, remove items, and place a single order per artisan from the cart — with the cart state persisting across screen navigations within a session.

---

## Section 4 – Architecture Context

```
CartProvider (ChangeNotifier — local only, no Firestore)
  ├── _items: Map<String, CartItemModel>
  │     (key: productId → prevents duplicate entries)
  ├── addItem(CartItemModel)
  ├── removeItem(String productId)
  ├── updateQuantity(String productId, int quantity)
  ├── clearCart()
  ├── totalPrice: double (computed)
  ├── itemCount: int (computed)
  └── items: List<CartItemModel> (unmodifiable)

ProductDetailScreen
  └── "Add to Cart" button
        └── context.read<CartProvider>().addItem(CartItemModel)
              → navigates to CartScreen if first item
              → shows snackbar "Added to cart" if already has items

CartScreen (fully wired)
  └── Consumer<CartProvider>
        ├── empty state → "Your cart is empty"
        └── items list → CartItemTile per item
              ├── onIncrement → CartProvider.updateQuantity(+1)
              ├── onDecrement → CartProvider.updateQuantity(-1)
              └── onRemove   → CartProvider.removeItem(productId)
        └── order summary
              └── "Place Order" → OrderProvider.createOrder() per unique artisan
                    → CartProvider.clearCart() on success
                    → BuyerOrdersScreen stub

lib/providers/cart_provider.dart      ← fully implemented this PR
lib/screens/buyer/cart_screen.dart    ← replaced with multi-item version
lib/screens/buyer/product_detail_screen.dart ← addToCart wired
```

This PR sits after user location (PR41) and before `OrderProvider` + `BuyerOrdersScreen` (PR43). `CartProvider` is registered in `MultiProvider` from PR08.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/cart_provider.dart`
- `lib/screens/buyer/cart_screen.dart`
- `lib/screens/buyer/product_detail_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`, `product_provider.dart`, or `order_provider.dart`.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/providers/cart_provider.dart`

Replace the PR08 minimal stub with the full implementation.

---

**Imports:**

```dart
import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/cart_item_model.dart';
```

---

**Class:** `CartProvider extends ChangeNotifier`

---

**Private fields:**

```dart
final Map<String, CartItemModel> _items = {};
```

A `Map<String, CartItemModel>` keyed by `productId` ensures each product appears at most once in the cart. Adding the same product twice increases its quantity rather than creating a duplicate entry.

---

**Public getters:**

```dart
List<CartItemModel> get items =>
    List.unmodifiable(_items.values.toList());

int get itemCount => _items.values
    .fold(0, (sum, item) => sum + item.quantity);

double get totalPrice => _items.values
    .fold(0.0, (sum, item) => sum + item.totalPrice);

bool get isEmpty => _items.isEmpty;

int get uniqueItemCount => _items.length;
```

---

**`addItem()` method:**

```dart
void addItem(CartItemModel item) {
  if (_items.containsKey(item.productId)) {
    final CartItemModel existing = _items[item.productId]!;
    _items[item.productId] = existing.copyWith(
      quantity: existing.quantity + item.quantity,
    );
  } else {
    _items[item.productId] = item;
  }
  notifyListeners();
}
```

If the product is already in the cart, the quantity is incremented. If not, the item is added as a new entry.

---

**`removeItem()` method:**

```dart
void removeItem(String productId) {
  _items.remove(productId);
  notifyListeners();
}
```

---

**`updateQuantity()` method:**

```dart
void updateQuantity(String productId, int quantity) {
  if (!_items.containsKey(productId)) return;
  if (quantity <= 0) {
    _items.remove(productId);
  } else {
    _items[productId] =
        _items[productId]!.copyWith(quantity: quantity);
  }
  notifyListeners();
}
```

If `quantity <= 0`, the item is removed. This handles the decrement-to-zero edge case.

---

**`clearCart()` method:**

```dart
void clearCart() {
  _items.clear();
  notifyListeners();
}
```

---

**`containsProduct()` method:**

```dart
bool containsProduct(String productId) {
  return _items.containsKey(productId);
}
```

---

**`getItemQuantity()` method:**

```dart
int getItemQuantity(String productId) {
  return _items[productId]?.quantity ?? 0;
}
```

---

### `lib/screens/buyer/product_detail_screen.dart`

Two targeted changes to the PR41 implementation.

---

**Change 1 — Add `CartProvider` import:**

```dart
import 'package:craft_bridge/providers/cart_provider.dart';
```

---

**Change 2 — Replace `_handleAddToCart()` with `CartProvider.addItem()` call:**

```dart
Future<void> _handleAddToCart() async {
  final CartItemModel cartItem = CartItemModel(
    productId: widget.product.id,
    title: widget.product.title,
    imageUrl: widget.product.imageUrl,
    price: widget.product.price,
    quantity: _quantity,
    artisanId: widget.product.artisanId,
    artisanName: widget.product.artisanName,
  );
  setState(() => _isAddingToCart = true);
  await Future.delayed(const Duration(milliseconds: 200));
  setState(() => _isAddingToCart = false);
  if (!mounted) return;
  context.read<CartProvider>().addItem(cartItem);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${widget.product.title} added to cart.'),
      action: SnackBarAction(
        label: 'View Cart',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
      ),
    ),
  );
}
```

**Key changes from PR33:**
- Creates a `CartItemModel` from the `ProductModel` and `_quantity`.
- Calls `CartProvider.addItem(cartItem)` — adds to the multi-item cart.
- Shows a snackbar with a "View Cart" action instead of navigating directly to `CartScreen`.
- `CartScreen` is now a `const` constructor — no parameters needed since it reads from `CartProvider`.

---

**Change 3 — Update `CartScreen` import and remove parameter:**

The `cart_screen.dart` import is already present from PR33. No import change needed.

The navigation in the snackbar action uses `const CartScreen()` — no product or quantity parameters, since `CartScreen` now reads from `CartProvider`.

---

### `lib/screens/buyer/cart_screen.dart`

Replace the PR33 single-item stub with the full multi-item `CartProvider`-driven implementation.

---

**Widget type:** `StatefulWidget`

**Class names:** `CartScreen` and `_CartScreenState`

**Imports:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/cart_item_model.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/cart_item_tile.dart';
import 'package:craft_bridge/widgets/custom_button.dart';
```

---

**`CartScreen` class:**

```dart
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}
```

No constructor parameters — reads from `CartProvider`.

---

**`_CartScreenState` fields:**

```dart
bool _isPlacingOrder = false;
```

---

**`_handlePlaceOrder()` method:**

```dart
Future<void> _handlePlaceOrder() async {
  final authProvider = context.read<AuthProvider>();
  final cartProvider = context.read<CartProvider>();
  final orderProvider = context.read<OrderProvider>();
  final String? buyerId = authProvider.currentUser?.uid;
  final String? buyerName = authProvider.currentUser?.displayName;
  if (buyerId == null || buyerName == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Error: user not authenticated.')),
    );
    return;
  }
  setState(() => _isPlacingOrder = true);
  final List<CartItemModel> items = cartProvider.items;
  bool allSuccess = true;
  for (final CartItemModel item in items) {
    final bool success = await orderProvider.createOrder(
      buyerId: buyerId,
      buyerName: buyerName,
      product: _cartItemToProductStub(item),
      quantity: item.quantity,
    );
    if (!success) {
      allSuccess = false;
    }
  }
  setState(() => _isPlacingOrder = false);
  if (!mounted) return;
  if (allSuccess) {
    cartProvider.clearCart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Order placed successfully! Check your order history.')),
    );
    Navigator.of(context).pop();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          orderProvider.errorMessage ?? 'Some orders failed to place.',
        ),
      ),
    );
  }
}
```

---

**`_cartItemToProductStub()` helper:**

`OrderProvider.createOrder()` requires a `ProductModel` parameter. Since `CartItemModel` has all the necessary fields but is not a `ProductModel`, a bridge is needed:

```dart
dynamic _cartItemToProductStub(CartItemModel item) {
  return _CartProductBridge(
    id: item.productId,
    artisanId: item.artisanId,
    artisanName: item.artisanName,
    title: item.title,
    imageUrl: item.imageUrl,
    price: item.price,
  );
}
```

Add a private bridge class at the bottom of `cart_screen.dart`:

```dart
class _CartProductBridge {
  final String id;
  final String artisanId;
  final String artisanName;
  final String title;
  final String imageUrl;
  final double price;

  const _CartProductBridge({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    required this.title,
    required this.imageUrl,
    required this.price,
  });
}
```

Wait — `OrderProvider.createOrder()` takes a `ProductModel` typed parameter. `_CartProductBridge` is not a `ProductModel`. This requires an update to `OrderProvider.createOrder()` to accept a more flexible type, OR rethinking the approach.

**Revised approach — update `OrderProvider.createOrder()` parameter type:**

Rather than a bridge class, update `OrderProvider.createOrder()` to accept named fields directly instead of a `ProductModel`:

```dart
Future<bool> createOrder({
  required String buyerId,
  required String buyerName,
  required String productId,
  required String productTitle,
  required String productImageUrl,
  required String artisanId,
  required String artisanName,
  required double price,
  required int quantity,
}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    final String orderId = FirebaseFirestore.instance
        .collection(AppConstants.ordersCollection)
        .doc()
        .id;
    final OrderModel order = OrderModel(
      id: orderId,
      buyerId: buyerId,
      buyerName: buyerName,
      artisanId: artisanId,
      artisanName: artisanName,
      productId: productId,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      quantity: quantity,
      totalPrice: price * quantity,
      status: AppConstants.statusPending,
      createdAt: Timestamp.now(),
    );
    await _firestoreService.createOrder(order);
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = 'Failed to place order: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

This change also requires updating the `CartScreen` from PR33 and the existing `CartScreen._handlePlaceOrder()` in PR33 to use the new named parameters. Since `cart_screen.dart` is being fully replaced in this PR, that is handled here.

**`order_provider.dart` must be modified this PR** to update `createOrder()` signature.

---

**`_buildEmptyCart()` method:**

```dart
Widget _buildEmptyCart() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: 80,
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Your cart is empty',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add products from the Browse screen.',
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

**`_buildOrderSummary()` method:**

```dart
Widget _buildOrderSummary(CartProvider cartProvider) {
  return Container(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 0.5,
        ),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cartProvider.itemCount} item${cartProvider.itemCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '₹${cartProvider.totalPrice.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
            ),
            Text(
              'Free',
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
            ),
          ],
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${cartProvider.totalPrice.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    color:
                        Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          label: 'Place Order',
          onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
          isLoading: _isPlacingOrder,
        ),
        const SizedBox(height: 8),
        Text(
          'No payment required for this demo order.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.45),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
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
      title: const Text('My Cart'),
      actions: [
        Consumer<CartProvider>(
          builder: (_, cartProvider, __) {
            if (cartProvider.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content:
                        const Text('Remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context
                              .read<CartProvider>()
                              .clearCart();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear'),
            );
          },
        ),
      ],
    ),
    body: Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        if (cartProvider.isEmpty) {
          return _buildEmptyCart();
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(
                    AppConstants.defaultPadding),
                itemCount: cartProvider.items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final CartItemModel item =
                      cartProvider.items[index];
                  return CartItemTile(
                    productId: item.productId,
                    title: item.title,
                    imageUrl: item.imageUrl,
                    price: item.price,
                    quantity: item.quantity,
                    artisanName: item.artisanName,
                    onIncrement: () =>
                        cartProvider.updateQuantity(
                      item.productId,
                      item.quantity + 1,
                    ),
                    onDecrement: () =>
                        cartProvider.updateQuantity(
                      item.productId,
                      item.quantity - 1,
                    ),
                    onRemove: () =>
                        cartProvider.removeItem(item.productId),
                  );
                },
              ),
            ),
            _buildOrderSummary(cartProvider),
          ],
        );
      },
    ),
  );
}
```

---

**`order_provider.dart` update** — Section 5 must be updated to include `order_provider.dart` as an allowed modification:

The `createOrder()` method signature change in `OrderProvider` is required because `CartScreen` calls `createOrder()` for each cart item using fields from `CartItemModel` (not a `ProductModel`). The PR33 signature `createOrder({..., required ProductModel product, ...})` must be updated to use individual fields.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/cart_provider.dart` | Full `CartProvider` with `Map`-based cart, `addItem`, `removeItem`, `updateQuantity`, `clearCart`, computed getters |
| 2 | `lib/screens/buyer/cart_screen.dart` | Full multi-item `CartScreen` with `Consumer<CartProvider>`, `CartItemTile` list, order summary, place order flow |
| 3 | `lib/screens/buyer/product_detail_screen.dart` | `_handleAddToCart()` updated to use `CartProvider.addItem()` with snackbar + "View Cart" action |
| 4 | `lib/providers/order_provider.dart` | `createOrder()` signature updated from `ProductModel` to individual named fields |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify four files.

---

**File 1: `lib/providers/cart_provider.dart`**

Replace the PR08 minimal stub entirely. Write the complete file as specified in Section 6 with all fields, getters, and methods.

**Critical rules:**
- `Map<String, CartItemModel>` keyed by `productId` — not `List`.
- `addItem()` uses `copyWith(quantity: existing.quantity + item.quantity)` for duplicate products.
- `updateQuantity()` removes the item when quantity reaches 0.
- `items` getter returns `List.unmodifiable(_items.values.toList())`.
- No Firebase calls — `CartProvider` is local state only.

---

**File 2: `lib/providers/order_provider.dart`**

Update `createOrder()` signature from `required ProductModel product` to individual named fields as specified in Section 6. Update the `OrderModel` construction inside accordingly. Remove `ProductModel` import if it was the only usage.

**Critical rule:** All existing `listenToArtisanOrders()`, `listenToBuyerOrders()`, `listenToAllOrders()`, `updateOrderStatus()`, `clearError()`, and `dispose()` are unchanged.

---

**File 3: `lib/screens/buyer/cart_screen.dart`**

Replace the PR33 stub with the full implementation. Write the complete file as specified in Section 6. No `_CartProductBridge` class needed — `createOrder()` now takes individual fields.

---

**File 4: `lib/screens/buyer/product_detail_screen.dart`**

Two targeted changes:
1. Add `CartProvider` import.
2. Replace `_handleAddToCart()` with the `CartProvider.addItem()` version.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `CartItemModel.totalPrice` getter — confirm it exists from PR07; `createOrder` signature change — check all call sites; `CartScreen` const constructor — verify `const CartScreen()` is valid now that it has no required parameters.

2. **Verify `CartProvider` Map backing**
   ```
   grep 'Map<String, CartItemModel>' lib/providers/cart_provider.dart
   ```
   Must return one line — the `_items` field declaration.

3. **Verify `addItem` deduplication**
   ```
   grep 'containsKey' lib/providers/cart_provider.dart
   ```
   Must return at least one line — the duplicate check in `addItem`.

4. **Verify `updateQuantity` zero-removal**
   ```
   grep 'quantity <= 0' lib/providers/cart_provider.dart
   ```
   Must return one line.

5. **Verify `createOrder` signature updated**
   ```
   grep 'required String productId' lib/providers/order_provider.dart
   ```
   Must return one line — confirming individual field parameters.

6. **Verify `CartScreen` has no constructor parameters**
   ```
   grep 'const CartScreen({super.key})' lib/screens/buyer/cart_screen.dart
   ```
   Must return one line.

7. **Verify `Consumer<CartProvider>` in `CartScreen`**
   ```
   grep -c 'Consumer<CartProvider>' lib/screens/buyer/cart_screen.dart
   ```
   Must return at least `2` — one for the app bar action and one for the body.

8. **Verify `_handleAddToCart` uses `CartProvider`**
   ```
   grep 'CartProvider' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — import and `addItem` call.

9. **Hot reload on emulator — full cart flow test**
   ```
   flutter run
   ```
   Log in as a buyer.

   **Add multiple items:**
   - Browse to product A → set quantity to 2 → tap "Add to Cart".
   - Snackbar "Product A added to cart." with "View Cart" action appears.
   - Browse to product B → tap "Add to Cart".
   - Tap "View Cart" in snackbar OR navigate to Cart tab.

   **Cart screen validation:**
   - `CartScreen` shows both items in `CartItemTile` widgets.
   - Item count in order summary correct.
   - Total price correct.
   - Increment/decrement quantity on item A — total price updates.
   - Remove item B — item disappears, total updates.
   - Tap "Clear" in app bar → AlertDialog → confirm → cart empties, empty state shown.

   **Add same product twice:**
   - Add product A (qty 1), then add product A again (qty 1).
   - Cart shows product A once with quantity 2 — not two separate entries.

   **Place order:**
   - Add items from cart → tap "Place Order" → loading spinner → success snackbar.
   - Cart is cleared after successful order.
   - Firebase Console → `orders` → confirm one order document per cart item.

   Press `q` to quit.

10. **Verify correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/providers/cart_provider.dart`, `lib/providers/order_provider.dart`, `lib/screens/buyer/cart_screen.dart`, `lib/screens/buyer/product_detail_screen.dart`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 42
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
git commit -m "PR42: CRUD Flow — CartProvider + CartScreen Fully Wired"
git push origin pr42-cart-provider
```

---

## Section 9 – Acceptance Criteria

- [ ] `CartProvider` uses `Map<String, CartItemModel>` keyed by `productId` — adding the same product twice increases quantity, not creates a duplicate entry.
- [ ] `CartProvider.addItem()`, `removeItem()`, `updateQuantity()`, `clearCart()`, `containsProduct()`, `getItemQuantity()` are all implemented.
- [ ] `CartProvider.updateQuantity()` removes the item when quantity reaches 0 or below.
- [ ] `CartProvider.items` getter returns `List.unmodifiable(...)`.
- [ ] `OrderProvider.createOrder()` accepts individual named fields (not `ProductModel`) — `productId`, `productTitle`, `productImageUrl`, `artisanId`, `artisanName`, `price`.
- [ ] `CartScreen` is a `StatefulWidget` with `const CartScreen({super.key})` — no constructor parameters.
- [ ] `CartScreen` uses `Consumer<CartProvider>` for both app bar action and body.
- [ ] `CartScreen._handlePlaceOrder()` iterates over all cart items and calls `OrderProvider.createOrder()` for each, then calls `CartProvider.clearCart()` on full success.
- [ ] `ProductDetailScreen._handleAddToCart()` calls `CartProvider.addItem()` and shows a snackbar with "View Cart" action.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR42 for CraftBridge. I implemented `CartProvider` — the local multi-item cart state — and wired `CartScreen` to it, replacing the single-item PR33 stub with a full cart experience where buyers can add multiple products, adjust quantities, and place orders for all items at once."

2. **`Map<String, CartItemModel>` backing store:** "`CartProvider` uses a `Map` keyed by `productId` rather than a `List`. This prevents duplicate entries — if a buyer taps 'Add to Cart' on the same product twice, the second call finds the existing entry and increments the quantity rather than adding a second line item. A `List` would require a `.firstWhere` search for duplicates on every add; the `Map` lookup is O(1)."

3. **`addItem()` deduplication logic:** "The `containsKey` check is the core of deduplication. If the product is already in the map, `copyWith(quantity: existing.quantity + item.quantity)` merges the quantities. If not, the item is inserted directly. This means adding product A twice with quantity 1 each results in a single cart entry for product A with quantity 2."

4. **`updateQuantity()` zero-removal:** "`updateQuantity()` removes the item when quantity reaches 0 or below. This handles the `CartItemTile` decrement button edge case — when the buyer decrements from 1 to 0, the item is removed rather than showing a 0-quantity entry. This is the standard e-commerce cart pattern."

5. **`CartProvider` as local-only state:** "`CartProvider` never calls `FirebaseFirestore` or `StorageService`. The cart exists only in device memory for the duration of the app session. When the app is terminated and relaunched, the cart is empty. This is a deliberate MVP simplification — persisting the cart to Firestore would require additional collection management and is a post-MVP enhancement."

6. **`OrderProvider.createOrder()` signature change:** "The PR33 `createOrder()` took a `ProductModel` parameter. `CartScreen` has `CartItemModel` objects, not `ProductModel` objects. Rather than converting between types, the method signature was updated to accept individual named fields that both `ProductModel` and `CartItemModel` provide. This is a clean refactor — all existing call sites in `CartScreen` and the PR33 test path are updated accordingly."

7. **Iterating cart items for order placement:** "`CartScreen._handlePlaceOrder()` iterates over `cartProvider.items` and calls `orderProvider.createOrder()` once per item. Each product potentially comes from a different artisan — one order document per product is the correct data model. `allSuccess` tracks whether all orders succeeded; if any fail, the error message is shown without clearing the cart."

8. **"View Cart" snackbar action:** "When a buyer taps 'Add to Cart' on `ProductDetailScreen`, a snackbar appears with a 'View Cart' action button. Tapping the action navigates to `CartScreen`. This is a standard mobile cart UX pattern — the buyer can continue browsing and add more items, or immediately review the cart. The snackbar disappears after 4 seconds without action."

9. **Cart cleared on success, preserved on failure:** "`CartProvider.clearCart()` is called only when `allSuccess == true`. If any order in the batch fails, the cart retains its items and the buyer sees an error message. This prevents the cart from being cleared when an order fails, allowing the buyer to retry."

10. **What's Next:** "PR43 will implement `OrderProvider.listenToBuyerOrders()` wiring and the full `BuyerOrdersScreen` — giving buyers a real-time view of all their placed orders with status tracking."