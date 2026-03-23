# PR07 – Low-Level Design (LLD) — Models + FirestoreService

**Project:** CraftBridge
**PR Number:** 07 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement all five model classes with `fromMap()`, `toMap()`, and `copyWith()`, create `FirestoreService` with all method stubs, and create `StorageService` with `uploadProductImage()` stub.

---

## Section 2 – Assignments Covered

- Assignment 3.7 — Low-Level Design (LLD) — Models + FirestoreService

---

## Section 3 – Objective

This PR implements the complete data layer for CraftBridge — all five model classes that represent Firestore documents as typed Dart objects, `FirestoreService` with every method stub that will be progressively filled in through PRs 10 to 48, and `StorageService` with its upload stub. After this PR, the model contracts are permanently locked — no model file is ever modified again. `FirestoreService` and `StorageService` are never rewritten from scratch; they are only filled in. This PR is the single most structurally important PR in the project because every subsequent PR that touches data depends entirely on the signatures established here.

---

## Section 4 – Architecture Context

```
lib/
  models/
    user_model.dart          ← fully implemented this PR (LOCKED after)
    product_model.dart       ← fully implemented this PR (LOCKED after)
    order_model.dart         ← fully implemented this PR (LOCKED after)
    cart_item_model.dart     ← fully implemented this PR (LOCKED after)
    review_model.dart        ← fully implemented this PR (LOCKED after)
  services/
    firestore_service.dart   ← all stubs created this PR (filled progressively)
    storage_service.dart     ← upload stub created this PR (filled in PR24/PR27)

Progressive FirestoreService implementation schedule:
  PR07  → all method stubs (throw UnimplementedError)
  PR10  → user methods implemented
  PR26  → product read methods implemented
  PR30  → order read methods implemented
  PR31  → product write methods implemented
  PR33  → order write methods implemented
  PR34  → real-time stream methods implemented
  PR48  → admin methods implemented

Model lock rule:
  After PR07 merges → user_model.dart, product_model.dart,
  order_model.dart, cart_item_model.dart, review_model.dart
  are NEVER modified again in any PR.
```

This PR sits between the HLD (PR06) and the MaterialApp wiring (PR08). The models and service stubs established here are the data contract that every Provider, every screen, and every agent in PRs 08 through 51 must reference without deviation.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders from PR01.

**Allowed file modification:**
- `lib/models/user_model.dart`
- `lib/models/product_model.dart`
- `lib/models/order_model.dart`
- `lib/models/cart_item_model.dart`
- `lib/models/review_model.dart`
- `lib/services/firestore_service.dart`
- `lib/services/storage_service.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify `main.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `pubspec.yaml`.
- Do NOT modify any screen or widget placeholder files.
- Do NOT modify any provider placeholder files.

---

## Section 6 – Technical Requirements

---

### `lib/models/user_model.dart`

**Imports:** `package:cloud_firestore/cloud_firestore.dart`

**Class:** `UserModel`

**Fields** (all `final`):
- `uid`: `String`
- `email`: `String`
- `displayName`: `String`
- `role`: `String`
- `photoUrl`: `String`
- `bio`: `String`
- `isApproved`: `bool`
- `createdAt`: `Timestamp`

**Constructor:** `const UserModel({required ...})` — all fields required.

**Factory `fromMap`:**
```
factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
  uid: map['uid'] as String,
  email: map['email'] as String,
  displayName: map['displayName'] as String,
  role: map['role'] as String,
  photoUrl: map['photoUrl'] as String? ?? '',
  bio: map['bio'] as String? ?? '',
  isApproved: map['isApproved'] as bool? ?? false,
  createdAt: map['createdAt'] as Timestamp,
);
```

**`toMap` method:**
```
Map<String, dynamic> toMap() => {
  'uid': uid,
  'email': email,
  'displayName': displayName,
  'role': role,
  'photoUrl': photoUrl,
  'bio': bio,
  'isApproved': isApproved,
  'createdAt': createdAt,
};
```

**`copyWith` method:** Returns a new `UserModel` with any specified fields overridden. All parameters are nullable and optional. Uses `??` to fall back to current field values for any parameter not provided.

