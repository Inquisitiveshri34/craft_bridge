# PR39 – Security Rules — Firestore Rules Deployed

**Project:** CraftBridge
**PR Number:** 39 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Write and deploy production-ready Firestore security rules enforcing role-based access control across all four collections, replacing the PR04 test-mode rules.

---

## Section 2 – Assignments Covered

- Assignment 3.39 — Security Rules — Firestore Rules Deployed

---

## Section 3 – Objective

This PR replaces the open test-mode Firestore security rules deployed in PR04 with production-ready rules that enforce role-based access control across all four collections — `users`, `products`, `orders`, and `reviews`. After this PR, unauthenticated users cannot read or write any data, buyers cannot write to collections they don't own, artisans cannot access other artisans' data, and admins have platform-wide read access. No Dart files are modified — this PR writes only `firestore.rules`. The rules are deployed to the live Firebase project using the Firebase CLI.

---

## Section 4 – Architecture Context

```
firestore.rules (after this PR)

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    isAuthenticated()      → request.auth != null
    isOwner(uid)           → request.auth.uid == uid
    getUserRole()          → get(/users/{uid}).data.role
    isAdmin()              → getUserRole() == 'admin'
    isArtisan()            → getUserRole() == 'artisan'
    isBuyer()              → getUserRole() == 'buyer'
    isApprovedArtisan()    → isArtisan() && get(/users/{uid}).data.isApproved

    users/{uid}:
      read:  owner OR admin
      write: owner (own doc only) OR admin

    products/{productId}:
      read:  authenticated (all active products visible to buyers)
      write: artisan (own products only, artisanId must match)

    orders/{orderId}:
      read:  buyer (own orders) OR artisan (own orders) OR admin
      write (create): buyer only
      write (update): artisan (own orders, status field only) OR admin

    reviews/{reviewId}:
      read:  authenticated
      write (create): buyer only
      write (update/delete): owner (own review)
  }
}

Firebase CLI deployment:
  firebase deploy --only firestore:rules

No Dart files modified. No pubspec.yaml changes.
```

This PR sits after FCM setup (PR38) and before Google Maps (PR40). It is the only PR that modifies `firestore.rules`.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `firestore.rules` — production rules replacing test-mode open rules

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new `.dart` files.
- Do NOT modify any existing `.dart` files.
- Do NOT modify `pubspec.yaml`.
- Do NOT modify `firebase.json`.
- Do NOT modify `analysis_options.yaml`.

---

## Section 6 – Technical Requirements

### `firestore.rules`

