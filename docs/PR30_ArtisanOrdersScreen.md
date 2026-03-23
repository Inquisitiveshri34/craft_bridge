# PR30 – Session Persistence — ArtisanOrdersScreen

**Project:** CraftBridge
**PR Number:** 30 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `ArtisanOrdersScreen` with `StreamBuilder` order list, implement `OrderProvider` stub with artisan order stream, and implement `FirestoreService` order stream methods for artisan.

---

## Section 2 – Assignments Covered

- Assignment 3.30 — Session Persistence — ArtisanOrdersScreen

---

## Section 3 – Objective

This PR implements `ArtisanOrdersScreen` — the screen where artisans view all incoming orders for their products — using a `StreamBuilder` that listens to a live Firestore stream. `OrderProvider` is upgraded from its PR08 minimal stub to a full `ChangeNotifier` with artisan order stream management. `FirestoreService.getOrdersByArtisan()` is implemented, filling one of the three Order Stream Method stubs from PR07. After this PR, artisans can see all their orders in real time, with orders grouped by status and colour-coded using the `OrderCard` widget from PR22.

---

## Section 4 – Architecture Context

```
ArtisanHomeScreen
    └── "My Orders" → ArtisanOrdersScreen (this PR)

ArtisanOrdersScreen (StatefulWidget)
    │
    ├── initState() → OrderProvider.listenToArtisanOrders(artisanId)
    │
    └── build() → Consumer<OrderProvider>
                      ├── isLoading → CircularProgressIndicator
                      ├── errorMessage → error widget
                      ├── artisanOrders.isEmpty → empty state
                      └── artisanOrders.isNotEmpty → ListView of OrderCard

OrderProvider (ChangeNotifier — implemented this PR)
    ├── _artisanOrders: List<OrderModel>
    ├── _isLoading: bool
    ├── _errorMessage: String?
    ├── _artisanOrdersSubscription: StreamSubscription?
    │
    ├── listenToArtisanOrders(String artisanId)
    │     └── FirestoreService.getOrdersByArtisan(artisanId)
    │
    └── dispose()

FirestoreService.getOrdersByArtisan(String artisanId) ← implemented this PR
    → _db.collection('orders')
         .where('artisanId', isEqualTo: artisanId)
         .orderBy('createdAt', descending: true)
         .snapshots()
         → Stream<List<OrderModel>>

firestore_service.dart UnimplementedError count:
    Before: 12
    After:  11 (getOrdersByArtisan filled)
```

This PR sits after auth flow testing (PR29) and before full product CRUD (PR31). It introduces `OrderProvider` and implements the first of the three order stream methods in `FirestoreService`.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/artisan/artisan_orders_screen.dart`
- `lib/providers/order_provider.dart`
- `lib/services/firestore_service.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart` or `product_provider.dart` or `cart_provider.dart`.
- Do NOT modify any screen files other than `artisan_orders_screen.dart`.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/firestore_service.dart`

Replace only the `getOrdersByArtisan` stub body. All other method stubs and implementations remain unchanged.

---

**Implemented `getOrdersByArtisan` method:**

```dart
Stream<List<OrderModel>> getOrdersByArtisan(String artisanId) {
  return _db
      .collection(AppConstants.ordersCollection)
      .where('artisanId', isEqualTo: artisanId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data()))
          .toList());
}
```

**Implementation notes:**

- `.orderBy('createdAt', descending: true)` — orders are shown newest first. This requires a composite index in Firestore for `artisanId` + `createdAt`. The Firestore emulator creates indexes automatically; the live project will prompt for index creation in the debug console when this query first runs.
- The method must NOT be declared `async` — it returns a `Stream`, not a `Future`.
- Uses `AppConstants.ordersCollection`, not the hardcoded string `'orders'`.

---

**`UnimplementedError` count after this PR:**

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `11`.

---

### `lib/providers/order_provider.dart`

Replace the PR08 minimal stub with the full implementation.

---

