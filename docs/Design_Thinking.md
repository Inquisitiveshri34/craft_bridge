# CraftBridge - Design Thinking

## 1. Design Philosophy

CraftBridge is designed for real-world artisan commerce, where many artisans may have low technical confidence and need a calm, straightforward interface they can trust on first use. At the same time, buyers are mobile-first shoppers who expect clean browsing, fast navigation, and clear product detail experiences similar to modern commerce apps. The visual direction combines Material 3 usability foundations with a handcrafted aesthetic built on warm browns, soft off-whites, and natural earthy accents. The result is a UI language that feels welcoming and human while still being structured, scalable, and consistent for long-term product growth.

## 2. Color Palette

| Token | Hex Value | Usage |
|-------|-----------|-------|
| Primary (seed) | `#5C4033` | App bar, buttons, FAB, active states |
| Surface | `#FFF8F5` | Screen backgrounds, input fill |
| Accent / Sienna | `#A0522D` | Secondary highlights, category chips selected |
| On-surface | `#1C1B1F` | Body text, icons |
| Muted border | `#CAC4C0` | Input field borders (unfocused) |
| Divider | `#E0D6D0` | List dividers, card separators |
| Chip background | `#F0E6E0` | Unselected category filter chips |
| Error | `#BA1A1A` | Form validation errors, destructive actions |
| White | `#FFFFFF` | Card backgrounds, app bar text |

These colors were selected to communicate warmth, authenticity, and natural craft materials while keeping readability and clarity high across screens. Primary interactions use deep espresso tones for strong hierarchy, while surfaces remain soft and light to reduce visual fatigue. Supporting neutrals ensure forms and lists remain legible and structured at scale. Text and interactive contrast combinations are chosen to meet WCAG AA guidance for accessibility on their intended backgrounds.

## 3. Typography

| Style | Size | Weight | Usage in CraftBridge |
|-------|------|--------|----------------------|
| headlineLarge | 32sp | 700 | Welcome screens, empty state headings |
| headlineMedium | 28sp | 600 | Screen titles (non-AppBar), section headers |
| headlineSmall | 24sp | 600 | Card section headings |
| titleLarge | 22sp | 600 | AppBar title |
| titleMedium | 16sp | 600 | Product card title, list item primary text |
| bodyLarge | 16sp | 400 | Product descriptions, form labels |
| bodyMedium | 14sp | 400 | Supporting text, artisan name on card |
| bodySmall | 12sp | 400 | Timestamps, metadata, status chips |
| labelLarge | 14sp | 600 | Button labels |
| labelSmall | 11sp | 500 | Badge counts, micro labels |

## 4. User Personas

### Persona 1 - Artisan
- Name: Meera Devi
- Role: Artisan
- Age: 38
- Location: Jaipur, Rajasthan
- Tech Comfort: Low - uses WhatsApp and basic smartphone apps
- Goal: Sell her handmade block-print textiles beyond her local market without needing a middleman
- Pain Point: No digital storefront, relies on physical exhibitions, loses orders due to no order tracking
- What CraftBridge solves for them: A simple product listing flow (title, photo, price, stock), automatic admin approval that gives her legitimacy, and an order tracking screen that shows her exactly what buyers have ordered.

### Persona 2 - Buyer
- Name: Arjun Mehta
- Role: Buyer
- Age: 27
- Location: Bengaluru, Karnataka
- Tech Comfort: High - daily e-commerce user, expects app-store-quality UX
- Goal: Discover and buy authentic handcrafted goods directly from artisans, not factory-made imitations
- Pain Point: Mainstream e-commerce platforms mix handmade and mass-produced goods with no clear distinction
- What CraftBridge solves for them: A curated feed of only approved artisans' products, artisan context on the product detail screen including location on map, and a simple cart-to-order flow with order history.