Replace the entire contents of `firestore.rules` with the following production-ready rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper Functions ─────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isAdmin() {
      return isAuthenticated() && getUserData().role == 'admin';
    }

    function isApprovedArtisan() {
      return isAuthenticated() &&
             getUserData().role == 'artisan' &&
             getUserData().isApproved == true;
    }

    function isBuyer() {
      return isAuthenticated() && getUserData().role == 'buyer';
    }

    // ── Users Collection ─────────────────────────────────────

    match /users/{uid} {
      // Users can read their own document; admins can read all
      allow read: if isAuthenticated() && (isOwner(uid) || isAdmin());

      // Users can create their own document on registration
      allow create: if isAuthenticated() && isOwner(uid);

      // Users can update their own document; admins can update any
      allow update: if isAuthenticated() && (isOwner(uid) || isAdmin());

      // Only admins can delete user documents
      allow delete: if isAdmin();
    }

    // ── Products Collection ───────────────────────────────────

    match /products/{productId} {
      // Any authenticated user can read products
      // (isActive filtering is done in the Flutter query, not rules)
      allow read: if isAuthenticated();

      // Only approved artisans can create products
      // artisanId in the document must match the authenticated user
      allow create: if isApprovedArtisan() &&
                       request.resource.data.artisanId == request.auth.uid;

      // Only the owning artisan can update their products
      allow update: if isApprovedArtisan() &&
                       resource.data.artisanId == request.auth.uid;

      // Only the owning artisan or admin can delete
      allow delete: if (isApprovedArtisan() &&
                        resource.data.artisanId == request.auth.uid) ||
                       isAdmin();
    }

    // ── Orders Collection ─────────────────────────────────────

    match /orders/{orderId} {
      // Buyers can read their own orders
      // Artisans can read orders for their products
      // Admins can read all orders
      allow read: if isAuthenticated() && (
        (isBuyer() && resource.data.buyerId == request.auth.uid) ||
        (isApprovedArtisan() && resource.data.artisanId == request.auth.uid) ||
        isAdmin()
      );

      // Only buyers can create orders
      // buyerId in the document must match the authenticated user
      allow create: if isBuyer() &&
                       request.resource.data.buyerId == request.auth.uid;

      // Artisans can update order status only
      // Admins can update any field
      allow update: if (isApprovedArtisan() &&
                        resource.data.artisanId == request.auth.uid &&
                        request.resource.data.diff(resource.data).affectedKeys()
                          .hasOnly(['status'])) ||
                       isAdmin();

      // No one can delete orders in the MVP
      allow delete: if false;
    }

    // ── Reviews Collection ────────────────────────────────────

    match /reviews/{reviewId} {
      // Any authenticated user can read reviews
      allow read: if isAuthenticated();

      // Only buyers can create reviews
      // buyerId must match the authenticated user
      allow create: if isBuyer() &&
                       request.resource.data.buyerId == request.auth.uid;

      // Buyers can update or delete only their own reviews
      allow update: if isBuyer() &&
                       resource.data.buyerId == request.auth.uid;

      allow delete: if isBuyer() &&
                       resource.data.buyerId == request.auth.uid;
    }

  }
}
```

---

**Rule design decisions documented inline:**

**`getUserData()` function:** Reads the authenticated user's document from Firestore to determine their role. This is a cross-document read (`get()`) inside a security rule — Firestore supports this but bills it as an additional read operation per rule evaluation. Acceptable for an MVP.

**`isActive` filter not in rules:** Products are filtered by `isActive: true` in the Flutter query (`FirestoreService.getProducts()`), not in the security rules. Rules enforce access control — query filtering is the application's responsibility. Putting `isActive` in the rules would prevent artisans from reading their own inactive products, which is incorrect.

**`affectedKeys().hasOnly(['status'])`:** This constraint on the orders update rule ensures artisans can only change the `status` field — they cannot change `totalPrice`, `buyerId`, or any other field. `request.resource.data.diff(resource.data).affectedKeys()` returns the set of fields that differ between the incoming write and the current document. `.hasOnly(['status'])` verifies only `status` is being changed.

**`allow delete: if false` for orders:** Orders are permanent records in the MVP — no one can delete an order document. If a cancellation occurs, the status is set to `'cancelled'`, but the document remains.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `firestore.rules` | Production-ready role-based security rules for all four collections, deployed to Firebase |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must perform two tasks: write `firestore.rules` and deploy it.

---

**Task 1: Write `firestore.rules`**

Replace the entire content of `firestore.rules` with the rules specified in Section 6. The file must contain exactly the rules shown — no additions, no removals, no reformatting that changes the logical meaning.

**Critical rules:**
- `rules_version = '2'` must be the first line.
- All helper functions must be defined before the collection match blocks.
- `getUserData()` uses the correct Firestore path syntax: `/databases/$(database)/documents/users/$(request.auth.uid)`.
- `request.resource.data` refers to the incoming write data. `resource.data` refers to the existing document data.
- `affectedKeys().hasOnly(['status'])` is the correct Firestore rules syntax for restricting which fields can be updated.
- `allow delete: if false` is valid Firestore rules syntax — it permanently denies all delete operations.

---

**Task 2: Deploy `firestore.rules`**

Run the Firebase CLI deployment command:

```
firebase deploy --only firestore:rules
```

This command reads `firestore.rules` and `firebase.json` from the project root and deploys the rules to the Firebase project configured in `.firebaserc`. The command requires the Firebase CLI to be authenticated (done in PR04's Part 1 manual setup).

**Expected output:**
```
=== Deploying to 'craftbridge-xxxxx'...

i  deploying firestore
i  firestore: checking firestore.rules for compilation errors...
✔  firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

