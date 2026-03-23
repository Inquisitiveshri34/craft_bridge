# PR37 – Cloud Functions — Order Status Serverless Trigger

**Project:** CraftBridge
**PR Number:** 37 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Wire order status updates from `ArtisanOrdersScreen` status bottom sheet to `FirestoreService.updateOrderStatus()` via `OrderProvider.updateOrderStatus()`, replacing the PR30 stub snackbar with a real Firestore write.

---

## Section 2 – Assignments Covered

- Assignment 3.37 — Cloud Functions — Order Status Serverless Trigger

---

## Section 3 – Objective

This PR wires the order status update flow end-to-end — replacing the stub snackbar in `ArtisanOrdersScreen`'s status bottom sheet with a real call to `OrderProvider.updateOrderStatus()`, which calls `FirestoreService.updateOrderStatus()` to write the new status to Firestore. After this PR, artisans can change order statuses (Confirmed, Shipped, Delivered, Cancelled) and the change is immediately reflected in both `ArtisanOrdersScreen` and `BuyerOrdersScreen` (once implemented in PR43) via live Firestore streams. The assignment title references Cloud Functions — in this MVP the status update is a direct Firestore write; a serverless trigger would be a post-MVP enhancement to send push notifications on status change.

---

## Section 4 – Architecture Context

```
ArtisanOrdersScreen
    └── OrderCard onTap → _showOrderStatusSheet(context, order)
                                    │
                          BottomSheet status ListTile onTap
                                    │
                     PR30: stub snackbar "wired in PR37"
                     PR37: OrderProvider.updateOrderStatus(orderId, newStatus)
                                    │
                          FirestoreService.updateOrderStatus(orderId, status)
                                    │
                          orders/{orderId}.update({'status': newStatus})
                                    │
                          Firestore stream fires
                                    │
                     ┌──────────────┴──────────────┐
                     │                             │
             ArtisanOrdersScreen             BuyerOrdersScreen
             OrderCard status chip           OrderCard status chip
             updates in real time            updates in real time (PR43)

OrderProvider new method this PR:
  updateOrderStatus(String orderId, String newStatus)
    → FirestoreService.updateOrderStatus(orderId, newStatus)
    → returns Future<bool>

firestore_service.dart:
  updateOrderStatus already implemented in PR33
  UnimplementedError count: unchanged at 4
```

This PR sits after image management (PR36) and before FCM setup (PR38). `FirestoreService.updateOrderStatus()` was implemented in PR33 — this PR wires the screen-to-provider-to-service call chain.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/order_provider.dart`
- `lib/screens/artisan/artisan_orders_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`, `product_provider.dart`, or `cart_provider.dart`.
- Do NOT modify any other screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/providers/order_provider.dart`

Add one new method to the existing PR33/PR34 implementation. All existing fields, getters, and methods are unchanged.

---

**`updateOrderStatus()` method:**

```dart
Future<bool> updateOrderStatus(
    String orderId, String newStatus) async {
  try {
    await _firestoreService.updateOrderStatus(orderId, newStatus);
    return true;
  } catch (e) {
    _errorMessage = 'Failed to update order status: $e';
    notifyListeners();
    return false;
  }
}
```

**Implementation notes:**

- No `_isLoading` flag is set — status updates are fast Firestore writes and the UI is updated reactively via the existing stream. Setting loading state would cause a brief spinner flash that is more disruptive than helpful for a single-field update.
- The method returns `bool` — `true` on success, `false` on error — consistent with all other Provider write methods.
- On error, `_errorMessage` is set and `notifyListeners()` is called — screens that watch `orderProvider.errorMessage` will display the error.
- The live `getOrdersByArtisan` stream in `OrderProvider` fires automatically when the status field changes in Firestore — the artisan's order list updates without any additional logic.

---

### `lib/screens/artisan/artisan_orders_screen.dart`

Two targeted changes to the PR30 implementation.

---

**Change 1 — Replace stub `onTap` in `_buildStatusOptions()` with real status update:**

In `_buildStatusOptions()`, replace the `onTap` callback for non-current status `ListTile` items from the PR30 stub:

```dart
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
```

