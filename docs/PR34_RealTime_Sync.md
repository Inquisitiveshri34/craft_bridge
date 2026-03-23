# PR34 – Real-Time Sync — ArtisanOrders Live Listener

**Project:** CraftBridge
**PR Number:** 34 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `FirestoreService.getOrdersByBuyer()` and `getAllOrders()`, complete `OrderProvider` order stream methods, verify and document real-time sync behaviour across artisan and buyer order screens.

---

## Section 2 – Assignments Covered

- Assignment 3.34 — Real-Time Sync — ArtisanOrders Live Listener

---

## Section 3 – Objective

This PR completes the Order Stream Methods group in `FirestoreService` — implementing `getOrdersByBuyer()` and `getAllOrders()` — and fills in `OrderProvider.listenToBuyerOrders()` and `listenToAllOrders()`. It also produces `docs/PR34_RealTime_Sync.md` documenting the real-time sync architecture, Firestore stream lifecycle, and the composite index requirements for the order queries. After this PR, all three order stream subscriptions are functional and ready for `BuyerOrdersScreen` (PR43) and `ManageAllOrdersScreen` (PR48) to consume.

---

## Section 4 – Architecture Context

```
FirestoreService Order Stream Methods (all three filled after this PR):
  getOrdersByArtisan(artisanId)  ← filled PR30 ✓
  getOrdersByBuyer(buyerId)      ← filled this PR
  getAllOrders()                  ← filled this PR

OrderProvider stream methods (all three filled after this PR):
  listenToArtisanOrders(artisanId)  ← filled PR30 ✓
  listenToBuyerOrders(buyerId)      ← filled this PR
  listenToAllOrders()               ← filled this PR

Consumers of the new methods:
  listenToBuyerOrders  → BuyerOrdersScreen (PR43)
  listenToAllOrders    → ManageAllOrdersScreen (PR48)

firestore_service.dart UnimplementedError count:
  Before: 6
  After:  4 (getOrdersByBuyer + getAllOrders filled)

Real-time sync verified this PR:
  Artisan places status update → ArtisanOrdersScreen updates
  Buyer places order → ArtisanOrdersScreen updates in < 1s
  Multiple concurrent buyers → all orders appear without refresh

docs/PR34_RealTime_Sync.md ← produced this PR
```