If the deployment fails with an authentication error:
```
Error: Failed to get credentials
```
Run `firebase login` to re-authenticate and retry.

If the deployment fails with a rules syntax error:
```
Error: [firestore/invalid-argument] ...
```
Check the `firestore.rules` file for syntax errors and fix before retrying.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. No Dart files were modified — this must pass identically to PR38.

2. **Verify `firestore.rules` content**
   ```
   cat firestore.rules
   ```
   Confirm:
   - `rules_version = '2'` is the first line.
   - All four collection blocks are present: `users`, `products`, `orders`, `reviews`.
   - All helper functions are present: `isAuthenticated()`, `isOwner()`, `getUserData()`, `isAdmin()`, `isApprovedArtisan()`, `isBuyer()`.
   - `affectedKeys().hasOnly(['status'])` is present in the orders update rule.
   - `allow delete: if false` is present in the orders block.

3. **Verify deployment succeeded**
   ```
   firebase deploy --only firestore:rules
   ```
   Must complete with `✔  Deploy complete!` and no errors.

4. **Test rules — authenticated read (should succeed):**
   ```
   flutter run
   ```
   Sign in as a buyer → `BuyerHomeScreen` loads products → confirm no `PERMISSION_DENIED` errors in debug console.

5. **Test rules — unauthenticated read (should fail):**
   Sign out completely. In the Firebase Console → Firestore → try to read a document in the `products` collection using the Rules Playground:
   - Set authentication to "Unauthenticated"
   - Operation: get
   - Path: `/products/{any-product-id}`
   - Confirm: `Denied`

6. **Test rules — buyer cannot write products (should fail):**
   In the Firebase Console → Firestore → Rules Playground:
   - Authentication: sign in as a buyer (use "Add authentication" with buyer UID)
   - Operation: create
   - Path: `/products/test-id`
   - Document data: `{artisanId: 'buyer-uid', ...}`
   - Confirm: `Denied`

7. **Test rules — artisan can only update own products (should succeed for own, fail for others):**
   In the Rules Playground:
   - Authentication: artisan UID
   - Operation: update
   - Path: `/products/{artisan's-own-product-id}`
   - Confirm: `Allowed`
   Then:
   - Path: `/products/{different-artisan's-product-id}`
   - Confirm: `Denied`

8. **Test rules — artisan can only update `status` field on orders:**
   In the Rules Playground:
   - Authentication: artisan UID
   - Operation: update
   - Path: `/orders/{artisan's-order-id}`
   - Data: `{status: 'confirmed'}` (only status changed)
   - Confirm: `Allowed`
   Then:
   - Data: `{status: 'confirmed', totalPrice: 0}` (totalPrice also changed)
   - Confirm: `Denied`

9. **Full app flow regression test:**
   ```
   flutter run
   ```
   Confirm all existing flows still work under the new rules:
   - Buyer registration → Firestore user doc created ✓
   - Artisan registration → Firestore user doc created ✓
   - Buyer browses products → reads allowed ✓
   - Artisan adds product → create allowed (approved artisan) ✓
   - Buyer places order → create allowed ✓
   - Artisan updates order status → update allowed (status only) ✓
   - No `PERMISSION_DENIED` errors in debug console during normal flows ✓
   Press `q` to quit.

10. **Verify only `firestore.rules` was modified**
    ```
    git diff --name-only
    ```
    Only `firestore.rules` should appear. No `.dart` files, no `pubspec.yaml`.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix the rule syntax and redeploy before retrying.