**Imports:**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
```

---

**Class:** `OrderProvider extends ChangeNotifier`

---

**Private fields:**

```dart
final FirestoreService _firestoreService = FirestoreService();
List<OrderModel> _artisanOrders = [];
List<OrderModel> _buyerOrders = [];
List<OrderModel> _allOrders = [];
bool _isLoading = false;
String? _errorMessage;
StreamSubscription<List<OrderModel>>? _artisanOrdersSubscription;
StreamSubscription<List<OrderModel>>? _buyerOrdersSubscription;
StreamSubscription<List<OrderModel>>? _allOrdersSubscription;
```

---

**Public getters:**

```dart
List<OrderModel> get artisanOrders => List.unmodifiable(_artisanOrders);
List<OrderModel> get buyerOrders => List.unmodifiable(_buyerOrders);
List<OrderModel> get allOrders => List.unmodifiable(_allOrders);
bool get isLoading => _isLoading;
String? get errorMessage => _errorMessage;
```

---

**`listenToArtisanOrders()` method:**

```dart
void listenToArtisanOrders(String artisanId) {
  _artisanOrdersSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  _artisanOrdersSubscription =
      _firestoreService.getOrdersByArtisan(artisanId).listen(
    (orderList) {
      _artisanOrders = orderList;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (Object error) {
      _errorMessage = 'Failed to load orders: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}
```

---

**`listenToBuyerOrders()` stub method:**

```dart
void listenToBuyerOrders(String buyerId) {
  // Implemented in PR43
}
```

---

**`listenToAllOrders()` stub method:**

```dart
void listenToAllOrders() {
  // Implemented in PR48
}
```

---

**`clearError()` method:**

```dart
void clearError() {
  _errorMessage = null;
  notifyListeners();
}
```

---

**`dispose()` override:**

```dart
@override
void dispose() {
  _artisanOrdersSubscription?.cancel();
  _buyerOrdersSubscription?.cancel();
  _allOrdersSubscription?.cancel();
  super.dispose();
}
```

---

### `lib/screens/artisan/artisan_orders_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `ArtisanOrdersScreen` and `_ArtisanOrdersScreenState`

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

**`ArtisanOrdersScreen` class:**

```dart
class ArtisanOrdersScreen extends StatefulWidget {
  const ArtisanOrdersScreen({super.key});

  @override
  State<ArtisanOrdersScreen> createState() => _ArtisanOrdersScreenState();
}
```

---

**`_ArtisanOrdersScreenState`:**

**`initState()` method:**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final String? artisanId =
        context.read<AuthProvider>().currentUser?.uid;
    if (artisanId != null) {
      context.read<OrderProvider>().listenToArtisanOrders(artisanId);
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'No orders yet',
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
          'Orders from buyers will appear here.',
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
Widget _buildOrderList(List<OrderModel> orders) {
  return ListView.separated(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    itemCount: orders.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final OrderModel order = orders[index];
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
        showBuyerName: true,
        onTap: () => _showOrderStatusSheet(context, order),
      );
    },
  );
}
```

---

**`_showOrderStatusSheet()` method:**

```dart
void _showOrderStatusSheet(BuildContext context, OrderModel order) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Order Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            order.productTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          const Divider(height: 24),
          ..._buildStatusOptions(ctx, order),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
```

---

**`_buildStatusOptions()` method:**

```dart
List<Widget> _buildStatusOptions(
    BuildContext ctx, OrderModel order) {
  final List<Map<String, dynamic>> statuses = [
    {
      'status': AppConstants.statusConfirmed,
      'label': 'Confirmed',
      'icon': Icons.check_circle_outline,
      'color': Colors.blue.shade700,
    },
    {
      'status': AppConstants.statusShipped,
      'label': 'Shipped',
      'icon': Icons.local_shipping_outlined,
      'color': Colors.purple.shade700,
    },
    {
      'status': AppConstants.statusDelivered,
      'label': 'Delivered',
      'icon': Icons.done_all,
      'color': Colors.green.shade700,
    },
    {
      'status': AppConstants.statusCancelled,
      'label': 'Cancelled',
      'icon': Icons.cancel_outlined,
      'color': Colors.red.shade700,
    },
  ];
  return statuses.map((statusMap) {
    final bool isCurrent = order.status == statusMap['status'];
    return ListTile(
      leading: Icon(
        statusMap['icon'] as IconData,
        color: isCurrent
            ? statusMap['color'] as Color
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
      title: Text(
        statusMap['label'] as String,
        style: TextStyle(
          color: isCurrent
              ? statusMap['color'] as Color
              : Theme.of(context).colorScheme.onSurface,
          fontWeight:
              isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isCurrent
          ? Icon(Icons.check,
              color: statusMap['color'] as Color, size: 20)
          : null,
      onTap: isCurrent
          ? null
          : () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Status update to "${statusMap['label']}" — wired in PR37.',
                  ),
                ),
              );
            },
    );
  }).toList();
}
```

**Note:** The `onTap` in `_buildStatusOptions` shows a stub snackbar in this PR. In PR37, it will call `OrderProvider.updateOrderStatus()` which calls `FirestoreService.updateOrderStatus()`.

---

**`build()` method:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      title: const Text('My Orders'),
      actions: [
        Consumer<OrderProvider>(
          builder: (_, orderProvider, __) {
            final int count = orderProvider.artisanOrders.length;
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
                    final String? artisanId =
                        context.read<AuthProvider>().currentUser?.uid;
                    if (artisanId != null) {
                      orderProvider.listenToArtisanOrders(artisanId);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (orderProvider.artisanOrders.isEmpty) {
          return _buildEmptyState();
        }
        return _buildOrderList(orderProvider.artisanOrders);
      },
    ),
  );
}
```

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/artisan_orders_screen.dart` | Full `ArtisanOrdersScreen` with `Consumer<OrderProvider>`, loading/error/empty/list states, `OrderCard` widgets, status update bottom sheet stub |
| 2 | `lib/providers/order_provider.dart` | Full `OrderProvider` with `listenToArtisanOrders()`, stub methods for buyer/admin order streams, `dispose()` |
| 3 | `lib/services/firestore_service.dart` | `getOrdersByArtisan()` implemented — `UnimplementedError` count drops to 11 |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly three files.

---

**File 1: `lib/services/firestore_service.dart`**

Make one targeted replacement:

Find the `getOrdersByArtisan` method in the Order Stream Methods group. Replace its `throw UnimplementedError(...)` body with the implementation specified in Section 6. Verify the method is NOT declared `async`.

After editing:
```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `11`.

---

**File 2: `lib/providers/order_provider.dart`**

Replace the PR08 minimal stub entirely. Write the complete file as specified in Section 6:

1. All four import statements.
2. `class OrderProvider extends ChangeNotifier` opening.
3. All nine private fields.
4. All five public getters using `List.unmodifiable()` for order lists.
5. `listenToArtisanOrders(String artisanId)` — full implementation with cancel, loading, stream listen, onError.
6. `listenToBuyerOrders(String buyerId)` — stub comment only.
7. `listenToAllOrders()` — stub comment only.
8. `clearError()` — sets null, notifies.
9. `dispose()` — cancels all three subscriptions, calls `super.dispose()`.

**Critical rules:**
- `listenToBuyerOrders` and `listenToAllOrders` are stub methods with only a comment — no `throw`, no logic. They exist to show what will be implemented in PRs 43 and 48.
- `dispose()` must cancel all three subscriptions even though `_buyerOrdersSubscription` and `_allOrdersSubscription` are null — `?.cancel()` is a no-op on null.

---

**File 3: `lib/screens/artisan/artisan_orders_screen.dart`**

Replace the PR16 minimal stub entirely. Write the complete file as specified in Section 6:

1. All six import statements.
2. `ArtisanOrdersScreen extends StatefulWidget` with `const` constructor.
3. `_ArtisanOrdersScreenState` containing:
   - `initState()` with `addPostFrameCallback` calling `listenToArtisanOrders(artisanId)`.
   - `_buildEmptyState()` — receipt icon, "No orders yet", subtitle.
   - `_buildOrderList(List<OrderModel> orders)` — `ListView.separated` with `OrderCard` items, `showBuyerName: true`, `onTap` calls `_showOrderStatusSheet`.
   - `_showOrderStatusSheet(BuildContext context, OrderModel order)` — `showModalBottomSheet` with "Update Order Status" header, product title subtitle, divider, and status options.
   - `_buildStatusOptions(BuildContext ctx, OrderModel order)` — list of four status `ListTile` items (Confirmed, Shipped, Delivered, Cancelled), current status highlighted with colour and checkmark, others show stub snackbar on tap.
   - `build()` — `Scaffold` with app bar (order count action via `Consumer`), body is `Consumer<OrderProvider>` with four states: loading, error with retry, empty, list.

**Critical rules:**
- `initState()` uses `addPostFrameCallback` — Provider reads must not happen in `initState()` directly.
- `Consumer<OrderProvider>` is used in both the `AppBar` action (for count) and the `body` — these are two separate `Consumer` instances.
- `showBuyerName: true` is passed to every `OrderCard` — artisans see buyer names.
- Status update `onTap` shows a stub snackbar referencing PR37 — not yet implemented.
- The error state includes a "Retry" `TextButton` that re-calls `listenToArtisanOrders`.
- `_buildStatusOptions` uses `AppConstants.statusConfirmed`, `AppConstants.statusShipped`, `AppConstants.statusDelivered`, `AppConstants.statusCancelled` — never hardcoded strings.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `OrderModel` import missing in screen file; `showModalBottomSheet` requires non-null `context`; `List.unmodifiable` return type annotation; `getOrdersByArtisan` must not be `async`.

2. **Verify `UnimplementedError` count**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return `11`.

3. **Verify `getOrdersByArtisan` is not async**
   ```
   grep 'Stream<List<OrderModel>> getOrdersByArtisan' lib/services/firestore_service.dart
   ```
   Must return one line without `async` keyword.

4. **Verify `orderBy` is present**
   ```
   grep 'orderBy' lib/services/firestore_service.dart
   ```
   Must return one line — the `createdAt` descending order clause.

5. **Verify `List.unmodifiable` in `OrderProvider`**
   ```
   grep -c 'List.unmodifiable' lib/providers/order_provider.dart
   ```
   Must return `3` — for `artisanOrders`, `buyerOrders`, and `allOrders`.

6. **Verify stub methods are present in `OrderProvider`**
   ```
   grep 'listenToBuyerOrders\|listenToAllOrders' lib/providers/order_provider.dart
   ```
   Must return at least two lines — the two stub method declarations.

7. **Verify `addPostFrameCallback` in `ArtisanOrdersScreen`**
   ```
   grep 'addPostFrameCallback' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return one line.

8. **Verify `showBuyerName: true` in `OrderCard` usage**
   ```
   grep 'showBuyerName: true' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return one line.

9. **Verify status constants are used**
   ```
   grep 'AppConstants.status' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return at least four lines — one per status option.

10. **Hot reload on emulator**
    ```
    flutter run
    ```
    Log in as an approved artisan → "My Orders".
    Confirm:
    - `ArtisanOrdersScreen` loads with a `CircularProgressIndicator` briefly.
    - If no orders exist in Firestore: empty state shows receipt icon and "No orders yet".
    - If orders exist (create test orders via Firebase Console): `OrderCard` widgets render with product title, buyer name, status chip, price.
    - Order count appears in app bar ("2 orders").
    - Tapping an `OrderCard` opens the status update bottom sheet with four status options.
    - Current order status is highlighted with colour and checkmark.
    - Tapping a different status shows the stub snackbar "Status update to '...' — wired in PR37."
    - Bottom sheet dismisses on status tap.
    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/artisan/artisan_orders_screen.dart`, `lib/providers/order_provider.dart`, and `lib/services/firestore_service.dart` should appear.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 30
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
git commit -m "PR30: Session Persistence — ArtisanOrdersScreen"
git push origin pr30-artisan-orders
```

---

## Section 9 – Acceptance Criteria

- [ ] `FirestoreService.getOrdersByArtisan()` is implemented — filters by `artisanId`, orders by `createdAt` descending, returns `Stream<List<OrderModel>>`, not declared `async`.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` returns `11`.
- [ ] `OrderProvider` extends `ChangeNotifier` with three order lists, `isLoading`, `errorMessage`, and three `StreamSubscription` fields.
- [ ] `listenToArtisanOrders()` cancels any existing subscription, sets loading, and handles stream errors via `onError`.
- [ ] `listenToBuyerOrders()` and `listenToAllOrders()` are stub methods with comments only.
- [ ] `OrderProvider.dispose()` cancels all three subscriptions.
- [ ] `ArtisanOrdersScreen` is a `StatefulWidget` that calls `listenToArtisanOrders(artisanId)` in `initState()` via `addPostFrameCallback`.
- [ ] `build()` uses `Consumer<OrderProvider>` with four states: loading spinner, error widget with retry, empty state, order list.
- [ ] `OrderCard` widgets use `showBuyerName: true`.
- [ ] Tapping an `OrderCard` opens a `showModalBottomSheet` with four status options using `AppConstants` status constants.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR30 for CraftBridge. I implemented `ArtisanOrdersScreen` with live Firestore order streaming, upgraded `OrderProvider` from a stub to a full `ChangeNotifier`, and implemented `FirestoreService.getOrdersByArtisan()` — bringing the artisan order tracking flow to life for the first time."

2. **`Consumer<OrderProvider>` for four UI states:** "`ArtisanOrdersScreen.build()` uses a `Consumer<OrderProvider>` that handles four states: loading (CircularProgressIndicator), error (error message with retry button), empty (no orders yet), and list (ListView of OrderCards). Every screen that reads live Firestore data should handle all four states — skipping any one leaves users with a confusing experience."

3. **`addPostFrameCallback` for Provider calls in `initState`:** "`initState()` uses `addPostFrameCallback` before calling `listenToArtisanOrders`. This is required because `context.read<OrderProvider>()` needs the widget to be fully mounted in the Provider tree — which happens on the first frame. Calling `context.read` directly in `initState()` before the first frame is technically valid with Provider, but `addPostFrameCallback` is the safer and more explicit pattern."

4. **`orderBy('createdAt', descending: true)` composite index:** "`getOrdersByArtisan()` chains `.where('artisanId', ...).orderBy('createdAt', descending: true)`. Firestore requires a composite index for queries that filter on one field and order by another. On first run, the Firestore SDK prints a direct link in the debug console to create the required index in the Firebase Console. This is a one-time setup step — after the index is created, the query runs correctly."

5. **`showBuyerName: true` on `OrderCard`:** "`OrderCard` has a `showBuyerName` parameter that toggles between showing the buyer name or artisan name. In `ArtisanOrdersScreen`, artisans need to know who placed each order — `showBuyerName: true`. In `BuyerOrdersScreen` (PR43), buyers need to know which artisan is fulfilling their order — `showBuyerName: false`. The same widget serves both contexts with a single parameter."

6. **Status update bottom sheet design:** "The status bottom sheet shows four options — Confirmed, Shipped, Delivered, Cancelled — as `ListTile` widgets. The current order status is highlighted with its semantic colour and a checkmark. Tapping the current status is a no-op (`onTap: null`). Tapping a different status currently shows a stub snackbar referencing PR37 — where `FirestoreService.updateOrderStatus()` and `OrderProvider.updateOrderStatus()` will be wired."

7. **`_buildStatusOptions` with `AppConstants` constants:** "The status options list uses `AppConstants.statusConfirmed`, `AppConstants.statusShipped`, etc. — never hardcoded strings. Each option is a map with `status`, `label`, `icon`, and `color` — a data-driven approach that makes adding or reordering statuses a one-line change in the list."

8. **Stub methods for buyer and admin order streams:** "`OrderProvider` includes `listenToBuyerOrders()` and `listenToAllOrders()` as empty stub methods with comments. They exist to show the full Provider API surface — Member 3 implementing PR43 and PR48 will fill these in. Unlike the PR07 service stubs that use `throw UnimplementedError`, these stub methods simply have no body — they're called from screens that aren't yet wired, so throwing would cause crashes."

9. **Order count in app bar:** "The app bar action renders `'$count order${count == 1 ? '' : 's'}'` — singular/plural handling for 1 order vs multiple. The `Consumer` in the action returns `SizedBox.shrink()` when count is 0 — avoiding an empty action slot. This is a small UX detail that makes the screen feel polished."

10. **What's Next:** "PR31 will implement full product CRUD — all product write methods in `FirestoreService`, `ProductProvider.addProduct()`, `updateProduct()`, and `deleteProduct()` — making the product creation and editing flow in `AddEditProductScreen` write real data to Firestore for the first time."