With the real implementation:

```dart
onTap: isCurrent
    ? null
    : () async {
        Navigator.pop(ctx);
        final bool success = await context
            .read<OrderProvider>()
            .updateOrderStatus(
              order.id,
              statusMap['status'] as String,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Order status updated to "${statusMap['label']}".'
                  : context
                          .read<OrderProvider>()
                          .errorMessage ??
                      'Failed to update status.',
            ),
          ),
        );
      },
```

**Key changes:**
- `onTap` becomes `async`.
- `Navigator.pop(ctx)` is called first — dismisses the bottom sheet before the async operation starts, preventing the sheet from remaining open during the Firestore write.
- `OrderProvider.updateOrderStatus(order.id, statusMap['status'])` is called.
- `mounted` check after `await` — required because the bottom sheet dismissal and async Firestore write span multiple frames.
- Success snackbar shows the new status label. Failure snackbar shows the error message from `OrderProvider`.

---

**Change 2 — Add `_updateOrderStatus()` helper method to `_ArtisanOrdersScreenState`:**

This refactor extracts the status update logic from the `_buildStatusOptions()` closure into a named method for clarity and testability:

```dart
Future<void> _updateOrderStatus(
  BuildContext ctx,
  OrderModel order,
  String newStatus,
  String statusLabel,
) async {
  Navigator.pop(ctx);
  final bool success = await context
      .read<OrderProvider>()
      .updateOrderStatus(order.id, newStatus);
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Order status updated to "$statusLabel".'
            : context.read<OrderProvider>().errorMessage ??
                'Failed to update status.',
      ),
    ),
  );
}
```

Then update the `onTap` in `_buildStatusOptions()` to call this method:

```dart
onTap: isCurrent
    ? null
    : () => _updateOrderStatus(
          ctx,
          order,
          statusMap['status'] as String,
          statusMap['label'] as String,
        ),
```

**Note:** Either approach (inline async `onTap` or extracted helper method) is acceptable. The extracted helper method is cleaner and is the recommended implementation. If using the helper method, the `onTap` lambda is no longer `async` — it calls a named `async` method via `=>`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/order_provider.dart` | `updateOrderStatus()` method added — delegates to `FirestoreService`, returns `Future<bool>`, no loading flag |
| 2 | `lib/screens/artisan/artisan_orders_screen.dart` | `_buildStatusOptions()` `onTap` wired to real `OrderProvider.updateOrderStatus()`, stub snackbar removed, `_updateOrderStatus()` helper added |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/providers/order_provider.dart`**

Add `updateOrderStatus(String orderId, String newStatus)` as a new method after `createOrder()`. The method body is specified in Section 6. No other changes to `order_provider.dart`.

**Critical rules:**
- No `_isLoading` flag — status updates are reactive via the existing stream.
- Returns `Future<bool>`.
- On error: sets `_errorMessage`, calls `notifyListeners()`, returns `false`.
- On success: returns `true` without calling `notifyListeners()` — the stream update triggers the UI rebuild.

---

**File 2: `lib/screens/artisan/artisan_orders_screen.dart`**

Make two targeted changes:

**Change 1:** Add `_updateOrderStatus(BuildContext ctx, OrderModel order, String newStatus, String statusLabel)` as a new private method to `_ArtisanOrdersScreenState`, after `_buildStatusOptions()`.

**Change 2:** In `_buildStatusOptions()`, locate the `onTap` callback for non-current status `ListTile` items. Replace the stub `onTap` with a call to `_updateOrderStatus(ctx, order, statusMap['status'] as String, statusMap['label'] as String)`.

**Critical rules:**
- `Navigator.pop(ctx)` must be called before the `await OrderProvider.updateOrderStatus()` call — the bottom sheet must be dismissed before the async operation.
- `mounted` check after `await` is required — dismissing the bottom sheet and then awaiting Firestore means the calling widget could theoretically be disposed.
- `context.read<OrderProvider>()` is used (not `context.watch`) in `_updateOrderStatus` — it is called from a callback, not from `build`.
- The `isCurrent ? null : ...` guard on `onTap` is preserved — tapping the current status remains a no-op.
- Remove the PR30 stub snackbar text entirely — no reference to "wired in PR37" should remain.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `async` closure in `onTap` — if using the inline approach, the lambda must be `() async { ... }`; `mounted` check placement — must be after the first `await`; `BuildContext ctx` vs `context` — `ctx` is the bottom sheet's context, `context` is the screen's context; `statusMap['status'] as String` cast.