- If the deployment fails after one retry, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 39
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
git commit -m "PR39: Security Rules — Firestore Rules Deployed"
git push origin pr39-security-rules
```

---

## Section 9 – Acceptance Criteria

- [ ] `firestore.rules` contains `rules_version = '2'` as the first line.
- [ ] All six helper functions are defined: `isAuthenticated()`, `isOwner()`, `getUserData()`, `isAdmin()`, `isApprovedArtisan()`, `isBuyer()`.
- [ ] `users` collection: owners can read and update their own document; admins can read and update all; only admins can delete.
- [ ] `products` collection: any authenticated user can read; only approved artisans can create (with matching `artisanId`); only the owning artisan can update; owning artisan or admin can delete.
- [ ] `orders` collection: buyers read own, artisans read own, admins read all; only buyers can create (with matching `buyerId`); artisans can update `status` field only (`affectedKeys().hasOnly(['status'])`); `allow delete: if false`.
- [ ] `reviews` collection: authenticated users can read; only buyers can create (with matching `buyerId`); buyers can update and delete only their own reviews.
- [ ] `firebase deploy --only firestore:rules` completes with `✔  Deploy complete!`.
- [ ] Unauthenticated reads to any collection are denied (verified in Firebase Console Rules Playground).
- [ ] Buyer attempting to write to `products` collection is denied.
- [ ] Artisan attempting to update `totalPrice` on an order is denied.
- [ ] All normal app flows (browse, register, add product, place order, update status) succeed without `PERMISSION_DENIED` errors.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR39 for CraftBridge. I wrote and deployed production-ready Firestore security rules — replacing the open test-mode rules from PR04 with role-based access control that enforces data ownership and role permissions across all four collections."

2. **Why test-mode rules are dangerous:** "The PR04 test-mode rules allowed any read or write to any collection from any client for 30 days. This means any device with the `firebase_options.dart` API key could read all user data, delete all products, or create fake orders. Production-ready rules are essential before any real user data enters the system."

3. **`getUserData()` cross-document read:** "`getUserData()` calls `get(/databases/$(database)/documents/users/$(request.auth.uid))` — a cross-document read inside a security rule. Firestore evaluates this at rule check time, reading the user's document to determine their role. This is Firestore's recommended pattern for role-based access control. It costs one additional read operation per rule evaluation, but it is the only way to check role from within the rules engine."

4. **`isActive` not in rules — deliberate decision:** "The products rules allow any authenticated user to read any product, including inactive ones. `isActive` filtering is done in the Flutter query layer (`FirestoreService.getProducts()` with `where('isActive', isEqualTo: true)`). If `isActive: false` were a rule-level restriction, artisans couldn't read their own inactive products to manage them. Rules enforce access control; queries enforce business logic."

5. **`affectedKeys().hasOnly(['status'])` field-level restriction:** "The orders update rule for artisans uses `request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status'])`. `diff()` computes the difference between the incoming write and the existing document. `affectedKeys()` returns the set of changed fields. `.hasOnly(['status'])` verifies that only the `status` field is being changed. This prevents an artisan from modifying `totalPrice`, `buyerId`, or any other field — they can only advance the order status."

6. **`allow delete: if false` for orders:** "Orders are permanent records in CraftBridge. A cancelled order still exists — its status is `'cancelled'` but the document remains for record-keeping. `allow delete: if false` ensures no client — not even an admin — can delete an order document through the Flutter app. If records need to be purged in the future, it would be done via a Firebase Admin SDK script, not through the client."

7. **Buyer `buyerId` ownership in creates:** "For orders and reviews, the create rule requires `request.resource.data.buyerId == request.auth.uid`. This ensures a buyer cannot create an order with someone else's `buyerId`. Even if a malicious client tried to forge an order attributing it to another buyer, the rule would deny it. The same pattern applies to artisan product creates — `artisanId` must match the authenticated UID."

8. **Security rule testing with the Rules Playground:** "The Firebase Console's Rules Playground allows testing rules without writing code. You specify an authentication context (authenticated as a specific UID), an operation (read, create, update, delete), a document path, and optional document data. The playground evaluates the rules and shows Allowed or Denied with the matching rule. This is how I verified each access pattern in the rules without running the full app for each test."

9. **No Flutter code changes:** "PR39 modifies exactly one file — `firestore.rules`. No Dart files, no `pubspec.yaml`. This demonstrates that security is a separate concern from application logic. The app's behaviour is unchanged — the same operations succeed or fail as before, but now they are enforced server-side rather than relying on client-side trust."

10. **What's Next:** "PR40 will integrate Google Maps into `ProductDetailScreen` — adding a static map with the artisan's location marker so buyers can see where the artisan is based when viewing a product."