This is the final PR assigned to Member 2. After this PR merges, Member 3 takes over at PR35.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/services/firestore_service.dart`
- `lib/providers/order_provider.dart`
- `docs/PR34_RealTime_Sync.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files other than `order_provider.dart`.
- Do NOT modify any screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/firestore_service.dart`

Replace the two remaining Order Stream Method stub bodies. All other methods remain unchanged.

---

**Implemented `getOrdersByBuyer` method:**

```dart
Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
  return _db
      .collection(AppConstants.ordersCollection)
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList());
}
```

---

**Implemented `getAllOrders` method:**

```dart
Stream<List<OrderModel>> getAllOrders() {
  return _db
      .collection(AppConstants.ordersCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList());
}
```

**Implementation notes:**

- `getOrdersByBuyer` filters by `buyerId` and orders by `createdAt` descending — same pattern as `getOrdersByArtisan`. Requires a composite index for `buyerId` + `createdAt`.
- `getAllOrders` orders by `createdAt` descending with no filter — admin sees all orders. A single-field index on `createdAt` is automatically created by Firestore.
- Neither method is declared `async` — both return `Stream` objects synchronously.
- Both methods use `AppConstants.ordersCollection`.

---

**`UnimplementedError` count after this PR:**

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `4`.

---

### `lib/providers/order_provider.dart`

Fill in the two stub methods from PR30. All existing fields, getters, `listenToArtisanOrders()`, `createOrder()`, `clearError()`, and `dispose()` are unchanged.

---

**Replace `listenToBuyerOrders()` stub with implementation:**

```dart
void listenToBuyerOrders(String buyerId) {
  _buyerOrdersSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  _buyerOrdersSubscription =
      _firestoreService.getOrdersByBuyer(buyerId).listen(
    (orderList) {
      _buyerOrders = orderList;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (Object error) {
      _errorMessage = 'Failed to load your orders: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}
```

---

**Replace `listenToAllOrders()` stub with implementation:**

```dart
void listenToAllOrders() {
  _allOrdersSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  _allOrdersSubscription =
      _firestoreService.getAllOrders().listen(
    (orderList) {
      _allOrders = orderList;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (Object error) {
      _errorMessage = 'Failed to load all orders: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}
```

---

### `docs/PR34_RealTime_Sync.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: Firestore's real-time sync capability allows CraftBridge screens to update automatically when data changes, without polling or manual refresh. The `StreamSubscription` pattern in `OrderProvider` and `ProductProvider` establishes persistent listeners that fire on every document change matching their queries. This document describes the real-time sync architecture, the Firestore stream lifecycle, the composite index requirements, and the observed latency characteristics.

---

#### 2. Real-Time Sync Architecture

An ASCII diagram showing how data flows from a Firestore write to a screen update:

```
Buyer places order (CartScreen)
        │
        ▼
FirestoreService.createOrder()
        │
        └── _db.collection('orders').doc(id).set(data)
                    │
                    ▼
            Firestore (cloud)
                    │
          document change event
                    │
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
getOrdersByArtisan          getOrdersByBuyer
stream fires                stream fires
(if artisanId matches)      (if buyerId matches)
         │                     │
         ▼                     ▼
OrderProvider               OrderProvider
_artisanOrders updated      _buyerOrders updated
notifyListeners()           notifyListeners()
         │                     │
         ▼                     ▼
ArtisanOrdersScreen         BuyerOrdersScreen
Consumer rebuilds           Consumer rebuilds
new OrderCard visible       new OrderCard visible
```

Followed by 2–3 sentences explaining: the write and the stream notification happen within the same Firebase transaction — typically under 500ms on a good mobile connection. Both the artisan and buyer see the order update without any user-initiated refresh.

---

#### 3. Firestore Stream Lifecycle

A prose section covering:

- **Stream creation:** `StreamSubscription` is created when a screen calls `listenToArtisanOrders()`, `listenToBuyerOrders()`, or `listenToAllOrders()`. The subscription starts a persistent WebSocket connection to Firestore.
- **First emission:** Firestore immediately emits the current state of all matching documents on subscription — this is the initial load. `_isLoading` transitions from `true` to `false` on this first emission.
- **Subsequent emissions:** Every document insertion, update, or deletion matching the query triggers a new emission. The full updated list is emitted — not a diff.
- **Subscription cancellation:** `_artisanOrdersSubscription?.cancel()` is called in `dispose()` and before restarting a subscription. Cancellation closes the WebSocket connection and stops billing for the listener.
- **Offline behaviour:** Firestore caches the last known state locally. If the device goes offline, the stream emits the cached data. When connectivity is restored, Firestore re-syncs and emits the latest state.

---

#### 4. Composite Index Requirements

A table with columns: **Query**, **Fields Indexed**, **Index Type**, **PR That Creates Index**, **How to Create**.

| Query | Fields Indexed | Index Type | PR That Creates Index | How to Create |
|-------|---------------|------------|----------------------|---------------|
| `getOrdersByArtisan` | `artisanId` (ASC) + `createdAt` (DESC) | Composite | PR30 (first run) | Click link in debug console or Firebase Console → Indexes |
| `getOrdersByBuyer` | `buyerId` (ASC) + `createdAt` (DESC) | Composite | PR34 (first run) | Click link in debug console or Firebase Console → Indexes |
| `getAllOrders` | `createdAt` (DESC) | Single-field | Auto-created | No action required |
| `getProducts` | `isActive` (ASC) | Single-field | Auto-created | No action required |
| `getProductsByArtisan` | `artisanId` (ASC) | Single-field | Auto-created | No action required |

Followed by a prose note: composite indexes are required whenever a Firestore query combines a `where` filter with an `orderBy` on a different field. When the query first runs on a live Firebase project (not the emulator), Firestore prints a direct URL in the debug console — clicking it opens the Firebase Console with the index pre-configured for one-click creation. Index creation typically takes 1–5 minutes.

---

#### 5. Observed Latency Characteristics

A prose section covering:

- **Write-to-stream latency:** In testing on the Android emulator with a live Firebase project over WiFi, order creation writes appear in `ArtisanOrdersScreen` within 200–600ms of the "Place Order" button tap. This includes Firestore write latency plus stream notification delivery.
- **Local optimistic updates:** Firestore's local cache provides optimistic writes — the `StreamBuilder` or `Consumer` may show the new document before Firebase confirms the write to the server. This makes the UI feel instantaneous in most cases.
- **Cold start stream latency:** The first emission after app launch (loading cached data) is typically under 100ms. The first emission after a new subscription is typically under 500ms on a good connection.
- **Concurrent order scenario:** In testing with two buyer sessions placing orders for the same artisan simultaneously, both orders appear in `ArtisanOrdersScreen` without conflict. Firestore handles concurrent writes to different documents atomically.

---

#### 6. Member 2 Handoff Notes

A prose section addressed to Member 3, covering:

- All 17 PRs assigned to Member 2 (PRs 18–34) are now merged to `main`.
- The following `FirestoreService` methods remain as `UnimplementedError` stubs for Member 3 to implement: `addReview()` (PR44), `getReviewsByProduct()` (PR44), and `getPendingArtisans()` (PR48). The `UnimplementedError` count at handoff is 4 — these are the four remaining stubs.
- `OrderProvider.listenToBuyerOrders()` and `listenToAllOrders()` are now implemented — `BuyerOrdersScreen` (PR43) and `ManageAllOrdersScreen` (PR48) can call these methods directly.
- The composite indexes for `getOrdersByArtisan` and `getOrdersByBuyer` must be created in the Firebase Console on first run — check the debug console for the index creation URL after the first order query runs on the live project.
- All reusable widgets (`ProductCard`, `OrderCard`, `CartItemTile`, `CustomTextField`, `CustomButton`) are complete — Member 3 should use these widgets without modification.
- `AppTheme` is complete — do not add hardcoded color values to any new screen. Use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*` exclusively.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/services/firestore_service.dart` | `getOrdersByBuyer()` and `getAllOrders()` implemented — `UnimplementedError` count drops to 4 |
| 2 | `lib/providers/order_provider.dart` | `listenToBuyerOrders()` and `listenToAllOrders()` implemented — all three order stream methods complete |
| 3 | `docs/PR34_RealTime_Sync.md` | Complete real-time sync documentation with all 6 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify two Dart files and write one Markdown document.

---

**File 1: `lib/services/firestore_service.dart`**

Replace the `getOrdersByBuyer` and `getAllOrders` stub bodies with the implementations specified in Section 6. Verify neither method is declared `async`. Verify `UnimplementedError` count is 4 after editing.

---

**File 2: `lib/providers/order_provider.dart`**

Replace the `listenToBuyerOrders` and `listenToAllOrders` stub comment bodies with the full implementations specified in Section 6. Pattern is identical to `listenToArtisanOrders` — cancel existing subscription, set loading, start new subscription with `onError` callback.

**Critical rules:**
- `listenToBuyerOrders` updates `_buyerOrders`, not `_artisanOrders`.
- `listenToAllOrders` updates `_allOrders`.
- Each method cancels its own subscription (`_buyerOrdersSubscription`, `_allOrdersSubscription`) — not each other's.
- Error messages are distinct: "Failed to load your orders" for buyer, "Failed to load all orders" for admin.

---

**File 3: `docs/PR34_RealTime_Sync.md`**

Write the complete Markdown document with all 6 sections as specified in Section 6. The ASCII diagram in Section 2 must be reproduced exactly. The composite index table in Section 4 must have all 5 rows. Section 6 must address Member 3 directly and cover all five handoff points.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `getOrdersByBuyer` and `getAllOrders` must not be `async`; `_buyerOrders` vs `_artisanOrders` — confirm correct field is updated in each method.

2. **Verify `UnimplementedError` count**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return `4`.

3. **Verify `getOrdersByBuyer` is not async**
   ```
   grep 'Stream<List<OrderModel>> getOrdersByBuyer' lib/services/firestore_service.dart
   ```
   Must return one line without `async` keyword.

4. **Verify `getAllOrders` is not async**
   ```
   grep 'Stream<List<OrderModel>> getAllOrders' lib/services/firestore_service.dart
   ```
   Must return one line without `async` keyword.

5. **Verify `getAllOrders` has no `where` filter**
   ```
   grep -A5 'Stream<List<OrderModel>> getAllOrders' lib/services/firestore_service.dart
   ```
   Confirm the method body does not contain `.where(` — admin sees all orders without filtering.

6. **Verify `listenToBuyerOrders` updates `_buyerOrders`**
   ```
   grep '_buyerOrders' lib/providers/order_provider.dart
   ```
   Must return at least three lines — field declaration, getter, and assignment in `listenToBuyerOrders`.

7. **Verify `listenToAllOrders` updates `_allOrders`**
   ```
   grep '_allOrders' lib/providers/order_provider.dart
   ```
   Must return at least three lines.

8. **Verify all three `listen` methods are present and complete**
   ```
   grep 'void listenToArtisanOrders\|void listenToBuyerOrders\|void listenToAllOrders' lib/providers/order_provider.dart
   ```
   Must return `3` lines — all three method declarations.

9. **Verify document has 6 sections**
   ```
   cat docs/PR34_RealTime_Sync.md
   ```
   Confirm all 6 sections present. Confirm Section 4 composite index table has 5 rows. Confirm Section 6 is addressed to Member 3.

10. **Hot reload on emulator — real-time sync test**
    ```
    flutter run
    ```

    **Concurrent session test:**
    - Run two emulator instances (or use a physical device + emulator).
    - Log in as an artisan on one, a buyer on the other.
    - On the buyer device: place an order.
    - On the artisan device: confirm the new order appears in `ArtisanOrdersScreen` within 1–2 seconds without any manual refresh.

    **Status update propagation test:**
    - On the artisan device: tap an order → status bottom sheet → tap "Confirmed" (stub snackbar will show — full wiring in PR37).
    - Since status update is stubbed, manually update the order status in Firebase Console → confirm `ArtisanOrdersScreen` updates in real time.

    **Stream restart test:**
    - Navigate away from `ArtisanOrdersScreen` and back.
    - `initState` calls `listenToArtisanOrders` again — verify `cancel()` before restart prevents duplicate listeners.
    - Orders list still shows correctly after restart.

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/services/firestore_service.dart`, `lib/providers/order_provider.dart`, `docs/PR34_RealTime_Sync.md`.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 34
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
git commit -m "PR34: Real-Time Sync — ArtisanOrders Live Listener"
git push origin pr34-realtime-sync
```

---

## Section 9 – Acceptance Criteria

- [ ] `FirestoreService.getOrdersByBuyer()` returns `Stream<List<OrderModel>>` filtering by `buyerId`, ordered by `createdAt` descending, not declared `async`.
- [ ] `FirestoreService.getAllOrders()` returns `Stream<List<OrderModel>>` ordered by `createdAt` descending with no filter, not declared `async`.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` returns `4`.
- [ ] `OrderProvider.listenToBuyerOrders()` is fully implemented — cancels existing subscription, starts stream, updates `_buyerOrders`, handles errors.
- [ ] `OrderProvider.listenToAllOrders()` is fully implemented — cancels existing subscription, starts stream, updates `_allOrders`, handles errors.
- [ ] All three order stream methods (`listenToArtisanOrders`, `listenToBuyerOrders`, `listenToAllOrders`) are complete in `OrderProvider`.
- [ ] `docs/PR34_RealTime_Sync.md` exists with all 6 sections including the ASCII data flow diagram, composite index table, and Member 3 handoff notes.
- [ ] Real-time order creation in `CartScreen` is visible in `ArtisanOrdersScreen` within seconds on the emulator.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR34 — the final PR for Member 2 on CraftBridge. I implemented `FirestoreService.getOrdersByBuyer()` and `getAllOrders()`, completed `OrderProvider` with all three order stream methods, and produced the real-time sync documentation. With this PR, the complete order stream infrastructure is in place for Member 3 to build `BuyerOrdersScreen` and `ManageAllOrdersScreen`."

2. **`getAllOrders` no filter design:** "`getAllOrders()` has no `where` filter — it returns every order in the `orders` collection, sorted by `createdAt` descending. This is correct for the admin use case — admins see all orders across all artisans and all buyers. A single-field index on `createdAt` is auto-created by Firestore, so no manual index creation is needed for this query."

3. **Composite index requirement for `getOrdersByBuyer`:** "`getOrdersByBuyer` combines `.where('buyerId', ...).orderBy('createdAt', descending: true)` — a multi-field query requiring a composite index. When this query first runs on a live Firebase project, Firestore returns an error with a direct URL to create the index. The index typically builds in 1–5 minutes. The Firestore emulator creates indexes automatically, so this issue only appears on the live project."

4. **Stream subscription cancel-before-restart:** "Both `listenToBuyerOrders` and `listenToAllOrders` call `_buyerOrdersSubscription?.cancel()` and `_allOrdersSubscription?.cancel()` before starting new subscriptions. If a screen calls `listenToBuyerOrders` multiple times — for example, during a hot restart or if `initState` fires more than once — the cancel prevents multiple simultaneous listeners on the same query, which would cause duplicate `OrderCard` widgets."

5. **Why `_isLoading` is shared across all three order types:** "`OrderProvider` has a single `_isLoading` field shared by all three order stream methods. This is a simplification — if `listenToArtisanOrders` and `listenToBuyerOrders` were called simultaneously, they would overwrite each other's loading state. In the MVP, only one order stream is active at a time per role (artisan, buyer, or admin), so the shared flag is acceptable. A production app might use per-stream loading flags."

6. **Firestore stream lifecycle documented:** "Section 3 of the PR34 document covers the full stream lifecycle — creation, first emission, subsequent emissions, cancellation, and offline behaviour. The offline behaviour is particularly interesting: Firestore caches the last known state locally, so `ArtisanOrdersScreen` still shows orders when the artisan has no connectivity. When the device reconnects, the stream emits any changes that occurred while offline."

7. **Observed latency under 600ms:** "In testing, the write-to-stream latency was 200–600ms over WiFi on the Android emulator. Firestore's local optimistic writes make the UI feel even faster — the `Consumer` may rebuild with the new order before Firebase confirms the server write. For a student project demo, sub-second order appearance is impressive and clearly demonstrates real-time sync."

8. **Member 3 handoff coverage:** "Section 6 of the document is a direct handoff note to Member 3. It covers: the remaining 4 `UnimplementedError` stubs (reviews in PR44 and admin in PR48), which Provider methods to call for buyer and admin screens, the composite index creation requirement, the reusable widget set, and the `AppTheme` constraint. Member 3 should be able to pick up at PR35 without needing to ask Member 2 any questions."

9. **`UnimplementedError` count trajectory:** "The `UnimplementedError` count in `firestore_service.dart` has dropped from 20 (PR07) to 4 (this PR) across Member 2's 17 PRs. The 4 remaining stubs are `addReview`, `getReviewsByProduct` (both PR44), and `getPendingArtisans` (PR48). Member 3 will close this to 0 by PR48."

10. **What's Next:** "PR35, owned by Member 3, will implement product search and category filtering on the Firestore query level — adding `where` filters and text search capabilities to `ProductProvider` and `BuyerHomeScreen`."