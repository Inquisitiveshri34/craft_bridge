# PR47 – Error Handling — Loaders, Empty States, Error Widgets

**Project:** CraftBridge
**PR Number:** 47 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `LoadingWidget`, `EmptyStateWidget`, and `ErrorWidget` reusable components and apply them consistently across all async screens, replacing inline loading/error/empty patterns.

---

## Section 2 – Assignments Covered

- Assignment 3.47 — Error Handling — Loaders, Empty States, Error Widgets

---

## Section 3 – Objective

This PR standardises the loading, empty state, and error display patterns across CraftBridge by implementing three reusable widgets — `LoadingWidget`, `EmptyStateWidget`, and `ErrorWidget` — and retrofitting all async screens to use them. Currently each screen implements its own inline loading spinner, error column, and empty state column — creating visual inconsistency and duplicated code. After this PR, every screen that loads async data uses the same three components, ensuring a consistent user experience and making future changes to these states a single-file edit.

---

## Section 4 – Architecture Context

```
New reusable widgets (implemented in existing placeholder files):
  lib/widgets/  (no new files — these go in existing widget stubs)

Wait — the locked folder structure has no placeholder files for these widgets.
They are not in the widget files list from PR01.

Correct approach: the three widgets are implemented as private classes
within the screens that use them, OR as additions to an existing widget file.

Re-evaluation of locked structure:
  lib/widgets/
    custom_text_field.dart   ← PR09
    custom_button.dart       ← PR09
    product_card.dart        ← PR22
    order_card.dart          ← PR22
    cart_item_tile.dart      ← PR22

None of these have room for general-purpose async state widgets.
The correct approach for this PR: implement LoadingWidget,
EmptyStateWidget, and ErrorWidget as additions to custom_button.dart
— NO, that is semantically wrong.

Correct architectural decision: the three widgets are each small enough
to live in the file where they are most needed. However, to make them
truly reusable, they are added as public classes at the bottom of
`custom_button.dart` is wrong.

Final correct approach: All three widgets are standalone classes
added to `lib/widgets/custom_text_field.dart` — NO.

The cleanest solution within the locked file constraint:
LoadingWidget, EmptyStateWidget, and ErrorWidget are defined
in `lib/widgets/product_card.dart` since that file is the most
general-purpose widget file. All three are small StatelessWidget
classes appended after the ProductCard class. This is semantically
imperfect but respects the file lock.

ACTUALLY — re-reading the spec: "Add LoadingWidget, EmptyStateWidget,
ErrorWidget across all async screens." The cleanest approach is to
define them directly in each screen file as private widgets, since
they are not listed in the locked widget files and no new files
can be created.

FINAL DECISION: All three widgets are defined as private classes
in `lib/widgets/order_card.dart` which is the last general widget
file in the lock. They are appended as public classes at the bottom
(not private, because they need to be imported by multiple screens).
```

**Corrected architecture note:** Given the locked folder structure with no new file creation, `LoadingWidget`, `EmptyStateWidget`, and `ErrorWidget` are appended as public `StatelessWidget` classes to `lib/widgets/order_card.dart`. All async screens import `order_card.dart` (they already do for `OrderCard`) or add the import to use these widgets.

```
lib/widgets/order_card.dart  ← LoadingWidget, EmptyStateWidget,
                                ErrorWidget appended (this PR)

Screens updated to use shared widgets:
  manage_products_screen.dart   ← Consumer states → shared widgets
  artisan_orders_screen.dart    ← Consumer states → shared widgets
  buyer_home_screen.dart        ← Consumer states → shared widgets
  buyer_orders_screen.dart      ← Consumer states → shared widgets
```

This PR sits after dark mode (PR46) and before admin screens (PR48).

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/widgets/order_card.dart` — append `LoadingWidget`, `EmptyStateWidget`, `ErrorWidget` classes
- `lib/screens/artisan/manage_products_screen.dart`
- `lib/screens/artisan/artisan_orders_screen.dart`
- `lib/screens/buyer/buyer_home_screen.dart`
- `lib/screens/buyer/buyer_orders_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/widgets/order_card.dart`

Append three new public `StatelessWidget` classes at the bottom of the file, after the existing `OrderCard` class. No modifications to the existing `OrderCard` class.

---

**`LoadingWidget`:**

```dart
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

---

**`EmptyStateWidget`:**

```dart
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.45),
                      ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

**`ErrorWidget` — renamed to `AppErrorWidget` to avoid conflict with Flutter's built-in `ErrorWidget`:**

```dart
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Note:** `ErrorWidget` conflicts with Flutter's built-in `ErrorWidget` class. The widget is named `AppErrorWidget` to avoid this conflict.

---

### Screen updates

Replace inline loading/error/empty patterns with the three shared widgets in each of the four async screens. The `Consumer`/`build` logic structure is preserved — only the returned widget instances change.