### Persona 3 - Admin
- Name: Priya Nair
- Role: Admin
- Age: 34
- Location: Chennai, Tamil Nadu
- Tech Comfort: Medium - comfortable with web dashboards and basic mobile apps
- Goal: Maintain platform quality by ensuring only legitimate artisans are approved and all orders are visible for dispute resolution
- Pain Point: No central tool to review artisan registrations or monitor platform-wide order status
- What CraftBridge solves for them: A ManageUsersScreen that surfaces pending artisan registrations with approve/reject actions, and a ManageAllOrdersScreen that shows every order across the platform.

## 5. User Journey Maps

### Journey 1 - Artisan: From Registration to First Sale

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | RegistrationScreen | Selects "I am an Artisan", fills name, email, password, bio | Creates Firestore user doc with `isApproved: false` | Hopeful |
| 2 | RoleRouterScreen | App reads role and approval status | Redirects to pending approval screen | Anxious |
| 3 | (email/phone) | Waits for admin contact | Admin approves in ManageUsersScreen | Relieved |
| 4 | ArtisanHomeScreen | Logs in after approval | RoleRouter now routes to ArtisanHomeScreen | Excited |
| 5 | AddEditProductScreen | Adds product: photo, title, price, category, stock | Product saved to Firestore with `isActive: true` | Proud |
| 6 | ArtisanOrdersScreen | Buyer places an order | New order appears in artisan's orders list | Surprised, happy |
| 7 | ArtisanOrdersScreen | Taps order, updates status to "Confirmed" | Order status updates in Firestore in real time | Confident |

### Journey 2 - Buyer: From Browse to Order

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | RegistrationScreen | Selects "I am a Buyer", fills details | Creates Firestore user doc with role `buyer` | Curious |
| 2 | BuyerHomeScreen | Browses product grid | Loads all active products from approved artisans | Engaged |
| 3 | BuyerHomeScreen | Taps category chip to filter by "Textiles" | Grid filters to Textiles products only | Focused |
| 4 | ProductDetailScreen | Taps a product card | Sees full description, price, artisan name, map location | Interested |
| 5 | CartScreen | Taps "Add to Cart" | Item added to local CartProvider | Satisfied |
| 6 | CartScreen | Reviews cart, taps "Place Order" | Order written to Firestore orders collection | Excited |
| 7 | BuyerOrdersScreen | Views order history | Order shows status "Pending" | Patient |
| 8 | BuyerOrdersScreen | Checks back later | Status updated to "Confirmed" by artisan | Pleased |

### Journey 3 - Admin: Approve Artisan + Monitor Orders

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | LoginScreen | Logs in with admin credentials | RoleRouter reads `role: admin`, routes to AdminHomeScreen | In control |
| 2 | AdminHomeScreen | Taps "Manage Users" | Navigates to ManageUsersScreen | Focused |
| 3 | ManageUsersScreen | Sees list of pending artisan registrations | Firestore query for `isApproved: false` | Attentive |
| 4 | ManageUsersScreen | Taps "Approve" on Meera Devi's account | Sets `isApproved: true` in Firestore | Satisfied |
| 5 | AdminHomeScreen | Taps "All Orders" | Navigates to ManageAllOrdersScreen | Thorough |
| 6 | ManageAllOrdersScreen | Scrolls through all platform orders | Sees orders by all buyers across all artisans | Informed |

## 6. Wireframe Descriptions

### SplashScreen
Full-screen centered layout. Top: app logo placeholder (circular icon, 80x80). Middle: app name in `headlineMedium`. Bottom: tagline in `bodyLarge`. No app bar. Transitions automatically to RoleRouterScreen after auth check.

### LoginScreen
Single-column scrollable layout. Top: app logo (48x48) + app name. Below: "Welcome back" in `headlineSmall`. Two `CustomTextField` widgets - email and password (with visibility toggle). `CustomButton` - "Log In" (full width, primary color). Text button - "Don't have an account? Register". Error text in red below button if auth fails.

### RegistrationScreen
Single-column scrollable layout. Top: "Create Account" in `headlineSmall`. Fields: Display Name, Email, Password, Confirm Password. Role selector - two tappable cards: "I am an Artisan" and "I am a Buyer" with icons. Artisan card reveals a Bio text field when selected. `CustomButton` - "Create Account". Text button - "Already have an account? Log In".

