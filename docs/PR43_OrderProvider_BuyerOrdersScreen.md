# PR43 – Provider — OrderProvider + BuyerOrdersScreen

**Project:** CraftBridge
**PR Number:** 43 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `BuyerOrdersScreen` with live `OrderProvider.listenToBuyerOrders()` stream and wire the buyer orders tab in `BuyerHomeScreen`'s `BottomNavigationBar`.

---

## Section 2 – Assignments Covered

- Assignment 3.43 — Provider — OrderProvider + BuyerOrdersScreen

---

## Section 3 – Objective

This PR implements `BuyerOrdersScreen` — the screen where buyers view all their placed orders with live status updates — and wires it into `BuyerHomeScreen`'s `BottomNavigationBar` so buyers can navigate to it via the Orders tab. `OrderProvider.listenToBuyerOrders()` was implemented in PR34 — this PR creates the screen that consumes it. After this PR, buyers can track every order they've placed, see real-time status updates as artisans advance orders through the fulfillment pipeline, and navigate back to `BuyerHomeScreen` from the Orders tab.

---

## Section 4 – Architecture Context

```
BuyerHomeScreen
  └── BottomNavigationBar (3 tabs)
        ├── index 0: Home → BuyerHomeScreen product grid
        ├── index 1: Cart → CartScreen
        └── index 2: Orders → BuyerOrdersScreen (this PR)

BuyerOrdersScreen (StatefulWidget)
  │
  ├── initState() → OrderProvider.listenToBuyerOrders(buyerId)
  │
  └── build() → Consumer<OrderProvider>
                    ├── isLoading → CircularProgressIndicator
                    ├── errorMessage → error widget with retry
                    ├── buyerOrders.isEmpty → empty state
                    └── buyerOrders.isNotEmpty
                          └── ListView of OrderCard
                                (showBuyerName: false — show artisan name)

BuyerHomeScreen (updated this PR)
  └── BottomNavigationBar onTap → IndexedStack
        ├── index 0: BuyerHomeScreen content
        ├── index 1: CartScreen
        └── index 2: BuyerOrdersScreen

Files modified this PR:
  lib/screens/buyer/buyer_orders_screen.dart  ← full implementation
  lib/screens/buyer/buyer_home_screen.dart    ← IndexedStack + nav wiring
```

This PR sits after `CartProvider` (PR42) and before the review form (PR44). `OrderProvider.listenToBuyerOrders()` is already implemented in PR34 — this PR builds the screen on top of it.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/buyer/buyer_orders_screen.dart`
- `lib/screens/buyer/buyer_home_screen.dart`

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

### `lib/screens/buyer/buyer_orders_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `BuyerOrdersScreen` and `_BuyerOrdersScreenState`

**Imports:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/order_card.dart';
```

---

**`BuyerOrdersScreen` class:**

```dart
class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}
```

---

**`_BuyerOrdersScreenState`:**

**`initState()` method:**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final String? buyerId =
        context.read<AuthProvider>().currentUser?.uid;
    if (buyerId != null) {
      context
          .read<OrderProvider>()
          .listenToBuyerOrders(buyerId);
    }
  });
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
          Icons.receipt_long_outlined,
          size: 80,
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No orders yet',
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
          'Products you order will appear here.',
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

**`_buildOrderList()` method:**

```dart
Widget _buildOrderList(List<dynamic> orders) {
  return ListView.separated(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    itemCount: orders.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final order = orders[index];
      return OrderCard(
        orderId: order.id,
        productTitle: order.productTitle,
        productImageUrl: order.productImageUrl,
        buyerName: order.buyerName,
        artisanName: order.artisanName,
        quantity: order.quantity,
        totalPrice: order.totalPrice,
        status: order.status,
        createdAt: order.createdAt,
        showBuyerName: false,
      );
    },
  );
}
```

**Note:** `showBuyerName: false` — buyers see the artisan name on their order cards, not their own name.

---

**`build()` method:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: const Text('My Orders'),
      automaticallyImplyLeading: false,
      actions: [
        Consumer<OrderProvider>(
          builder: (_, orderProvider, __) {
            final int count = orderProvider.buyerOrders.length;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '$count order${count == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          },
        ),
      ],
    ),
    body: Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orderProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  orderProvider.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    orderProvider.clearError();
                    final String? buyerId = context
                        .read<AuthProvider>()
                        .currentUser
                        ?.uid;
                    if (buyerId != null) {
                      orderProvider.listenToBuyerOrders(buyerId);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (orderProvider.buyerOrders.isEmpty) {
          return _buildEmptyState();
        }
        return _buildOrderList(orderProvider.buyerOrders);
      },
    ),
  );
}
```