```
UserModel copyWith({
  String? uid,
  String? email,
  String? displayName,
  String? role,
  String? photoUrl,
  String? bio,
  bool? isApproved,
  Timestamp? createdAt,
}) => UserModel(
  uid: uid ?? this.uid,
  email: email ?? this.email,
  displayName: displayName ?? this.displayName,
  role: role ?? this.role,
  photoUrl: photoUrl ?? this.photoUrl,
  bio: bio ?? this.bio,
  isApproved: isApproved ?? this.isApproved,
  createdAt: createdAt ?? this.createdAt,
);
```

---

### `lib/models/product_model.dart`

**Imports:** `package:cloud_firestore/cloud_firestore.dart`

**Class:** `ProductModel`

**Fields** (all `final`):
- `id`: `String`
- `artisanId`: `String`
- `artisanName`: `String`
- `title`: `String`
- `description`: `String`
- `price`: `double`
- `imageUrl`: `String`
- `category`: `String`
- `stock`: `int`
- `isActive`: `bool`
- `createdAt`: `Timestamp`

**Constructor:** `const ProductModel({required ...})` — all fields required.

**Factory `fromMap`:**
```
factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
  id: map['id'] as String,
  artisanId: map['artisanId'] as String,
  artisanName: map['artisanName'] as String,
  title: map['title'] as String,
  description: map['description'] as String,
  price: (map['price'] as num).toDouble(),
  imageUrl: map['imageUrl'] as String? ?? '',
  category: map['category'] as String,
  stock: map['stock'] as int,
  isActive: map['isActive'] as bool? ?? true,
  createdAt: map['createdAt'] as Timestamp,
);
```

**`toMap` method:**
```
Map<String, dynamic> toMap() => {
  'id': id,
  'artisanId': artisanId,
  'artisanName': artisanName,
  'title': title,
  'description': description,
  'price': price,
  'imageUrl': imageUrl,
  'category': category,
  'stock': stock,
  'isActive': isActive,
  'createdAt': createdAt,
};
```

**`copyWith` method:** Same pattern as `UserModel.copyWith`. All parameters nullable and optional, `??` fallback to current values.

```
ProductModel copyWith({
  String? id,
  String? artisanId,
  String? artisanName,
  String? title,
  String? description,
  double? price,
  String? imageUrl,
  String? category,
  int? stock,
  bool? isActive,
  Timestamp? createdAt,
}) => ProductModel(
  id: id ?? this.id,
  artisanId: artisanId ?? this.artisanId,
  artisanName: artisanName ?? this.artisanName,
  title: title ?? this.title,
  description: description ?? this.description,
  price: price ?? this.price,
  imageUrl: imageUrl ?? this.imageUrl,
  category: category ?? this.category,
  stock: stock ?? this.stock,
  isActive: isActive ?? this.isActive,
  createdAt: createdAt ?? this.createdAt,
);
```

---

### `lib/models/order_model.dart`

**Imports:** `package:cloud_firestore/cloud_firestore.dart`

**Class:** `OrderModel`

**Fields** (all `final`):
- `id`: `String`
- `buyerId`: `String`
- `buyerName`: `String`
- `artisanId`: `String`
- `artisanName`: `String`
- `productId`: `String`
- `productTitle`: `String`
- `productImageUrl`: `String`
- `quantity`: `int`
- `totalPrice`: `double`
- `status`: `String`
- `createdAt`: `Timestamp`

**Constructor:** `const OrderModel({required ...})` — all fields required.

**Factory `fromMap`:**
```
factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
  id: map['id'] as String,
  buyerId: map['buyerId'] as String,
  buyerName: map['buyerName'] as String,
  artisanId: map['artisanId'] as String,
  artisanName: map['artisanName'] as String,
  productId: map['productId'] as String,
  productTitle: map['productTitle'] as String,
  productImageUrl: map['productImageUrl'] as String? ?? '',
  quantity: map['quantity'] as int,
  totalPrice: (map['totalPrice'] as num).toDouble(),
  status: map['status'] as String,
  createdAt: map['createdAt'] as Timestamp,
);
```