2. **Verify `updateOrderStatus` is added to `OrderProvider`**
   ```
   grep 'Future<bool> updateOrderStatus' lib/providers/order_provider.dart
   ```
   Must return one line.

3. **Verify no `_isLoading` in `updateOrderStatus`**
   ```
   grep -A10 'Future<bool> updateOrderStatus' lib/providers/order_provider.dart | grep '_isLoading'
   ```
   Must return no output — confirming no loading flag is set.

4. **Verify stub snackbar text is removed**
   ```
   grep 'wired in PR37' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return no output — the stub text must be completely removed.

5. **Verify `_updateOrderStatus` helper method exists**
   ```
   grep '_updateOrderStatus' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return at least two lines — the method definition and the call in `_buildStatusOptions`.

6. **Verify `Navigator.pop(ctx)` precedes the await**
   ```
   grep -A3 '_updateOrderStatus' lib/screens/artisan/artisan_orders_screen.dart | grep 'Navigator.pop'
   ```
   Must return one line — confirming the pop happens before the async update.

7. **Verify `mounted` check after await**
   ```
   grep 'mounted' lib/screens/artisan/artisan_orders_screen.dart
   ```
   Must return at least one line — inside `_updateOrderStatus`.

8. **Hot reload on emulator — status update flow test**
   ```
   flutter run
   ```

   **Prerequisites:** Create a test order using the PR33 buyer flow — log in as a buyer, place an order on any product. Then log in as the artisan.

   **Status update test:**
   - Navigate to `ArtisanOrdersScreen` — confirm the test order appears with "Pending" status chip.
   - Tap the order card → status bottom sheet opens.
   - Confirm: "Pending" is not shown as an option (status options are Confirmed, Shipped, Delivered, Cancelled).
   - Tap "Confirmed" → bottom sheet dismisses → brief Firestore write → "Order status updated to 'Confirmed'." snackbar.
   - Confirm: the order card's status chip updates to "Confirmed" (blue) in real time — no manual refresh.
   - Tap the order again → status bottom sheet → "Confirmed" is now highlighted with checkmark — other statuses are tappable.
   - Tap "Shipped" → status chip updates to "Shipped" (purple) in real time.
   - Tap "Cancelled" → confirm dialog not needed (direct update) → status chip updates to "Cancelled" (red).

   **Firebase Console verification:**
   - Open Firestore → `orders` → confirm the order document's `status` field reflects the latest update.

   **BuyerOrdersScreen preview (not yet wired — PR43):**
   - Log in as buyer → `BuyerHomeScreen` (no order history screen yet).
   - Status update will be visible in PR43.

   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/providers/order_provider.dart` and `lib/screens/artisan/artisan_orders_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 37
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
git commit -m "PR37: Cloud Functions — Order Status Serverless Trigger"
git push origin pr37-order-status
```

---

## Section 9 – Acceptance Criteria

- [ ] `OrderProvider.updateOrderStatus(String orderId, String newStatus)` is implemented — delegates to `FirestoreService.updateOrderStatus()`, returns `Future<bool>`, does not set `_isLoading`.
- [ ] `_ArtisanOrdersScreenState` has a `_updateOrderStatus(BuildContext ctx, OrderModel order, String newStatus, String statusLabel)` helper method.
- [ ] `_buildStatusOptions()` `onTap` for non-current statuses calls `_updateOrderStatus()` — not the PR30 stub snackbar.
- [ ] `Navigator.pop(ctx)` is called before `await OrderProvider.updateOrderStatus()`.
- [ ] `mounted` check is present after the `await` in `_updateOrderStatus`.
- [ ] Stub snackbar text "wired in PR37" is completely removed from `artisan_orders_screen.dart`.
- [ ] Tapping a non-current status on the emulator updates the Firestore order document and the `ArtisanOrdersScreen` order card status chip updates in real time.
- [ ] Success snackbar shows `'Order status updated to "$statusLabel".'`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR37 for CraftBridge. I wired the order status update flow end-to-end — replacing the PR30 stub snackbar in `ArtisanOrdersScreen`'s status bottom sheet with a real `OrderProvider.updateOrderStatus()` call that writes to Firestore and immediately reflects in the order card's status chip."

2. **Why no `_isLoading` flag for status updates:** "`OrderProvider.updateOrderStatus()` doesn't set `_isLoading = true` because the update is a fast single-field Firestore write — typically 100–300ms. More importantly, the UI doesn't need a loading state: the bottom sheet is dismissed before the write, and the order card's status chip updates automatically via the existing `getOrdersByArtisan` stream when Firestore confirms the change. Adding a loading spinner would cause a brief flash that is more jarring than helpful."

3. **`Navigator.pop(ctx)` before the await:** "`Navigator.pop(ctx)` is called as the first line of `_updateOrderStatus()` — before the `await OrderProvider.updateOrderStatus()` call. This dismisses the bottom sheet immediately when the artisan taps a status option, giving instant feedback. If the pop were called after the await, the bottom sheet would remain open for the 100–300ms Firestore write latency, which feels sluggish."

4. **`ctx` vs `context` in `_updateOrderStatus`:** "The `_updateOrderStatus` helper receives both `BuildContext ctx` (the bottom sheet's context) and uses the implicit `context` from the `State` class (the screen's context). `Navigator.pop(ctx)` must use the bottom sheet context — using the screen's `context` would pop the screen itself. `context.read<OrderProvider>()` uses the screen context — the Provider is registered above the screen, not the bottom sheet."

5. **`mounted` check necessity:** "`Navigator.pop(ctx)` dismisses the bottom sheet, then `await OrderProvider.updateOrderStatus()` executes the Firestore write. Between these two operations, the calling `State` object is technically still mounted. However, if navigation away from `ArtisanOrdersScreen` happened concurrently — unlikely but possible — the `mounted` check after the await prevents calling `ScaffoldMessenger.of(context)` on a disposed widget."

6. **Real-time stream update from status change:** "After `updateOrderStatus()` writes `{'status': 'confirmed'}` to Firestore, the `getOrdersByArtisan` stream in `OrderProvider` fires with an updated `List<OrderModel>`. `OrderProvider.notifyListeners()` is called by the stream listener, `Consumer<OrderProvider>` in `ArtisanOrdersScreen.build()` rebuilds, and the `OrderCard` for the updated order now shows a blue 'Confirmed' chip. No additional logic is needed — the stream does all the work."

7. **`_updateOrderStatus` helper method pattern:** "Extracting the status update logic into a named helper method `_updateOrderStatus()` rather than an inline async lambda in `_buildStatusOptions()` makes the code readable and testable. The `_buildStatusOptions()` method was already complex with four `ListTile` entries — adding async logic inline would make it harder to follow. The helper method has a clear signature that communicates its intent."

8. **Assignment title — Cloud Functions context:** "The assignment title references 'Cloud Functions' — in a production app, changing an order status might trigger a Cloud Function that sends a push notification to the buyer. In this MVP, the status update is a direct Firestore write from the Flutter client. The Cloud Function trigger is a post-MVP enhancement that would be wired to PR38's FCM setup. PR37 does the client side; a future Cloud Function would handle the server-side notification dispatch."

9. **Status progression enforcement:** "The current implementation allows any status transition — an artisan could mark an order 'Delivered' before 'Confirmed'. A production app might enforce a valid status state machine. For the MVP, the status options are presented as four distinct choices and the artisan is trusted to apply them in a reasonable order. Status validation could be added as a Firestore security rule or Cloud Function in a post-MVP iteration."

10. **What's Next:** "PR38 will set up Firebase Cloud Messaging — adding the `firebase_messaging` package, implementing a notification permission request at login, and creating a notification token stub in `AuthProvider` — preparing the notification infrastructure that a post-MVP Cloud Function status trigger would use."