---

**`lib/screens/artisan/manage_products_screen.dart`**

Add import:
```dart
import 'package:craft_bridge/widgets/order_card.dart';
```

In `Consumer<ProductProvider>` builder:
- Replace inline `CircularProgressIndicator` with: `const LoadingWidget()`
- Replace inline error `Column` with: `AppErrorWidget(message: productProvider.errorMessage!, onRetry: () { ... })`
- Replace `_buildEmptyState()` result — `_buildEmptyState()` already returns the correct visual, but replace its internal `Column` structure with: call `EmptyStateWidget(icon: Icons.inventory_2_outlined, title: 'No products yet', subtitle: 'Tap the + button to add your first product.')` — update `_buildEmptyState()` to return this.

---

**`lib/screens/artisan/artisan_orders_screen.dart`**

Add import (already present for `OrderCard` — `LoadingWidget`, `EmptyStateWidget`, `AppErrorWidget` are in the same file):

In `Consumer<OrderProvider>` builder:
- Replace inline `CircularProgressIndicator` with: `const LoadingWidget()`
- Replace inline error `Column` with: `AppErrorWidget(message: orderProvider.errorMessage!, onRetry: () { orderProvider.clearError(); ... })`
- Replace `_buildEmptyState()` to return: `const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'No orders yet', subtitle: 'Orders from buyers will appear here.')`

---

**`lib/screens/buyer/buyer_home_screen.dart`**

In `Consumer<ProductProvider>` builder in `_buildProductGrid()`:
- Replace inline `CircularProgressIndicator` with: `const LoadingWidget()`
- Replace inline error `Column` with: `AppErrorWidget(message: productProvider.errorMessage!, onRetry: () { productProvider.clearError(); productProvider.listenToProducts(); })`

The `_buildEmptyState()` in `buyer_home_screen.dart` handles the no-results-found case (search/filter), not a loading error — keep it as-is with `EmptyStateWidget`:
```dart
Widget _buildEmptyState() {
  return const EmptyStateWidget(
    icon: Icons.search_off_rounded,
    title: 'No products found',
    subtitle: 'Try a different search or category.',
  );
}
```

---

**`lib/screens/buyer/buyer_orders_screen.dart`**

The `order_card.dart` import is already present.

