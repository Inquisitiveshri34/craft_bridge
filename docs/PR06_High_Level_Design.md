# PR06 – High-Level Design (HLD)

**Project:** CraftBridge
**PR Number:** 06 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

High-Level Design document covering system architecture, module interaction map, Firebase service layer, data flow, and deployment architecture for CraftBridge.

---

## Section 2 – Assignments Covered

- Assignment 3.6 — High-Level Design (HLD)

---

## Section 3 – Objective

This PR produces the formal High-Level Design document for CraftBridge, describing the system from an architectural perspective — how the Flutter client, Firebase backend, and external services (Google Maps, Firebase Storage) connect and interact. No new Dart files are created or modified. The HLD document becomes the structural blueprint that directly informs the Low-Level Design in PR07, where the architecture described here is decomposed into concrete files, classes, and method signatures. Every teammate should read this document before implementing any screen or service.

---

## Section 4 – Architecture Context

```
docs/
  PR06_High_Level_Design.md       ← produced this PR

No Dart files touched.
No Firebase interactions.
No new dependencies.

System layers described in this PR:

┌─────────────────────────────────────────┐
│           Flutter Client (Mobile)        │
│  Screens → Providers → Services         │
└──────────────────┬──────────────────────┘
                   │ Firebase SDK
┌──────────────────▼──────────────────────┐
│              Firebase Backend            │
│  Auth │ Firestore │ Storage │ FCM        │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           External Services              │
│  Google Maps SDK │ Geolocator            │
└─────────────────────────────────────────┘
```

This PR sits between Design Thinking (PR05) and the LLD (PR07). The architecture described here is the contract that PR07 decomposes into files and signatures. All module names, service names, and data flow descriptions used in this document must match the locked folder structure and Firestore schema exactly.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders or implementations from previous PRs.

**Allowed file modification:**
- `docs/PR06_High_Level_Design.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new `.dart` files.
- Do NOT modify any existing `.dart` files.
- Do NOT modify `pubspec.yaml`.
- Do NOT modify `README.md`.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.

---

## Section 6 – Technical Requirements

### `docs/PR06_High_Level_Design.md`

A Markdown document containing all of the following sections in order. No section may be omitted.

---

#### 1. System Overview

A 4–5 sentence paragraph covering: CraftBridge is a Flutter mobile application backed entirely by Firebase with no custom server or REST API. The client communicates directly with Firebase Auth, Cloud Firestore, and Firebase Storage using the FlutterFire SDKs. State is managed on the client using the Provider package — four providers (AuthProvider, ProductProvider, OrderProvider, CartProvider) mediate between the UI layer and the service layer. Google Maps Flutter SDK and the Geolocator package provide location features on the product detail screen. The architecture is intentionally serverless — all business logic lives in the Flutter client and Firestore security rules, with no middleware tier.

---

#### 2. Architecture Diagram

An ASCII diagram showing the three-tier architecture. The diagram must show:

```
┌──────────────────────────────────────────────────────┐
│                  Flutter Client                       │
│                                                      │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐        │
│   │  Screens  │   │Providers │   │ Services │        │
│   │(UI Layer) │◄──│(State)   │◄──│(Data)    │        │
│   └──────────┘   └──────────┘   └──────────┘        │
│                                        │             │
└────────────────────────────────────────┼─────────────┘
                                         │ FlutterFire SDKs
┌────────────────────────────────────────▼─────────────┐
│                  Firebase Backend                     │
│                                                      │
│   ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌────┐ │
│   │  Auth    │  │ Firestore │  │ Storage  │  │FCM │ │
│   │(email/pw)│  │(4 colls)  │  │(images)  │  │    │ │
│   └──────────┘  └───────────┘  └──────────┘  └────┘ │
└────────────────────────────────────────┬─────────────┘
                                         │