**`automaticallyImplyLeading: false`** — `BuyerOrdersScreen` is displayed inside an `IndexedStack` within `BuyerHomeScreen`, not pushed via `Navigator`. It has no back button because it is a tab screen, not a pushed route.

---

### `lib/screens/buyer/buyer_home_screen.dart`

Replace the stub `BottomNavigationBar` with a full `IndexedStack`-based tab navigation. Five targeted changes.

---

**Change 1 — Add imports:**

```dart
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/screens/buyer/cart_screen.dart';
import 'package:craft_bridge/screens/buyer/buyer_orders_screen.dart';
```

---

**Change 2 — Remove body `Column` from `Scaffold.body` and replace with `IndexedStack`:**

The PR32/PR42 `build()` has:
```dart
body: AnimatedOpacity(
  ...
  child: Column(
    children: [
      _buildSearchBar(),
      _buildCategoryChips(),
      Expanded(child: _buildProductGrid()),
    ],
  ),
),
```

The entire `Scaffold` `body` changes to an `IndexedStack` that swaps between the three tab screens:

```dart
body: IndexedStack(
  index: _currentNavIndex,
  children: [
    AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeIn,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    ),
    const CartScreen(),
    const BuyerOrdersScreen(),
  ],
),
```

**`IndexedStack` behaviour:** All three children are built and kept in the tree simultaneously. `IndexedStack` shows only the child at `index` matching `_currentNavIndex` — the others are hidden but remain mounted. This preserves scroll positions and loaded state across tab switches.

---

**Change 3 — Update `BottomNavigationBar` to show cart badge:**

Replace the PR17 `BottomNavigationBar` with a version that shows a badge on the Cart tab when items are in the cart:

```dart
bottomNavigationBar: Consumer<CartProvider>(
  builder: (context, cartProvider, _) {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) => setState(() => _currentNavIndex = index),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: cartProvider.itemCount > 0,
            label: Text('${cartProvider.itemCount}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: cartProvider.itemCount > 0,
            label: Text('${cartProvider.itemCount}'),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ],
    );
  },
),
```

**`Badge` widget:** Flutter 3.10+ provides `Badge` as a Material 3 widget. It wraps any widget and shows a count label. `isLabelVisible: cartProvider.itemCount > 0` hides the badge when the cart is empty.

---

**Change 4 — Update `AppBar` to show sign-out only on Home tab:**

Update the `AppBar` `actions` to conditionally show the sign-out button only when on the Home tab (`_currentNavIndex == 0`):

```dart
appBar: AppBar(
  title: Text(_currentNavIndex == 0
      ? 'Discover'
      : _currentNavIndex == 1
          ? 'My Cart'
          : 'My Orders'),
  actions: [
    if (_currentNavIndex == 0)
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Sign Out',
        onPressed: () =>
            context.read<AuthProvider>().signOut(),
      ),
  ],
),
```

---

**Change 5 — Remove `_buildSearchBar` and `_buildCategoryChips` `setState` calls that reference `_selectedCategory`:**

These were already updated in PR35 — no further change needed.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_orders_screen.dart` | Full `BuyerOrdersScreen` — `Consumer<OrderProvider>`, loading/error/empty/list states, `OrderCard` with `showBuyerName: false`, `automaticallyImplyLeading: false` |
| 2 | `lib/screens/buyer/buyer_home_screen.dart` | `IndexedStack` body with three tab screens, cart badge on `BottomNavigationBar`, dynamic `AppBar` title |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/screens/buyer/buyer_orders_screen.dart`**

Replace the PR01 placeholder comment with the full implementation specified in Section 6. Write the complete file:

1. All six import statements.
2. `BuyerOrdersScreen extends StatefulWidget` with `const` constructor.
3. `_BuyerOrdersScreenState` with:
   - `initState()` using `addPostFrameCallback` calling `listenToBuyerOrders(buyerId)`.
   - `_buildEmptyState()` — receipt icon, "No orders yet", subtitle.
   - `_buildOrderList(List orders)` — `ListView.separated` with `OrderCard` widgets, `showBuyerName: false`.
   - `build()` — `Scaffold` with `automaticallyImplyLeading: false`, order count in app bar action via `Consumer`, body `Consumer<OrderProvider>` with four states.