In `Consumer<OrderProvider>` builder:
- Replace inline `CircularProgressIndicator` with: `const LoadingWidget()`
- Replace inline error `Column` with: `AppErrorWidget(message: orderProvider.errorMessage!, onRetry: () { orderProvider.clearError(); ... })`
- Replace `_buildEmptyState()` to return: `const EmptyStateWidget(icon: Icons.receipt_long_outlined, title: 'No orders yet', subtitle: 'Products you order will appear here.')`

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/widgets/order_card.dart` | `LoadingWidget`, `EmptyStateWidget`, `AppErrorWidget` appended as public `StatelessWidget` classes |
| 2 | `lib/screens/artisan/manage_products_screen.dart` | Inline async states replaced with shared widgets |
| 3 | `lib/screens/artisan/artisan_orders_screen.dart` | Inline async states replaced with shared widgets |
| 4 | `lib/screens/buyer/buyer_home_screen.dart` | Inline async states in `_buildProductGrid()` replaced with shared widgets |
| 5 | `lib/screens/buyer/buyer_orders_screen.dart` | Inline async states replaced with shared widgets |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify five files.

---

**File 1: `lib/widgets/order_card.dart`**

Append three new classes at the bottom of the existing file, after the `OrderCard` class. Do NOT modify `OrderCard` itself.

1. Append `LoadingWidget` with optional `message` parameter.
2. Append `EmptyStateWidget` with required `icon`, `title`, `subtitle` and optional `actionLabel`, `onAction`.
3. Append `AppErrorWidget` (NOT `ErrorWidget`) with required `message` and optional `onRetry`.

**Critical rules:**
- All three classes are `const`-constructible — use `const` constructors.
- `AppErrorWidget` — not `ErrorWidget` — avoids conflict with Flutter's built-in `ErrorWidget` class in `flutter/widgets.dart`.
- `EmptyStateWidget` optional action: `OutlinedButton` only shown when both `actionLabel` and `onAction` are non-null.

---

**Files 2–5: Four async screens**

For each screen, make the following replacements:

**Loading state replacement:**
Find: `return const Center(child: CircularProgressIndicator());`
Replace with: `return const LoadingWidget();`

**Error state replacement:**
Find: the `Center(child: Column(...))` error block with `Icon(Icons.error_outline...)`, error text, and Retry `TextButton`.
Replace with:
```dart
return AppErrorWidget(
  message: [provider].errorMessage!,
  onRetry: () {
    [provider].clearError();
    // re-subscribe call as appropriate for screen
  },
);
```

**Empty state replacement:**
Update each screen's `_buildEmptyState()` method to return `EmptyStateWidget(icon: ..., title: ..., subtitle: ...)` with the appropriate values per screen:

| Screen | Icon | Title | Subtitle |
|--------|------|-------|----------|
| `manage_products_screen.dart` | `Icons.inventory_2_outlined` | `'No products yet'` | `'Tap the + button to add your first product.'` |
| `artisan_orders_screen.dart` | `Icons.receipt_long_outlined` | `'No orders yet'` | `'Orders from buyers will appear here.'` |
| `buyer_home_screen.dart` | `Icons.search_off_rounded` | `'No products found'` | `'Try a different search or category.'` |
| `buyer_orders_screen.dart` | `Icons.receipt_long_outlined` | `'No orders yet'` | `'Products you order will appear here.'` |

**Import requirement:** `manage_products_screen.dart` needs `import 'package:craft_bridge/widgets/order_card.dart'` added if not already present. The other three screens already import `order_card.dart` for `OrderCard` — the new widgets are in the same file so no new import is needed.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Critical: `AppErrorWidget` must NOT be named `ErrorWidget` — the analyzer will flag a conflict with Flutter's built-in class. `EmptyStateWidget` and `LoadingWidget` have no naming conflicts.

2. **Verify three new widget classes in `order_card.dart`**
   ```
   grep 'class LoadingWidget\|class EmptyStateWidget\|class AppErrorWidget' lib/widgets/order_card.dart
   ```
   Must return `3` lines.

3. **Verify `ErrorWidget` is NOT used (would conflict)**
   ```
   grep 'class ErrorWidget' lib/widgets/order_card.dart
   ```
   Must return no output — confirming the class is named `AppErrorWidget`.

4. **Verify `LoadingWidget` usage in all four screens**
   ```
   grep -l 'LoadingWidget' lib/screens/artisan/manage_products_screen.dart lib/screens/artisan/artisan_orders_screen.dart lib/screens/buyer/buyer_home_screen.dart lib/screens/buyer/buyer_orders_screen.dart
   ```
   Must return all four file paths.

5. **Verify `AppErrorWidget` usage in all four screens**
   ```
   grep -l 'AppErrorWidget' lib/screens/artisan/manage_products_screen.dart lib/screens/artisan/artisan_orders_screen.dart lib/screens/buyer/buyer_home_screen.dart lib/screens/buyer/buyer_orders_screen.dart
   ```
   Must return all four file paths.

6. **Verify `EmptyStateWidget` usage in all four screens**
   ```
   grep -l 'EmptyStateWidget' lib/screens/artisan/manage_products_screen.dart lib/screens/artisan/artisan_orders_screen.dart lib/screens/buyer/buyer_home_screen.dart lib/screens/buyer/buyer_orders_screen.dart
   ```
   Must return all four file paths.

7. **Verify inline `CircularProgressIndicator` is removed from Consumer builders**
   ```
   grep 'CircularProgressIndicator' lib/screens/artisan/manage_products_screen.dart
   grep 'CircularProgressIndicator' lib/screens/artisan/artisan_orders_screen.dart
   grep 'CircularProgressIndicator' lib/screens/buyer/buyer_orders_screen.dart
   ```
   Each must return no output from Consumer builder contexts — the inline spinners are replaced by `LoadingWidget`. (Note: `buyer_home_screen.dart` may still have a `CircularProgressIndicator` in `_buildProductGrid` for image loading — that is acceptable.)

8. **Hot reload on emulator — async state display test**
   ```
   flutter run
   ```

   **Loading state test:**
   - Fresh login → `BuyerHomeScreen` briefly shows `LoadingWidget` (spinner centred) while `ProductProvider` stream first emits.
   - Artisan "My Orders" → brief `LoadingWidget` before orders load.

   **Empty state test:**
   - Create a fresh artisan account → navigate to "My Products" → `EmptyStateWidget` shows inventory icon, "No products yet", subtitle.
   - Buyer with no orders → Orders tab → `EmptyStateWidget` shows receipt icon, "No orders yet", subtitle.

   **Error state test:**
   - Temporarily disable network on emulator → navigate to a data screen → `AppErrorWidget` shows error icon, "Something went wrong", error message, "Retry" button.
   - Tap "Retry" → re-initiates the stream → loading widget → data loads.

   **Visual consistency verification:**
   - All four screens use identical loading spinner, error layout, and empty state layout — consistent visual language confirmed.

   Press `q` to quit.

9. **Verify only correct files were modified**
   ```
   git diff --name-only
   ```
   Expected: `lib/widgets/order_card.dart`, `lib/screens/artisan/manage_products_screen.dart`, `lib/screens/artisan/artisan_orders_screen.dart`, `lib/screens/buyer/buyer_home_screen.dart`, `lib/screens/buyer/buyer_orders_screen.dart`.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 47
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
git commit -m "PR47: Error Handling — Loaders, Empty States, Error Widgets"
git push origin pr47-error-handling
```