┌────────────────────────────────────────▼─────────────┐
│                External Services                      │
│                                                      │
│        ┌──────────────────┐  ┌──────────────┐        │
│        │ Google Maps SDK  │  │  Geolocator  │        │
│        │(artisan location)│  │(buyer loc.)  │        │
│        └──────────────────┘  └──────────────┘        │
└──────────────────────────────────────────────────────┘
```

Followed by 2–3 sentences explaining the three tiers and the direction of data flow.

---

#### 3. Module Breakdown

A table with columns: **Module**, **Files**, **Responsibility**, **Depends On**.

| Module | Files | Responsibility | Depends On |
|--------|-------|----------------|------------|
| App Entry | `main.dart` | Firebase init, Provider registration, MaterialApp, theme wiring | AppTheme, all Providers |
| Theme & Constants | `app_theme.dart`, `app_constants.dart` | Global theme tokens, string/numeric constants | None |
| Models | `user_model.dart`, `product_model.dart`, `order_model.dart`, `cart_item_model.dart`, `review_model.dart` | Typed data contracts, Firestore serialisation/deserialisation | None |
| Services | `firestore_service.dart`, `storage_service.dart` | All Firebase read/write operations, Storage upload/delete | Firebase SDKs, Models |
| Providers | `auth_provider.dart`, `product_provider.dart`, `order_provider.dart`, `cart_provider.dart` | State management, exposes streams/notifiers to UI | Services, Models |
| Auth Screens | `login_screen.dart`, `registration_screen.dart` | User-facing sign-in and registration flows | AuthProvider, CustomTextField, CustomButton |
| Shared Screens | `splash_screen.dart`, `role_router_screen.dart` | App entry routing, role-based navigation | AuthProvider |
| Artisan Screens | `artisan_home_screen.dart`, `manage_products_screen.dart`, `add_edit_product_screen.dart`, `artisan_orders_screen.dart` | Full artisan product and order management flows | ProductProvider, OrderProvider, StorageService |
| Buyer Screens | `buyer_home_screen.dart`, `product_detail_screen.dart`, `cart_screen.dart`, `buyer_orders_screen.dart` | Full buyer browse, cart, and order flows | ProductProvider, CartProvider, OrderProvider |
| Admin Screens | `admin_home_screen.dart`, `manage_users_screen.dart`, `manage_all_orders_screen.dart` | Artisan approval, user oversight, order monitoring | FirestoreService, AuthProvider |
| Widgets | `custom_text_field.dart`, `custom_button.dart`, `product_card.dart`, `order_card.dart`, `cart_item_tile.dart` | Reusable UI components shared across screen modules | AppTheme |

---

#### 4. Firebase Service Layer

A sub-section for each Firebase service used in CraftBridge.

**4.1 Firebase Authentication**

Paragraph covering: email and password sign-in and registration via `FirebaseAuth.instance`. Auth state is exposed through `authStateChanges()` stream in `AuthProvider`. On sign-up, a corresponding user document is created in Firestore `users/{uid}`. On sign-in, `AuthProvider` reads the user's role and approval status from Firestore and exposes them to the widget tree. Sign-out clears the local auth state and Provider state, redirecting to LoginScreen via RoleRouterScreen.

**4.2 Cloud Firestore**

Paragraph covering: four collections — `users`, `products`, `orders`, `reviews`. All reads and writes go through `FirestoreService` methods — no screen or provider ever accesses `FirebaseFirestore.instance` directly. Real-time listeners use `snapshots()` streams exposed through Providers, enabling reactive UI updates without polling. Queries are scoped by role: artisans query products by `artisanId`, buyers query all active products, admins query all documents. Security rules (PR39) enforce role-based access at the database level.

**4.3 Firebase Storage**

Paragraph covering: product images are uploaded to Firebase Storage via `StorageService.uploadProductImage()`. Images are stored at path `products/{artisanId}/{filename}`. The download URL is saved to the product document's `imageUrl` field in Firestore. Image deletion (PR36) removes the Storage file and clears the `imageUrl` field. No other file types are stored in Storage in the MVP.

**4.4 Firebase Cloud Messaging (FCM)**

Short paragraph covering: FCM integration is documented in PR38 as a notification stub. In the MVP, a notification permission request is made at login and an FCM token is stored in the user document. Full notification delivery (order status changes triggering push notifications) is out of scope for the MVP and documented as a post-MVP enhancement.

---

#### 5. Data Flow Diagrams

Three data flow descriptions — one per major operation. Each is a numbered ASCII flow followed by a paragraph explanation.

**5.1 User Registration and Role Routing**

```
User taps "Create Account"
        │
        ▼
RegistrationScreen validates form
        │
        ▼
AuthProvider.signUp(email, password, displayName, role)
        │
        ├── FirebaseAuth.createUserWithEmailAndPassword()
        │         └── returns UserCredential (uid)
        │
        └── FirestoreService.createUser(UserModel)
                  └── writes to users/{uid}
                            ├── role: 'artisan' | 'buyer'
                            └── isApproved: false (artisan) | true (buyer)
        │
        ▼
AuthProvider.authStateChanges() fires
        │
        ▼
RoleRouterScreen reads role + isApproved
        │
        ├── role == 'admin'   → AdminHomeScreen
        ├── role == 'artisan' + isApproved == true  → ArtisanHomeScreen
        ├── role == 'artisan' + isApproved == false → Pending screen
        └── role == 'buyer'   → BuyerHomeScreen
