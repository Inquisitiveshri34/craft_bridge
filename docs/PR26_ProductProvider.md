# PR26 – Firebase Project Setup — ProductProvider + Product Read

**Project:** CraftBridge
**PR Number:** 26 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Implement `ProductProvider` with product stream state management and implement `FirestoreService.getProducts()`, `getProductsByArtisan()`, and `getProductById()` — enabling live Firestore product reads.

---

## Section 2 – Assignments Covered

- Assignment 3.26 — Firebase Project Setup — ProductProvider + Product Read

---

## Section 3 – Objective

This PR implements the product read layer — `ProductProvider` as a full `ChangeNotifier` that subscribes to Firestore product streams, and the three product read methods in `FirestoreService`. After this PR, any screen that calls `context.watch<ProductProvider>()` will receive a live-updating list of products from Firestore, reactive to any document changes. `BuyerHomeScreen` and `ManageProductsScreen` are not yet wired to the Provider in this PR — that happens in PR31 and PR32 — but the Provider is ready and registered in the `MultiProvider` tree from PR08.

---

## Section 4 – Architecture Context

```
FirestoreService (Product Read Methods — filled this PR)
  getProducts()
    → _db.collection('products')
         .where('isActive', isEqualTo: true)
         .snapshots()
         → Stream<List<ProductModel>>

  getProductsByArtisan(String artisanId)
    → _db.collection('products')
         .where('artisanId', isEqualTo: artisanId)
         .snapshots()
         → Stream<List<ProductModel>>

  getProductById(String productId)
    → _db.collection('products').doc(productId).get()
         → Future<ProductModel?>

ProductProvider (ChangeNotifier — fully implemented this PR)
  ├── _products: List<ProductModel>
  ├── _artisanProducts: List<ProductModel>
  ├── _isLoading: bool
  ├── _errorMessage: String?
  ├── _productsSubscription: StreamSubscription?
  ├── _artisanSubscription: StreamSubscription?
  │
  ├── listenToProducts()
  │     └── FirestoreService.getProducts() → sets _products
  │
  ├── listenToArtisanProducts(String artisanId)
  │     └── FirestoreService.getProductsByArtisan() → sets _artisanProducts
  │
  ├── getProductById(String productId)
  │     └── FirestoreService.getProductById() → returns ProductModel?
  │
  └── dispose()
        └── cancels both subscriptions

firestore_service.dart UnimplementedError count:
  Before this PR: 15
  After this PR:  12 (3 product read stubs filled)
```

This PR sits after animations (PR25) and before `StorageService` full implementation (PR27). The `ProductProvider` is registered in `MultiProvider` in `main.dart` from PR08 — it is already in the widget tree. No screen wiring happens in this PR.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/providers/product_provider.dart`
- `lib/services/firestore_service.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart` or any other provider files.
- Do NOT modify any screen files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/services/firestore_service.dart`

Replace only the three Product Read Method stub bodies. All other method stubs remain as `throw UnimplementedError(...)`. The class structure, `_db` field, all import statements, and all other method groups are preserved unchanged.

---

**Product Read Methods — replace stub bodies with implementations:**

```dart
// ── Product Read Methods ── implemented in PR26 ───────────────

Stream<List<ProductModel>> getProducts() {
  return _db
      .collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              ProductModel.fromMap(doc.data()))
          .toList());
}

Stream<List<ProductModel>> getProductsByArtisan(String artisanId) {
  return _db
      .collection(AppConstants.productsCollection)
      .where('artisanId', isEqualTo: artisanId)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              ProductModel.fromMap(doc.data()))
          .toList());
}

Future<ProductModel?> getProductById(String productId) async {
  final DocumentSnapshot doc = await _db
      .collection(AppConstants.productsCollection)
      .doc(productId)
      .get();
  if (!doc.exists) return null;
  return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
}
```

**Implementation notes:**

- `getProducts()` filters by `isActive == true` — only active products are shown to buyers. This query requires a Firestore composite index if combined with ordering — for this MVP no ordering is applied so no index is needed.
- `getProductsByArtisan()` does NOT filter by `isActive` — artisans see all their products including inactive ones.
- Both stream methods use `.snapshots().map(...)` — converting `QuerySnapshot` to `List<ProductModel>` in a single chain. The `.map` on the stream transforms every emission.
- `getProductById()` uses `.get()` — a one-time fetch, not a stream. It returns `null` if the document does not exist.
- `ProductModel.fromMap(doc.data())` — `doc.data()` returns `Map<String, dynamic>?` but after the `doc.exists` check in `getProductById`, it is safe to force-unwrap as `Map<String, dynamic>`. For stream methods, Firestore guarantees `doc.data()` is non-null for documents in a query snapshot.

