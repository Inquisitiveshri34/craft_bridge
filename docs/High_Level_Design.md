# CraftBridge - High-Level Design (HLD)

## 1. System Overview

CraftBridge is a Flutter mobile application backed entirely by Firebase, with no custom server, no REST API, and no middleware layer. The Flutter client communicates directly with Firebase Authentication, Cloud Firestore, and Firebase Storage through FlutterFire SDK integrations. Client-side state is managed using Provider, with four dedicated providers: AuthProvider, ProductProvider, OrderProvider, and CartProvider, which mediate interactions between UI modules and data services. Location features are integrated through Google Maps Flutter SDK and Geolocator, primarily for artisan location display in product details and buyer location context. This architecture is intentionally serverless, where business workflows are enforced through Flutter application logic and Firestore security rules rather than an intermediate backend service.

## 2. Architecture Diagram

```text
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

The architecture is organized into three layers: Flutter Client, Firebase Backend, and External Services. UI actions originate in Screens, are coordinated by Providers, and execute persistence through Services that call FlutterFire SDKs. Data and auth state then flow back upward through stream listeners and notifier updates, enabling reactive UI rendering.

## 3. Module Breakdown

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

## 4. Firebase Service Layer

### 4.1 Firebase Authentication

CraftBridge uses email/password authentication via `FirebaseAuth.instance` for registration and login flows. `AuthProvider` subscribes to `authStateChanges()` and exposes current authentication state to the widget tree for role-aware routing. During sign-up, the app creates an auth user first and then writes a linked user profile document to `users/{uid}` in Firestore. During sign-in, `AuthProvider` reads role and approval metadata from Firestore and publishes the resolved user context; on sign-out it clears local state and redirects users back to LoginScreen through RoleRouterScreen.

### 4.2 Cloud Firestore

The data layer is centered on four collections: `users`, `products`, `orders`, and `reviews`. All Firestore reads and writes are routed through `FirestoreService`; screens and providers do not access `FirebaseFirestore.instance` directly, which keeps query logic centralized and testable. Reactive UI updates are powered by `snapshots()` listeners surfaced through providers, so product grids and order lists refresh without polling. Query scope is role-driven: artisans filter by `artisanId`, buyers view active products and own orders, and admins access platform-wide data, with final enforcement handled by security rules in PR39.

### 4.3 Firebase Storage

Product image media is stored in Firebase Storage through `StorageService.uploadProductImage()`. The canonical path format is `products/{artisanId}/{filename}`, which keeps assets grouped by artisan for cleanup and access control. The resulting download URL is persisted to the product document `imageUrl` field in Firestore. In image-management flows (PR36), deletion removes both the file in Storage and the associated Firestore URL reference so stale links are not retained.

### 4.4 Firebase Cloud Messaging (FCM)

FCM appears in the architecture as a notification-ready layer and is formally integrated as a stub in PR38. In MVP scope, the app requests notification permission after login and stores an FCM token in the user document for future routing. Full push delivery behavior for order-state transitions is intentionally deferred to post-MVP enhancements.

## 5. Data Flow Diagrams

### 5.1 User Registration and Role Routing

```text
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

This flow starts from a validated registration form, then chains Firebase Auth identity creation with Firestore profile creation so role and approval metadata exist at first login. Routing is centralized in RoleRouterScreen based on role and approval status, avoiding duplicated navigation logic. The same event stream supports both first-time registration and app restarts.

### 5.2 Product Creation by Artisan

```text
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

The artisan product flow separates media upload from metadata persistence to keep responsibilities clear and error handling targeted. Storage upload returns a URL that becomes part of the product object before Firestore write. Provider stream updates then trigger an immediate UI refresh in the product grid.

### 5.3 Order Placement by Buyer

```text
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

Checkout uses CartProvider local state as the source of truth, converts each item into an order write, and then clears local cart state only after persistence completes. The buyer is navigated directly to order history where stream-backed rendering confirms order creation in near real time. Initial status is always `pending`, enabling a consistent artisan update workflow.