```

**5.2 Product Creation by Artisan**

```
Artisan taps FAB on ManageProductsScreen
        │
        ▼
AddEditProductScreen opens (add mode)
        │
        ▼
Artisan fills form + selects image from gallery
        │
        ▼
StorageService.uploadProductImage(file, artisanId)
        │   └── uploads to Storage: products/{artisanId}/{filename}
        │   └── returns downloadUrl (String)
        │
        ▼
ProductProvider.addProduct(ProductModel)
        │
        └── FirestoreService.addProduct(product)
                  └── writes to products/{productId}
                            └── imageUrl: downloadUrl
        │
        ▼
ManageProductsScreen StreamBuilder rebuilds
        └── new ProductCard appears in grid
```

**5.3 Order Placement by Buyer**

```
Buyer taps "Place Order" on CartScreen
        │
        ▼
CartProvider provides List<CartItemModel>
        │
        ▼
For each CartItem → OrderProvider.createOrder(OrderModel)
        │
        └── FirestoreService.createOrder(order)
                  └── writes to orders/{orderId}
                            ├── status: 'pending'
                            ├── buyerId, buyerName
                            ├── artisanId, artisanName
                            └── productId, quantity, totalPrice
        │
        ▼
CartProvider.clearCart()
        │
        ▼
Navigation → BuyerOrdersScreen
        └── StreamBuilder shows new order with status 'pending'
```

---

#### 6. State Management Architecture

A prose section covering the following points:

- **Provider pattern:** CraftBridge uses the Provider package exclusively for state management. There is no BLoC, Riverpod, or Redux. Four `ChangeNotifier` providers are registered at the top of the widget tree in `main.dart` using `MultiProvider`.
- **AuthProvider:** The most critical provider. It wraps `FirebaseAuth.instance.authStateChanges()` and exposes `currentUser` (nullable `UserModel`), `isInitialized` (bool), `isLoading` (bool), and `errorMessage` (nullable String). Every role-gated screen reads from `AuthProvider`.
- **ProductProvider:** Exposes `products` (List<ProductModel>), `artisanProducts` (List<ProductModel> filtered by artisanId), `isLoading`, and `errorMessage`. Wraps Firestore stream listeners for reactive product list updates.
- **OrderProvider:** Exposes `artisanOrders` (List<OrderModel> for current artisan), `buyerOrders` (List<OrderModel> for current buyer), `allOrders` (for admin), `isLoading`. Wraps Firestore stream listeners.
- **CartProvider:** Local state only — never writes to Firestore. Exposes `items` (List<CartItemModel>), `totalPrice` (double), `itemCount` (int). Provides `addItem`, `removeItem`, `updateQuantity`, `clearCart` methods.
- **Consumer vs context.read vs context.watch:** Screens that rebuild on state changes use `context.watch<T>()` or `Consumer<T>`. One-time actions (button taps) use `context.read<T>()`. This pattern is enforced across all screen implementations.

---

#### 7. Navigation Architecture

A prose section covering:

- **No named routes:** CraftBridge uses direct `Navigator.push` and `Navigator.pushReplacement` calls. No `onGenerateRoute` or named route map. This keeps navigation explicit and traceable.
- **RoleRouterScreen as the navigation hub:** After every login and app restart, the app lands on `RoleRouterScreen`, which reads `AuthProvider` and pushes the correct home screen. It never appears in the navigation stack — it always calls `pushReplacement`.
- **SplashScreen → RoleRouterScreen:** `SplashScreen` waits for `AuthProvider.isInitialized` and then calls `Navigator.pushReplacement` to `RoleRouterScreen`. Users never see a back-navigation option to the splash.
- **Screen-level navigation:** Each role's screens navigate forward using `Navigator.push`. Back navigation uses the default back button behavior. No bottom navigation for artisan or admin screens — only BuyerHomeScreen has a `BottomNavigationBar` (implemented in PR45).
- **Modal flows:** `AddEditProductScreen` and order status updates on `ArtisanOrdersScreen` use `Navigator.push` and bottom sheets respectively, not full-screen replacements.

---

#### 8. Security Architecture

A prose section covering:

- **Firestore security rules (PR39):** Rules enforce role-based access. Buyers can only read products and write their own orders. Artisans can only write their own products and read their own orders. Admins can read and write all documents. Rules are deployed in PR39 after all screen implementations are complete.
- **Authentication gating:** Every screen except `LoginScreen`, `RegistrationScreen`, and `SplashScreen` assumes an authenticated user. If `AuthProvider.currentUser` is null, `RoleRouterScreen` redirects to `LoginScreen`. There is no client-side route guard beyond this — Firestore rules are the enforcement layer.
- **Storage security:** Firebase Storage rules (set to test mode in PR04, tightened in PR39) will restrict image uploads to authenticated artisans only and image reads to authenticated users.
- **No secrets in client code:** `firebase_options.dart` contains API keys that are specific to the Firebase project. These are safe to commit for mobile apps — Firebase project-level security is enforced via Firestore rules, Auth domain restrictions, and Android/iOS app restrictions in the Firebase Console, not by keeping the options file secret.

---

#### 9. Deployment Architecture

A prose section covering:

- **Android primary target:** The MVP targets Android. The release APK build is documented in PR49. A signed APK is produced using a keystore generated in PR49.
- **iOS secondary target:** iOS is supported by the Flutter project configuration but is not the primary submission target. No separate iOS release steps are documented.
- **Firebase Hosting:** Not used. CraftBridge is a mobile app with no web component in the MVP.
- **Play Store deployment:** Documented in PR50. The app targets API level 34 (Android 14). The `applicationId` is `com.craftbridge.craft_bridge`.
- **CI/CD:** Not implemented in the MVP. All builds are produced manually using `flutter build apk --release` in PR49.
- **Firebase project environments:** A single Firebase project is used for both development and production in the MVP. Separate dev/prod Firebase projects are a post-MVP enhancement.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `docs/PR06_High_Level_Design.md` | Complete HLD document with all 9 sections — system overview, architecture diagram, module breakdown, Firebase service layer, data flow diagrams, state management, navigation, security, and deployment architecture |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR05 is merged to main**

Open your GitHub repository and confirm the `pr05-design-thinking` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR06 branch**
```
git checkout -b pr06-hld
```

**Step 4 — Confirm `docs/` contains both previous documents**
```
ls docs/
```
Confirm both `PR05_Design_Thinking.md` and `PR04` (no doc for PR04 — check `PR03_Flutter_Dart_Fundamentals.md` and `PR02_Project_Plan_MVP_Scope.md` and `PR01_Technology_Orientation_Project_Scaffold.md`) are present. The `docs/` directory should contain PR01 through PR05 documents at this point.

---

Manual setup for this PR is now complete.
Open `docs/PR06_High_Level_Design.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must perform exactly one task: write the file `docs/PR06_High_Level_Design.md`.