---

**`UnimplementedError` count after this PR:**

```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `12` (was 15 — 3 product read stubs replaced).

---

### `lib/providers/product_provider.dart`

Replace the PR08 minimal stub with the full implementation.

---

**Imports:**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
```

---

**Class:** `ProductProvider extends ChangeNotifier`

---

**Private fields:**

```dart
final FirestoreService _firestoreService = FirestoreService();
List<ProductModel> _products = [];
List<ProductModel> _artisanProducts = [];
bool _isLoading = false;
String? _errorMessage;
StreamSubscription<List<ProductModel>>? _productsSubscription;
StreamSubscription<List<ProductModel>>? _artisanSubscription;
```

---

**Public getters:**

```dart
List<ProductModel> get products => List.unmodifiable(_products);
List<ProductModel> get artisanProducts =>
    List.unmodifiable(_artisanProducts);
bool get isLoading => _isLoading;
String? get errorMessage => _errorMessage;
```

`List.unmodifiable()` prevents callers from mutating the provider's internal list directly — all mutations must go through provider methods.

---

**`listenToProducts()` method:**

```dart
void listenToProducts() {
  _productsSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  _productsSubscription = _firestoreService.getProducts().listen(
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

**`listenToArtisanProducts()` method:**

```dart
void listenToArtisanProducts(String artisanId) {
  _artisanSubscription?.cancel();
  _isLoading = true;
  notifyListeners();
  _artisanSubscription =
      _firestoreService.getProductsByArtisan(artisanId).listen(
    (productList) {
      _artisanProducts = productList;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    },
    onError: (Object error) {
      _errorMessage = 'Failed to load your products: $error';
      _isLoading = false;
      notifyListeners();
    },
  );
}
```

---

**`getProductById()` method:**

```dart
Future<ProductModel?> getProductById(String productId) async {
  try {
    return await _firestoreService.getProductById(productId);
  } catch (e) {
    _errorMessage = 'Failed to load product: $e';
    notifyListeners();
    return null;
  }
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
  _productsSubscription?.cancel();
  _artisanSubscription?.cancel();
  super.dispose();
}
```

---

**Full class structure summary:**

```
ProductProvider
  fields:   _firestoreService, _products, _artisanProducts,
            _isLoading, _errorMessage,
            _productsSubscription, _artisanSubscription
  getters:  products, artisanProducts, isLoading, errorMessage
  methods:  listenToProducts(), listenToArtisanProducts(artisanId),
            getProductById(productId), clearError(), dispose()
```

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/providers/product_provider.dart` | Full `ProductProvider` with stream subscriptions, `List.unmodifiable` getters, loading/error state, and `dispose()` |
| 2 | `lib/services/firestore_service.dart` | Product Read Methods group filled — `getProducts()`, `getProductsByArtisan()`, `getProductById()` — all other stubs unchanged |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify exactly two files.

---

**File 1: `lib/services/firestore_service.dart`**

Make targeted replacements to the existing PR07/PR10 implementation:

**Change 1 — Verify `AppConstants` import is present:**
Check the import block for `package:craft_bridge/core/constants/app_constants.dart`. It was added in PR10 — confirm it is present. If missing, add it.

**Change 2 — Replace the three Product Read Method stub bodies:**
Locate the `// ── Product Read Methods ── implemented in PR26 ───────────────` comment block. Replace each of the three method bodies (`throw UnimplementedError(...)`) with the implementations specified in Section 6.

**Change 3 — Verify the stream methods are NOT async:**
`getProducts()` and `getProductsByArtisan()` return `Stream<List<ProductModel>>` — they must NOT be declared `async`. Stream methods are synchronous by nature — they return a `Stream` object immediately. Adding `async` would change the return type to `Future<Stream<...>>`. Confirm neither method has the `async` keyword.

After editing, verify:
```
grep -c 'UnimplementedError' lib/services/firestore_service.dart
```
Must return `12`.

---

**File 2: `lib/providers/product_provider.dart`**

Replace the entire PR08 minimal stub content with the full implementation specified in Section 6.

Write the complete file in this order:

1. All four import statements: `dart:async`, `flutter/foundation.dart`, `product_model.dart`, `firestore_service.dart`.
2. `class ProductProvider extends ChangeNotifier` opening.
3. All seven private fields in the order specified.
4. All four public getters — `products` and `artisanProducts` using `List.unmodifiable()`.
5. `listenToProducts()` — cancels existing subscription, sets loading, starts new stream subscription with `listen` callbacks.
6. `listenToArtisanProducts(String artisanId)` — same pattern as `listenToProducts()`.
7. `getProductById(String productId)` — `async` method, try-catch, delegates to `_firestoreService`.
8. `clearError()` — sets `_errorMessage = null`, notifies.
9. `dispose()` — cancels both subscriptions, calls `super.dispose()`.

**Critical implementation rules:**

- `List.unmodifiable(_products)` — the getter returns an unmodifiable view. Callers (screens) cannot do `context.watch<ProductProvider>().products.add(...)` — all mutations go through provider methods.
- Both `listen` subscriptions use named `onError` callbacks — unhandled stream errors would crash the app if not caught here.
- `_productsSubscription?.cancel()` before starting a new subscription — prevents multiple listeners accumulating if `listenToProducts()` is called more than once.
- `getProductById()` is `async` and wrapped in try-catch — it is a one-time `Future`, not a stream, so try-catch is the correct error handling pattern.
- `dispose()` must call `super.dispose()` after cancelling subscriptions.
- Do NOT call `listenToProducts()` or `listenToArtisanProducts()` from the constructor — screens call these methods explicitly when they need the data. Auto-subscribing in the constructor would start a Firestore listener before any screen has navigated, wasting bandwidth and quota.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `StreamSubscription` requires `dart:async` import; `List.unmodifiable` return type — annotate getter return type as `List<ProductModel>` explicitly if inference fails; stream methods in `firestore_service.dart` must not have `async` keyword; `doc.data()` in `getProductById` cast requires null check pattern.

2. **Verify `UnimplementedError` count in `firestore_service.dart`**
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return `12`.

3. **Verify stream methods are not async in `firestore_service.dart`**
   ```
   grep -n 'Stream<List<ProductModel>>' lib/services/firestore_service.dart
   ```
   Review each returned line — confirm neither `getProducts` nor `getProductsByArtisan` declaration contains `async`.

4. **Verify `isActive` filter in `getProducts`**
   ```
   grep 'isActive' lib/services/firestore_service.dart
   ```
   Must return one line — the `where('isActive', isEqualTo: true)` clause.

5. **Verify `List.unmodifiable` is used in getters**
   ```
   grep 'List.unmodifiable' lib/providers/product_provider.dart
   ```
   Must return `2` lines — one for `products`, one for `artisanProducts`.

6. **Verify both stream subscriptions are declared**
   ```
   grep 'StreamSubscription' lib/providers/product_provider.dart
   ```
   Must return at least `3` lines — the import and two field declarations.

7. **Verify `dispose()` cancels both subscriptions**
   ```
   grep -c '\.cancel()' lib/providers/product_provider.dart
   ```
   Must return at least `4` — two cancels in `dispose()` plus two in `listenToProducts()` and `listenToArtisanProducts()` before restarting.

8. **Verify `listenToProducts` is NOT called from constructor**
   ```
   grep -A5 'ProductProvider()' lib/providers/product_provider.dart
   ```
   The constructor (if present) must not call `listenToProducts()` or `listenToArtisanProducts()`. If no explicit constructor exists, the implicit constructor is fine.

9. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - App launches without errors.
   - No `UnimplementedError` crash on startup.
   - `ProductProvider` is in the widget tree (registered in `main.dart` from PR08) — confirm no `ProviderNotFoundException`.
   - `BuyerHomeScreen` still shows stub products (not yet wired to `ProductProvider` — that is PR32). This is expected.
   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/providers/product_provider.dart` and `lib/services/firestore_service.dart` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 26
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
git commit -m "PR26: Firebase Project Setup — ProductProvider + Product Read"
git push origin pr26-product-provider
```

---

## Section 9 – Acceptance Criteria