**`toMap` method:**
```
Map<String, dynamic> toMap() => {
  'id': id,
  'buyerId': buyerId,
  'buyerName': buyerName,
  'artisanId': artisanId,
  'artisanName': artisanName,
  'productId': productId,
  'productTitle': productTitle,
  'productImageUrl': productImageUrl,
  'quantity': quantity,
  'totalPrice': totalPrice,
  'status': status,
  'createdAt': createdAt,
};
```

**`copyWith` method:** Same pattern. All parameters nullable and optional.

```
OrderModel copyWith({
  String? id,
  String? buyerId,
  String? buyerName,
  String? artisanId,
  String? artisanName,
  String? productId,
  String? productTitle,
  String? productImageUrl,
  int? quantity,
  double? totalPrice,
  String? status,
  Timestamp? createdAt,
}) => OrderModel(
  id: id ?? this.id,
  buyerId: buyerId ?? this.buyerId,
  buyerName: buyerName ?? this.buyerName,
  artisanId: artisanId ?? this.artisanId,
  artisanName: artisanName ?? this.artisanName,
  productId: productId ?? this.productId,
  productTitle: productTitle ?? this.productTitle,
  productImageUrl: productImageUrl ?? this.productImageUrl,
  quantity: quantity ?? this.quantity,
  totalPrice: totalPrice ?? this.totalPrice,
  status: status ?? this.status,
  createdAt: createdAt ?? this.createdAt,
);
```

---

### `lib/models/cart_item_model.dart`

**Imports:** None required.

**Class:** `CartItemModel`

**Fields** (all `final`):
- `productId`: `String`
- `title`: `String`
- `imageUrl`: `String`
- `price`: `double`
- `quantity`: `int`
- `artisanId`: `String`
- `artisanName`: `String`

**Constructor:** `const CartItemModel({required ...})` — all fields required.

**No `fromMap` or `toMap`:** `CartItemModel` is local-only — it is never stored in or read from Firestore.

**`copyWith` method:**
```
CartItemModel copyWith({
  String? productId,
  String? title,
  String? imageUrl,
  double? price,
  int? quantity,
  String? artisanId,
  String? artisanName,
}) => CartItemModel(
  productId: productId ?? this.productId,
  title: title ?? this.title,
  imageUrl: imageUrl ?? this.imageUrl,
  price: price ?? this.price,
  quantity: quantity ?? this.quantity,
  artisanId: artisanId ?? this.artisanId,
  artisanName: artisanName ?? this.artisanName,
);
```

**Computed getter:**
```
double get totalPrice => price * quantity;
```

---

### `lib/models/review_model.dart`

**Imports:** `package:cloud_firestore/cloud_firestore.dart`

**Class:** `ReviewModel`

**Fields** (all `final`):
- `id`: `String`
- `productId`: `String`
- `buyerId`: `String`
- `buyerName`: `String`
- `rating`: `double`
- `comment`: `String`
- `createdAt`: `Timestamp`

**Constructor:** `const ReviewModel({required ...})` — all fields required.

**Factory `fromMap`:**
```
factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
  id: map['id'] as String,
  productId: map['productId'] as String,
  buyerId: map['buyerId'] as String,
  buyerName: map['buyerName'] as String,
  rating: (map['rating'] as num).toDouble(),
  comment: map['comment'] as String,
  createdAt: map['createdAt'] as Timestamp,
);
```

**`toMap` method:**
```
Map<String, dynamic> toMap() => {
  'id': id,
  'productId': productId,
  'buyerId': buyerId,
  'buyerName': buyerName,
  'rating': rating,
  'comment': comment,
  'createdAt': createdAt,
};
```

**`copyWith` method:**
```
ReviewModel copyWith({
  String? id,
  String? productId,
  String? buyerId,
  String? buyerName,
  double? rating,
  String? comment,
  Timestamp? createdAt,
}) => ReviewModel(
  id: id ?? this.id,
  productId: productId ?? this.productId,
  buyerId: buyerId ?? this.buyerId,
  buyerName: buyerName ?? this.buyerName,
  rating: rating ?? this.rating,
  comment: comment ?? this.comment,
  createdAt: createdAt ?? this.createdAt,
);
```

---

### `lib/services/firestore_service.dart`