### ArtisanHomeScreen
Scaffold with `AppBar` titled "My Shop". Body: `Column` with a welcome `Text` (artisan name), followed by two large navigation cards - "My Products" (navigates to ManageProductsScreen) and "My Orders" (navigates to ArtisanOrdersScreen). Cards use icon + label layout.

### ManageProductsScreen
Scaffold with `AppBar` titled "My Products". Body: `GridView` (2 columns) of `ProductCard` widgets. FAB (+ icon) navigates to AddEditProductScreen. Empty state: centered illustration + "No products yet. Tap + to add your first product." Swipe left on a card to reveal delete action.

### AddEditProductScreen
Scaffold with `AppBar` titled "Add Product" or "Edit Product". Scrollable single-column form. Fields: Title, Description, Price, Category (dropdown from `AppConstants.productCategories`), Stock (numeric). Image section: tappable image placeholder -> opens image picker -> shows preview. `CustomButton` - "Save Product" at bottom.

### ArtisanOrdersScreen
Scaffold with `AppBar` titled "My Orders". Body: `ListView` of `OrderCard` widgets. Each card shows: product image (60x60), product title, buyer name, quantity, total price, status chip. Tapping a card opens a bottom sheet with status update options.

### BuyerHomeScreen
Scaffold with `AppBar` titled "Discover". Body: `Column` - horizontal scrollable row of category filter chips, then `GridView` (2 columns, responsive) of `ProductCard` widgets. Search bar below the app bar. `BottomNavigationBar` with three tabs: Home, Cart, My Orders.

### ProductDetailScreen
Scaffold with `AppBar` (transparent, back button). Hero image (full width, aspect ratio 4:3). Below: product title in `titleLarge`, price in `headlineSmall` (primary color), artisan name + avatar row, description in `bodyLarge`, Google Map widget (250px height, artisan location marker), "Add to Cart" `CustomButton` fixed at bottom.

### CartScreen
Scaffold with `AppBar` titled "My Cart". Body: `ListView` of `CartItemTile` widgets. Each tile: product image (56x56), title, quantity stepper (- qty +), item total. Bottom: order summary card (subtotal, item count), "Place Order" `CustomButton`.

### BuyerOrdersScreen
Scaffold with `AppBar` titled "My Orders". Body: `ListView` of `OrderCard` widgets. Each card: product image, title, artisan name, status chip (color-coded), order date, total price.

### AdminHomeScreen
Scaffold with `AppBar` titled "Admin Dashboard". Body: `Column` of two large navigation cards - "Manage Users" and "All Orders" - with subtitle counts (pending approvals, total orders).

### ManageUsersScreen
Scaffold with `AppBar` titled "Manage Users". Body: `ListView` of user tiles. Each tile: avatar, display name, email, role chip. Artisan tiles show an approval status chip and Approve / Reject action buttons if `isApproved: false`.

### ManageAllOrdersScreen
Scaffold with `AppBar` titled "All Orders". Body: `ListView` of `OrderCard` widgets showing all orders across all artisans and buyers with status chips.

## 7. Accessibility Notes

- Minimum touch target size: 48x48dp for all interactive elements, per Material 3 guidelines.
- Color contrast: all primary text on surface backgrounds meets WCAG AA (4.5:1 for normal text, 3:1 for large text).
- All images must include semantic labels for screen readers via `semanticLabel` parameter on `Image` widgets.
- Form fields must use `labelText` and `hintText` so screen readers can identify field purpose.
- Status chips must not rely on color alone - always include a text label alongside the color indicator.
- `CustomButton` must never be disabled without also providing a visible explanation of why it is disabled.

## 8. Figma Reference Note

A Figma reference file was used during planning to define the structure, hierarchy, and visual behavior of all key screens described in this document. The Figma file itself is not committed in this repository, so this written specification is the implementation source of truth for the team. Any teammate building a screen should treat Section 6 here as the authoritative layout contract, alongside the matching technical requirements in that screen's PR document. 