## 6. State Management Architecture

CraftBridge standardizes on Provider as the sole state-management approach; no BLoC, Riverpod, or Redux layers are introduced to keep architecture predictable for a three-member team. The app registers four `ChangeNotifier` providers in `main.dart` under `MultiProvider`, creating a single root dependency graph for all screen modules.

`AuthProvider` is the critical gatekeeper and wraps `FirebaseAuth.instance.authStateChanges()` while exposing `currentUser`, `isInitialized`, `isLoading`, and `errorMessage` to consumers. Role-gated routing, splash bootstrapping, and login/session transitions are all driven from this provider.

`ProductProvider` owns product-state concerns and publishes `products`, `artisanProducts`, loading state, and errors while subscribing to Firestore stream updates for reactive catalog behavior. `OrderProvider` mirrors that strategy for `artisanOrders`, `buyerOrders`, and `allOrders`, giving each role a role-scoped real-time order view.

`CartProvider` intentionally remains local-only and does not write directly to Firestore; it exposes `items`, `totalPrice`, and `itemCount`, plus mutation methods (`addItem`, `removeItem`, `updateQuantity`, `clearCart`) that make cart behavior deterministic and testable.

Usage patterns are explicit: screens that must rebuild subscribe with `context.watch<T>()` or `Consumer<T>()`, while one-time intent actions such as button taps use `context.read<T>()`. This separation reduces unnecessary rebuilds and keeps UI/event intent clear.

## 7. Navigation Architecture

CraftBridge does not use named routes, `onGenerateRoute`, or a global route map. Navigation is explicit via `Navigator.push` and `Navigator.pushReplacement`, making screen transitions easy to trace in code review and debugging.

`RoleRouterScreen` is the central navigation hub after both login and app restart. It evaluates authenticated user state from `AuthProvider` and routes to the correct role home screen using replacement navigation so it never remains in back stack history.

Startup flow is `SplashScreen` to `RoleRouterScreen`: splash waits for auth bootstrap (`isInitialized`) and then performs `pushReplacement`. This prevents back navigation into non-interactive bootstrap screens.

Role modules navigate forward with `Navigator.push` and use default back behavior for screen-level return. Artisan and Admin flows avoid tabbed shell complexity, while Buyer flow introduces `BottomNavigationBar` later in PR45.

Modal interaction patterns remain scoped: product add/edit uses full-screen `Navigator.push`, while artisan order status changes use bottom sheets to preserve context and reduce navigation depth.

## 8. Security Architecture

Firestore access control is enforced primarily by security rules planned for PR39. Buyers are constrained to reading catalog data and writing their own orders, artisans manage only their own products and order subsets, and admins have broad oversight rights.

Client-side access is additionally gated by authentication state and role checks in `RoleRouterScreen`. Any null or invalid auth context is redirected to LoginScreen, ensuring private screens are not reachable through normal client navigation.

Storage is initialized in permissive test mode from PR04 and later hardened in PR39 to restrict write operations to authenticated artisan contexts and read operations to authenticated users. This aligns image access policy with Firestore role policy.

`firebase_options.dart` is intentionally committed and not treated as a secret artifact in mobile architecture. Security depends on Firebase rules, project configuration restrictions, and authorized app identities rather than hiding client configuration values.

## 9. Deployment Architecture

The MVP deployment target is Android, with release packaging documented in PR49 using signed APK workflows and keystore configuration. iOS remains supported by project configuration but is secondary and not the main submission channel.

Firebase Hosting is not part of the architecture because CraftBridge MVP has no web deployment target. Play Store submission steps are defined in PR50, with target API level 34 and `applicationId` set to `com.craftbridge.craft_bridge`.

CI/CD automation is intentionally excluded from MVP scope; release artifacts are built manually through Flutter CLI processes in controlled release PRs. The project uses a single Firebase environment for both development and production during MVP to minimize operational complexity, while split dev/prod environments are documented as a post-MVP enhancement.