**Imports:**
- `package:cloud_firestore/cloud_firestore.dart`
- `package:craft_bridge/models/user_model.dart`
- `package:craft_bridge/models/product_model.dart`
- `package:craft_bridge/models/order_model.dart`
- `package:craft_bridge/models/review_model.dart`

**Class:** `FirestoreService`

**Private field:**
```
final FirebaseFirestore _db = FirebaseFirestore.instance;
```

All methods below are stubs. Every stub body is exactly:
```
throw UnimplementedError('[methodName] not yet implemented');
```

The stubs are grouped by implementation PR. Every group must have a comment header. Every method must have the exact return type and signature specified below.

---

**Group: User Methods — implemented in PR10**

```dart
// ── User Methods ── implemented in PR10 ──────────────────────

Future<void> createUser(UserModel user) async {
  throw UnimplementedError('createUser not yet implemented');
}

Future<UserModel?> getUser(String uid) async {
  throw UnimplementedError('getUser not yet implemented');
}

Future<void> updateUser(String uid, Map<String, dynamic> data) async {
  throw UnimplementedError('updateUser not yet implemented');
}

Future<List<UserModel>> getAllUsers() async {
  throw UnimplementedError('getAllUsers not yet implemented');
}

Future<void> updateUserApproval(String uid, bool isApproved) async {
  throw UnimplementedError('updateUserApproval not yet implemented');
}
```

---

**Group: Product Read Methods — implemented in PR26**

```dart
// ── Product Read Methods ── implemented in PR26 ───────────────

Stream<List<ProductModel>> getProducts() {
  throw UnimplementedError('getProducts not yet implemented');
}

Stream<List<ProductModel>> getProductsByArtisan(String artisanId) {
  throw UnimplementedError('getProductsByArtisan not yet implemented');
}

Future<ProductModel?> getProductById(String productId) async {
  throw UnimplementedError('getProductById not yet implemented');
}
```

---

**Group: Product Write Methods — implemented in PR31**

```dart
// ── Product Write Methods ── implemented in PR31 ──────────────

Future<void> addProduct(ProductModel product) async {
  throw UnimplementedError('addProduct not yet implemented');
}

Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
  throw UnimplementedError('updateProduct not yet implemented');
}

Future<void> deleteProduct(String productId) async {
  throw UnimplementedError('deleteProduct not yet implemented');
}
```

---

**Group: Order Methods — implemented in PR33**

```dart
// ── Order Methods ── implemented in PR33 ─────────────────────

Future<void> createOrder(OrderModel order) async {
  throw UnimplementedError('createOrder not yet implemented');
}

Future<void> updateOrderStatus(String orderId, String status) async {
  throw UnimplementedError('updateOrderStatus not yet implemented');
}
```

---

**Group: Order Stream Methods — implemented in PR34**

```dart
// ── Order Stream Methods ── implemented in PR34 ───────────────

Stream<List<OrderModel>> getOrdersByArtisan(String artisanId) {
  throw UnimplementedError('getOrdersByArtisan not yet implemented');
}

Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
  throw UnimplementedError('getOrdersByBuyer not yet implemented');
}

Stream<List<OrderModel>> getAllOrders() {
  throw UnimplementedError('getAllOrders not yet implemented');
}
```

---

**Group: Review Methods — implemented in PR44**

```dart
// ── Review Methods ── implemented in PR44 ────────────────────

Future<void> addReview(ReviewModel review) async {
  throw UnimplementedError('addReview not yet implemented');
}

Stream<List<ReviewModel>> getReviewsByProduct(String productId) {
  throw UnimplementedError('getReviewsByProduct not yet implemented');
}
```

---

**Group: Admin Methods — implemented in PR48**

```dart
// ── Admin Methods ── implemented in PR48 ─────────────────────

Future<List<UserModel>> getPendingArtisans() async {
  throw UnimplementedError('getPendingArtisans not yet implemented');
}
```

---

**Total method count:** 20 methods across 6 groups. Every method must be present. No method may be omitted. No method may be implemented — all bodies must be `throw UnimplementedError(...)`.

---

### `lib/services/storage_service.dart`

**Imports:**
- `dart:io`
- `package:firebase_storage/firebase_storage.dart`