The file is a Markdown document. It must contain all 9 sections specified in Section 6 of this PR document, in order, with no sections omitted. The agent must write each section as follows:

**Section 1 — System Overview:** Write a 4–5 sentence paragraph covering all five points specified in Section 6: serverless architecture, direct Firebase SDK communication, four-provider state management, Google Maps and Geolocator, and intentional absence of a middleware tier.

**Section 2 — Architecture Diagram:** Reproduce the exact ASCII three-tier diagram specified in Section 6, followed by 2–3 sentences explaining the tiers and data flow direction.

**Section 3 — Module Breakdown:** Produce the complete 11-row table with all columns populated exactly as specified in Section 6. No rows may be omitted. No cells may be empty.

**Section 4 — Firebase Service Layer:** Write all four sub-sections (4.1 through 4.4) as prose paragraphs covering all points specified in Section 6 for each Firebase service.

**Section 5 — Data Flow Diagrams:** Reproduce all three ASCII flow diagrams exactly as specified in Section 6, each followed by a brief paragraph explanation of the flow.

**Section 6 — State Management Architecture:** Write full prose covering all six bullet points specified in Section 6 — Provider pattern, AuthProvider, ProductProvider, OrderProvider, CartProvider, and the Consumer/context.read/context.watch pattern.

**Section 7 — Navigation Architecture:** Write full prose covering all five navigation points specified in Section 6.

**Section 8 — Security Architecture:** Write full prose covering all four security points specified in Section 6.

**Section 9 — Deployment Architecture:** Write full prose covering all six deployment points specified in Section 6.

The agent must not create any `.dart` files. The agent must not modify any existing files. The only file written in this PR is `docs/PR06_High_Level_Design.md`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings. No Dart files were modified in this PR so this must pass identically to PR05. If it does not, diagnose before continuing.

2. **Verify the document exists**
   ```
   ls docs/
   ```
   Confirm `PR06_High_Level_Design.md` is present alongside all previous PR documents.

3. **Verify document completeness**
   ```
   cat docs/PR06_High_Level_Design.md
   ```
   Confirm all 9 sections are present in order. Confirm Section 3 module table has 11 rows. Confirm Section 4 has four sub-sections. Confirm Section 5 has three ASCII flow diagrams. Confirm Sections 6, 7, 8, and 9 are written in prose.