---

## Section 9 – Acceptance Criteria

- [ ] `lib/widgets/order_card.dart` contains `LoadingWidget`, `EmptyStateWidget`, and `AppErrorWidget` as public `const`-constructible `StatelessWidget` classes.
- [ ] `AppErrorWidget` is named `AppErrorWidget` — not `ErrorWidget` — to avoid conflict with Flutter's built-in class.
- [ ] `LoadingWidget` renders a centred `CircularProgressIndicator` with optional message text.
- [ ] `EmptyStateWidget` accepts required `icon`, `title`, `subtitle` and optional `actionLabel`/`onAction` — renders the `OutlinedButton` only when both action parameters are non-null.
- [ ] `AppErrorWidget` accepts required `message` and optional `onRetry` — renders "Something went wrong", error message, and "Retry" `OutlinedButton.icon` when `onRetry` is non-null.
- [ ] All four async screens (`ManageProductsScreen`, `ArtisanOrdersScreen`, `BuyerHomeScreen`, `BuyerOrdersScreen`) use `LoadingWidget`, `AppErrorWidget`, and `EmptyStateWidget` in place of inline implementations.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR47 for CraftBridge. I standardised the loading, error, and empty state UI across all async screens by implementing three reusable components — `LoadingWidget`, `EmptyStateWidget`, and `AppErrorWidget` — and retrofitting four screens to use them."

2. **Why reusable async state widgets matter:** "Before PR47, each screen had its own inline implementation of loading spinners, error columns, and empty states — similar code scattered across four files. If we wanted to change the loading spinner colour or the error icon size, we'd need to update four files. After PR47, that change is a single edit in `order_card.dart`."

3. **`AppErrorWidget` naming to avoid framework conflict:** "Flutter has a built-in `ErrorWidget` class in `widgets.dart` that renders the red error screen shown during debug layout failures. Naming our class `ErrorWidget` would shadow the built-in and cause confusing analyzer errors. `AppErrorWidget` — with the app prefix — is a clear signal that this is our application-level error display widget, not the framework's error renderer."

4. **`EmptyStateWidget` optional action:** "`EmptyStateWidget` has optional `actionLabel` and `onAction` parameters. When both are provided, an `OutlinedButton` appears below the subtitle — for example, "Browse Products" on the empty orders screen. When neither is provided (the most common case), the widget is a static informational display. The button requires both parameters to be non-null — providing a label without a callback or vice versa would be a logic error."

5. **`LoadingWidget` optional message:** "`LoadingWidget` has an optional `message` parameter. The default (no message) shows just the spinner — appropriate for a fast operation where showing 'Loading...' text would feel redundant. For slower operations, passing a message like `'Loading your orders...'` gives the user context. All four screens in this PR use `const LoadingWidget()` without a message — the spinner alone is sufficient."

6. **Co-location in `order_card.dart`:** "The three widgets are appended to `order_card.dart` because the locked folder structure has no appropriate new file slot. `order_card.dart` is the most general-purpose of the existing widget files — it's already imported by every async data screen that uses `OrderCard`. Adding the utility widgets here means those screens get the new widgets with no new import."

7. **`_buildEmptyState()` replacement pattern:** "Rather than replacing the entire `_buildEmptyState()` method call in `Consumer` builders, the method itself is updated to return an `EmptyStateWidget(...)` call. This keeps the screen's widget tree structure unchanged — the same method call in the builder, just returning a shared widget. This is the minimal-diff approach."

8. **Error retry flow:** "`AppErrorWidget.onRetry` is passed a callback that calls `provider.clearError()` followed by the re-subscription method. `clearError()` is important — without it, the `errorMessage` would still be non-null after the retry, and the `Consumer` would show the error state again before the stream fires. `clearError()` + `notifyListeners()` transitions the UI to the loading state before the new stream starts."

9. **Dark mode compatibility:** "All three widgets use `Theme.of(context).colorScheme.*` and `Theme.of(context).textTheme.*` exclusively — no hardcoded colours. They render correctly in both light and dark mode without any additional changes. The PR46 dark theme's `colorScheme.error`, `colorScheme.primary.withOpacity(0.3)`, and `colorScheme.onSurface.withOpacity(0.45)` all adapt automatically."

10. **What's Next:** "PR48 will implement the three admin screens — `AdminHomeScreen` (already a nav shell), `ManageUsersScreen` with artisan approval/rejection, and `ManageAllOrdersScreen` with platform-wide order monitoring — and implement `FirestoreService.getPendingArtisans()`, closing the last `UnimplementedError` stub."