**Class:** `StorageService`

**Private field:**
```
final FirebaseStorage _storage = FirebaseStorage.instance;
```

**Stub methods:**

```dart
// ── Storage Methods ── implemented in PR24 ───────────────────

Future<String> uploadProductImage(File imageFile, String artisanId) async {
  throw UnimplementedError('uploadProductImage not yet implemented');
}

// ── Storage Methods ── implemented in PR27 ───────────────────

Future<String> updateProductImage(
  File newImageFile,
  String artisanId,
  String oldImageUrl,
) async {
  throw UnimplementedError('updateProductImage not yet implemented');
}

Future<void> deleteProductImage(String imageUrl) async {
  throw UnimplementedError('deleteProductImage not yet implemented');
}
```

**Total method count:** 3 methods. All bodies must be `throw UnimplementedError(...)`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/models/user_model.dart` | `UserModel` with all 8 fields, `const` constructor, `fromMap`, `toMap`, `copyWith` |
| 2 | `lib/models/product_model.dart` | `ProductModel` with all 11 fields, `const` constructor, `fromMap`, `toMap`, `copyWith` |
| 3 | `lib/models/order_model.dart` | `OrderModel` with all 12 fields, `const` constructor, `fromMap`, `toMap`, `copyWith` |
| 4 | `lib/models/cart_item_model.dart` | `CartItemModel` with all 7 fields, `const` constructor, `copyWith`, `totalPrice` getter — no Firestore serialisation |
| 5 | `lib/models/review_model.dart` | `ReviewModel` with all 7 fields, `const` constructor, `fromMap`, `toMap`, `copyWith` |
| 6 | `lib/services/firestore_service.dart` | `FirestoreService` with all 20 method stubs across 6 groups, each throwing `UnimplementedError` |
| 7 | `lib/services/storage_service.dart` | `StorageService` with 3 method stubs throwing `UnimplementedError` |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR06 is merged to main**

Open your GitHub repository and confirm the `pr06-hld` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR07 branch**
```
git checkout -b pr07-lld-models
```

**Step 4 — Confirm all placeholder files exist**
```
cat lib/models/user_model.dart
cat lib/models/product_model.dart
cat lib/models/order_model.dart
cat lib/models/cart_item_model.dart
cat lib/models/review_model.dart
cat lib/services/firestore_service.dart
cat lib/services/storage_service.dart
```
All seven files must show their single-comment placeholder lines from PR01. If any show a full implementation, do not proceed — diagnose before continuing.

---

Manual setup for this PR is now complete.
Open `docs/PR07_Low_Level_Design.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must implement all seven files. No new files are created. No new folders are created. The agent replaces placeholder content in the seven files listed below. All implementations must match Section 6 exactly — field names, types, method signatures, and stub bodies are locked.

---

**File 1: `lib/models/user_model.dart`**

Replace the placeholder. Write the complete `UserModel` class exactly as specified in Section 6. Import `package:cloud_firestore/cloud_firestore.dart`. Implement `const` constructor with all 8 required fields, `factory fromMap` with all safe-cast fallbacks, `toMap` returning all 8 fields, and `copyWith` with all nullable optional parameters. No extra fields. No extra methods.

---

**File 2: `lib/models/product_model.dart`**

Replace the placeholder. Write the complete `ProductModel` class exactly as specified in Section 6. Import `package:cloud_firestore/cloud_firestore.dart`. Note: `price` uses `(map['price'] as num).toDouble()` — never `map['price'] as double` — because Firestore may return numeric fields as `int` when the value has no decimal part. Same pattern for any `double` field. Implement all 11 fields, `fromMap`, `toMap`, `copyWith`.

---

**File 3: `lib/models/order_model.dart`**

Replace the placeholder. Write the complete `OrderModel` class exactly as specified in Section 6. Same `(map['totalPrice'] as num).toDouble()` pattern for `totalPrice`. Implement all 12 fields, `fromMap`, `toMap`, `copyWith`.

---

**File 4: `lib/models/cart_item_model.dart`**

Replace the placeholder. Write the complete `CartItemModel` class exactly as specified in Section 6. No imports required. No `fromMap` or `toMap`. Implement all 7 fields, `const` constructor, `copyWith`, and `double get totalPrice => price * quantity`. This is the only model without Firestore serialization.