4. **Verify no Dart files were modified**
   ```
   git diff --name-only
   ```
   The only file that should appear in the diff is `docs/PR06_High_Level_Design.md`. If any `.dart` files appear, the agent has violated scope — do not push and output a VERIFICATION FAILED report.

5. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 06
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
git commit -m "PR06: High-Level Design (HLD)"
git push origin pr06-hld
```

---

## Section 9 – Acceptance Criteria

- [ ] `docs/PR06_High_Level_Design.md` exists at the correct path.
- [ ] The document contains all 9 sections in the correct order with no sections omitted.
- [ ] Section 2 contains the three-tier ASCII architecture diagram showing Flutter client, Firebase backend, and external services.
- [ ] Section 3 contains an 11-row module breakdown table with Module, Files, Responsibility, and Depends On columns fully populated.
- [ ] Section 4 contains four sub-sections covering Auth, Firestore, Storage, and FCM service layers.
- [ ] Section 5 contains three data flow diagrams — user registration, product creation, and order placement.
- [ ] Section 6 describes all four Providers and the Consumer/context.read/context.watch usage pattern.
- [ ] Section 7 describes the RoleRouterScreen navigation hub and the no-named-routes decision.
- [ ] No `.dart` files were created or modified by this PR.
- [ ] `git diff --name-only` shows only `docs/PR06_High_Level_Design.md` as changed.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR06 for CraftBridge. I produced the High-Level Design document — the system architecture blueprint that describes how the Flutter client, Firebase backend, and external services are structured and how data flows between them."

2. **Serverless architecture decision:** "CraftBridge has no custom server, no REST API, and no middleware tier. The Flutter client talks directly to Firebase using the FlutterFire SDKs. This is an intentional architectural decision — it keeps the project maintainable by a small team, eliminates server infrastructure costs, and lets Firestore security rules handle access control at the database level."

3. **Three-tier diagram:** "Section 2 shows the three tiers: the Flutter client layer with Screens, Providers, and Services; the Firebase backend with Auth, Firestore, Storage, and FCM; and the external services layer with Google Maps and Geolocator. Data flows down from Screens through Providers to Services, then out to Firebase. State changes flow back up through Provider's `notifyListeners()` to rebuild only the widgets that are listening."

4. **Module breakdown table:** "Section 3 maps every file in the project to a module, its responsibility, and what it depends on. This table is the reference that lets any teammate answer 'which file do I need to touch for X?' without reading the entire codebase. Notice that Models and the Theme/Constants module depend on nothing — they are the foundation layer. Services depend on Models. Providers depend on Services. Screens depend on Providers."

5. **Firebase service layer:** "Section 4 covers how each Firebase service is used. Auth manages session state through `authStateChanges()`. Firestore has a strict rule — no screen ever touches `FirebaseFirestore.instance` directly, everything goes through `FirestoreService`. Storage is scoped to product images only. FCM is a stub in the MVP."

6. **Data flow diagrams:** "Section 5 shows three critical flows as ASCII diagrams: user registration and role routing, product creation by an artisan, and order placement by a buyer. These flows cross every architectural layer — from a button tap on screen, through a Provider method, through a Service call, into Firebase, and back up through a stream listener to rebuild the UI. Understanding these three flows means understanding ninety percent of how the app works."

7. **State management rationale:** "Section 6 explains why Provider was chosen over BLoC or Riverpod. For a three-member student project building a defined set of 51 PRs, Provider gives the right balance of explicitness and simplicity. The four providers have clear, non-overlapping responsibilities. CartProvider is the most interesting — it's local-only, never writes to Firestore, and demonstrates that not all state needs to be persisted."

8. **Navigation architecture:** "Section 7 documents the decision to use direct `Navigator.push` calls rather than named routes. `RoleRouterScreen` is the navigation hub — it always uses `pushReplacement` so it never appears in the back stack. Once you're in BuyerHomeScreen, pressing back doesn't take you to RoleRouterScreen, it takes you out of the app. This is the correct mobile navigation pattern."

9. **Security architecture:** "Section 8 covers the two-layer security model: client-side routing via `RoleRouterScreen` and server-side enforcement via Firestore security rules in PR39. The `firebase_options.dart` section is important — students often panic when they see API keys committed to git, but for mobile apps this is correct and expected. The real security comes from Firestore rules and Firebase Console app restrictions."

10. **What's Next:** "PR07 will produce the Low-Level Design — decomposing this architecture into concrete Dart files: all five model classes with `fromMap()`, `toMap()`, and `copyWith()`, `FirestoreService` with all method stubs, and `StorageService` with its upload stub."