**Critical rules:**
- `automaticallyImplyLeading: false` — no back button since this is a tab, not a pushed screen.
- `showBuyerName: false` on all `OrderCard` widgets — buyers see artisan names.
- `listenToBuyerOrders` must be called in `initState` via `addPostFrameCallback`.
- Error state includes "Retry" `TextButton` that re-calls `listenToBuyerOrders`.

---

**File 2: `lib/screens/buyer/buyer_home_screen.dart`**

Make the five targeted changes specified in Section 6:

1. Add `CartProvider`, `CartScreen`, and `BuyerOrdersScreen` imports.
2. Replace `Scaffold.body` `AnimatedOpacity(Column(...))` with `IndexedStack` containing three children: the existing `AnimatedOpacity` home content, `const CartScreen()`, and `const BuyerOrdersScreen()`.
3. Replace `BottomNavigationBar` with `Consumer<CartProvider>`-wrapped version including `Badge` on the Cart tab.
4. Update `AppBar` to show dynamic title and conditional sign-out action.
5. Ensure no other structural changes — `_contentOpacity`, `initState()`, `dispose()`, `_buildSearchBar()`, `_buildCategoryChips()`, `_buildProductGrid()`, `_buildEmptyState()`, `_filteredProducts` getter all unchanged.

**Critical rules:**
- `IndexedStack` must be the direct child of `Scaffold.body` — not wrapped in `AnimatedOpacity` at the top level.
- Only the Home tab content (index 0) gets the `AnimatedOpacity` wrapper — Cart and Orders tabs don't need fade-in.
- `Badge` from `package:flutter/material.dart` — no additional import needed.
- `Consumer<CartProvider>` wraps the entire `BottomNavigationBar` — not just the Cart item — so the badge updates trigger a rebuild of the whole bar.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `Badge` widget — available in Flutter 3.10+; `automaticallyImplyLeading: false` must be on the `AppBar`, not the `Scaffold`; `_buildOrderList` parameter type — use `List<OrderModel>` with proper import.

2. **Verify `automaticallyImplyLeading: false`**
   ```
   grep 'automaticallyImplyLeading' lib/screens/buyer/buyer_orders_screen.dart
   ```
   Must return one line.

3. **Verify `showBuyerName: false`**
   ```
   grep 'showBuyerName: false' lib/screens/buyer/buyer_orders_screen.dart
   ```
   Must return at least one line.

4. **Verify `IndexedStack` in `buyer_home_screen.dart`**
   ```
   grep 'IndexedStack' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

5. **Verify `Badge` widget in `BottomNavigationBar`**
   ```
   grep 'Badge(' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines — one for unselected, one for selected cart icon.

6. **Verify `Consumer<CartProvider>` wraps `BottomNavigationBar`**
   ```
   grep -B2 'BottomNavigationBar(' lib/screens/buyer/buyer_home_screen.dart | grep 'Consumer<CartProvider>'
   ```
   Must return one line.

7. **Verify three IndexedStack children**
   ```
   grep 'CartScreen\|BuyerOrdersScreen' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines — one for each screen in the `IndexedStack`.

8. **Hot reload on emulator — full buyer tab navigation test**
   ```
   flutter run
   ```
   Log in as a buyer.

   **Home tab (index 0):**
   - "Discover" in app bar, sign-out icon visible.
   - Product grid, search bar, category chips all functional.

   **Cart tab (index 1):**
   - Tap Cart tab → app bar title changes to "My Cart".
   - No sign-out icon.
   - If cart is empty: empty cart state shown.
   - Add a product (go to Home → product → Add to Cart) → Cart tab badge shows count.
   - Return to Cart tab → `CartScreen` shows the added item.

   **Orders tab (index 2):**
   - Tap Orders tab → app bar title changes to "My Orders".
   - No back button in app bar.
   - If no orders placed: empty state shown.
   - Place an order (from Cart) → return to Orders tab → order appears in real time.
   - `OrderCard` shows artisan name (not buyer name).

   **Tab state preservation:**
   - Switch to Home tab, scroll down → switch to Orders tab → switch back to Home → scroll position preserved (IndexedStack keeps all tabs mounted).

   **Badge test:**
   - Add item to cart → Cart tab badge shows "1".
   - Add another item → badge shows "2".
   - Remove items from CartScreen → badge disappears when cart is empty.

   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/buyer/buyer_orders_screen.dart` and `lib/screens/buyer/buyer_home_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 43
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
git commit -m "PR43: Provider — OrderProvider + BuyerOrdersScreen"
git push origin pr43-buyer-orders
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerOrdersScreen` is a `StatefulWidget` with `automaticallyImplyLeading: false` on its `AppBar`.
- [ ] `initState()` calls `OrderProvider.listenToBuyerOrders(buyerId)` via `addPostFrameCallback`.
- [ ] `build()` uses `Consumer<OrderProvider>` with four states: loading, error with retry, empty, list.
- [ ] All `OrderCard` widgets use `showBuyerName: false` — artisan names are shown.
- [ ] `BuyerHomeScreen.body` uses `IndexedStack` with three children: Home content, `CartScreen`, `BuyerOrdersScreen`.
- [ ] `BottomNavigationBar` is wrapped in `Consumer<CartProvider>` and shows a `Badge` on the Cart tab when `cartProvider.itemCount > 0`.
- [ ] `AppBar` title dynamically shows "Discover", "My Cart", or "My Orders" based on `_currentNavIndex`.
- [ ] Sign-out `IconButton` is only shown on the Home tab (`_currentNavIndex == 0`).
- [ ] Tab state is preserved across switches — `IndexedStack` keeps all three screens mounted.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR43 for CraftBridge. I implemented `BuyerOrdersScreen` with live order tracking via `OrderProvider.listenToBuyerOrders()`, and upgraded `BuyerHomeScreen` to use `IndexedStack` with full tab navigation — including a cart badge that shows the number of items in the cart."