---

**File 5: `lib/models/review_model.dart`**

Replace the placeholder. Write the complete `ReviewModel` class exactly as specified in Section 6. `rating` uses `(map['rating'] as num).toDouble()`. Implement all 7 fields, `fromMap`, `toMap`, `copyWith`.

---

**File 6: `lib/services/firestore_service.dart`**

Replace the placeholder. Write the complete `FirestoreService` class exactly as specified in Section 6. Import `cloud_firestore`, `user_model.dart`, `product_model.dart`, `order_model.dart`, and `review_model.dart`. Declare `final FirebaseFirestore _db = FirebaseFirestore.instance`. Write all 20 method stubs in the exact group order specified: User Methods (PR10), Product Read Methods (PR26), Product Write Methods (PR31), Order Methods (PR33), Order Stream Methods (PR34), Review Methods (PR44), Admin Methods (PR48). Every method body must be exactly `throw UnimplementedError('[methodName] not yet implemented');`. Every group must have its comment header. No method may be implemented. No method may be omitted.

---

**File 7: `lib/services/storage_service.dart`**

Replace the placeholder. Write the complete `StorageService` class exactly as specified in Section 6. Import `dart:io` and `firebase_storage`. Declare `final FirebaseStorage _storage = FirebaseStorage.instance`. Write all 3 method stubs with `throw UnimplementedError(...)` bodies and the correct group comment headers.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: missing `async` keyword on `Future<void>` stubs that use `throw` (note: `throw` inside an `async` function is valid and required here — but Stream-returning methods must NOT be `async`), unused `_db` or `_storage` field warnings, incorrect `as` cast types in `fromMap`.

2. **Verify method counts**

   For `firestore_service.dart`:
   ```
   grep -c 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Must return `20`.

   For `storage_service.dart`:
   ```
   grep -c 'UnimplementedError' lib/services/storage_service.dart
   ```
   Must return `3`.

3. **Verify model field counts**

   Spot-check each model by reading the file and counting `final` field declarations:
   - `user_model.dart` → 8 fields
   - `product_model.dart` → 11 fields
   - `order_model.dart` → 12 fields
   - `cart_item_model.dart` → 7 fields
   - `review_model.dart` → 7 fields

4. **Verify `CartItemModel` has no `fromMap`/`toMap`**
   ```
   grep -n 'fromMap\|toMap' lib/models/cart_item_model.dart
   ```
   Must return no output. `CartItemModel` is local-only.

5. **Verify `CartItemModel` has `totalPrice` getter**
   ```
   grep 'get totalPrice' lib/models/cart_item_model.dart
   ```
   Must return the getter line.

6. **Verify Stream-returning methods are not async**
   ```
   grep -n 'Stream<' lib/services/firestore_service.dart
   ```
   Check each result — none of the `Stream<...>` method signatures should have `async` keyword. Stream methods that throw are synchronous throws and must not be declared `async`.

7. **Verify no implementations exist — all stubs throw**
   ```
   grep -n 'UnimplementedError' lib/services/firestore_service.dart
   ```
   Confirm 20 lines with `UnimplementedError`. Confirm no method body contains actual Firestore logic.

8. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm the app still launches cleanly showing the PR04 demo screen. The models and services are not wired to any UI yet — no visible change is expected. No errors in debug console. Press `q` to quit.

9. **Verify no unintended files were modified**
   ```
   git diff --name-only
   ```
   Only these seven files should appear: all five model files and both service files.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 07
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
git commit -m "PR07: Low-Level Design (LLD) — Models + FirestoreService"
git push origin pr07-lld-models
```

---

## Section 9 – Acceptance Criteria