- [ ] `FirestoreService.getProducts()` returns `Stream<List<ProductModel>>` filtering `isActive == true`, using `AppConstants.productsCollection`.
- [ ] `FirestoreService.getProductsByArtisan()` returns `Stream<List<ProductModel>>` filtering by `artisanId`, without `isActive` filter.
- [ ] `FirestoreService.getProductById()` returns `Future<ProductModel?>` — null if document does not exist.
- [ ] Neither `getProducts()` nor `getProductsByArtisan()` is declared `async`.
- [ ] `grep -c 'UnimplementedError' lib/services/firestore_service.dart` returns `12`.
- [ ] `ProductProvider` extends `ChangeNotifier` and declares `_products`, `_artisanProducts`, `_isLoading`, `_errorMessage`, `_productsSubscription`, `_artisanSubscription`.
- [ ] `products` and `artisanProducts` getters return `List.unmodifiable(...)` views.
- [ ] `listenToProducts()` and `listenToArtisanProducts()` cancel existing subscriptions before starting new ones, set `_isLoading = true`, and handle stream errors via `onError`.
- [ ] `dispose()` cancels both `_productsSubscription` and `_artisanSubscription` and calls `super.dispose()`.
- [ ] `listenToProducts()` is not called from the `ProductProvider` constructor.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR26 for CraftBridge. I implemented the full product read layer — `ProductProvider` with stream-based state management and the three product read methods in `FirestoreService` — enabling live Firestore product data for any screen that subscribes."

2. **`getProducts()` — `isActive` filter design:** "`getProducts()` filters by `isActive == true`. This means only products that artisans have set as active are shown to buyers. If an artisan marks a product inactive — for example, because it's out of stock — it disappears from buyer searches in real time without any buyer-side logic change. `getProductsByArtisan()` deliberately does not filter by `isActive` — artisans need to see all their products, including inactive ones, to manage them."

3. **Stream-to-list transformation:** "Both stream methods use `.snapshots().map(snapshot => snapshot.docs.map(doc => ProductModel.fromMap(doc.data())).toList())`. The outer `.map()` runs on the `Stream<QuerySnapshot>`, transforming each `QuerySnapshot` emission into a `List<ProductModel>`. This is a pure functional pipeline — each Firestore update produces a new list, and the stream never closes until the subscription is cancelled."

4. **Why stream methods are not `async`:** "Dart's `async` keyword changes a function's return type to `Future<T>` and wraps its body in an async context. A method returning `Stream<T>` declared `async` would have the compiler infer the return type as `Future<Stream<T>>` — completely wrong. Stream methods are synchronous at the top level — they construct and return a `Stream` object immediately. The `async` keyword belongs on `getProductById()` which returns a `Future`."

5. **`List.unmodifiable()` in getters:** "`products` and `artisanProducts` return `List.unmodifiable(_products)` rather than `_products` directly. If a screen called `context.watch<ProductProvider>().products.add(fakeProduct)`, it would mutate the provider's internal list without going through `notifyListeners()` — a silent state corruption bug. `List.unmodifiable` throws an `UnsupportedError` immediately if a caller tries to mutate the returned list, making the bug visible rather than silent."

6. **Subscription cancel before restart:** "Both `listen` methods cancel the existing subscription before starting a new one. This prevents subscription leaks if `listenToProducts()` is called multiple times — for example, if a screen calls it in `initState` and is then hot-reloaded. Without the cancel, each call would add a new listener, and `_products` would be updated multiple times per Firestore event."

7. **`onError` stream callback:** "The `listen` call includes an `onError` named callback that catches stream errors — `FirebaseException` for permission denials, network errors, or malformed data. Without `onError`, an unhandled stream error would propagate up and crash the app. The `onError` sets `_errorMessage` and calls `notifyListeners()` so screens can show error UI."

8. **Not calling `listenToProducts()` from the constructor:** "`ProductProvider` is constructed in `MultiProvider` at app startup — before any user is logged in. Calling `listenToProducts()` in the constructor would start a Firestore query immediately, likely failing with a permission error because the security rules (PR39) require authentication. Screens call these methods explicitly when they are ready to receive data — `BuyerHomeScreen` calls `listenToProducts()` in PR32, `ManageProductsScreen` calls `listenToArtisanProducts()` in PR31."

9. **`dispose()` subscription management:** "`ProductProvider.dispose()` cancels both stream subscriptions. `ChangeNotifier.dispose()` is called by `MultiProvider` when the widget tree disposes the provider — in practice, when the app shuts down. Cancelling subscriptions here stops Firestore from attempting to deliver data after the provider is gone, preventing memory leaks and post-dispose error logs."

10. **What's Next:** "PR27 will fully implement `StorageService` — adding `updateProductImage()` and `deleteProductImage()` — completing the Storage lifecycle for product images that will be used when artisans edit or delete products in PR36."