2. **`automaticallyImplyLeading: false`:** "`BuyerOrdersScreen` sets `automaticallyImplyLeading: false` on its `AppBar`. Without this, Flutter would render a back arrow because the screen is inside a `Navigator` context. But `BuyerOrdersScreen` is a tab screen inside an `IndexedStack` — it should not have a back button. `automaticallyImplyLeading: false` removes the default back arrow."

3. **`showBuyerName: false` on OrderCard:** "Buyers don't need to see their own name on their order history — they already know who they are. They want to see which artisan is fulfilling each order. `showBuyerName: false` switches the `OrderCard` subtitle from 'Buyer: [name]' to 'Artisan: [name]'. The same `OrderCard` widget serves both artisan and buyer contexts with this single boolean."

4. **`IndexedStack` vs `Navigator.push` for tab navigation:** "`IndexedStack` keeps all three tab screens mounted simultaneously and shows only the one at the current index. This means switching from Home to Orders doesn't rebuild the orders screen — it was already mounted, its stream is already active, and its scroll position is preserved. `Navigator.push` would unmount the previous screen, losing its state."

5. **Cart badge with `Badge` widget:** "Flutter 3.10's `Badge` widget wraps any widget with a small count indicator. `isLabelVisible: cartProvider.itemCount > 0` hides the badge when the cart is empty. The entire `BottomNavigationBar` is wrapped in `Consumer<CartProvider>` so any cart change triggers a rebuild that updates the badge count. The badge shows the total item count (sum of quantities), not the unique product count."

6. **Dynamic `AppBar` title:** "The `AppBar` title changes based on `_currentNavIndex` — 'Discover' for Home, 'My Cart' for Cart, 'My Orders' for Orders. This gives the buyer clear context about which tab they're on. The sign-out `IconButton` only appears on the Home tab — it would be out of place in the Cart or Orders app bars."

7. **`OrderProvider.listenToBuyerOrders()` timing:** "`listenToBuyerOrders()` is called in `initState()` via `addPostFrameCallback`. Since `BuyerOrdersScreen` is in an `IndexedStack`, it is mounted when `BuyerHomeScreen` mounts — even before the buyer taps the Orders tab. The Firestore stream starts immediately, so when the buyer first taps Orders, the order list is already loaded."

8. **Real-time order status updates:** "When an artisan updates an order status in `ArtisanOrdersScreen`, the `getOrdersByBuyer` stream fires and `OrderProvider._buyerOrders` updates. The `Consumer<OrderProvider>` in `BuyerOrdersScreen` rebuilds the `OrderCard` with the new status chip. The buyer sees the status change in real time — from 'Pending' to 'Confirmed' to 'Shipped' — without any manual refresh."

9. **Tab state preservation demo:** "On the emulator: scroll down in the Home tab to see products below the fold. Tap Cart tab. Tap Home tab. The scroll position in the Home tab is preserved — the `IndexedStack` never unmounts the Home content. This is the key UX advantage of `IndexedStack` over `Navigator.push` for tab navigation."

10. **What's Next:** "PR44 will implement the review submission form on `ProductDetailScreen` — a bottom sheet where buyers can submit star ratings and comments on products they've purchased, writing to the `reviews` Firestore collection."