- [ ] All five model files are fully implemented with `const` constructors, all specified fields, and `copyWith` methods.
- [ ] `UserModel`, `ProductModel`, `OrderModel`, and `ReviewModel` each have `fromMap` and `toMap` methods.
- [ ] `CartItemModel` has no `fromMap` or `toMap` methods and has the `totalPrice` computed getter.
- [ ] `ProductModel.fromMap` and `OrderModel.fromMap` use `(map['price'] as num).toDouble()` and `(map['totalPrice'] as num).toDouble()` respectively.
- [ ] `firestore_service.dart` contains exactly 20 method stubs, all throwing `UnimplementedError`, grouped with comment headers matching the implementation PR schedule.
- [ ] No `Stream<...>`-returning method in `firestore_service.dart` is declared `async`.
- [ ] `storage_service.dart` contains exactly 3 method stubs all throwing `UnimplementedError`.
- [ ] No model file contains any logic beyond field declarations, constructor, `fromMap`, `toMap`, and `copyWith`.
- [ ] No method in `firestore_service.dart` or `storage_service.dart` contains actual Firebase implementation code.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR07 for CraftBridge. I implemented all five model classes, created `FirestoreService` with twenty method stubs, and created `StorageService` with three stubs — establishing the complete data contract for the project. After this PR merges, the model files are permanently locked."

2. **Why models are locked after PR07:** "The models are the contract between the Flutter client and Firestore. If `ProductModel` had a field renamed in PR26, every screen, every provider, and every Firestore document that references that field would break. Locking the models after PR07 means that every PR from PR08 through PR51 works from a stable, known data shape — no surprises."

3. **`fromMap` safe-cast pattern:** "Every `fromMap` factory uses `as Type?` with a `??` fallback for optional fields, and direct `as Type` for required fields. The most important pattern is `(map['price'] as num).toDouble()` for `double` fields. Firestore stores numbers without type annotation — if the stored value is `100` with no decimal, Dart will cast it as `int`, and `map['price'] as double` will throw a `TypeError` at runtime. Using `as num` and calling `.toDouble()` is safe for any numeric value."

4. **`CartItemModel` design:** "`CartItemModel` is the only model with no `fromMap` or `toMap`. The cart is local-only state managed entirely by `CartProvider` — it is never written to Firestore and never read from Firestore. It does have a `copyWith` for quantity updates and a `totalPrice` computed getter. This is a deliberate architectural decision — it keeps the cart fast and offline-capable."

5. **`copyWith` pattern:** "Every model has a `copyWith` method where every parameter is nullable and optional, with `??` fallback to `this.fieldName`. This means you can update a single field — for example `product.copyWith(stock: newStock)` — without reconstructing the entire object. Provider state updates use this pattern throughout."

6. **`FirestoreService` stub architecture:** "All 20 methods are stubs throwing `UnimplementedError`. They are grouped into six sections with comment headers that tell you exactly which PR implements each group: PR10 for user methods, PR26 for product reads, PR31 for product writes, PR33 for order writes, PR34 for order streams, PR44 for reviews, PR48 for admin methods. This means when Member 2 opens `firestore_service.dart` in PR26, they know exactly which methods they need to fill in and nothing else."

7. **Stream methods are not async:** "The three `Stream<>`-returning methods — `getProducts`, `getProductsByArtisan`, `getOrdersByArtisan`, `getOrdersByBuyer`, `getAllOrders`, and `getReviewsByProduct` — are not declared `async`. A `Stream` is returned synchronously by Firestore's `.snapshots()`. If you mark a Stream method `async`, Dart wraps the return in a `Future<Stream>`, which breaks `StreamBuilder`. The `throw UnimplementedError()` in a non-async method is a synchronous throw — correct for a stub."

8. **`StorageService` stubs:** "`StorageService` has three methods: `uploadProductImage` implemented in PR24, `updateProductImage` and `deleteProductImage` implemented in PR27. Separating update and delete from upload into PR27 is deliberate — PR24 wires the initial upload flow, PR27 adds the image lifecycle management that makes the product editing flow complete."

9. **`flutter analyze` on stubs:** "Running the analyzer on a file with 20 `throw UnimplementedError()` stubs is a useful test — it catches type mismatches in return types, missing `async` on `Future`-returning methods, and unused import warnings. Getting zero issues here confirms the method signatures are syntactically correct even before a single one is implemented."

10. **What's Next:** "PR08 will update `main.dart` with the full `MultiProvider` registration of all four providers and the `home` pointing to `SplashScreen`, laying the complete application wiring that every subsequent PR will build on."